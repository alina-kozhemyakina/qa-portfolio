-- SQL-запросы для практики ручного QA.
-- Запускайте запросы по отдельности.

-- 1. Получить имена и города всех покупателей.
SELECT name, city
FROM customers;

-- 2. Найти заказы дороже 1000.
SELECT id, customer_id, amount, status
FROM orders
WHERE amount > 1000;

-- 3. Найти завершённые заказы дороже 1000.
SELECT id, customer_id, amount
FROM orders
WHERE status = 'completed'
  AND amount > 1000;

-- 4. Отсортировать заказы от самой большой суммы к самой маленькой.
SELECT id, amount
FROM orders
ORDER BY amount DESC;

-- 5. Получить уникальные статусы заказов.
SELECT DISTINCT status
FROM orders;

-- 6. Посчитать количество и сумму заказов по каждому статусу.
SELECT status,
       COUNT(id) AS orders_count,
       SUM(amount) AS total_amount
FROM orders
GROUP BY status;

-- 7. Посчитать количество заказов каждого покупателя,
-- включая покупателей без заказов.
SELECT customers.id,
       customers.name,
       COUNT(orders.id) AS orders_count
FROM customers
LEFT JOIN orders
    ON customers.id = orders.customer_id
GROUP BY customers.id, customers.name
ORDER BY customers.id;

-- 8. Посчитать сумму заказов каждого покупателя.
-- COALESCE заменяет NULL на 0 для покупателя без заказов.
SELECT customers.id,
       customers.name,
       COALESCE(SUM(orders.amount), 0) AS total_amount
FROM customers
LEFT JOIN orders
    ON customers.id = orders.customer_id
GROUP BY customers.id, customers.name
ORDER BY customers.id;

-- 9. Найти покупателей, у которых нет заказов.
SELECT customers.name
FROM customers
LEFT JOIN orders
    ON customers.id = orders.customer_id
WHERE orders.id IS NULL;

-- 10. Найти покупателей, у которых есть хотя бы один
-- завершённый заказ.
SELECT customers.name
FROM customers
WHERE EXISTS (
    SELECT 1
    FROM orders
    WHERE orders.customer_id = customers.id
      AND orders.status = 'completed'
);

-- 11. Найти покупателей, у которых нет завершённых заказов.
-- Сюда попадут и покупатели без заказов вообще.
SELECT customers.name
FROM customers
WHERE NOT EXISTS (
    SELECT 1
    FROM orders
    WHERE orders.customer_id = customers.id
      AND orders.status = 'completed'
);

-- 12. Найти покупателей, у которых не менее двух заказов,
-- а общая сумма заказов превышает 2000.
SELECT customers.id,
       customers.name,
       COUNT(orders.id) AS orders_count,
       SUM(orders.amount) AS total_amount
FROM customers
INNER JOIN orders
    ON customers.id = orders.customer_id
GROUP BY customers.id, customers.name
HAVING COUNT(orders.id) >= 2
   AND SUM(orders.amount) > 2000;

-- 13. Найти покупателей, у которых все заказы отменены.
-- Сначала считаем общее количество заказов и количество
-- отменённых заказов, затем сравниваем эти значения.
SELECT customers.id,
       customers.name,
       COUNT(orders.id) AS total_orders,
       SUM(CASE
               WHEN orders.status = 'cancelled' THEN 1
               ELSE 0
           END) AS cancelled_orders
FROM customers
INNER JOIN orders
    ON customers.id = orders.customer_id
GROUP BY customers.id, customers.name
HAVING COUNT(orders.id) =
       SUM(CASE
               WHEN orders.status = 'cancelled' THEN 1
               ELSE 0
           END);

-- 14. QA-проверка: найти заказы с нулевой или отрицательной суммой.
-- В текущей схеме CHECK не позволит вставить отрицательную сумму,
-- но запрос полезен для проверки уже существующих таблиц без такого ограничения.
SELECT id, customer_id, amount
FROM orders
WHERE amount <= 0;

-- 15. QA-проверка: поиск заказов без существующего покупателя.
-- В текущей схеме внешний ключ запрещает такую запись.
-- Запрос полезен при проверке данных в таблицах без FK-ограничения.
SELECT orders.id, orders.customer_id
FROM orders
LEFT JOIN customers
    ON customers.id = orders.customer_id
WHERE customers.id IS NULL;

-- 16. QA-проверка: найти покупателей без указанного города.
SELECT id, name
FROM customers
WHERE city IS NULL;
