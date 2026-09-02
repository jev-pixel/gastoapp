import uuid
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.deps import get_current_user
from app.core.database import get_db
from app.db.models.card_wallet import CardWallet
from app.db.models.qr_reservation import BankProvider, QrReservation, QrReservationStatus
from app.db.models.user import User
from app.db.models.wallet_transaction import TransactionType, WalletTransaction
from app.schemas.qr import QrDeepLinkInfo, QrReservationRead, QrReserveRequest

router = APIRouter(prefix="/api/v1/wallet/qr", tags=["qr"])

RESERVATION_TTL_MINUTES = 15

# iOS scheme also doubles as the Android launch URI in this app's deep-link
# dispatcher — Flutter's url_launcher resolves it via the intent filter
# declared in AndroidManifest.xml, so one scheme string covers both.
_DEEP_LINKS = {
    BankProvider.GCASH: QrDeepLinkInfo(
        ios_scheme="gcash://", android_package="com.gcash",
        store_fallback_ios="https://apps.apple.com/ph/app/gcash/id520020791",
        store_fallback_android="https://play.google.com/store/apps/details?id=com.globe.gcash.android",
    ),
    BankProvider.MAYA: QrDeepLinkInfo(
        ios_scheme="paymaya://", android_package="com.paymaya",
        store_fallback_ios="https://apps.apple.com/ph/app/maya/id924768728",
        store_fallback_android="https://play.google.com/store/apps/details?id=com.paymaya",
    ),
    BankProvider.UNIONBANK: QrDeepLinkInfo(
        ios_scheme="ubp://", android_package="com.unionbankph.online",
        store_fallback_ios="https://apps.apple.com/ph/app/unionbank-online/id1177532820",
        store_fallback_android="https://play.google.com/store/apps/details?id=com.unionbankph.online",
    ),
    BankProvider.BDO: QrDeepLinkInfo(
        ios_scheme="bdo.online://", android_package="com.bdo.pay",
        store_fallback_ios="https://apps.apple.com/ph/app/bdo-digital-banking/id1130320737",
        store_fallback_android="https://play.google.com/store/apps/details?id=com.bdo.pay",
    ),
}


async def _get_owned_card_wallet_locked(card_wallet_id: uuid.UUID, db: AsyncSession, user: User) -> CardWallet:
    result = await db.execute(
        select(CardWallet)
        .where(CardWallet.id == card_wallet_id, CardWallet.user_id == user.id)
        .with_for_update()
    )
    wallet = result.scalar_one_or_none()
    if not wallet:
        raise HTTPException(status_code=404, detail="Card wallet not found")
    return wallet


async def _expire_stale(db: AsyncSession, card_wallet_id: uuid.UUID) -> None:
    now = datetime.now(timezone.utc)
    result = await db.execute(
        select(QrReservation).where(
            QrReservation.card_wallet_id == card_wallet_id,
            QrReservation.status == QrReservationStatus.PENDING,
            QrReservation.expires_at < now,
        )
    )
    for r in result.scalars().all():
        r.status = QrReservationStatus.EXPIRED


async def _active_reserved_total(db: AsyncSession, card_wallet_id: uuid.UUID) -> float:
    result = await db.execute(
        select(func.coalesce(func.sum(QrReservation.amount), 0)).where(
            QrReservation.card_wallet_id == card_wallet_id,
            QrReservation.status == QrReservationStatus.PENDING,
        )
    )
    return float(result.scalar_one())


@router.post("/reserve", response_model=QrReservationRead, status_code=201)
async def reserve_qr_payment(
    payload: QrReserveRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    # Row lock serializes concurrent scans against the same card wallet —
    # this is what stops two parallel deep-links from both passing the
    # balance check before either settles.
    wallet = await _get_owned_card_wallet_locked(payload.card_wallet_id, db, current_user)
    await _expire_stale(db, wallet.id)

    reserved = await _active_reserved_total(db, wallet.id)
    available = float(wallet.current_balance) - reserved
    if payload.amount > available:
        raise HTTPException(
            status_code=400,
            detail=f"Amount {payload.amount:.2f} exceeds available balance of {available:.2f} "
                   f"({reserved:.2f} already on hold for other pending QR payments)",
        )

    reservation = QrReservation(
        user_id=current_user.id,
        card_wallet_id=wallet.id,
        amount=payload.amount,
        merchant_name=payload.merchant_name,
        destination_account=payload.destination_account,
        provider=payload.provider,
        status=QrReservationStatus.PENDING,
        expires_at=datetime.now(timezone.utc) + timedelta(minutes=RESERVATION_TTL_MINUTES),
    )
    db.add(reservation)
    await db.commit()
    await db.refresh(reservation)
    return reservation


@router.post("/{reservation_id}/settle", response_model=QrReservationRead)
async def settle_qr_payment(
    reservation_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(QrReservation).where(QrReservation.id == reservation_id, QrReservation.user_id == current_user.id)
    )
    reservation = result.scalar_one_or_none()
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    if reservation.status != QrReservationStatus.PENDING:
        raise HTTPException(status_code=400, detail=f"Reservation is already {reservation.status.value}")
    if reservation.expires_at < datetime.now(timezone.utc):
        reservation.status = QrReservationStatus.EXPIRED
        await db.commit()
        raise HTTPException(status_code=410, detail="This reservation expired — please scan again")

    wallet = await _get_owned_card_wallet_locked(reservation.card_wallet_id, db, current_user)
    if float(reservation.amount) > float(wallet.current_balance):
        raise HTTPException(status_code=400, detail="Card wallet balance is no longer sufficient")

    wallet.current_balance = float(wallet.current_balance) - float(reservation.amount)
    tx = WalletTransaction(
        user_id=current_user.id,
        type=TransactionType.CARD_EXPENSE,
        amount=reservation.amount,
        description=reservation.merchant_name or f"QR payment via {reservation.provider.value}",
        card_wallet_id=wallet.id,
    )
    db.add(tx)
    await db.flush()

    reservation.status = QrReservationStatus.SETTLED
    reservation.related_transaction_id = tx.id
    await db.commit()
    await db.refresh(reservation)
    return reservation


@router.post("/{reservation_id}/cancel", response_model=QrReservationRead)
async def cancel_qr_payment(
    reservation_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(QrReservation).where(QrReservation.id == reservation_id, QrReservation.user_id == current_user.id)
    )
    reservation = result.scalar_one_or_none()
    if not reservation:
        raise HTTPException(status_code=404, detail="Reservation not found")
    if reservation.status != QrReservationStatus.PENDING:
        raise HTTPException(status_code=400, detail=f"Reservation is already {reservation.status.value}")
    reservation.status = QrReservationStatus.CANCELLED
    await db.commit()
    await db.refresh(reservation)
    return reservation


@router.get("/deep-link/{provider}", response_model=QrDeepLinkInfo)
async def get_deep_link_info(provider: BankProvider):
    info = _DEEP_LINKS.get(provider)
    if not info:
        raise HTTPException(status_code=404, detail="No deep link configured for this provider")
    return info