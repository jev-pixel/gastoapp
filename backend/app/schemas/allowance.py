import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field

from app.db.models.expense import ExpenseCategory
from app.db.models.wallet_transaction import TransactionType


# ---- Allowances ----

class AllowanceCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    allocated_amount: float = Field(gt=0)


class AllowanceResize(BaseModel):
    # New total allocated_amount for this envelope. The delta (up or down)
    # is moved to/from unallocated automatically.
    allocated_amount: float = Field(gt=0)


class AllowanceRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    name: str
    allocated_amount: float
    current_balance: float


class WalletSummary(BaseModel):
    current_wallet_balance: float
    allocated_total: float
    unallocated_balance: float
    allowances: list[AllowanceRead]


# ---- Expenses against allowances / unallocated ----

class AllowanceExpenseCreate(BaseModel):
    # None = pay from unallocated funds directly.
    allowance_id: uuid.UUID | None = None
    amount: float = Field(gt=0)
    category: ExpenseCategory
    description: str | None = None
    # Optional client-generated key (e.g. a UUID created once per submit
    # attempt) so a double-tapped submit button can't create two expenses.
    idempotency_key: str | None = Field(default=None, max_length=100)


# ---- Transfers ----

class AllowanceTransfer(BaseModel):
    # None on either side means "unallocated".
    from_allowance_id: uuid.UUID | None = None
    to_allowance_id: uuid.UUID | None = None
    amount: float = Field(gt=0)


# ---- Transaction history ----

class WalletTransactionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    type: TransactionType
    amount: float
    description: str | None
    allowance_id: uuid.UUID | None
    from_allowance_id: uuid.UUID | None
    to_allowance_id: uuid.UUID | None
    related_expense_id: uuid.UUID | None
    created_at: datetime


# ---- AI Simulator for unallocated funds ----

class UnallocatedSimulationRequest(BaseModel):
    # Optional: what the user is thinking about doing with the leftover
    # money (e.g. "buy a new phone", "just save it"). Left blank, the AI
    # gives a general recommendation based on the allowance picture alone.
    goal_description: str | None = Field(default=None, max_length=300)


class SuggestedAllocation(BaseModel):
    action: str  # e.g. "Top up Emergency Allowance", "Keep as savings buffer"
    target_allowance_name: str | None = None  # null if the suggestion isn't tied to an existing envelope
    suggested_amount: float
    reasoning: str


class UnallocatedSimulationResponse(BaseModel):
    unallocated_balance: float
    recommendation_summary: str
    risk_note: str
    suggested_actions: list[SuggestedAllocation]