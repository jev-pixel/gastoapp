import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CardWalletCreate(BaseModel):
    provider: str = Field(min_length=1, max_length=50)
    name: str = Field(min_length=1, max_length=120)
    current_balance: float = Field(ge=0, default=0)


class CardWalletUpdate(BaseModel):
    provider: str | None = None
    name: str | None = None


class CardWalletRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    provider: str
    name: str
    current_balance: float
    created_at: datetime


class CardWalletTransactionCreate(BaseModel):
    amount: float = Field(gt=0)
    description: str | None = None
    idempotency_key: str | None = Field(default=None, max_length=100)


class CardWalletTransfer(BaseModel):
    # Exactly one source, one destination — physical wallet or a card wallet.
    from_card_wallet_id: uuid.UUID | None = None
    from_physical: bool = False
    to_card_wallet_id: uuid.UUID | None = None
    to_physical: bool = False
    amount: float = Field(gt=0)