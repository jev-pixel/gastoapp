import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.db.models.allowance import Allowance
from app.db.models.card_wallet import CardWallet
from app.db.models.user import User
from app.db.models.wallet_transaction import TransactionType, WalletTransaction
from app.schemas.allowance import WalletTransactionRead
from app.schemas.card_wallet import (
    CardWalletCreate,
    CardWalletRead,
    CardWalletTransactionCreate,
    CardWalletTransfer,
    CardWalletUpdate,
)

router = APIRouter(prefix="/api/v1/card-wallets", tags=["card-wallets"])


async def _get_owned_card_wallet(card_wallet_id: uuid.UUID, db: AsyncSession, user: User) -> CardWallet:
    result = await db.execute(
        select(CardWallet).where(CardWallet.id == card_wallet_id, CardWallet.user_id == user.id)
    )
    wallet = result.scalar_one_or_none()
    if not wallet:
        raise HTTPException(status_code=404, detail="Card wallet not found")
    return wallet


async def _unallocated_physical_balance(db: AsyncSession, user: User) -> float:
    """Mirrors wallet.py's helper: physical cash not already earmarked in an envelope."""
    result = await db.execute(
        select(func.coalesce(func.sum(Allowance.current_balance), 0)).where(Allowance.user_id == user.id)
    )
    allocated = float(result.scalar_one())
    return float(user.current_wallet_balance) - allocated


def _log(user: User, tx_type: TransactionType, amount: float, **kwargs) -> WalletTransaction:
    return WalletTransaction(user_id=user.id, type=tx_type, amount=amount, **kwargs)


