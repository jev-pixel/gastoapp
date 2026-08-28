"""
Import all models here so Base.metadata is fully populated
before Alembic (or create_all) inspects it for autogeneration.
"""
from app.core.database import Base  # noqa: F401
from app.db.models.user import User  # noqa: F401
from app.db.models.fixed_bill import FixedBill  # noqa: F401
from app.db.models.expense import Expense  # noqa: F401
from app.db.models.ai_scenario_log import AIScenarioLog  # noqa: F401
from app.db.models.allowance import Allowance  # noqa: F401
from app.db.models.wallet_transaction import WalletTransaction  # noqa: F401
from app.db.models.card_wallet import CardWallet  # noqa: F401