import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.db.models.allowance import Allowance
from app.db.models.expense import Expense
from app.db.models.user import User
from app.db.models.wallet_transaction import TransactionType, WalletTransaction
from app.schemas.allowance import (
    AllowanceCreate,
    AllowanceExpenseCreate,
    AllowanceRead,
    AllowanceResize,
    AllowanceTransfer,
    UnallocatedSimulationRequest,
    UnallocatedSimulationResponse,
    WalletSummary,
    WalletTransactionRead,
)
from app.services.wallet_ai_service import get_unallocated_funds_recommendation

router = APIRouter(prefix="/api/v1/wallet", tags=["wallet"])


# ---- helpers ----

async def _get_owned_allowance(allowance_id: uuid.UUID, db: AsyncSession, user: User) -> Allowance:
    result = await db.execute(
        select(Allowance).where(Allowance.id == allowance_id, Allowance.user_id == user.id)
    )
    allowance = result.scalar_one_or_none()
    if not allowance:
        raise HTTPException(status_code=404, detail="Allowance not found")
    return allowance


async def _allocated_total(db: AsyncSession, user: User) -> float:
    result = await db.execute(
        select(func.coalesce(func.sum(Allowance.current_balance), 0)).where(
            Allowance.user_id == user.id
        )
    )
    return float(result.scalar_one())


async def _unallocated_balance(db: AsyncSession, user: User) -> float:
    allocated = await _allocated_total(db, user)
    return float(user.current_wallet_balance) - allocated


def _log(
    user: User,
    tx_type: TransactionType,
    amount: float,
    *,
    description: str | None = None,
    allowance_id: uuid.UUID | None = None,
    from_allowance_id: uuid.UUID | None = None,
    to_allowance_id: uuid.UUID | None = None,
    related_expense_id: uuid.UUID | None = None,
    idempotency_key: str | None = None,
) -> WalletTransaction:
    return WalletTransaction(
        user_id=user.id,
        type=tx_type,
        amount=amount,
        description=description,
        allowance_id=allowance_id,
        from_allowance_id=from_allowance_id,
        to_allowance_id=to_allowance_id,
        related_expense_id=related_expense_id,
        idempotency_key=idempotency_key,
    )


# ---- Summary ----

@router.get("/summary", response_model=WalletSummary)
async def get_wallet_summary(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Allowance).where(Allowance.user_id == current_user.id).order_by(Allowance.created_at.asc())
    )
    allowances = result.scalars().all()
    allocated_total = sum(float(a.current_balance) for a in allowances)
    return WalletSummary(
        current_wallet_balance=float(current_user.current_wallet_balance),
        allocated_total=allocated_total,
        unallocated_balance=float(current_user.current_wallet_balance) - allocated_total,
        allowances=allowances,
    )


# ---- Allowances ----

