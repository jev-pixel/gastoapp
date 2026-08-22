import re
import uuid

from pydantic import BaseModel, EmailStr, ConfigDict, field_validator

_PIN_PATTERN = re.compile(r"^\d{4}$")


def _validate_pin(value: str) -> str:
    if not _PIN_PATTERN.match(value):
        raise ValueError("PIN must be exactly 4 digits (0-9 only)")
    return value


class UserCreate(BaseModel):
    email: EmailStr
    password: str  # 4-digit PIN — stored hashed, see security.py
    full_name: str
    monthly_income: float = 0
    target_savings_floor: float = 0
    current_wallet_balance: float = 0

    @field_validator("password")
    @classmethod
    def check_pin_format(cls, v: str) -> str:
        return _validate_pin(v)


class UserLogin(BaseModel):
    email: EmailStr
    password: str  # 4-digit PIN

    @field_validator("password")
    @classmethod
    def check_pin_format(cls, v: str) -> str:
        return _validate_pin(v)


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
