import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Allowance(Base):
    __tablename__ = "allowances"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    name: Mapped[str] = mapped_column(String(120), nullable=False)  # e.g. "Emergency", "Foods"
    allocated_amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    current_balance: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="allowances")
