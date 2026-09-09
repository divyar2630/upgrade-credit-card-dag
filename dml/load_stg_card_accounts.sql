-- ============================================================
-- LOAD STG_CARD_ACCOUNTS
-- CDC: 2-day lookback on _fivetran_synced
-- ============================================================

BEGIN;

MERGE INTO {{ schema }}.stg_card_accounts AS tgt
USING (
    SELECT
        account_id,
        customer_id,
        card_product,
        credit_limit,
        apr,
        open_date,
        close_date,
        NVL(account_status, 'ACTIVE')   AS account_status,
        billing_cycle_day,
        NVL(autopay_enabled, FALSE)     AS autopay_enabled,
        _fivetran_synced,
        GETDATE()                       AS _loaded_at
    FROM {{ source_schema }}.raw_card_accounts
    WHERE _fivetran_synced >= DATEADD(day, -2, CONVERT_TIMEZONE('UTC', GETDATE())::DATE)
) AS src
ON tgt.account_id = src.account_id
WHEN MATCHED THEN UPDATE SET
    customer_id        = src.customer_id,
    card_product       = src.card_product,
    credit_limit       = src.credit_limit,
    apr                = src.apr,
    open_date          = src.open_date,
    close_date         = src.close_date,
    account_status     = src.account_status,
    billing_cycle_day  = src.billing_cycle_day,
    autopay_enabled    = src.autopay_enabled,
    _fivetran_synced   = src._fivetran_synced,
    _loaded_at         = src._loaded_at
WHEN NOT MATCHED THEN INSERT (
    account_id, customer_id, card_product, credit_limit, apr,
    open_date, close_date, account_status, billing_cycle_day,
    autopay_enabled, _fivetran_synced, _loaded_at
) VALUES (
    src.account_id, src.customer_id, src.card_product, src.credit_limit, src.apr,
    src.open_date, src.close_date, src.account_status, src.billing_cycle_day,
    src.autopay_enabled, src._fivetran_synced, src._loaded_at
);

ANALYZE {{ schema }}.stg_card_accounts;

COMMIT;
