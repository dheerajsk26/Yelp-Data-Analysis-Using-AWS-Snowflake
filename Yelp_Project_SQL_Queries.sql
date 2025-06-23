select * from yelp_reviews
limit 10;

select * from yelp_reviews_table
limit 10;

-- -----------------------------------

select * from yelp_businesses
limit 10;

select * from yelp_businesses_table
limit 10; 

-- -----------------------------------

SELECT COUNT(*) FROM yelp_reviews_table;
SELECT COUNT(*) FROM yelp_businesses_table;

-- -----------------------------------

-- 1) Find the number of businesses in each category

WITH category_cte AS (
SELECT business_id, TRIM(C.value) AS category
FROM yelp_businesses_table,
LATERAL split_to_table(categories,',') AS C
) 

SELECT category, COUNT(*) AS number_of_businesses
FROM category_cte
GROUP BY category
ORDER BY number_of_businesses DESC;

-- -----------------------------------

-- 2) Find the top 10 users who have reviewed the most businesses in the “Restaurants” category

WITH cte1 AS (
SELECT r.user_id, COUNT(DISTINCT r.business_id) AS distinct_count_reviews 
FROM yelp_businesses_table AS b
INNER JOIN yelp_reviews_table AS r 
ON b.business_id = r.business_id
WHERE categories ILIKE '%Restaurants%'
GROUP BY  r.user_id
ORDER BY distinct_count_reviews DESC 
) 

, cte2 AS (
SELECT *, RANK() OVER(ORDER BY distinct_count_reviews DESC) AS review_rank
FROM cte1
)

SELECT user_id, distinct_count_reviews
FROM cte2
WHERE review_rank <=10; 

-- -----------------------------------

-- 3) Find the most popular categories of businesses (based on the number of reviews)

WITH category_cte AS (
SELECT business_id, TRIM(C.value) AS category
FROM yelp_businesses_table,
LATERAL split_to_table(categories,',') AS C
) 

SELECT c.category, COUNT(*) AS number_of_reviews
FROM yelp_reviews_table r
INNER JOIN category_cte c 
ON r.business_id = c.business_id
GROUP BY category
ORDER BY number_of_reviews DESC;

-- -----------------------------------

-- 4) Find the top 3 most recent reviews for each business

WITH cte1 AS (
SELECT *, ROW_NUMBER() OVER(PARTITION BY r.business_id ORDER BY r.review_date DESC) AS rn
FROM yelp_businesses_table AS b
INNER JOIN yelp_reviews_table AS r 
ON b.business_id = r.business_id
)

SELECT *
FROM cte1 
WHERE rn<=3;

-- -----------------------------------

-- 5) Find the month with the highest number of reviews

WITH cte AS(
SELECT EXTRACT(MONTH FROM review_date) AS review_month, COUNT(*) AS total_reviews, 
RANK() OVER(ORDER BY total_reviews DESC) AS rank_review
FROM yelp_reviews_table
GROUP BY review_month
ORDER BY total_reviews DESC
) 

SELECT * FROM cte
WHERE rank_review = 1;

-- -----------------------------------

-- 6) Find the percentage of 5-star reviews for each business

SELECT b.business_id, b.name, COUNT(*) AS total_reviews,
COUNT(CASE WHEN r.review_stars = '5' THEN 1 ELSE NULL END) AS five_star_review,
ROUND((five_star_review/total_reviews)*100,2) AS percent_of_five_star_review
FROM yelp_reviews_table r
INNER JOIN yelp_businesses_table b
ON r.business_id = b.business_id
GROUP BY b.business_id, b.name
ORDER BY percent_of_five_star_review DESC; 


-- -----------------------------------

-- 7) Find the top 5 most reviewed businesses in each city

WITH cte1 AS (
SELECT b.city, b.business_id, b.name, COUNT(*) AS total_reviews
FROM yelp_businesses_table AS b
INNER JOIN yelp_reviews_table AS r 
ON b.business_id = r.business_id
GROUP BY b.city, b.business_id, b.name
) 

,cte2 AS(
SELECT  city, name, total_reviews, ROW_NUMBER() OVER(PARTITION BY city ORDER BY total_reviews DESC) AS rank_review
FROM cte1
) 

SELECT * FROM cte2
WHERE rank_review <=5
ORDER BY city,rank_review; 


-- -----------------------------------

-- 8) Find the average rating of businesses that have at least 100 reviews

SELECT b.business_id, b.name, COUNT(*) AS total_reviews,
ROUND(AVG(review_stars),2) AS avg_rating
FROM yelp_reviews_table r
INNER JOIN yelp_businesses_table b
ON r.business_id = b.business_id
GROUP BY b.business_id, b.name
HAVING total_reviews >=100
ORDER BY total_reviews DESC;


-- -----------------------------------

-- 9) List the top 10 users who have written the most reviews

WITH cte1 AS (
SELECT r.user_id, COUNT(*) total_reviews 
FROM yelp_businesses_table AS b
INNER JOIN yelp_reviews_table AS r 
ON b.business_id = r.business_id
GROUP BY  r.user_id
)

, cte2 AS (
SELECT *, RANK() OVER(ORDER BY total_reviews DESC) AS review_rank
FROM cte1
)

SELECT user_id,business_id, total_reviews
FROM cte2
WHERE review_rank <= 10
ORDER BY total_reviews DESC;

-- -----------------------------------

-- 10) Find the top 10 businesses with the highest positive sentiment reviews

WITH cte1 AS (
SELECT b.business_id, b.name, COUNT(*) AS total_reviews
FROM yelp_reviews_table r
INNER JOIN yelp_businesses_table b
ON r.business_id = b.business_id
WHERE sentiments = 'Positive'
GROUP BY b.business_id, b.name 
) 

, cte2 AS (
SELECT *, RANK() OVER(ORDER BY total_reviews DESC) as rank_review
FROM cte1
)

SELECT * FROM 
cte2 
WHERE rank_review <=10;


-- -----------------------------------