from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.core.security import create_access_token, hash_password, verify_password
from app.db.models.user import User
from app.schemas.user import Token, UserCreate, UserLogin, UserRead, UserUpdate

router = APIRouter(prefix="/api/v1/auth", tags=["auth"])

# A 4-digit PIN only has 10,000 combinations, so — unlike a real password —
# it's meaningless to rely on hashing cost alone; it has to be paired with
# a lockout or it's trivially guessable via online brute force.
PIN_LOCKOUT_THRESHOLD = 5
PIN_LOCKOUT_MINUTES = 5


@router.get("/me", response_model=UserRead)
async def read_me(
    current_user: User = Depends(get_current_user),
):
    return current_user


@router.patch("/me", response_model=UserRead)
async def update_me(
    payload: UserUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(current_user, field, value)
    await db.commit()
    await db.refresh(current_user)
    return current_user


@router.post("/register", response_model=UserRead, status_code=status.HTTP_201_CREATED)
async def register(payload: UserCreate, db: AsyncSession = Depends(get_db)):
    existing = await db.execute(select(User).where(User.email == payload.email))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
        full_name=payload.full_name,
        monthly_income=payload.monthly_income,
        target_savings_floor=payload.target_savings_floor,
        current_wallet_balance=payload.current_wallet_balance,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


@router.post("/login", response_model=Token)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    now = datetime.now(timezone.utc)

    # Locked accounts are rejected before even checking the PIN, so a
    # locked-out attacker can't use response timing to learn anything.
    if user and user.locked_until and user.locked_until > now:
        wait_minutes = max(1, int((user.locked_until - now).total_seconds() // 60) + 1)
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Too many incorrect PIN attempts. Try again in {wait_minutes} minute(s).",
        )

    if not user or not verify_password(payload.password, user.hashed_password):
        if user:
            user.failed_pin_attempts += 1
            if user.failed_pin_attempts >= PIN_LOCKOUT_THRESHOLD:
                user.locked_until = now + timedelta(minutes=PIN_LOCKOUT_MINUTES)
            await db.commit()
        raise HTTPException(status_code=401, detail="Incorrect email or PIN")

    # Successful login — clear any accumulated strikes.
    if user.failed_pin_attempts or user.locked_until:
        user.failed_pin_attempts = 0
        user.locked_until = None
        await db.commit()

    token = create_access_token(subject=str(user.id))
    return Token(access_token=token)
