import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class TransactionType(str, enum.Enum):
    ALLOCATION = "allocation"
    DEALLOCATION = "deallocation"
    EXPENSE_ALLOWANCE = "expense_allowance"
    EXPENSE_UNALLOCATED = "expense_unallocated"
    TRANSFER = "transfer"


class WalletTransaction(Base):
    __tablename__ = "wallet_transactions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    type: Mapped[TransactionType] = mapped_column(
        Enum(TransactionType, name="transactiontype"), nullable=False
    )
    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    description: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # Single-allowance operations (allocation/deallocation/expense-from-allowance)
    allowance_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("allowances.id", ondelete="SET NULL"), nullable=True
    )
    # Two-sided operations (transfer between allowances / unallocated)
    from_allowance_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("allowances.id", ondelete="SET NULL"), nullable=True
    )
    to_allowance_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("allowances.id", ondelete="SET NULL"), nullable=True
    )
    related_expense_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("expenses.id", ondelete="SET NULL"), nullable=True
    )
    # Nullable + unique so a client-generated key can't be submitted twice,
    # while requests that don't send one (None) don't collide with each other.
    idempotency_key: Mapped[str | None] = mapped_column(String(100), nullable=True, unique=True)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="wallet_transactions")
