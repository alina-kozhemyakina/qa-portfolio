-- SQL Testing: учебные запросы для Manual QA
-- Диалект: PostgreSQL
-- Схема: customers, orders, products (см. schema.sql)
--
-- Каждый запрос сопровождается комментарием:
-- что проверяем и какой результат ожидаем на текущих тестовых данных.

-- =========================================================
-- 1. БАЗОВЫЕ ВЫБОРКИ И ФИЛЬТРАЦИЯ
-- =========================================================

-- 1.1. Получить список покупателей.
-- Проверка: данные из таблицы customers доступны.
SELECT id, name, city
FROM customers;

-- 1.2. Найти заказы на сумму больше 1000.
-- Ожидаемые ID: 101, 103, 104, 105.
SELECT id, customer_id, amount, status
FROM orders
WHERE amount > 1000;

-- 1.3. Найти завершённые заказы на сумму больше 1000.
-- Ожидаемые ID: 101, 103, 105.
SELECT id, customer_id, amount, status
FROM orders
WHERE status = 'completed'
  AND amount > 1000;

-- 1.4. Найти заказы, которые либо завершены, либо имеют сумму меньше 1000.
-- Демонстрация OR. Ожидаемые ID: 101, 102, 103, 105.
SELECT id, customer_id, amount, status
FROM orders
WHERE status = 'completed'
   OR amount < 1000;

-- 1.5. Найти заказы с указанными статусами.
-- Демонстрация IN. Ожидаются все пять заказов, кроме случаев с иными статусами.
SELECT id, customer_id, amount, status
FROM orders
WHERE status IN ('completed', 'pending');

-- 1.6. Найти заказы в диапазоне сумм от 1000 до 2500 включительно.
-- Демонстрация BETWEEN. Ожидаемые ID: 101, 103, 104.
SELECT id, customer_id, amount, status
FROM orders
WHERE amount BETWEEN 1000 AND 2500;

-- 1.7. Найти покупателей, имя которых начинается с буквы «М».
-- Демонстрация LIKE. Ожидаемая запись: Мария.
SELECT id, name, city
FROM customers
WHERE name LIKE 'М%';

-- 1.8. Получить список уникальных статусов заказов.
-- Ожидаемые значения: completed, pending, cancelled.
SELECT DISTINCT status
FROM orders;

-- 1.9. Отсортировать заказы от самой большой суммы к самой маленькой.
SELECT id, amount, status
FROM orders
ORDER BY amount DESC;

-- 1.10. Найти покупателей, у которых город указан.
-- Демонстрация IS NOT NULL. На текущих данных вернутся все пять покупателей.
SELECT id, name, city
FROM customers
WHERE city IS NOT NULL;


-- =========================================================
-- 2. АГРЕГАТНЫЕ ФУНКЦИИ И ГРУППИРОВКА
-- =========================================================

-- 2.1. Посчитать общее количество заказов.
-- Ожидаемый результат: 5.
SELECT COUNT(*) AS total_orders
FROM orders;

-- 2.2. Посчитать количество заказов каждого статуса и сумму заказов по статусам.
SELECT
    status,
    COUNT(*) AS orders_count,
    SUM(amount) AS total_amount
FROM orders
GROUP BY status
ORDER BY status;

-- 2.3. Рассчитать среднюю, минимальную и максимальную сумму заказа.
-- Демонстрация AVG, MIN и MAX.
-- Ожидаемые значения: AVG = 1800, MIN = 800, MAX = 3000.
SELECT
    AVG(amount) AS average_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM orders;

-- 2.4. Найти покупателей, у которых не менее двух заказов,
-- а общая сумма заказов превышает 2000.
-- Демонстрация HAVING: фильтрация групп после GROUP BY.
-- Ожидаемый результат: Анна, 2 заказа, сумма 4000.
SELECT
    c.name,
    COUNT(o.id) AS orders_count,
    SUM(o.amount) AS total_amount
FROM customers AS c
JOIN orders AS o
    ON o.customer_id = c.id
GROUP BY c.id, c.name
HAVING COUNT(o.id) >= 2
   AND SUM(o.amount) > 2000;


-- =========================================================
-- 3. СВЯЗИ МЕЖДУ ТАБЛИЦАМИ
-- =========================================================

-- 3.1. Получить заказы вместе с именами покупателей.
-- INNER JOIN возвращает только строки, для которых найдена связь.
SELECT
    o.id AS order_id,
    c.name AS customer_name,
    o.amount,
    o.status
FROM orders AS o
INNER JOIN customers AS c
    ON c.id = o.customer_id;

-- 3.2. Получить всех покупателей и количество их заказов,
-- включая покупателей без заказов.
-- Важно: COUNT(o.id), а не COUNT(*), чтобы для покупателя без заказов получить 0.
-- У Елены ожидается 0 заказов.
SELECT
    c.name,
    COUNT(o.id) AS orders_count
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY c.id;

