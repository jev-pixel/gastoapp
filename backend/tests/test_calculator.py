import unittest

from app.services.calculator import FinancialContext, compute_financial_impact


class TestCalculator(unittest.TestCase):
    def test_low_risk_comfortable_buffer(self):
        ctx = FinancialContext(
            current_wallet_balance=20000,
            fixed_dues_unpaid=4500,
            essential_allowance_remaining=4000,
            target_savings_buffer=2000,
            remaining_days_in_cycle=12,
        )
        result = compute_financial_impact(ctx, proposed_amount=1500)
        self.assertEqual(result["risk_level"], "LOW")
        self.assertFalse(result["savings_floor_breached"])

    def test_high_risk_negative_disposable(self):
        ctx = FinancialContext(
            current_wallet_balance=10000,
            fixed_dues_unpaid=4500,
            essential_allowance_remaining=4000,
            target_savings_buffer=2000,
            remaining_days_in_cycle=12,
        )
        result = compute_financial_impact(ctx, proposed_amount=1500)
        self.assertEqual(result["risk_level"], "HIGH")
        self.assertTrue(result["savings_floor_breached"])
        self.assertLess(result["disposable_after"], 0)

    def test_medium_risk_boundary_below_half_savings_floor(self):
        # disposable_before = 30000 - (4500+4000+2000) = 19500
        # proposed = 18600 -> disposable_after = 900, which is < 2000*0.5 (=1000) -> MEDIUM
        ctx = FinancialContext(
            current_wallet_balance=30000,
            fixed_dues_unpaid=4500,
            essential_allowance_remaining=4000,
            target_savings_buffer=2000,
            remaining_days_in_cycle=12,
        )
        result = compute_financial_impact(ctx, proposed_amount=18600)
        self.assertEqual(result["risk_level"], "MEDIUM")
        self.assertFalse(result["savings_floor_breached"])

    def test_exact_zero_disposable_after_is_not_flagged_breached(self):
        ctx = FinancialContext(
            current_wallet_balance=10500,
            fixed_dues_unpaid=4500,
            essential_allowance_remaining=4000,
            target_savings_buffer=2000,
            remaining_days_in_cycle=12,
        )
        result = compute_financial_impact(ctx, proposed_amount=0)
        self.assertEqual(result["disposable_after"], 0)
        self.assertFalse(result["savings_floor_breached"])  # 0 is not < 0

    def test_zero_remaining_days_does_not_divide_by_zero(self):
        ctx = FinancialContext(
            current_wallet_balance=10000,
            fixed_dues_unpaid=0,
            essential_allowance_remaining=0,
            target_savings_buffer=0,
            remaining_days_in_cycle=0,  # edge case: cycle ends today
        )
        result = compute_financial_impact(ctx, proposed_amount=500)
        self.assertIsNotNone(result["daily_disposable_after"])  # no ZeroDivisionError raised

    def test_daily_disposable_never_negative(self):
        ctx = FinancialContext(
            current_wallet_balance=5000,
            fixed_dues_unpaid=4500,
            essential_allowance_remaining=4000,
            target_savings_buffer=2000,
            remaining_days_in_cycle=10,
        )
        result = compute_financial_impact(ctx, proposed_amount=10000)
        self.assertGreaterEqual(result["daily_disposable_after"], 0.0)


if __name__ == "__main__":
    unittest.main()