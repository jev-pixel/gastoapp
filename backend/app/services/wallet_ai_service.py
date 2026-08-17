import json

from google.genai import types

from app.services.ai_service import _get_client

SYSTEM_INSTRUCTION = """You are GastoApp's AI Budgeting Advisor. The user has some
unallocated wallet funds left over after assigning money to their budget envelopes
("allowances"). Rely STRICTLY on the numbers provided — do NOT invent figures or
recalculate the unallocated balance yourself. Recommend whether to top up an existing
allowance, keep the funds as a buffer, or (only if the user described a specific goal)
consider spending some of it. Never suggest an action whose suggested_amount exceeds
the unallocated_balance provided. Be conservative: favor strengthening low-balance
allowances or preserving a safety buffer over discretionary spending when the picture
is ambiguous. Return valid JSON matching the response schema."""

RESPONSE_SCHEMA = {
    "type": "object",
    "properties": {
        "recommendation_summary": {"type": "string"},
        "risk_note": {"type": "string"},
        "suggested_actions": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "action": {"type": "string"},
                    "target_allowance_name": {"type": "string", "nullable": True},
                    "suggested_amount": {"type": "number"},
                    "reasoning": {"type": "string"},
                },
                "required": ["action", "suggested_amount", "reasoning"],
            },
        },
    },
    "required": ["recommendation_summary", "risk_note", "suggested_actions"],
}


async def get_unallocated_funds_recommendation(
    unallocated_balance: float,
    allowances: list[dict],  # [{"name": str, "allocated_amount": float, "current_balance": float}, ...]
    monthly_income: float,
    target_savings_floor: float,
    goal_description: str | None,
) -> dict:
    allowance_lines = "\n".join(
        f"    - {a['name']}: PHP {a['current_balance']:,.2f} remaining of PHP {a['allocated_amount']:,.2f} allocated"
        for a in allowances
    ) or "    (no allowances set up yet)"

    user_prompt = f"""
    - Monthly Income: PHP {monthly_income:,.2f}
    - Target Savings Floor: PHP {target_savings_floor:,.2f}
    - Unallocated Wallet Balance: PHP {unallocated_balance:,.2f}
    - Current Allowances:
{allowance_lines}
    - User's Stated Goal: {goal_description or "None provided — give a general recommendation."}
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