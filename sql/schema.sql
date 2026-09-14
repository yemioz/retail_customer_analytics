/*

Retail Customer Analytics
PostgreSQL Database Schema

Purpose:
    Defines the relational database used for the Retail Customer Analytics
    project.

Design Notes:
    - Transaction data is stored at the transaction level in transactions.
    - Line-item data is stored separately in transaction_items.
    - transaction_items uses a surrogate identity primary key because a
      transaction may contain multiple item records.
    - Customer registration is optional at checkout, so transactions.user_id
      may be NULL for guest transactions.
    - Voucher usage is optional, so transactions.voucher_id may be NULL.
*/

-- MENU ITEMS

CREATE TABLE IF NOT EXISTS menu_items (
    item_id INT PRIMARY KEY,
    item_name VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) CHECK (price >= 0),
    is_season BOOLEAN DEFAULT FALSE,
    available_from DATE,
    available_to DATE
);

-- PAYMENT METHODS

CREATE TABLE IF NOT EXISTS payment_methods (
    method_id INT PRIMARY KEY,

    method_name VARCHAR(100)
        CHECK (
            method_name IN (
                'cash',
                'credit_card',
                'debit_card',
                'tng',
                'grabpay'
            )
        ),

    category VARCHAR(100)
        CHECK (
            category IN (
                'cash',
                'card',
                'ewallet'
            )
        )
);

-- STORES

CREATE TABLE IF NOT EXISTS stores (
    store_id INT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    street VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state_ VARCHAR(100) NOT NULL,
    latitude DECIMAL(30, 10),
    longitude DECIMAL(30, 10)
);

-- VOUCHERS

CREATE TABLE IF NOT EXISTS vouchers (
    voucher_id INT PRIMARY KEY,
    voucher_code VARCHAR(100),

    discount_type VARCHAR(100)
        CHECK (
            discount_type IN (
                'percentage',
                'fixed'
            )
        ),

    discount_value DECIMAL(10, 2),
    valid_from DATE,
    valid_to DATE,

    CONSTRAINT vouchers_valid_date_range
        CHECK (
            valid_from IS NULL
            OR valid_to IS NULL
            OR valid_from <= valid_to
        )
);

-- USERS

CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT PRIMARY KEY,
    gender TEXT,
    birthdate DATE,
    registered_at TIMESTAMP NOT NULL
);

-- TRANSACTIONS

CREATE TABLE IF NOT EXISTS transactions (
    transaction_id VARCHAR(100) PRIMARY KEY,

    store_id INT NOT NULL,

    payment_method_id INT NOT NULL,

    voucher_id INT,

    user_id BIGINT,

    original_amount DECIMAL(10, 2),

    discount_applied DECIMAL(10, 2)
        DEFAULT 0,

    final_amount DECIMAL(10, 2),

    created_at TIMESTAMP NOT NULL,


    CONSTRAINT transactions_store_id_fkey
        FOREIGN KEY (store_id)
        REFERENCES stores(store_id),

    CONSTRAINT transactions_payment_method_id_fkey
        FOREIGN KEY (payment_method_id)
        REFERENCES payment_methods(method_id),

    CONSTRAINT transactions_voucher_id_fkey
        FOREIGN KEY (voucher_id)
        REFERENCES vouchers(voucher_id),

    CONSTRAINT transactions_user_id_fkey
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
);

-- TRANSACTION ITEMS

CREATE TABLE IF NOT EXISTS transaction_items (
    transaction_item_id BIGINT
        GENERATED ALWAYS AS IDENTITY,

    transaction_id VARCHAR(100) NOT NULL,

    item_id INT NOT NULL,

    quantity INT
        CHECK (quantity > 0),

    unit_price DECIMAL(10, 2)
        CHECK (unit_price >= 0),

    subtotal DECIMAL(10, 2)
        CHECK (subtotal = quantity * unit_price),

    created_at TIMESTAMP NOT NULL,


    CONSTRAINT transaction_items_pkey
        PRIMARY KEY (transaction_item_id),

    CONSTRAINT transaction_items_transaction_id_fkey
        FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id),

    CONSTRAINT transaction_items_item_id_fkey
        FOREIGN KEY (item_id)
        REFERENCES menu_items(item_id)
);