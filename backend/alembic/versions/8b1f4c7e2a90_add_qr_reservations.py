"""add qr_reservations table

Revision ID: 8b1f4c7e2a90
Revises: d4e9a7c31258
Create Date: 2026-09-03 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

revision = '8b1f4c7e2a90'
down_revision = 'd4e9a7c31258'
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        'qr_reservations',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('card_wallet_id', sa.UUID(), nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('merchant_name', sa.String(120), nullable=True),
        sa.Column('destination_account', sa.String(120), nullable=True),
        sa.Column('provider', sa.Enum('gcash', 'maya', 'unionbank', 'bdo', 'other', name='bankprovider'), nullable=False),
        sa.Column('status', sa.Enum('pending', 'settled', 'expired', 'cancelled', name='qrreservationstatus'),
                   nullable=False, server_default='pending'),
        sa.Column('related_transaction_id', sa.UUID(), nullable=True),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['card_wallet_id'], ['card_wallets.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['related_transaction_id'], ['wallet_transactions.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
    )


def downgrade() -> None:
    op.drop_table('qr_reservations')
    op.execute('DROP TYPE IF EXISTS qrreservationstatus')
    op.execute('DROP TYPE IF EXISTS bankprovider')
