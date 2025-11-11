create table listings(
id numeric,
listing_url varchar,
name varchar,
description varchar,
host_id numeric,
host_name varchar,
host_since date,
host_location varchar,
host_response_time varchar,
host_response_rate varchar,
host_acceptance_rate varchar,
host_is_superhost boolean,
host_listings_count int,
host_total int,
host_verifications varchar,
property_type varchar,
room_type varchar,
accommodates integer,
bathrooms decimal,
bathrooms_text varchar,
bedrooms decimal,
beds int,
number_of_reviews numeric,
review_scores_rating decimal
)

drop table reviews;

create table reviews (
listing_id numeric,
id numeric,
date date,
reviewer_id numeric,
reviewer_name varchar,
comments text
)

create table calendar(
listing_id int,
date date,
available boolean,
price varchar,
minimum_nights int,
maximum_nights int
)



--Question 1: Property Diversity

--1)

SELECT count(id) AS total_listings FROM listings;

SELECT count(DISTINCT property_type) AS unique_property_types  FROM listings;


-2)

SELECT property_type , count(*) as listing_count FROM listings
GROUP by property_type
ORDER BY listing_count DESC
LIMIT 5;



--Question 2: Guest Ratings

--1)
SELECT ROUND(AVG(review_scores_rating),2) FROM listings
WHERE review_scores_rating IS NOT NULL;

--2)
SELECT id,review_scores_rating FROM listings
WHERE review_scores_rating IS NOT NULL
ORDER BY review_scores_rating DESC
LIMIT 10;

--3)
SELECT count(id) AS low_rated_listings FROM listings
WHERE review_scores_rating < 4.0;


--Question 3: Host Engagement

--1)
SELECT host_id,host_name,COUNT(id) AS total_listings FROM listings
GROUP BY host_id,host_name
HAVING COUNT(id)> 3;

--2)
SELECT host_id,host_name,ROUND(AVG(review_scores_rating)) AS average_review_score FROM listings 
WHERE review_scores_rating IS NOT NULL
GROUP BY host_id;

--3) INCORRECT 
SELECT host_id FROM listings
WHERE host_listings_count >= 2 

INTERSECT

SELECT host_id FROM listings
WHERE review_scores_rating < 4.0



--Question 4: Booking Trends
--1)
SELECT listing_id, 
	round((Sum(CASE WHEN available=False then 1 ELSE 0 END)*1.0 / Count(*)),2) as occupancy_rate
FROM calendar 
WHERE date BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY listing_id

--2)
SELECT listing_id, 
	round((Sum(CASE WHEN available=False then 1 ELSE 0 END)*1.0 / Count(*)),2) as occupancy_rate
FROM calendar 
WHERE date BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY listing_id
order by occupancy_rate DESC
limit 5;

--3)
SELECT listing_id, 
	round((Sum(CASE WHEN available=False then 1 ELSE 0 END)*1.0 / Count(*)),2) as occupancy_rate
FROM calendar 
WHERE date BETWEEN '2024-01-01' AND '2024-01-31'
GROUP BY listing_id
HAVING round((Sum(CASE WHEN available=False then 1 ELSE 0 END)*1.0 / Count(*)),2) = 0



--Question 5: Pricing Patterns Across Property Types

--1)
SELECT l.property_type,ROUND(AVG(cast(REPLACE(Replace(c.price,'$',''),',','') as DECIMAL)),2) AS "avg_price_per_night"
FROM listings l
JOIN calendar c
ON l.id = c.listing_id
WHERE c.price IS NOT NULL
GROUP BY property_type


--2)
SELECT l.id,l.name,l.property_type,cast(REPLACE(Replace(c.price,'$',''),',','') as DECIMAL) AS "price_per_night"
FROM listings l
JOIN calendar c
ON l.id = c.listing_id
WHERE c.price IS NOT NULL
ORDER BY price_per_night DESC
LIMIT 5;

--3)
SELECT l.property_type,ROUND(AVG(cast(REPLACE(Replace(c.price,'$',''),',','') as DECIMAL)),2) AS "avg_price_per_night"
FROM listings l
JOIN calendar c
ON l.id = c.listing_id
WHERE c.price IS NOT NULL  
GROUP BY property_type
HAVING ROUND(AVG(cast(REPLACE(Replace(c.price,'$',''),',','') as DECIMAL)),2) < 150



--Question 6: Guest Review Insights

--1)
SELECT r.reviewer_id, r.reviewer_name 
FROM reviews r
JOIN listings l
ON r.listing_id = l.id
ORDER BY l.number_of_reviews DESC
LIMIT 10;

--2)
SELECT id,round(avg(number_of_reviews),2) as avg_no_of_reviews
FROM listings
GROUP BY id
ORDER BY avg_no_of_reviews DESC;

--3)
SELECT l.id FROM listings l
JOIN reviews r 
ON l.id = r.listing_id
WHERE EXTRACT(YEAR FROM r.date) = 2023 AND l.number_of_reviews =0 