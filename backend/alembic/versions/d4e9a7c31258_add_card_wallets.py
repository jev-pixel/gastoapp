"""add card wallets and card wallet transaction columns

Revision ID: d4e9a7c31258
Revises: c3d8f2a91b47
Create Date: 2026-08-28 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = 'd4e9a7c31258'
down_revision: Union[str, None] = 'c3d8f2a91b47'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'card_wallets',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('provider', sa.String(length=50), nullable=False),
        sa.Column('name', sa.String(length=120), nullable=False),
        sa.Column('current_balance', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.execute("ALTER TYPE transactiontype ADD VALUE IF NOT EXISTS 'CARD_ALLOWANCE'")
    op.execute("ALTER TYPE transactiontype ADD VALUE IF NOT EXISTS 'CARD_EXPENSE'")

    op.add_column('wallet_transactions', sa.Column('card_wallet_id', sa.UUID(), nullable=True))
    op.add_column('wallet_transactions', sa.Column('from_card_wallet_id', sa.UUID(), nullable=True))
    op.add_column('wallet_transactions', sa.Column('to_card_wallet_id', sa.UUID(), nullable=True))
    op.create_foreign_key(None, 'wallet_transactions', 'card_wallets', ['card_wallet_id'], ['id'], ondelete='SET NULL')
    op.create_foreign_key(None, 'wallet_transactions', 'card_wallets', ['from_card_wallet_id'], ['id'], ondelete='SET NULL')
    op.create_foreign_key(None, 'wallet_transactions', 'card_wallets', ['to_card_wallet_id'], ['id'], ondelete='SET NULL')


def downgrade() -> None:
    op.drop_column('wallet_transactions', 'to_card_wallet_id')
    op.drop_column('wallet_transactions', 'from_card_wallet_id')
    op.drop_column('wallet_transactions', 'card_wallet_id')
    op.drop_table('card_wallets')
    # Postgres can't drop enum values cleanly — left in place on downgrade.