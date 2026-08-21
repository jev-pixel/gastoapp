"""add due_date and is_paid to expenses and wallet_transactions

Revision ID: a1b2c3d4e5f6
Revises: f4a1c9d2b8e6
Create Date: 2026-08-22 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = 'f4a1c9d2b8e6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('expenses', sa.Column('due_date', sa.DateTime(timezone=True), nullable=True))
    op.add_column(
        'expenses',
        sa.Column('is_paid', sa.Boolean(), nullable=False, server_default=sa.true()),
    )

    op.add_column('wallet_transactions', sa.Column('due_date', sa.DateTime(timezone=True), nullable=True))
    op.add_column(
        'wallet_transactions',
        sa.Column('is_paid', sa.Boolean(), nullable=False, server_default=sa.true()),
    )


def downgrade() -> None:
    op.drop_column('wallet_transactions', 'is_paid')
    op.drop_column('wallet_transactions', 'due_date')
    op.drop_column('expenses', 'is_paid')
    op.drop_column('expenses', 'due_date')