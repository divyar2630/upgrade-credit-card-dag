-- ============================================================
-- DIM_MERCHANTS
-- SCD Type 1 — latest merchant attributes only
-- ============================================================

CREATE TABLE IF NOT EXISTS {{ schema }}.dim_merchants (
    merchant_id             BIGINT        NOT NULL,
    merchant_name           VARCHAR(200),
    merchant_category       VARCHAR(100),
    mcc_code                VARCHAR(4),
    city                    VARCHAR(100),
    state_code              VARCHAR(2),
    country_code            VARCHAR(3)    DEFAULT 'US',
    is_online               BOOLEAN       DEFAULT FALSE,
    risk_tier               VARCHAR(10),
    first_seen_date         DATE,
    last_updated_at         TIMESTAMP     DEFAULT GETDATE(),
    PRIMARY KEY (merchant_id)
)
DISTSTYLE ALL
SORTKEY (mcc_code, merchant_name);