-- 3.3. Получить общую сумму заказов каждого покупателя.
-- COALESCE заменяет NULL на 0 для покупателей без заказов.
SELECT
    c.name,
    COALESCE(SUM(o.amount), 0) AS total_amount
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY c.id;

-- 3.4. Найти покупателей без заказов.
-- Ожидаемый результат: Елена.
SELECT
    c.id,
    c.name
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.id
WHERE o.id IS NULL;

-- 3.5. Сравнить COUNT(*) и COUNT(o.id) при LEFT JOIN.
-- Для Елены COUNT(*) будет равен 1 (строка покупателя сохраняется),
-- а COUNT(o.id) будет равен 0 (заказа нет).
SELECT
    c.name,
    COUNT(*) AS joined_rows_count,
    COUNT(o.id) AS actual_orders_count
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY c.id;


-- =========================================================
-- 4. EXISTS, NOT EXISTS И ПОДЗАПРОСЫ
-- =========================================================

-- 4.1. Найти покупателей, у которых есть хотя бы один завершённый заказ.
-- EXISTS проверяет наличие хотя бы одной подходящей строки.
-- Ожидаемые покупатели: Анна и Петр.
SELECT
    c.id,
    c.name
FROM customers AS c
WHERE EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.id
      AND o.status = 'completed'
);

-- 4.2. Найти покупателей, у которых нет завершённых заказов.
-- NOT EXISTS также вернёт покупателей без заказов вообще.
-- Ожидаемые покупатели: Иван, Мария и Елена.
SELECT
    c.id,
    c.name
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.id
      AND o.status = 'completed'
);

-- 4.3. Найти заказы, сумма которых выше средней суммы всех заказов.
-- Демонстрация скалярного подзапроса в WHERE.
-- На текущих данных средняя сумма равна 1800.
SELECT id, customer_id, amount
FROM orders
WHERE amount > (
    SELECT AVG(amount)
    FROM orders
);

-- 4.4. Найти покупателей, у которых все существующие заказы отменены.
-- Проверяем, что заказов хотя бы один и нет ни одного заказа с другим статусом.
-- Ожидаемый результат: Мария.
SELECT
    c.id,
    c.name
FROM customers AS c
WHERE EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.id
)
AND NOT EXISTS (
    SELECT 1
    FROM orders AS o
    WHERE o.customer_id = c.id
      AND o.status <> 'cancelled'
);


-- =========================================================
-- 5. УСЛОВНЫЕ ВЫРАЖЕНИЯ CASE WHEN
-- =========================================================

-- 5.1. Присвоить заказам текстовую категорию по сумме.
-- Демонстрация CASE WHEN.
SELECT
    id,
    amount,
    CASE
        WHEN amount >= 2500 THEN 'high'
        WHEN amount >= 1000 THEN 'medium'
        ELSE 'low'
    END AS amount_category
FROM orders
ORDER BY id;

-- 5.2. Посчитать количество завершённых и незавершённых заказов по каждому покупателю.
-- Условная агрегация с CASE WHEN.
SELECT
    c.name,
    SUM(CASE WHEN o.status = 'completed' THEN 1 ELSE 0 END) AS completed_count,
    SUM(CASE WHEN o.id IS NOT NULL AND o.status <> 'completed' THEN 1 ELSE 0 END) AS other_status_count
FROM customers AS c
LEFT JOIN orders AS o
    ON o.customer_id = c.id
GROUP BY c.id, c.name
ORDER BY c.id;


-- =========================================================
-- 6. QA-ПРОВЕРКИ КАЧЕСТВА ДАННЫХ
-- =========================================================

-- 6.1. Найти заказы с нулевой или отрицательной суммой.
-- На текущей схеме таких записей быть не должно:
-- ограничение CHECK (amount >= 0) запрещает отрицательные значения.
SELECT id, customer_id, amount
FROM orders
WHERE amount <= 0;

-- 6.2. Найти заказы, для которых не существует покупателя.
-- На текущей схеме таких записей быть не должно:
-- внешний ключ customer_id REFERENCES customers(id) защищает связь.
-- Запрос полезен для проверки импортированных/старых таблиц без FK.
SELECT
    o.id,
    o.customer_id
FROM orders AS o
LEFT JOIN customers AS c
    ON c.id = o.customer_id
WHERE c.id IS NULL;

-- 6.3. Найти покупателей без указанного города.
-- На текущих тестовых данных результат пустой.
SELECT id, name
FROM customers
WHERE city IS NULL;

-- 6.4. Найти возможные дубликаты покупателей по имени и городу.
-- На текущих тестовых данных дубликатов нет.
-- В реальном проекте критерий дубликата нужно согласовать с бизнес-правилами.
SELECT
    name,
    city,
    COUNT(*) AS duplicates_count
FROM customers
GROUP BY name, city
HAVING COUNT(*) > 1;

-- 6.5. Проверить, что цена товара не отрицательная.
-- На текущей схеме ограничение CHECK (price >= 0) запрещает такие значения.
SELECT id, name, price
FROM products
WHERE price < 0;
