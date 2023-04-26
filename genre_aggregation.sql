/* Query to retrieve Category aggregations. */
SELECT 
c.name as category_name, 
sum(amount_by_category) as amount_by_category, 
COUNT(fc.film_id) as film_count
FROM 
category AS c
INNER JOIN film_category AS fc ON c.category_id = fc.category_id
INNER JOIN (
	SELECT i.film_id,
	SUM(p.amount) as amount_by_category
	FROM payment AS p
	INNER JOIN rental AS r ON p.rental_id = r.rental_id
	INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id
	GROUP BY i.film_id
) AS film_sum_amount ON (film_sum_amount.film_id = fc.film_id)
GROUP BY c.name
ORDER BY amount_by_category DESC
