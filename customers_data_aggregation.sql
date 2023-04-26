/* Retrieving information about customers counts and payments by regions. */
SELECT country,
       COUNT(DISTINCT A.customer_id) AS customer_count,
       SUM(amount) AS total_payment,
	   AVG(amount) AS avg_payment,
	   D.region
FROM 
 ( SELECT 
  		A.customer_id,
  		sum(amount) as amount,
  		A.address_id
  	FROM
  	customer A
	INNER JOIN payment E ON A.customer_id = E.customer_id
  	GROUP BY A.customer_id
) as A
INNER JOIN address B ON A.address_id = B.address_id
INNER JOIN city C ON B.city_id = C.city_id
INNER JOIN country D ON C.country_ID = D.country_ID
GROUP BY D.region, country
ORDER BY avg_payment DESC