async def _reject_duplicate(db: AsyncSession, user: User, idempotency_key: str | None):
    if not idempotency_key:
        return
    existing = await db.execute(
        select(WalletTransaction).where(
            WalletTransaction.user_id == user.id,
            WalletTransaction.idempotency_key == idempotency_key,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="This transaction was already submitted")


# ---- CRUD ----

@router.post("/", response_model=CardWalletRead, status_code=201)
async def create_card_wallet(
    payload: CardWalletCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    wallet = CardWallet(
        user_id=current_user.id,
        provider=payload.provider,
        name=payload.name,
        current_balance=payload.current_balance,
    )
    db.add(wallet)
    await db.commit()
    await db.refresh(wallet)
    return wallet


@router.get("/", response_model=list[CardWalletRead])
async def list_card_wallets(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(CardWallet).where(CardWallet.user_id == current_user.id).order_by(CardWallet.created_at.asc())
    )
    return result.scalars().all()


@router.patch("/{card_wallet_id}", response_model=CardWalletRead)
async def update_card_wallet(
    card_wallet_id: uuid.UUID,
    payload: CardWalletUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    wallet = await _get_owned_card_wallet(card_wallet_id, db, current_user)
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(wallet, field, value)
    await db.commit()
    await db.refresh(wallet)
    return wallet


@router.delete("/{card_wallet_id}", status_code=204)
async def delete_card_wallet(
    card_wallet_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    wallet = await _get_owned_card_wallet(card_wallet_id, db, current_user)
    if float(wallet.current_balance) > 0:
        raise HTTPException(
            status_code=400,
            detail="Transfer or spend down this card wallet's balance before deleting it",
        )
    await db.delete(wallet)
    await db.commit()


# ---- Add / Spend ----

@router.post("/{card_wallet_id}/allowances", response_model=WalletTransactionRead, status_code=201)
async def add_card_allowance(
    card_wallet_id: uuid.UUID,
    payload: CardWalletTransactionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    wallet = await _get_owned_card_wallet(card_wallet_id, db, current_user)
    await _reject_duplicate(db, current_user, payload.idempotency_key)

    wallet.current_balance = float(wallet.current_balance) + payload.amount
    tx = _log(
        current_user, TransactionType.CARD_ALLOWANCE, payload.amount,
        description=payload.description, card_wallet_id=wallet.id,
        idempotency_key=payload.idempotency_key,
    )
    db.add(tx)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=409, detail="This transaction was already submitted")
    await db.refresh(tx)
    return tx


@router.post("/{card_wallet_id}/expenses", response_model=WalletTransactionRead, status_code=201)
async def spend_card_allowance(
    card_wallet_id: uuid.UUID,
    payload: CardWalletTransactionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    wallet = await _get_owned_card_wallet(card_wallet_id, db, current_user)
    await _reject_duplicate(db, current_user, payload.idempotency_key)

    if payload.amount > float(wallet.current_balance):
        raise HTTPException(
            status_code=400,
            detail=f"Expense of {payload.amount:.2f} exceeds {wallet.name}'s balance of {float(wallet.current_balance):.2f}",
        )

    wallet.current_balance = float(wallet.current_balance) - payload.amount
    tx = _log(
        current_user, TransactionType.CARD_EXPENSE, payload.amount,
        description=payload.description, card_wallet_id=wallet.id,
        idempotency_key=payload.idempotency_key,
    )
    db.add(tx)
    try:
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=409, detail="This expense was already submitted")
    await db.refresh(tx)
    return tx


@router.get("/{card_wallet_id}/transactions", response_model=list[WalletTransactionRead])
async def list_card_wallet_transactions(
    card_wallet_id: uuid.UUID,
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    await _get_owned_card_wallet(card_wallet_id, db, current_user)
    result = await db.execute(
        select(WalletTransaction)
        .where(
            WalletTransaction.user_id == current_user.id,
            (WalletTransaction.card_wallet_id == card_wallet_id)
            | (WalletTransaction.from_card_wallet_id == card_wallet_id)
            | (WalletTransaction.to_card_wallet_id == card_wallet_id),
        )
        .order_by(WalletTransaction.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


# ---- Transfer (physical <-> card, or card <-> card) ----

@router.post("/transfer", response_model=WalletTransactionRead, status_code=201)
async def transfer_with_card_wallets(
    payload: CardWalletTransfer,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if sum([payload.from_card_wallet_id is not None, payload.from_physical]) != 1:
        raise HTTPException(status_code=400, detail="Specify exactly one source")
    if sum([payload.to_card_wallet_id is not None, payload.to_physical]) != 1:
        raise HTTPException(status_code=400, detail="Specify exactly one destination")
    if (
        payload.from_card_wallet_id is not None
        and payload.from_card_wallet_id == payload.to_card_wallet_id
    ):
        raise HTTPException(status_code=400, detail="Cannot transfer a card wallet into itself")
    if payload.from_physical and payload.to_physical:
        raise HTTPException(status_code=400, detail="Cannot transfer the physical wallet into itself")

    if payload.from_card_wallet_id is not None:
        from_wallet = await _get_owned_card_wallet(payload.from_card_wallet_id, db, current_user)
        if payload.amount > float(from_wallet.current_balance):
            raise HTTPException(
                status_code=400,
                detail=f"Transfer of {payload.amount:.2f} exceeds {from_wallet.name}'s balance",
            )
        from_wallet.current_balance = float(from_wallet.current_balance) - payload.amount
    else:
        # Protects money already earmarked in envelopes — only unallocated cash can leave.
        unallocated = await _unallocated_physical_balance(db, current_user)
        if payload.amount > unallocated:
            raise HTTPException(
                status_code=400,
                detail=f"Transfer of {payload.amount:.2f} exceeds unallocated physical balance of {unallocated:.2f}",
            )
        current_user.current_wallet_balance = float(current_user.current_wallet_balance) - payload.amount

    if payload.to_card_wallet_id is not None:
        to_wallet = await _get_owned_card_wallet(payload.to_card_wallet_id, db, current_user)
        to_wallet.current_balance = float(to_wallet.current_balance) + payload.amount
    else:
        current_user.current_wallet_balance = float(current_user.current_wallet_balance) + payload.amount

    tx = _log(
        current_user, TransactionType.TRANSFER, payload.amount,
        from_card_wallet_id=payload.from_card_wallet_id,
        to_card_wallet_id=payload.to_card_wallet_id,
        description="Physical wallet" if (payload.from_physical or payload.to_physical) else None,
    )
    db.add(tx)
    await db.commit()
    await db.refresh(tx)
    return tx