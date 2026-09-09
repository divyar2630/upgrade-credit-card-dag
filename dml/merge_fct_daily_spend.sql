-- ============================================================
-- MERGE FCT_DAILY_SPEND
-- CDC: rebuild last 2 days of spend aggregates
-- Grain: (account_id, merchant_id, spend_date)
-- ============================================================

BEGIN;

-- Delete-and-reinsert for the lookback window
-- (simpler than MERGE for aggregated facts)
DELETE FROM {{ schema }}.fct_daily_spend
WHERE  spend_date >= DATEADD(day, -2, CONVERT_TIMEZONE('UTC', GETDATE())::DATE);

INSERT INTO {{ schema }}.fct_daily_spend (
    spend_date,
    account_id,
    merchant_id,
    transaction_count,
    gross_spend_usd,
    net_spend_usd,
    refund_count,
    refund_amount_usd,
    avg_transaction_usd,
    max_transaction_usd,
    international_txn_count,
    _loaded_at
)
SELECT
    CONVERT_TIMEZONE('UTC', transaction_ts)::DATE   AS spend_date,
    account_id,
    merchant_id,
    COUNT(*)                                         AS transaction_count,
    SUM(CASE WHEN amount_usd > 0 THEN amount_usd ELSE 0 END)  AS gross_spend_usd,
    SUM(amount_usd)                                  AS net_spend_usd,
    SUM(CASE WHEN amount_usd < 0 THEN 1 ELSE 0 END) AS refund_count,
    ABS(SUM(CASE WHEN amount_usd < 0 THEN amount_usd ELSE 0 END)) AS refund_amount_usd,
    AVG(ABS(amount_usd))                             AS avg_transaction_usd,
    MAX(ABS(amount_usd))                             AS max_transaction_usd,
    SUM(CASE WHEN is_international THEN 1 ELSE 0 END) AS international_txn_count,
    GETDATE()                                        AS _loaded_at
FROM {{ schema }}.stg_card_transactions
WHERE CONVERT_TIMEZONE('UTC', transaction_ts)::DATE
      >= DATEADD(day, -2, CONVERT_TIMEZONE('UTC', GETDATE())::DATE)
  AND status = 'POSTED'
GROUP BY 1, 2, 3;

ANALYZE {{ schema }}.fct_daily_spend;

COMMIT;
