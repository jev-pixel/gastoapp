"""add paymongo checkout session id to qr_reservations

Revision ID: a2d94f6c8b31
Revises: f7c1a9d3e5b2
Create Date: 2026-09-08 00:00:00.000000
"""
from alembic import op
import sqlalchemy as sa

revision = 'a2d94f6c8b31'
down_revision = 'f7c1a9d3e5b2'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column('qr_reservations', sa.Column('checkout_session_id', sa.String(length=100), nullable=True))


def downgrade() -> None:
    op.drop_column('qr_reservations', 'checkout_session_id')