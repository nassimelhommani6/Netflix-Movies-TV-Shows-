
-- **B) Data Exploration and analysis** 

USE live_streaming ;
SELECT *
FROM netflix ;


-- 1)**Understanding what content is available in different countries**

-- count the maximum  number of individual country in the country column 
SELECT  country ,(CHAR_LENGTH(country) - CHAR_LENGTH(REPLACE(country, ',', '')))+ 1 AS number_of_country 
FROM netflix
group by country 
Order by 2 DESC ;

-- ##Let's Breaking down the Country Column (country vs title)## 

With countries AS (
SELECT title,country , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', numbers.n), ',', -1)) AS country_name
  FROM netflix 
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
      UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
  ) AS numbers
  WHERE CHAR_LENGTH(country) - CHAR_LENGTH(REPLACE(country, ',', '')) >= numbers.n - 1
) 
SELECT country_name, COUNT(DISTINCT title) AS num_titles
FROM countries
GROUP BY country_name
ORDER BY num_titles DESC;

-- ##Country vs type## 
WITH country_type AS (SELECT type , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', numbers.n), ',', -1)) AS country_name
  FROM netflix 
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
      UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
  ) AS numbers
  WHERE CHAR_LENGTH(country) - CHAR_LENGTH(REPLACE(country, ',', '')) >= numbers.n - 1
   )
SELECT country_name, 
SUM(CASE WHEN type='Movie' THEN 1 ELSE 0 END ) AS movie_count,
SUM(CASE WHEN type='TV Show' THEN 1 ELSE 0 END ) AS tvshow_count
FROM country_type 
GROUP BY 1 ;

-- count the maximum  number of listin in the listin column
SELECT  listed_in ,(CHAR_LENGTH(country) - CHAR_LENGTH(REPLACE(country, ',', '')))+ 1 AS number_of_listedin 
FROM netflix
group by listed_in 
Order by 2 DESC ;

-- ##Country vs listed_in## 
WITH country_type AS (SELECT type , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', numbers.n), ',', -1)) AS country_name ,listed_in
  FROM netflix 
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
      UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12
  ) AS numbers
  WHERE CHAR_LENGTH(country) - CHAR_LENGTH(REPLACE(country, ',', '')) >= numbers.n - 1
   ) 
   
 SELECT country_name ,listedin_name ,count(listedin_name)
 FROM ( SELECT country_name  , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', numbers.n), ',', -1)) AS listedin_name
  FROM country_type 
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
  ) AS numbers
  WHERE CHAR_LENGTH(listed_in) - CHAR_LENGTH(REPLACE(listed_in, ',', '')) >= numbers.n - 1
 ORDER BY country_name, listedin_name DESC) AS listedin_table 
 GROUP BY 1,2 
 ORDER BY 3 DESC ;
 
 
 
 
  -- 2)**Identifying similar content by matching text-based features**
  
  --  titles that have similar words in their descriptions (using LIKE)
SELECT t1.title, t2.title
FROM netflix t1 
INNER JOIN netflix t2 
ON t1.title != t2.title 
AND t1.description LIKE CONCAT('%', t2.description, '%') ;

-- titles that have similar genres(listedin)
SELECT t1.title, t2.title,t1.listed_In, t2.listed_in
FROM netflix t1
INNER JOIN netflix t2 ON t1.title != t2.title 
AND t1.listed_in REGEXP CONCAT('\\b', t2.listed_in, '\\b')

-- optimization
SELECT t1.title, t2.title, t1.listed_in, t2.listed_in
FROM (
  SELECT DISTINCT title, listed_in
  FROM netflix
) t1
INNER JOIN (
  SELECT DISTINCT title, listed_in
  FROM netflix
) t2 ON t1.title != t2.title
AND t1.listed_in REGEXP CONCAT('\\b', t2.listed_in, '\\b')

-- titles that have similar cast
SELECT t1.title, t2.title,t1.cast, t2.cast
FROM netflix t1
INNER JOIN netflix t2 ON t1.title != t2.title 
AND t1.cast REGEXP CONCAT('\\b', t2.cast, '\\b')

-- titles that have similar director
SELECT t1.title, t2.title,t1.director, t2.director
FROM netflix t1
INNER JOIN netflix t2 ON t1.title != t2.title 
AND t1.director REGEXP CONCAT('\\b', t2.director, '\\b')
AND t1.director<>'Unknown director' AND t2.director<>'Unknown director'
AND t1.director<>t2.director 

 -- ##titles with similar text based features## 
SELECT t1.title, t2.title AS similar_title, t2.listed_in
FROM netflix t1
JOIN netflix t2 ON t1.title <> t2.title AND t1.type = t2.type AND
  (
    t1.description LIKE CONCAT('%', t2.description, '%')
    OR t1.country REGEXP CONCAT('\\b', t2.country, '\\b')
    OR t1.director REGEXP CONCAT('\\b', t2.director, '\\b')
    OR t1.cast REGEXP CONCAT('\\b', t2.cast, '\\b')
    OR t1.listed_in REGEXP CONCAT('\\b', t2.listed_in, '\\b')
  )
  
  -- **3)Network analysis of Actors / Directors and find interesting insights**
 -- create directors_casts table 
 -- director count(13) 
 SELECT  director ,(CHAR_LENGTH(director) - CHAR_LENGTH(REPLACE(director, ',', '')))+ 1 AS number_of_director 
