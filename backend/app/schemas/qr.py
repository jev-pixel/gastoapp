import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

from app.db.models.qr_reservation import BankProvider, QrReservationStatus


class QrReserveRequest(BaseModel):
    card_wallet_id: uuid.UUID
    amount: float = Field(gt=0)
    provider: BankProvider
    merchant_name: str | None = None
    destination_account: str | None = None
    raw_payload: str | None = None  # original scanned string, kept for audit only


class QrReservationRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    card_wallet_id: uuid.UUID
    amount: float
    provider: BankProvider
    merchant_name: str | None
    destination_account: str | None
    status: QrReservationStatus
    expires_at: datetime
    created_at: datetime


class QrDeepLinkInfo(BaseModel):
    ios_scheme: str
    android_package: str
    store_fallback_ios: str
    store_fallback_android: str