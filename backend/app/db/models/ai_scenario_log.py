import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Numeric, String, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class AIScenarioLog(Base):
    __tablename__ = "ai_scenario_logs"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    proposed_amount: Mapped[float] = mapped_column(Numeric(12, 2), nullable=False)
    risk_level: Mapped[str] = mapped_column(String(20), nullable=False)  # LOW / MEDIUM / HIGH
    verdict: Mapped[str] = mapped_column(String(50), nullable=False)     # APPROVED / PROCEED WITH CAUTION / NOT RECOMMENDED
    raw_response: Mapped[dict] = mapped_column(JSONB, nullable=False)     # full Gemini structured JSON output

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user: Mapped["User"] = relationship(back_populates="scenario_logs")
