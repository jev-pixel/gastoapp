import uuid
from datetime import datetime

from sqlalchemy import DateTime, Integer, Numeric, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)

    # PIN brute-force guardrails. A 4-digit PIN only has 10,000 possible
    # values — unlike a real password, bcrypt's work factor alone doesn't
    # protect it against online guessing, so it MUST be paired with a
    # lockout. See the /auth/login endpoint for how these are used.
    failed_pin_attempts: Mapped[int] = mapped_column(
        Integer, default=0, server_default="0", nullable=False
    )
    locked_until: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    # Financial profile — feeds the deterministic calculator's FinancialContext
    monthly_income: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    target_savings_floor: Mapped[float] = mapped_column(Numeric(12, 2), default=0)
    current_wallet_balance: Mapped[float] = mapped_column(Numeric(12, 2), default=0)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    fixed_bills: Mapped[list["FixedBill"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    expenses: Mapped[list["Expense"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    scenario_logs: Mapped[list["AIScenarioLog"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    allowances: Mapped[list["Allowance"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    wallet_transactions: Mapped[list["WalletTransaction"]] = relationship(back_populates="user", cascade="all, delete-orphan")
