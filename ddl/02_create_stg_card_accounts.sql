-- ============================================================
-- STG_CARD_ACCOUNTS
-- Source: Fivetran landing from OLTP (PostgreSQL)
-- ============================================================

CREATE TABLE IF NOT EXISTS {{ schema }}.stg_card_accounts (
    account_id              BIGINT        NOT NULL,
    customer_id             BIGINT        NOT NULL,
    card_product            VARCHAR(50),
    credit_limit            DECIMAL(12,2),
    apr                     DECIMAL(5,2),
    open_date               DATE,
    close_date              DATE,
    account_status          VARCHAR(20)   DEFAULT 'ACTIVE',
    billing_cycle_day       SMALLINT,
    autopay_enabled         BOOLEAN       DEFAULT FALSE,
    _fivetran_synced        TIMESTAMP     DEFAULT GETDATE(),
    _loaded_at              TIMESTAMP     DEFAULT GETDATE(),
    PRIMARY KEY (account_id)
)
DISTSTYLE KEY
DISTKEY (account_id)
COMPOUND SORTKEY (account_id, open_date);
