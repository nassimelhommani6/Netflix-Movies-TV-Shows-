/* 1)Understanding what content is available in different countries
   2)Identifying similar content by matching text-based features
   3)Network analysis of Actors / Directors and find interesting insights
   4) Does Netflix has more focus on TV Shows than movies in recent years 
   5) what is the target audience of Netflix's content  */
   SELECT * FROM netflix 
-- checking for nulls on each column
SELECT 
   SUM(CASE WHEN show_id IS NULL THEN 1 ELSE 0 END) AS show_id_null_count,
   SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) AS type_null_count,
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS title_null_count,
    SUM(CASE WHEN director IS NULL THEN 1 ELSE 0 END) AS director_null_count,
    SUM(CASE WHEN cast IS NULL THEN 1 ELSE 0 END) AS cast_null_count,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS country_null_count,
    SUM(CASE WHEN date_added IS NULL THEN 1 ELSE 0 END) AS date_added_null_count,
    SUM(CASE WHEN release_year IS NULL THEN 1 ELSE 0 END) AS release_year_null_count,
    SUM(CASE WHEN  rating IS NULL THEN 1 ELSE 0 END) AS rating_null_count,
    SUM(CASE WHEN  duration IS NULL THEN 1 ELSE 0 END) AS duration_null_count,
    SUM(CASE WHEN  listed_in  IS NULL THEN 1 ELSE 0 END) AS listed_in_null_count,
    SUM(CASE WHEN  description  IS NULL THEN 1 ELSE 0 END) AS description_null_count
FROM netflix ;

-- A) Data Validation and Cleaning 

-- checking for duplicates on each column 
SELECT
  COUNT(*) - COUNT(DISTINCT show_id ) AS show_id_duplicates,
  COUNT(*) - COUNT(DISTINCT type) AS type_duplicates,
  COUNT(*) - COUNT(DISTINCT title) AS title_duplicates,
  COUNT(*) - COUNT(DISTINCT director) AS director_duplicates,
  COUNT(*) - COUNT(DISTINCT cast ) AS cast_duplicates,
  COUNT(*) - COUNT(DISTINCT country) AS country_duplicates,
  COUNT(*) - COUNT(DISTINCT date_added) AS date_added_duplicates,
  COUNT(*) - COUNT(DISTINCT release_year) AS release_year_duplicates,
  COUNT(*) - COUNT(DISTINCT rating) AS rating_duplicates,
  COUNT(*) - COUNT(DISTINCT duration) AS duration_duplicates,
  COUNT(*) - COUNT(DISTINCT listed_in) AS listed_in_duplicates,
  COUNT(*) - COUNT(DISTINCT description) AS description_duplicates

FROM netflix;


-- **Standardize Date Format**

-- replace the "/" by "-"
Update netflix
SET date_added = REPLACE(date_added,"/","-");

-- Now we find out that not all column values have the same format so we need to adjust the query to make the conversion 
SELECT date_added ,  
  CASE 
   WHEN date_added LIKE '%,%'
   THEN STR_TO_DATE(date_added, '%M %d,%Y')
   ELSE STR_TO_DATE(date_added, '%m-%d-%Y')
END AS date_added_converted 
FROM netflix;

-- Update the column with the new date format
UPDATE netflix SET date_added = 
CASE 
   WHEN date_added LIKE '%,%'
   THEN STR_TO_DATE(date_added, '%M %d,%Y')
   ELSE STR_TO_DATE(date_added, '%m-%d-%Y')
END;

 -- Alter the column type to DATE
ALTER TABLE netflix MODIFY COLUMN date_added DATE;

-- ** remove inconsistent character from title ,director , cast and description**

SELECT director , CONVERT(CAST(CONVERT(director USING latin1) AS BINARY) USING utf8mb4) COLLATE utf8mb4_general_ci
from netflix ;

SELECT title , CONVERT(CAST(CONVERT( title USING latin1) AS BINARY) USING utf8mb4) COLLATE utf8mb4_general_ci
from netflix ;

SELECT description , CONVERT(CAST(CONVERT( description USING latin1) AS BINARY) USING utf8mb4) COLLATE utf8mb4_general_ci
from netflix ;

SELECT cast , CONVERT(CAST(CONVERT( cast USING latin1) AS BINARY) USING utf8mb4) COLLATE utf8mb4_general_ci
from netflix ;

-- update table 
UPDATE netflix
SET director = CONVERT(CAST(CONVERT(director USING latin1) AS BINARY) USING utf8mb4) COLLATE utf8mb4_general_ci;

UPDATE netflix
SET title = CONVERT(CAST(CONVERT(title USING latin1) AS BINARY) USING utf8mb4) COLLATE utf8mb4_general_ci;

UPDATE netflix
SET description = CONVERT(CAST(CONVERT(description USING latin1) AS BINARY) USING utf8mb4) COLLATE utf8mb4_general_ci;

UPDATE netflix
SET cast = CONVERT(CAST(CONVERT(cast USING latin1) AS BINARY) USING utf8mb4) COLLATE utf8mb4_general_ci;



-- **replace missing values in director , cast and country column **
-- Populate the Table using the description column 
SELECT t1.show_id, t1.type, t1.title, t1.director, t1.cast, t1.country, t1.date_added, t1.release_year, t1.rating, t1.duration, t1.listed_in, t1.description
FROM netflix AS t1
INNER JOIN (
    SELECT MIN(show_id) AS min_show_id, description, director, cast, country
    FROM netflix
    WHERE director IS NOT NULL AND cast IS NOT NULL AND country IS NOT NULL
    GROUP BY description, director, cast, country
) AS t2 ON t1.description = t2.description
WHERE t1.director IS NULL AND t1.cast IS NULL AND t1.country IS NULL;

UPDATE netflix AS t1
INNER JOIN (
    SELECT MIN(show_id) AS min_show_id, description, director, cast, country
    FROM netflix
    WHERE director IS NOT NULL AND cast IS NOT NULL AND country IS NOT NULL
    GROUP BY description, director, cast, country
) AS t2 ON t1.description = t2.description
SET t1.director = t2.director, t1.cast = t2.cast, t1.country = t2.country
WHERE t1.director IS NULL AND t1.cast IS NULL AND t1.country IS NULL;

-- Populate the country using the director column
SELECT nt2.title ,COALESCE(nt.country,nt2.country) AS new_country
FROM netflix  AS nt
JOIN netflix AS nt2 
ON nt.director = nt2.director 
AND nt.show_id <> nt2.show_id
WHERE nt.country IS NULL ;

--
update netflix AS nt
JOIN netflix  nt2 
ON nt.director = nt2.director 
AND nt.show_id <> nt2.show_id
SET nt.country = coalesce(nt.country,nt2.country)
WHERE nt.country IS NULL ;

-- ** Treating the nulls **
-- Populate the rest of the null countries 
UPDATE netflix
SET country = 'Unknown country'
WHERE country ='Unknown';

-- Populate the rest of the null director 
UPDATE netflix
SET director = 'Unknown director'
WHERE director IS NULL ;

-- Populate the rest of the null cast
UPDATE netflix
SET cast = 'Unknown cast'
WHERE cast IS NULL;

-- date_added nulls
SELECT show_id, date_added
FROM netflix
WHERE date_added IS NULL;

-- DELETE NULLS FROM duration , date_added , rating
COMMIT ;
DELETE FROM netflix 
WHERE date_added IS NULL 

DELETE FROM netflix 
WHERE duration IS NULL

DELETE FROM netflix 
WHERE rating IS NULL 




