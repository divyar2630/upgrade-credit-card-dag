-- ============================================================
-- MERGE DIM_MERCHANTS (SCD-1)
-- Upsert from staging transactions — deduplicate merchants
-- Uses LISTAGG for category rollup in audit query
-- ============================================================

BEGIN;

MERGE INTO {{ schema }}.dim_merchants AS tgt
USING (
    SELECT
        merchant_id,
        -- Take the most recent non-null merchant name
        LAST_VALUE(merchant_name IGNORE NULLS) OVER (
            PARTITION BY merchant_id
            ORDER BY transaction_ts
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS merchant_name,
        JSON_EXTRACT_PATH_TEXT(transaction_metadata, 'merchant_category') AS merchant_category,
        mcc_code,
        JSON_EXTRACT_PATH_TEXT(transaction_metadata, 'city')             AS city,
        JSON_EXTRACT_PATH_TEXT(transaction_metadata, 'state')            AS state_code,
        NVL(JSON_EXTRACT_PATH_TEXT(transaction_metadata, 'country'), 'US') AS country_code,
        CASE
            WHEN JSON_EXTRACT_PATH_TEXT(transaction_metadata, 'channel') = 'ONLINE'
            THEN TRUE ELSE FALSE
        END AS is_online,
        MIN(transaction_ts)::DATE AS first_seen_date
    FROM {{ schema }}.stg_card_transactions
    WHERE _loaded_at >= DATEADD(day, -2, GETDATE())
    GROUP BY merchant_id, merchant_name, transaction_metadata, mcc_code, transaction_ts
    QUALIFY ROW_NUMBER() OVER (PARTITION BY merchant_id ORDER BY transaction_ts DESC) = 1
) AS src
ON tgt.merchant_id = src.merchant_id
WHEN MATCHED THEN UPDATE SET
    merchant_name     = NVL(src.merchant_name, tgt.merchant_name),
    merchant_category = NVL(src.merchant_category, tgt.merchant_category),
    mcc_code          = NVL(src.mcc_code, tgt.mcc_code),
    city              = NVL(src.city, tgt.city),
    state_code        = NVL(src.state_code, tgt.state_code),
    country_code      = src.country_code,
    is_online         = src.is_online,
    last_updated_at   = GETDATE()
WHEN NOT MATCHED THEN INSERT (
    merchant_id, merchant_name, merchant_category, mcc_code,
    city, state_code, country_code, is_online, risk_tier,
    first_seen_date, last_updated_at
) VALUES (
    src.merchant_id, src.merchant_name, src.merchant_category, src.mcc_code,
    src.city, src.state_code, src.country_code, src.is_online, NULL,
    src.first_seen_date, GETDATE()
);

-- Audit: categories per merchant (uses LISTAGG)
-- This is a downstream reporting query included for conversion demo
CREATE TEMP TABLE tmp_merchant_audit AS
SELECT
    merchant_id,
    merchant_name,
    LISTAGG(DISTINCT merchant_category, ', ')
        WITHIN GROUP (ORDER BY merchant_category) AS all_categories,
    COUNT(*)                                       AS txn_count
FROM {{ schema }}.stg_card_transactions
WHERE _loaded_at >= DATEADD(day, -2, GETDATE())
GROUP BY merchant_id, merchant_name;

UNLOAD ('SELECT * FROM tmp_merchant_audit')
TO 's3://{{ s3_bucket }}/audit/merchants/'
IAM_ROLE '{{ iam_role }}'
FORMAT AS PARQUET
ALLOWOVERWRITE;

COMMIT;
