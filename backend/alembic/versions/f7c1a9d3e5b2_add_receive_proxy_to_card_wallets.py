"""add receive_proxy to card_wallets

Revision ID: f7c1a9d3e5b2
Revises: 8b1f4c7e2a90
Create Date: 2026-09-08 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = 'f7c1a9d3e5b2'
down_revision = '8b1f4c7e2a90'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('card_wallets', sa.Column('receive_proxy', sa.String(length=120), nullable=True))


def downgrade() -> None:
    op.drop_column('card_wallets', 'receive_proxy')