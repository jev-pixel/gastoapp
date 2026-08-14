import uuid

from pydantic import BaseModel


class ScenarioRequest(BaseModel):
    proposed_amount: float
    category: str  # e.g. "Wants/Entertainment"
    description: str | None = None

    # Simplification for now: caller supplies these directly rather than the
    # app deriving them from a full pay-cycle model. Revisit once payout
    # frequency / cycle tracking is built out.
    essential_allowance_remaining: float = 0
    remaining_days_in_cycle: int | None = None  # defaults to days left in current calendar month


class CompromiseOption(BaseModel):
    action: str
    new_amount: float
    impact_description: str


class ScenarioResponse(BaseModel):
    verdict: str
    verdict_summary: str
    risk_level: str
    post_expense_daily_budget: float
    trade_off_analysis: str
    compromise_options: list[CompromiseOption]