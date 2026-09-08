import uuid

from fastapi import APIRouter, Header, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends

from app.core.database import get_db
from app.db.models.qr_reservation import QrReservation, QrReservationStatus
from app.services.payment_gateway_service import verify_webhook_signature
from app.api.v1.endpoints.qr import _settle_reservation

router = APIRouter(prefix="/api/v1/webhooks", tags=["webhooks"])


@router.post("/paymongo")
async def paymongo_webhook(
    request: Request,
    db: AsyncSession = Depends(get_db),
    paymongo_signature: str | None = Header(default=None, alias="Paymongo-Signature"),
):
    raw_body = await request.body()
    if not verify_webhook_signature(raw_body, paymongo_signature):
        raise HTTPException(status_code=401, detail="Invalid webhook signature")

    payload = await request.json()
    event_type = payload.get("data", {}).get("attributes", {}).get("type")

    if event_type == "checkout_session.payment.paid":
        session_data = payload["data"]["attributes"]["data"]
        reference_number = session_data["attributes"].get("reference_number")
        if not reference_number:
            return {"received": True}

        result = await db.execute(
            select(QrReservation).where(QrReservation.id == uuid.UUID(reference_number))
        )
        reservation = result.scalar_one_or_none()
        if reservation and reservation.status == QrReservationStatus.PENDING:
            await _settle_reservation(reservation, db)

    return {"received": True}