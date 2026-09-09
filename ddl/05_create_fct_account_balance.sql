-- ============================================================
-- FCT_ACCOUNT_BALANCE
-- Daily balance snapshot per account
-- Grain: one row per (account_id, balance_date)
-- ============================================================

CREATE TABLE IF NOT EXISTS {{ schema }}.fct_account_balance (
    balance_date            DATE          NOT NULL,
    account_id              BIGINT        NOT NULL,
    statement_balance       DECIMAL(14,2),
    current_balance         DECIMAL(14,2),
    available_credit        DECIMAL(14,2),
    minimum_payment_due     DECIMAL(12,2),
    payment_due_date        DATE,
    days_past_due           INT           DEFAULT 0,
    utilization_pct         DECIMAL(5,2),
    _loaded_at              TIMESTAMP     DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (account_id)
COMPOUND SORTKEY (balance_date, account_id);
