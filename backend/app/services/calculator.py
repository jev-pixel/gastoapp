from dataclasses import dataclass


@dataclass
class FinancialContext:
    current_wallet_balance: float
    fixed_dues_unpaid: float
    essential_allowance_remaining: float
    target_savings_buffer: float
    remaining_days_in_cycle: int


def compute_financial_impact(ctx: FinancialContext, proposed_amount: float) -> dict:
    """
    Pure deterministic math — no AI involvement. This is the single source of truth
    for all financial figures; the AI layer only interprets these numbers, never
    recalculates them.
    """
    total_committed = (
        ctx.fixed_dues_unpaid + ctx.essential_allowance_remaining + ctx.target_savings_buffer
    )
    disposable_before = ctx.current_wallet_balance - total_committed
    disposable_after = disposable_before - proposed_amount

    days = max(1, ctx.remaining_days_in_cycle)  # avoid division by zero
    daily_before = max(0.0, disposable_before / days)
    daily_after = max(0.0, disposable_after / days)

    if disposable_after < 0:
        risk_level = "HIGH"
    elif disposable_after < (ctx.target_savings_buffer * 0.5):
        risk_level = "MEDIUM"
    else:
        risk_level = "LOW"

    return {
        "disposable_before": round(disposable_before, 2),
        "disposable_after": round(disposable_after, 2),
        "daily_disposable_before": round(daily_before, 2),
        "daily_disposable_after": round(daily_after, 2),
        "risk_level": risk_level,
        "savings_floor_breached": disposable_after < 0,
    }