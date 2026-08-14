import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.db.models.expense import Expense, ExpenseCategory
from app.db.models.fixed_bill import FixedBill
from app.db.models.user import User
from app.schemas.ledger import (
    ExpenseCreate,
    ExpenseRead,
    FixedBillCreate,
    FixedBillRead,
    FixedBillUpdate,
)

router = APIRouter(prefix="/api/v1/expenses", tags=["ledger"])


# ---- Expenses ----

@router.post("/", response_model=ExpenseRead, status_code=201)
async def create_expense(
    payload: ExpenseCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    expense = Expense(user_id=current_user.id, **payload.model_dump())
    db.add(expense)
    await db.commit()
    await db.refresh(expense)
    return expense


@router.get("/", response_model=list[ExpenseRead])
async def list_expenses(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Expense)
        .where(Expense.user_id == current_user.id)
        .order_by(Expense.occurred_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


@router.delete("/{expense_id}", status_code=204)
async def delete_expense(
    expense_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Expense).where(Expense.id == expense_id, Expense.user_id == current_user.id)
    )
    expense = result.scalar_one_or_none()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    await db.delete(expense)
    await db.commit()


# ---- Fixed Bills ----

@router.post("/fixed-bills", response_model=FixedBillRead, status_code=201)
async def create_fixed_bill(
    payload: FixedBillCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    bill = FixedBill(user_id=current_user.id, **payload.model_dump())
    db.add(bill)
    await db.commit()
    await db.refresh(bill)
    return bill


@router.get("/fixed-bills", response_model=list[FixedBillRead])
async def list_fixed_bills(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(FixedBill)
        .where(FixedBill.user_id == current_user.id)
        .order_by(FixedBill.due_day.asc())
        .offset(skip)
        .limit(limit)
    )
    return result.scalars().all()


@router.post("/fixed-bills/{bill_id}/pay", response_model=FixedBillRead)
async def pay_fixed_bill(
    bill_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    bill = await _get_owned_bill(bill_id, db, current_user)
    if bill.is_paid_current_cycle:
        raise HTTPException(status_code=400, detail="Bill is already marked as paid")

    current_user.current_wallet_balance = float(current_user.current_wallet_balance) - float(bill.amount)
    bill.is_paid_current_cycle = True

    db.add(Expense(
        user_id=current_user.id,
        amount=bill.amount,
        category=ExpenseCategory.FIXED_DUE,
        description=f"Paid: {bill.name}",
        related_fixed_bill_id=bill.id,
    ))

    await db.commit()
    await db.refresh(bill)
    return bill

@router.post("/fixed-bills/{bill_id}/unpay", response_model=FixedBillRead)
async def unpay_fixed_bill(
    bill_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    bill = await _get_owned_bill(bill_id, db, current_user)
    if not bill.is_paid_current_cycle:
        raise HTTPException(status_code=400, detail="Bill is not currently marked as paid")

    # Refund the wallet
    current_user.current_wallet_balance = float(current_user.current_wallet_balance) + float(bill.amount)
    bill.is_paid_current_cycle = False

    # Remove the linked expense record
    result = await db.execute(
        select(Expense)
        .where(Expense.related_fixed_bill_id == bill.id, Expense.user_id == current_user.id)
        .order_by(Expense.occurred_at.desc())
    )
    linked_expense = result.scalars().first()
    if linked_expense:
        await db.delete(linked_expense)

    await db.commit()
    await db.refresh(bill)
    return bill


async def _get_owned_bill(bill_id: uuid.UUID, db: AsyncSession, current_user: User) -> FixedBill:
    result = await db.execute(
        select(FixedBill).where(FixedBill.id == bill_id, FixedBill.user_id == current_user.id)
    )
    bill = result.scalar_one_or_none()
    if not bill:
        raise HTTPException(status_code=404, detail="Fixed bill not found")
    return bill


@router.patch("/fixed-bills/{bill_id}", response_model=FixedBillRead)
async def update_fixed_bill(
    bill_id: uuid.UUID,
    payload: FixedBillUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    bill = await _get_owned_bill(bill_id, db, current_user)
    updates = payload.model_dump(exclude_unset=True)
    for field, value in updates.items():
        setattr(bill, field, value)
    await db.commit()
    await db.refresh(bill)
    return bill



@router.delete("/fixed-bills/{bill_id}", status_code=204)
async def delete_fixed_bill(
    bill_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    bill = await _get_owned_bill(bill_id, db, current_user)
    await db.delete(bill)
    await db.commit()