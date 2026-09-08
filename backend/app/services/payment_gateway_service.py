import hashlib
import hmac

import httpx

from app.core.config import settings

PAYMONGO_API_BASE = "https://api.paymongo.com/v2"


class PaymongoError(Exception):
    pass


async def create_checkout_session(
    *,
    amount_php: float,
    description: str,
    reference_number: str,
    success_url: str,
    cancel_url: str,
    payment_method_types: list[str] | None = None,
) -> dict:
    """
    Creates a PayMongo Checkout Session (v2) — the modern, unified API
    that covers GCash, Maya, GrabPay, ShopeePay, QR Ph, and cards through
    one hosted page. Returns the parsed `data` object; the caller reads
    `["attributes"]["checkout_url"]`.

    NOTE: "gcash" and "qrph" are confirmed payment_method_types values.
    "paymaya" is PayMongo's historical identifier for Maya (pre-rebrand)
    and is my best inference, not independently confirmed against their
    current API Reference — check Settings → Developers → API Reference
    → Checkout → Create a Checkout Session in your own dashboard before
    relying on it, and adjust if it's actually "maya".
    """
    payment_method_types = payment_method_types or ["gcash", "paymaya", "qrph", "card"]

    payload = {
        "data": {
            "attributes": {
                "line_items": [
                    {
                        "name": description,
                        "amount": int(round(amount_php * 100)),  # centavos
                        "currency": "PHP",
                        "quantity": 1,
                    }
                ],
                "payment_method_types": payment_method_types,
                "reference_number": reference_number,
                "success_url": success_url,
                "cancel_url": cancel_url,
            }
        }
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{PAYMONGO_API_BASE}/checkout_sessions",
            json=payload,
            auth=(settings.PAYMONGO_SECRET_KEY, ""),  # basic auth, empty password
            timeout=15.0,
        )

    if response.status_code >= 400:
        raise PaymongoError(f"PayMongo error {response.status_code}: {response.text}")

    return response.json()["data"]


def verify_webhook_signature(raw_body: bytes, signature_header: str | None) -> bool:
    """
    PayMongo signs webhooks via the `Paymongo-Signature` header, formatted
    as `t=<timestamp>,te=<test_signature>,li=<live_signature>`, computed
    as HMAC-SHA256(webhook_secret, f"{timestamp}.{raw_body}"). This is my
    best recollection of their documented format — before deploying,
    trigger a real test-mode webhook from the dashboard's webhook log and
    confirm this actually verifies it. A silently-wrong check here either
    lets forged payment confirmations through or drops real ones.
    """
    if not signature_header:
        return False

    parts: dict[str, str] = {}
    for item in signature_header.split(","):
        if "=" in item:
            key, _, value = item.partition("=")
            parts[key.strip()] = value.strip()

    timestamp = parts.get("t")
    provided_signature = parts.get("li") or parts.get("te")
    if not timestamp or not provided_signature:
        return False

    signed_payload = f"{timestamp}.{raw_body.decode()}".encode()
    computed = hmac.new(settings.PAYMONGO_WEBHOOK_SECRET.encode(), signed_payload, hashlib.sha256).hexdigest()

    return hmac.compare_digest(computed, provided_signature)