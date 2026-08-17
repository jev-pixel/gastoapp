"""create allowances, wallet_transactions

Revision ID: f4a1c9d2b8e6
Revises: 7cda8ecf4da3
Create Date: 2026-08-18 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'f4a1c9d2b8e6'
down_revision: Union[str, None] = '7cda8ecf4da3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'allowances',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column('name', sa.String(length=120), nullable=False),
        sa.Column('allocated_amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('current_balance', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
    )

    op.create_table(
        'wallet_transactions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('user_id', sa.UUID(), nullable=False),
        sa.Column(
            'type',
            sa.Enum(
                'ALLOCATION', 'DEALLOCATION', 'EXPENSE_ALLOWANCE', 'EXPENSE_UNALLOCATED', 'TRANSFER',
                name='transactiontype',
            ),
            nullable=False,
        ),
        sa.Column('amount', sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column('description', sa.String(length=255), nullable=True),
        sa.Column('allowance_id', sa.UUID(), nullable=True),
        sa.Column('from_allowance_id', sa.UUID(), nullable=True),
        sa.Column('to_allowance_id', sa.UUID(), nullable=True),
        sa.Column('related_expense_id', sa.UUID(), nullable=True),
        sa.Column('idempotency_key', sa.String(length=100), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['allowance_id'], ['allowances.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['from_allowance_id'], ['allowances.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['to_allowance_id'], ['allowances.id'], ondelete='SET NULL'),
        sa.ForeignKeyConstraint(['related_expense_id'], ['expenses.id'], ondelete='SET NULL'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('idempotency_key'),
    )


def downgrade() -> None:
    op.drop_table('wallet_transactions')
    op.drop_table('allowances')
    op.execute('DROP TYPE IF EXISTS transactiontype')
