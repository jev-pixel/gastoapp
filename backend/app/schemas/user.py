import uuid

from pydantic import BaseModel, EmailStr, ConfigDict


class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: str
    monthly_income: float = 0
    target_savings_floor: float = 0
    current_wallet_balance: float = 0


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    email: EmailStr
    full_name: str
    monthly_income: float
    target_savings_floor: float
    current_wallet_balance: float


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserUpdate(BaseModel):
    full_name: str | None = None
    monthly_income: float | None = None
    target_savings_floor: float | None = None
    current_wallet_balance: float | None = None
