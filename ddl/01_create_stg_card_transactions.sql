-- ============================================================
-- STG_CARD_TRANSACTIONS
-- Source: Fivetran landing from OLTP (PostgreSQL)
-- Note: transaction_metadata is JSONB delivered as VARCHAR
--       by Fivetran (variant type expected Q4)
-- ============================================================

CREATE TABLE IF NOT EXISTS {{ schema }}.stg_card_transactions (
    transaction_id          BIGINT        IDENTITY(1,1),
    card_number             VARCHAR(19)   NOT NULL,
    account_id              BIGINT        NOT NULL,
    merchant_id             BIGINT        NOT NULL,
    transaction_ts          TIMESTAMP     NOT NULL,
    amount_usd              DECIMAL(12,2) NOT NULL,
    currency_code           VARCHAR(3)    DEFAULT 'USD',
    transaction_type        VARCHAR(20),
    authorization_code      VARCHAR(12),
    transaction_metadata    VARCHAR(65535),   -- JSONB from OLTP, delivered as string
    mcc_code                VARCHAR(4),
    is_international        BOOLEAN       DEFAULT FALSE,
    status                  VARCHAR(20)   DEFAULT 'POSTED',
    _fivetran_synced        TIMESTAMP     DEFAULT GETDATE(),
    _loaded_at              TIMESTAMP     DEFAULT GETDATE()
)
DISTSTYLE KEY
DISTKEY (account_id)
COMPOUND SORTKEY (transaction_ts, account_id);

COMMENT ON TABLE {{ schema }}.stg_card_transactions
IS 'Staging: raw card transactions landed by Fivetran. JSONB metadata stored as VARCHAR.';