FROM netflix
group by director
Order by 2 DESC ;
-- cast count (13)
  SELECT  cast,(CHAR_LENGTH(director) - CHAR_LENGTH(REPLACE(director, ',', '')))+ 1 AS number_of_director 
FROM netflix
group by cast
Order by 2 DESC ;
 
 -- 1) director-director collaboration 
-- create a temporary table directors-cast that includes two column director and cast 
 CREATE TABLE directors_casts AS (
 WITH director_type AS (
 SELECT cast , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(director, ',', numbers.n), ',', -1)) AS director_name 
  FROM netflix 
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
      UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12  UNION ALL SELECT 13
  ) AS numbers
  WHERE CHAR_LENGTH(director) - CHAR_LENGTH(REPLACE(director, ',', '')) >= numbers.n - 1
   ) 
 SELECT director_name , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', numbers.n), ',', -1)) AS cast_name
  FROM director_type 
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
      UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13
  ) AS numbers
  WHERE CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) >= numbers.n - 1
 ORDER BY director_name, cast_name DESC
)
-- ##find the director_collaboration (the directors that works a lot with each other)##
SELECT d1.director_name AS director1, d2.director_name AS director2, COUNT(*) AS weight   
FROM directors_casts AS d1
JOIN directors_casts  AS d2 
ON d1.cast_name = d2.cast_name AND d1.director_name < d2.director_name
GROUP BY 1,2 
ORDER BY 3 DESC ;

-- 2) cast-cast collaboration 
CREATE TABLE cast_cast AS (
SELECT show_id , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', numbers.n), ',', -1)) AS cast_name
  FROM netflix
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
      UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13
  ) AS numbers
  WHERE CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) >= numbers.n - 1
 ORDER BY show_id ASC
)
-- ##find the cast_collaboration (the actors that works a lot with each other)##
SELECT c1.cast_name AS cast1, c2.cast_name AS cast2, COUNT(*) AS weight   
FROM cast_cast AS c1
JOIN cast_cast  AS c2 
ON c1.show_id = c2.show_id AND c1.cast_name < c2.cast_name
GROUP BY 1,2 
ORDER BY 3 DESC ;

-- ##find the cast_director collaboration (the actors that works a lot with each other)##
SELECT director_name, cast_name, COUNT(*) as num_collaborations
FROM directors_casts
GROUP BY director_name, cast_name
ORDER BY num_collaborations DESC;

-- ** Number of works per Actors** 
 
 WITH cast_title AS (SELECT type,title  , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(cast, ',', numbers.n), ',', -1)) AS cast_name
  FROM netflix
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
      UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13
  ) AS numbers
  WHERE CHAR_LENGTH(cast) - CHAR_LENGTH(REPLACE(cast, ',', '')) >= numbers.n - 1
 ORDER BY cast_name DESC )
 
 SELECT cast_name  , SUM(CASE WHEN type='Movie' THEN 1 ELSE 0 END ) AS movie_count , SUM(CASE WHEN type='TV Show' THEN 1 ELSE 0 END ) AS TVshow_count , SUM(CASE WHEN type='Movie' THEN 1 ELSE 0 END )+SUM(CASE WHEN type='TV Show' THEN 1 ELSE 0 END )AS total_work
 FROM cast_title 
 GROUP BY 1
ORDER BY 4 desc ;

-- ** Number of works per director** 
WITH director_title AS (
 SELECT title ,type , TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(director, ',', numbers.n), ',', -1)) AS director_name 
  FROM netflix 
  CROSS JOIN (
      SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
      UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12  UNION ALL SELECT 13
  ) AS numbers
  WHERE CHAR_LENGTH(director) - CHAR_LENGTH(REPLACE(director, ',', '')) >= numbers.n - 1
   ) 
 SELECT director_name  , SUM(CASE WHEN type='Movie' THEN 1 ELSE 0 END ) AS movie_count , SUM(CASE WHEN type='TV Show' THEN 1 ELSE 0 END ) AS TVshow_count , SUM(CASE WHEN type='Movie' THEN 1 ELSE 0 END )+SUM(CASE WHEN type='TV Show' THEN 1 ELSE 0 END )AS total_work
 FROM director_title 
 GROUP BY 1
ORDER BY 4 desc ;

 -- **4) Does Netflix has more focus on TV Shows than movies in recent years**
 SELECT YEAR(date_added) AS year , SUM(CASE WHEN type='Movie' THEN 1 ELSE 0 END ) AS movie_count , SUM(CASE WHEN type='TV Show' THEN 1 ELSE 0 END ) AS tvshow_count
FROM netflix
WHERE type IN ('Movie', 'TV Show')
GROUP BY  YEAR(date_added) 
ORDER BY  year 


-- **5) what is the target audience of Netflix's content **
SELECT YEAR(date_added) AS year, rating, COUNT(rating) AS count
FROM netflix
WHERE YEAR(date_added) is NOT NULL
GROUP BY YEAR(date_added), rating
ORDER BY YEAR(date_added), rating;

SELECT  rating, COUNT(rating) AS count
FROM netflix
GROUP BY  rating
ORDER BY  2 DESC;


