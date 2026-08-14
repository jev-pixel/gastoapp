import json

from google import genai
from google.genai import types

from app.core.config import settings

_client: genai.Client | None = None


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        _client = genai.Client(api_key=settings.GEMINI_API_KEY)
    return _client


SYSTEM_INSTRUCTION = """You are GastoApp's AI Financial Advisor. Rely STRICTLY on the provided
pre-computed metrics. Do NOT recalculate numbers. Deliver a verdict ("APPROVED",
"PROCEED WITH CAUTION", "NOT RECOMMENDED"), a concise explanation, and 1 to 2 actionable
compromise options. Be consistent and conservative in your assessments — favor the same
verdict for materially identical inputs. Return valid JSON matching the response schema."""

RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "verdict": {"type": "string", "enum": ["APPROVED", "PROCEED WITH CAUTION", "NOT RECOMMENDED"]},
        "verdict_summary": {"type": "string"},
        "risk_level": {"type": "string"},
        "post_expense_daily_budget": {"type": "number"},
        "trade_off_analysis": {"type": "string"},
        "compromise_options": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "action": {"type": "string"},
                    "new_amount": {"type": "number"},
                    "impact_description": {"type": "string"},
                },
                "required": ["action", "new_amount", "impact_description"],
            },
        },
    },
    "required": [
        "verdict",
        "verdict_summary",
        "risk_level",
        "post_expense_daily_budget",
        "trade_off_analysis",
        "compromise_options",
    ],
}


async def get_ai_verdict(
    monthly_income: float,
    remaining_days_in_cycle: int,
    fixed_dues_unpaid: float,
    essential_allowance_remaining: float,
    target_savings_floor: float,
    proposed_amount: float,
    category: str,
    calc_result: dict,
) -> dict:
    user_prompt = f"""
    - Monthly Income: PHP {monthly_income:,.2f}
    - Remaining Days in Cycle: {remaining_days_in_cycle} Days
    - Unpaid Fixed Dues: PHP {fixed_dues_unpaid:,.2f}
    - Essential Food/Transport Allocation: PHP {essential_allowance_remaining:,.2f}
    - Target Savings Floor: PHP {target_savings_floor:,.2f}
    - Proposed Expense: PHP {proposed_amount:,.2f} (Category: {category})
    - Pre-Computed Risk Level: {calc_result['risk_level']}
    - Daily Discretionary Budget Post-Expense: PHP {calc_result['daily_disposable_after']:,.2f}/day
    """

    client = _get_client()
    response = client.models.generate_content(
        model="gemini-3.6-flash",
        contents=user_prompt,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM_INSTRUCTION,
            thinking_config=types.ThinkingConfig(thinking_level="low"),
            response_mime_type="application/json",
            response_schema=RESPONSE_SCHEMA,
        ),
    )

    return json.loads(response.text)