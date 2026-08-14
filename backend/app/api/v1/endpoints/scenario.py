from datetime import date, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.db.models.ai_scenario_log import AIScenarioLog
from app.db.models.fixed_bill import FixedBill
from app.db.models.user import User
from app.schemas.scenario import ScenarioRequest, ScenarioResponse
from app.services.calculator import FinancialContext, compute_financial_impact
from app.services.ai_service import get_ai_verdict
from sqlalchemy import select

router = APIRouter(prefix="/api/v1/scenario", tags=["scenario"])


def _days_left_in_month() -> int:
    today = date.today()
    if today.month == 12:
        next_month_start = date(today.year + 1, 1, 1)
    else:
        next_month_start = date(today.year, today.month + 1, 1)
    return (next_month_start - today).days


@router.post("/", response_model=ScenarioResponse)
async def simulate_scenario(
    payload: ScenarioRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Sum unpaid fixed bills for this user
    result = await db.execute(
        select(FixedBill).where(
            FixedBill.user_id == current_user.id,
            FixedBill.is_paid_current_cycle == False,  # noqa: E712
        )
    )
    fixed_dues_unpaid = sum(float(bill.amount) for bill in result.scalars().all())

    remaining_days = payload.remaining_days_in_cycle or _days_left_in_month()

    ctx = FinancialContext(
        current_wallet_balance=float(current_user.current_wallet_balance),
        fixed_dues_unpaid=fixed_dues_unpaid,
        essential_allowance_remaining=payload.essential_allowance_remaining,
        target_savings_buffer=float(current_user.target_savings_floor),
        remaining_days_in_cycle=remaining_days,
    )
    calc_result = compute_financial_impact(ctx, payload.proposed_amount)

    ai_result = await get_ai_verdict(
        monthly_income=float(current_user.monthly_income),
        remaining_days_in_cycle=remaining_days,
        fixed_dues_unpaid=fixed_dues_unpaid,
        essential_allowance_remaining=payload.essential_allowance_remaining,
        target_savings_floor=float(current_user.target_savings_floor),
        proposed_amount=payload.proposed_amount,
        category=payload.category,
        calc_result=calc_result,
    )

    log_entry = AIScenarioLog(
        user_id=current_user.id,
        proposed_amount=payload.proposed_amount,
        risk_level=ai_result["risk_level"],
        verdict=ai_result["verdict"],
        raw_response=ai_result,
    )
    db.add(log_entry)
    await db.commit()

    return ai_result