@router.post("/allowances", response_model=AllowanceRead, status_code=201)
async def create_allowance(
    payload: AllowanceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Rule: allocation cannot exceed wallet balance (i.e. cannot exceed
    # what's currently unallocated).
    unallocated = await _unallocated_balance(db, current_user)
    if payload.allocated_amount > unallocated:
        raise HTTPException(
            status_code=400,
            detail=f"Allocation of {payload.allocated_amount:.2f} exceeds unallocated balance of {unallocated:.2f}",
        )

    allowance = Allowance(
        user_id=current_user.id,
        name=payload.name,
        allocated_amount=payload.allocated_amount,
        current_balance=payload.allocated_amount,
    )
    db.add(allowance)
    await db.flush()  # get allowance.id before logging the transaction

    db.add(_log(
        current_user,
        TransactionType.ALLOCATION,
        payload.allocated_amount,
        description=f"Allocated to {payload.name}",
        allowance_id=allowance.id,
    ))

    await db.commit()
    await db.refresh(allowance)
    return allowance


@router.patch("/allowances/{allowance_id}", response_model=AllowanceRead)
async def resize_allowance(
    allowance_id: uuid.UUID,
    payload: AllowanceResize,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    allowance = await _get_owned_allowance(allowance_id, db, current_user)
    delta = payload.allocated_amount - float(allowance.allocated_amount)

    if delta > 0:
        unallocated = await _unallocated_balance(db, current_user)
        if delta > unallocated:
            raise HTTPException(
                status_code=400,
                detail=f"Increase of {delta:.2f} exceeds unallocated balance of {unallocated:.2f}",
            )
        allowance.current_balance = float(allowance.current_balance) + delta
        db.add(_log(
            current_user, TransactionType.ALLOCATION, delta,
            description=f"Increased {allowance.name}", allowance_id=allowance.id,
        ))
    elif delta < 0:
        amount_to_return = -delta
        if amount_to_return > float(allowance.current_balance):
            raise HTTPException(
                status_code=400,
                detail="Cannot shrink this allowance below what's already been spent from it",
            )
        allowance.current_balance = float(allowance.current_balance) - amount_to_return
        db.add(_log(
            current_user, TransactionType.DEALLOCATION, amount_to_return,
            description=f"Decreased {allowance.name}", allowance_id=allowance.id,
        ))

    allowance.allocated_amount = payload.allocated_amount
    await db.commit()
    await db.refresh(allowance)
    return allowance


@router.delete("/allowances/{allowance_id}", status_code=204)
async def delete_allowance(
    allowance_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    allowance = await _get_owned_allowance(allowance_id, db, current_user)
    remaining = float(allowance.current_balance)
    if remaining > 0:
        db.add(_log(
            current_user, TransactionType.DEALLOCATION, remaining,
            description=f"Deleted {allowance.name} — returned to unallocated",
            allowance_id=allowance.id,
        ))
    await db.delete(allowance)
    await db.commit()


# ---- Expenses against an allowance or unallocated funds ----

@router.post("/expenses", response_model=WalletTransactionRead, status_code=201)
async def create_allowance_expense(
    payload: AllowanceExpenseCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Rule: duplicate expense requests must be rejected. Pre-check for a
    # friendly error message; the DB unique constraint is the hard backstop
    # in case of a race between two near-simultaneous identical requests.
    if payload.idempotency_key:
        existing = await db.execute(
            select(WalletTransaction).where(
                WalletTransaction.user_id == current_user.id,
                WalletTransaction.idempotency_key == payload.idempotency_key,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=409, detail="This expense was already submitted")

    allowance: Allowance | None = None
    if payload.allowance_id is not None:
        allowance = await _get_owned_allowance(payload.allowance_id, db, current_user)
        # Rule: expense cannot exceed allowance remaining balance.
        if payload.amount > float(allowance.current_balance):
            raise HTTPException(
                status_code=400,
                detail=f"Expense of {payload.amount:.2f} exceeds {allowance.name}'s remaining balance of {float(allowance.current_balance):.2f}",
            )
    else:
        unallocated = await _unallocated_balance(db, current_user)
        # Rule: expense cannot exceed unallocated balance.
        if payload.amount > unallocated:
            raise HTTPException(
                status_code=400,
                detail=f"Expense of {payload.amount:.2f} exceeds unallocated balance of {unallocated:.2f}",
            )

    # Rule: wallet balance cannot be negative — final safety check even
    # though the allowance/unallocated checks above should already prevent
    # this from being reachable.
    new_wallet_balance = float(current_user.current_wallet_balance) - payload.amount
    if new_wallet_balance < 0:
        raise HTTPException(status_code=400, detail="Expense would make the wallet balance negative")

    expense = Expense(
        user_id=current_user.id,
        amount=payload.amount,
        category=payload.category,
        description=payload.description,
    )
    db.add(expense)
    await db.flush()

    if allowance is not None:
        allowance.current_balance = float(allowance.current_balance) - payload.amount

    current_user.current_wallet_balance = new_wallet_balance

    tx = _log(
        current_user,
        TransactionType.EXPENSE_ALLOWANCE if allowance is not None else TransactionType.EXPENSE_UNALLOCATED,
        payload.amount,
        description=payload.description,
        allowance_id=allowance.id if allowance is not None else None,
        related_expense_id=expense.id,
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


# ---- Transfers ----

@router.post("/transfer", response_model=WalletTransactionRead, status_code=201)
async def transfer_between_allowances(
    payload: AllowanceTransfer,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if payload.from_allowance_id is None and payload.to_allowance_id is None:
        raise HTTPException(status_code=400, detail="Specify at least one of from/to allowance")
    if payload.from_allowance_id == payload.to_allowance_id and payload.from_allowance_id is not None:
        raise HTTPException(status_code=400, detail="Cannot transfer an allowance into itself")

    from_allowance: Allowance | None = None
    to_allowance: Allowance | None = None

    if payload.from_allowance_id is not None:
        from_allowance = await _get_owned_allowance(payload.from_allowance_id, db, current_user)
        if payload.amount > float(from_allowance.current_balance):
            raise HTTPException(
                status_code=400,
                detail=f"Transfer of {payload.amount:.2f} exceeds {from_allowance.name}'s balance",
            )
        from_allowance.current_balance = float(from_allowance.current_balance) - payload.amount
    else:
        unallocated = await _unallocated_balance(db, current_user)
        if payload.amount > unallocated:
            raise HTTPException(
                status_code=400,
                detail=f"Transfer of {payload.amount:.2f} exceeds unallocated balance of {unallocated:.2f}",
            )
        # No row to decrement — unallocated is derived, so reducing it
        # happens implicitly once the destination allowance below increases.

    if payload.to_allowance_id is not None:
        to_allowance = await _get_owned_allowance(payload.to_allowance_id, db, current_user)
        to_allowance.current_balance = float(to_allowance.current_balance) + payload.amount
    # If to_allowance_id is None, the funds land in unallocated implicitly
    # (from_allowance.current_balance was already reduced above).

    tx = _log(
        current_user,
        TransactionType.TRANSFER,
        payload.amount,
        from_allowance_id=payload.from_allowance_id,
        to_allowance_id=payload.to_allowance_id,
    )
    db.add(tx)
    await db.commit()
    await db.refresh(tx)
    return tx


# ---- Transaction history ----

@router.get("/transactions", response_model=list[WalletTransactionRead])
async def list_wallet_transactions(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(WalletTransaction)
        .where(WalletTransaction.user_id == current_user.id)
        .order_by(WalletTransaction.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


# ---- AI Simulator for unallocated funds ----

@router.post("/simulate-unallocated", response_model=UnallocatedSimulationResponse)
async def simulate_unallocated_funds(
    payload: UnallocatedSimulationRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Allowance).where(Allowance.user_id == current_user.id).order_by(Allowance.created_at.asc())
    )
    allowances = result.scalars().all()
    allocated_total = sum(float(a.current_balance) for a in allowances)
    unallocated = float(current_user.current_wallet_balance) - allocated_total

    ai_result = await get_unallocated_funds_recommendation(
        unallocated_balance=unallocated,
        allowances=[
            {"name": a.name, "allocated_amount": float(a.allocated_amount), "current_balance": float(a.current_balance)}
            for a in allowances
        ],
        monthly_income=float(current_user.monthly_income),
        target_savings_floor=float(current_user.target_savings_floor),
        goal_description=payload.goal_description,
    )

    return UnallocatedSimulationResponse(
        unallocated_balance=unallocated,
        recommendation_summary=ai_result["recommendation_summary"],
        risk_note=ai_result["risk_note"],
        suggested_actions=ai_result["suggested_actions"],
    )