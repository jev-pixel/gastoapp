import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class QrReservationStatus(str, enum.Enum):
    PENDING = "pending"
    SETTLED = "settled"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class BankProvider(str, enum.Enum):
    GCASH = "gcash"
    MAYA = "maya"
    UNIONBANK = "unionbank"
    BDO = "bdo"
    OTHER = "other"


class QrReservation(Base):
    __tablename__ = "qr_reservations"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    card_wallet_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("card_wallets.id", ondelete="CASCADE"), nullable=False)

    amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    merchant_name: Mapped[str | None] = mapped_column(String(120), nullable=True)
    destination_account: Mapped[str | None] = mapped_column(String(120), nullable=True)
    provider: Mapped[str] = mapped_column(Enum(BankProvider, name="bankprovider"), nullable=False)
    status: Mapped[str] = mapped_column(
        Enum(QrReservationStatus, name="qrreservationstatus"),
        default=QrReservationStatus.PENDING, nullable=False,
    )
    related_transaction_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True), ForeignKey("wallet_transactions.id", ondelete="SET NULL"), nullable=True
    )

    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship()
    card_wallet: Mapped["CardWallet"] = relationship()