-- Sakila Database Queries for Data Analysis
-- -----------------------------------------

-- Category 1: Customer Information
-----------------------------------

-- 1. Retrieve the first, last names, and full name of all active customers
SELECT customer_id, first_name, last_name, CONCAT(first_name, ' ', last_name) AS full_name, active
FROM customer
WHERE active = 1;

-- 2. Count of active and inactive customers
SELECT CASE WHEN active = 0 THEN 'inactive' ELSE 'active' END AS active_inactive, COUNT(*)
FROM customer
GROUP BY active;

-- 3. Show the total number of rentals for each customer
SELECT c.customer_id "Customer ID", CONCAT(c.first_name, ' ', c.last_name) "Customer", COUNT(rental_id) AS "Total Rentals"
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id
ORDER BY COUNT(rental_id) DESC, c.customer_id;

-- 4. Display the total amount paid by each customer in rentals
SELECT c.customer_id AS "Customer ID", CONCAT(c.first_name, ' ', c.last_name) AS "Customer", SUM(p.amount)
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
ORDER BY SUM(p.amount) DESC;

-- 5. Retrieve the customer who has paid the highest total amount for rentals
SELECT c.customer_id "Customer ID", CONCAT(c.first_name, ' ', c.last_name) "Customer", SUM(p.amount)
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
ORDER BY SUM(p.amount) DESC
LIMIT 1;

-- 6. Top 5 customers with the highest total amount paid for rentals
SELECT c.customer_id AS "Customer ID", CONCAT(c.first_name, ' ', c.last_name) AS "Customer", SUM(p.amount)
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
ORDER BY SUM(p.amount) DESC
LIMIT 5;


-- Category 2: Film Information
------------------------------

-- 1. List of all films, film length, and respective category name
SELECT c.name AS category_name, f.title AS film_title, f.length AS film_length
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category c ON fc.category_id = c.category_id
ORDER BY c.name;

-- 2. Average film length
SELECT AVG(length) AS avg_film_length
FROM film;

-- 3. Average length of films in each category
SELECT c.name AS category_name, ROUND(AVG(f.length), 2) AS avg_film_length
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY c.name;

-- 4. Show the rental rate for each film
SELECT title AS film_title, ROUND(rental_rate, 2) AS rental_rate
FROM film
ORDER BY rental_rate DESC, title;

-- 5. Calculate the average rental rate for each film category
SELECT c.name AS category_name, ROUND(AVG(f.rental_rate), 2) AS avg_rental_rate
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category c ON c.category_id = fc.category_id
GROUP BY c.name
ORDER BY c.name;

-- 6. Films that were not rented by any customer
SELECT f.film_id AS "Film ID", title AS "Film Title"
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL;

-- 7. List of films priced at $0.99 under each category
SELECT c.name AS category_name, COUNT(*) AS "Films Priced at $0.99"
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE f.rental_rate = 0.99
GROUP BY c.name;

-- 8. Films inventory count
SELECT f.title AS film_title, COUNT(i.inventory_id) AS inventory_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY inventory_count DESC;


-- Category 3: Rental and Payment Information
---------------------------------------------

-- 1. Show the total number of rentals for each film
SELECT f.title AS "Film Title", COUNT(r.rental_id) AS "No. of Rentals"
FROM rental r
LEFT JOIN inventory i ON r.inventory_id = i.inventory_id
LEFT JOIN film f ON f.film_id = i.film_id
GROUP BY f.title
ORDER BY COUNT(r.rental_id) DESC, f.title ASC;

-- 2. Retrieve the names and rental durations of films that have a rental duration between 3 and 5 days
SELECT title AS "Film Title", rental_duration AS "Rental Duration"
FROM film
WHERE rental_duration BETWEEN 3 AND 5
ORDER BY rental_duration DESC, title;

-- 3. Films on rent that have not been returned
SELECT f.title AS film_title, r.rental_date
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON r.inventory_id = i.inventory_id
WHERE r.return_date IS NULL;

-- 4. Average rental duration for each staff member
SELECT p.staff_id AS "Staff ID", CONCAT(s.first_name, ' ', s.last_name) AS "Staff Name", ROUND(AVG(amount), 2) AS avg_amount
FROM payment p
LEFT JOIN staff s ON p.staff_id = s.staff_id
GROUP BY p.staff_id, CONCAT(s.first_name, ' ', s.last_name);

-- 5. Most profitable store based on total rental revenue
SELECT s.store_id, st.staff_id, SUM(p.amount) AS total_revenue
FROM store s
JOIN staff st ON s.store_id = st.store_id
JOIN payment p ON st.staff_id = p.staff_id
GROUP BY s.store_id, st.staff_id
ORDER BY total_revenue DESC;


-- Category 4: Analytical Questions
-----------------------------------

-- 1. Top 5 most rented films by month
WITH MonthlyRentals AS (
    SELECT f.title AS movie_title, COUNT(r.rental_id) AS total_rentals, TO_CHAR(r.rental_date, 'Month') AS rental_month,
           EXTRACT(MONTH FROM r.rental_date) AS month_number,
           ROW_NUMBER() OVER (PARTITION BY TO_CHAR(r.rental_date, 'Month') ORDER BY COUNT(r.rental_id) DESC) AS month_ranked
    FROM rental r
    LEFT JOIN inventory i ON r.inventory_id = i.inventory_id
    LEFT JOIN film f ON f.film_id = i.film_id
    GROUP BY f.title, TO_CHAR(r.rental_date, 'Month'), EXTRACT(MONTH FROM r.rental_date)
)
SELECT movie_title, total_rentals, rental_month
FROM MonthlyRentals
WHERE month_ranked <= 5
ORDER BY month_number;

-- 2. Top spending customers in each city
WITH HighestSpendingCustomers AS (
    SELECT c.customer_id AS CustomerID, CONCAT(c.first_name, ' ', c.last_name) AS Customer, SUM(p.amount) AS CustomerSpending,
           city.city AS City, ROW_NUMBER() OVER (PARTITION BY city.city ORDER BY SUM(p.amount) DESC) AS Customer_City_Rank
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    JOIN address a ON c.address_id = a.address_id
    JOIN city ON a.city_id = city.city_id
    GROUP BY c.customer_id, c.first_name, c.last_name, city.city
)
SELECT CustomerID, Customer, CustomerSpending, City
FROM HighestSpendingCustomers H
WHERE Customer_City_Rank = 1
ORDER BY CustomerSpending DESC, City;

-- 3. Most popular film categories by rentals
SELECT c.name AS category_name, COUNT(r.rental_id) AS rental_count
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category c ON fc.category_id = c.category_id
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY c.name
ORDER BY rental_count DESC;

-- 4. Top 3 longest rentals by customer
WITH RentalDurations AS (
    SELECT c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name, f.title AS film_title,
           r.rental_date, r.return_date, EXTRACT(DAY FROM (return_date - rental_date)) AS rental_duration_days
    FROM rental r
    JOIN customer c ON r.customer_id = c.customer_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    WHERE r.return_date IS NOT NULL
)
SELECT customer_name, film_title, rental_duration_days
FROM RentalDurations
ORDER BY rental_duration_days DESC
LIMIT 3;

