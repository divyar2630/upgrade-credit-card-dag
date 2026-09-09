-- ============================================================
-- FCT_DAILY_SPEND
-- Daily spend aggregates per account × merchant
-- Grain: one row per (account_id, merchant_id, spend_date)
-- ============================================================

CREATE TABLE IF NOT EXISTS {{ schema }}.fct_daily_spend (
    spend_date              DATE          NOT NULL,
    account_id              BIGINT        NOT NULL,
    merchant_id             BIGINT        NOT NULL,
    transaction_count       INT           DEFAULT 0,
    gross_spend_usd         DECIMAL(14,2) DEFAULT 0,
    net_spend_usd           DECIMAL(14,2) DEFAULT 0,
    refund_count            INT           DEFAULT 0,
    refund_amount_usd       DECIMAL(14,2) DEFAULT 0,
    avg_transaction_usd     DECIMAL(12,2),
    max_transaction_usd     DECIMAL(12,2),
    international_txn_count INT           DEFAULT 0,
    _loaded_at              TIMESTAMP     DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (account_id)
COMPOUND SORTKEY (spend_date, account_id);
