-- Учебная схема для проекта SQL Testing.
-- Диалект: PostgreSQL.

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;

CREATE TABLE customers (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(100)
);

CREATE TABLE orders (
    id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    status VARCHAR(20) NOT NULL
        CHECK (status IN ('completed', 'pending', 'cancelled'))
);

CREATE TABLE products (
    id INTEGER PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price NUMERIC(10, 2) NOT NULL CHECK (price >= 0)
);

INSERT INTO customers (id, name, city) VALUES
(1, 'Анна', 'Москва'),
(2, 'Иван', 'Казань'),
(3, 'Мария', 'Москва'),
(4, 'Петр', 'Самара'),
(5, 'Елена', 'Омск');

INSERT INTO orders (id, customer_id, amount, status) VALUES
(101, 1, 1500, 'completed'),
(102, 2, 800, 'pending'),
(103, 1, 2500, 'completed'),
(104, 3, 1200, 'cancelled'),
(105, 4, 3000, 'completed');

INSERT INTO products (id, name, price) VALUES
(1, 'Клавиатура', 2500),
(2, 'Мышь', 1200),
(3, 'Монитор', 15000);
