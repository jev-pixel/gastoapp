import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict

from app.db.models.expense import ExpenseCategory


class ExpenseCreate(BaseModel):
    amount: float
    category: ExpenseCategory
    description: str | None = None


class ExpenseRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    amount: float
    category: ExpenseCategory
    description: str | None
    occurred_at: datetime


class FixedBillCreate(BaseModel):
    name: str
    amount: float
    due_day: int
    is_paid_current_cycle: bool = False


class FixedBillRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    amount: float
    due_day: int
    is_paid_current_cycle: bool


class FixedBillUpdate(BaseModel):
    name: str | None = None
    amount: float | None = None
    due_day: int | None = None
    # is_paid_current_cycle: bool | None = None