-- ============================================================
-- MERGE FCT_ACCOUNT_BALANCE
-- Daily balance snapshot — CDC merge on 1-day lookback
-- ============================================================

BEGIN;

MERGE INTO {{ schema }}.fct_account_balance AS tgt
USING (
    SELECT
        CONVERT_TIMEZONE('UTC', GETDATE())::DATE    AS balance_date,
        a.account_id,
        -- Statement balance = sum of posted transactions in current cycle
        NVL(SUM(t.amount_usd), 0)                   AS statement_balance,
        -- Current balance includes pending
        NVL(SUM(CASE WHEN t.status IN ('POSTED','PENDING')
                      THEN t.amount_usd ELSE 0 END), 0) AS current_balance,
        a.credit_limit - NVL(SUM(CASE WHEN t.status IN ('POSTED','PENDING')
                                       THEN t.amount_usd ELSE 0 END), 0) AS available_credit,
        -- Minimum payment: 1% of balance or $25, whichever is greater
        GREATEST(
            NVL(SUM(t.amount_usd), 0) * 0.01,
            25.00
        )                                            AS minimum_payment_due,
        DATEADD(day, a.billing_cycle_day,
                DATE_TRUNC('month', GETDATE()))      AS payment_due_date,
        -- Days past due placeholder (would join to payments table)
        0                                            AS days_past_due,
        CASE
            WHEN a.credit_limit > 0
            THEN ROUND(
                NVL(SUM(CASE WHEN t.status IN ('POSTED','PENDING')
                              THEN t.amount_usd ELSE 0 END), 0)
                / a.credit_limit * 100, 2)
            ELSE 0
        END                                          AS utilization_pct,
        GETDATE()                                    AS _loaded_at
    FROM {{ schema }}.stg_card_accounts a
    LEFT JOIN {{ schema }}.stg_card_transactions t
        ON a.account_id = t.account_id
       AND t.transaction_ts >= DATEADD(day, -30, GETDATE())
    WHERE a.account_status = 'ACTIVE'
    GROUP BY a.account_id, a.credit_limit, a.billing_cycle_day
) AS src
ON  tgt.account_id   = src.account_id
AND tgt.balance_date  = src.balance_date
WHEN MATCHED THEN UPDATE SET
    statement_balance   = src.statement_balance,
    current_balance     = src.current_balance,
    available_credit    = src.available_credit,
    minimum_payment_due = src.minimum_payment_due,
    payment_due_date    = src.payment_due_date,
    days_past_due       = src.days_past_due,
    utilization_pct     = src.utilization_pct,
    _loaded_at          = src._loaded_at
WHEN NOT MATCHED THEN INSERT (
    balance_date, account_id, statement_balance, current_balance,
    available_credit, minimum_payment_due, payment_due_date,
    days_past_due, utilization_pct, _loaded_at
) VALUES (
    src.balance_date, src.account_id, src.statement_balance, src.current_balance,
    src.available_credit, src.minimum_payment_due, src.payment_due_date,
    src.days_past_due, src.utilization_pct, src._loaded_at
);

ANALYZE {{ schema }}.fct_account_balance;

COMMIT;
