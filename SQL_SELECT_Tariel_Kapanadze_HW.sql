/*
* 1. All animation movies released between 2017 and 2019 with rate more than 1, alphabetical.
* I didn't join category because I checked to see which category_id Animation had. other solution still would include join to link table and then writine c.name = 'Animation'
*/

SELECT 
    f.title, 
    f.release_year, 
    f.rating
FROM 
    film f 
LEFT JOIN 
    film_category AS fc ON fc.film_id = f.film_id
WHERE 
    fc.category_id = 2 
    AND f.release_year BETWEEN 2017 AND 2019
    AND f.rating != 'G'
ORDER BY 
    f.title;


/*
 * 2. The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
 * At first I focused to find store and link it with the payment to find the revenue. since adress is only join to store table,
 * I made a subquery for store and their revenue filtered with date and added adress later.
 */

SELECT 
    CONCAT(a.address, ' ', COALESCE(a.address2, '')) AS full_address, 
    store_revenue.revenue
FROM 
    store s
JOIN 
    address a ON s.address_id = a.address_id
JOIN (
    SELECT 
        i.store_id, 
        SUM(p.amount) AS revenue
    FROM 
        inventory i
    JOIN 
        rental r ON i.inventory_id = r.inventory_id
    JOIN 
        payment p ON r.rental_id = p.rental_id
    WHERE 
        p.payment_date > '2017-03-31'
    GROUP BY 
        i.store_id
) AS store_revenue ON s.store_id = store_revenue.store_id
ORDER BY 
    store_revenue.revenue DESC;

/* 3. Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
 * 
 */
SELECT 
    first_name, 
    last_name, 
    number_of_movies
FROM 
    actor a 
JOIN (
    SELECT 
        fa.actor_id, 
        COUNT(*) AS number_of_movies
    FROM 
        film f
    INNER JOIN 
        film_actor AS fa ON f.film_id = fa.film_id
    WHERE 
        f.release_year > 2015
    GROUP BY 
        fa.actor_id
) AS amount_of_movies ON a.actor_id = amount_of_movies.actor_id
ORDER BY 
    number_of_movies DESC
LIMIT 5;


/* 4. Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, 
 * number_of_documentary_movies) sorted by release year in descending order. Dealing with NULL values is encouraged)
 * I had other solution with using CASE WHEN, but count and filter also works in this case.
*/
SELECT 
    f.release_year, 
    COUNT(*) FILTER (WHERE fg.name = 'Drama') AS number_of_drama_movies,
    COUNT(*) FILTER (WHERE fg.name = 'Travel') AS number_of_travel_movies,
    COUNT(*) FILTER (WHERE fg.name = 'Documentary') AS number_of_documentary_movies
FROM 
    film f
LEFT JOIN 
    film_category fc ON f.film_id = fc.film_id
LEFT JOIN 
    category fg ON fc.category_id = fg.category_id
GROUP BY 
    f.release_year
ORDER BY 
    f.release_year DESC;
    
/* Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 
 * 
 */

WITH test_query AS (
    SELECT 
        p.staff_id, 
        MAX(p.payment_date) AS last_payment_date, 
        SUM(p.amount) AS max_amount
    FROM 
        payment p
    WHERE 
        EXTRACT(YEAR FROM p.payment_date) = 2017
    GROUP BY 
        p.staff_id
)
SELECT 
    tq.staff_id, 
    s.first_name, 
    s.last_name, 
    tq.max_amount AS revenue, 
    st.store_id AS last_store 
FROM 
    test_query AS tq
LEFT JOIN 
    staff AS s ON tq.staff_id = s.staff_id
LEFT JOIN 
    store AS st ON s.store_id = st.store_id
ORDER BY 
    revenue DESC
LIMIT 3;



/* 2. Which 5 movies were rented more than others (number of rentals), and what's the expected age of the 
 * 	audience for these movies? To determine expected age please use 'Motion Picture Association film rating system
 * 
 * 
 */
SELECT 
    f.title, 
    rt.rental_count, 
    f.rating
FROM (
    SELECT 
        f.film_id, 
        COUNT(rental_id) AS rental_count
    FROM 
        film f
    LEFT JOIN 
        inventory i ON f.film_id = i.film_id
    LEFT JOIN 
        rental r ON i.inventory_id = r.inventory_id
    GROUP BY 
        f.film_id
) AS rt
LEFT JOIN 
    film f ON rt.film_id = f.film_id
ORDER BY 
    rt.rental_count DESC
LIMIT 5;


WITH rating_mapping AS (
    -- Create a temporary mapping between film ratings and expected audience ages.
   -- Query to list the 5 most rented movies and determine the expected audience age 
-- using the Motion Picture Association film rating system.
-- The query aggregates rental counts for each movie by joining film, inventory, and rental tables.

SELECT 
    f.title,                                  
    COUNT(r.rental_id) AS rental_count,      
    CASE f.rating                             
         WHEN 'G' THEN 'All Ages'            
         WHEN 'PG' THEN '10+'               
         WHEN 'PG-13' THEN '13+'             
         WHEN 'R' THEN '17+'                 
         WHEN 'NC-17' THEN '18+'             
         ELSE 'Unrated'                     
    END AS expected_audience_age
FROM film AS f
    
    INNER JOIN inventory AS i 
        ON f.film_id = i.film_id
    
    INNER JOIN rental AS r 
        ON i.inventory_id = r.inventory_id
GROUP BY 
    f.film_id,      
    f.title,        
    f.rating        
ORDER BY 
    rental_count DESC  
LIMIT 5;               



/*	Part 3. Which actors/actresses didn't act for a longer period of time than the others? 
 * 
 * V1: gap between the latest release_year and current year per each actor; 
 * inner joined films and link table to actor table. Current Year - Maximum release year.
 */

SELECT 
    CONCAT(a.first_name, ' ', a.last_name) AS actor_name,  
    (EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year)) AS gap_years
FROM 
    actor a
INNER JOIN 
    film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN 
    film f ON fa.film_id = f.film_id
GROUP BY 
    actor_name 
ORDER BY 
    gap_years DESC;