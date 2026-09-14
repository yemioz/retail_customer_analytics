CREATE OR REPLACE VIEW analytics.average_transaction_value AS
SELECT AVG(final_amount) AS average_transaction_value FROM transactions;