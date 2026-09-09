-- ============================================================
-- LOAD STG_CARD_TRANSACTIONS
-- CDC: 2-day lookback window from Fivetran source
-- Handles JSONB-as-string from Fivetran (JSON_EXTRACT_PATH_TEXT)
-- ============================================================

BEGIN;

DELETE FROM {{ schema }}.stg_card_transactions
WHERE  transaction_ts >= DATEADD(day, -2, CONVERT_TIMEZONE('UTC', GETDATE())::DATE);

INSERT INTO {{ schema }}.stg_card_transactions (
    card_number,
    account_id,
    merchant_id,
    transaction_ts,
    amount_usd,
    currency_code,
    transaction_type,
    authorization_code,
    transaction_metadata,
    mcc_code,
    is_international,
    status,
    _fivetran_synced,
    _loaded_at
)
SELECT
    t.card_number,
    t.account_id,
    t.merchant_id,
    CONVERT_TIMEZONE('UTC', t.transaction_ts)       AS transaction_ts,
    t.amount_usd,
    NVL(t.currency_code, 'USD')                     AS currency_code,
    t.transaction_type,
    t.authorization_code,
    t.transaction_metadata,                          -- JSONB as VARCHAR passthrough
    -- Extract MCC from the JSONB string field
    JSON_EXTRACT_PATH_TEXT(t.transaction_metadata, 'mcc_code')  AS mcc_code,
    CASE
        WHEN NVL(JSON_EXTRACT_PATH_TEXT(t.transaction_metadata, 'country'), 'US') <> 'US'
        THEN TRUE ELSE FALSE
    END                                              AS is_international,
    NVL(t.status, 'POSTED')                          AS status,
    t._fivetran_synced,
    GETDATE()                                        AS _loaded_at
FROM {{ source_schema }}.raw_card_transactions t
WHERE t._fivetran_synced >= DATEADD(day, -2, CONVERT_TIMEZONE('UTC', GETDATE())::DATE);

ANALYZE {{ schema }}.stg_card_transactions;

COMMIT;
