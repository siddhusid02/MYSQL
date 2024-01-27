USE imdb;

/* To begin with, it is beneficial to know the shape of the tables and whether any column has null values.





-- Finding the total number of rows in each table of the schema

SELECT (SELECT COUNT(*) FROM DIRECTOR_MAPPING) as DIRECTOR_MAPPING_rows,
		(SELECT COUNT(*) FROM GENRE) as GENRE_rows,
		(SELECT COUNT(*) FROM  MOVIE) as MOVIE_rows,
		(SELECT COUNT(*) FROM  NAMES) as NAMES_rows,
		(SELECT COUNT(*) FROM  RATINGS) as RATINGS_rows,
		(SELECT COUNT(*) FROM  ROLE_MAPPING) as ROLE_MAPPING_rows;

-- Finding null values


SELECT Sum(CASE
             WHEN id IS NULL THEN 1
             ELSE 0
           END) AS null_count_id,
       Sum(CASE
             WHEN title IS NULL THEN 1
             ELSE 0
           END) AS null_count_title,
       Sum(CASE
             WHEN year IS NULL THEN 1
             ELSE 0
           END) AS null_count_year,
       Sum(CASE
             WHEN date_published IS NULL THEN 1
             ELSE 0
           END) AS null_count_date_published,
       Sum(CASE
             WHEN duration IS NULL THEN 1
             ELSE 0
           END) AS null_count_duration,
       Sum(CASE
             WHEN country IS NULL THEN 1
             ELSE 0
           END) AS null_count_country,
       Sum(CASE
             WHEN worlwide_gross_income IS NULL THEN 1
             ELSE 0
           END) AS null_count_worlwide_gross_income,
       Sum(CASE
             WHEN languages IS NULL THEN 1
             ELSE 0
           END) AS null_count_languages,
       Sum(CASE
             WHEN production_company IS NULL THEN 1
             ELSE 0
           END) AS null_count_production_company
FROM   movie; 

-- Now as you can see four columns of the movie table has null values. Let's look at the at the movies released each year. 

SELECT year,
       Count(title) AS number_of_movies
FROM   movie
GROUP  BY year;

-- Number of movies released each month 
SELECT Month(date_published) AS month_num,
       Count(*)              AS number_of_movies
FROM   movie
GROUP  BY month_num
ORDER  BY month_num; 

/*The highest number of movies is produced in the month of March.
 let’s take a look at the other details in the movies table. 
We know USA and India produces huge number of movies each year. Lets find the number of movies produced by USA or India for the last year.*/
  

SELECT Count(DISTINCT id) AS number_of_movies, year
FROM   movie
WHERE  ( country LIKE '%INDIA%'
          OR country LIKE '%USA%' )
       AND year = 2019; 

/* USA and India produced more than a thousand movies in the year 2019.
Exploring table Genre would be fun!! 
Let’s find out the different genres in the dataset.*/


SELECT DISTINCT genre
FROM   genre; 

/* So, RSVP Movies plans to make a movie of one of these genres.
Combining both the movie and genres table can give more interesting insights. */



SELECT     genre,
           Count(m.id) AS number_of_movies
FROM       movie       AS m
INNER JOIN genre       AS g
where      g.movie_id = m.id
GROUP BY   genre
ORDER BY   number_of_movies DESC limit 1 ;

/* So,RSVP Movies should focus on the ‘Drama’ genre. 
 let’s find out the count of movies that belong to only one genre.*/

WITH movies_with_one_genre
     AS (SELECT movie_id
         FROM   genre
         GROUP  BY movie_id
         HAVING Count(DISTINCT genre) = 1)
SELECT Count(*) AS movies_with_one_genre
FROM   movies_with_one_genre; 

/* There are more than three thousand movies which has only one genre associated with them.
So, this figure appears significant. 
Now, let's find out the possible duration of RSVP Movies’ next project.*/



SELECT     genre,
           Round(Avg(duration),2) AS avg_duration
FROM       movie                  AS m
INNER JOIN genre                  AS g
ON      g.movie_id = m.id
GROUP BY   genre
ORDER BY avg_duration DESC;

/* Now we know, movies of genre 'Drama' (produced highest in number in 2019) has the average duration of 106.77 mins.
Lets find where the movies of genre 'thriller' on the basis of number of movies.*/



WITH genre_summary AS
(
	SELECT     genre,
	Count(movie_id)                            AS movie_count ,
	Rank() OVER(ORDER BY Count(movie_id) DESC) AS genre_rank
	FROM       genre                                 
	GROUP BY   genre )
SELECT *
FROM   genre_summary
WHERE  genre = "THRILLER" ;

/*Thriller movies is in top 3 among all genres in terms of number of movies
 In the previous segment, you analysed the movies and genres tables. 
 In this segment, you will analyse the ratings table as well.
To start with lets get the min and max values of different columns in the table*/



SELECT Min(avg_rating)    AS min_avg_rating,
       Max(avg_rating)    AS max_avg_rating,
       Min(total_votes)   AS min_total_votes,
       Max(total_votes)   AS max_total_votes,
       Min(median_rating) AS min_median_rating,
       Max(median_rating) AS max_median_rating
FROM   ratings; 

/* So, the minimum and maximum values in each column of the ratings table are in the expected range. 
This implies there are no outliers in the table. 
Now, let’s find out the top 10 movies based on average rating.*/


-- It's ok if RANK() or DENSE_RANK() is used too
SELECT     title,
           avg_rating,
           Rank() OVER(ORDER BY avg_rating DESC) AS movie_rank
FROM       ratings                               AS r
INNER JOIN movie                                 AS m
ON         m.id = r.movie_id limit 10;

-- top 10 movies can also be displayed using WHERE caluse with CTE
WITH MOVIE_RANK AS
(
SELECT	title,
		avg_rating,
		ROW_NUMBER() OVER(ORDER BY avg_rating DESC) AS movie_rank
FROM ratings AS r
INNER JOIN movie AS m
ON m.id = r.movie_id
)
SELECT * FROM MOVIE_RANK
WHERE movie_rank<=10;

So, now that we know the top 10 movies, do you think character actors and filler actors can be from these movies?
Summarising the ratings table based on the movie counts by median rating can give an excellent insight.*/


-- Order by is good to have
SELECT median_rating,
       Count(movie_id) AS movie_count
FROM   ratings
GROUP  BY median_rating
ORDER  BY movie_count DESC;

/* Movies with a median rating of 7 is highest in number. 
Now, let's find out the production house with which RSVP Movies can partner for its next project.*/


WITH production_company_hit_movie_summary
     AS (SELECT production_company,
                Count(movie_id)                     AS movie_count,
                Rank()
                  OVER(
                    ORDER BY Count(movie_id) DESC ) AS prod_company_rank
         FROM   ratings AS R
                INNER JOIN movie AS M
                        ON M.id = R.movie_id
         WHERE  avg_rating > 8
                AND production_company IS NOT NULL
         GROUP  BY production_company)
SELECT *
FROM   production_company_hit_movie_summary
WHERE  prod_company_rank = 1;



SELECT genre,
       Count(M.id) AS MOVIE_COUNT
FROM   movie AS M
       INNER JOIN genre AS G
               ON G.movie_id = M.id
       INNER JOIN ratings AS R
               ON R.movie_id = M.id
WHERE  year = 2017
       AND Month(date_published) = 3
       AND country LIKE '%USA%'
       AND total_votes > 1000
GROUP  BY genre
ORDER  BY movie_count DESC;

-- Lets try to analyse with a unique problem statement.


SELECT  title,
       avg_rating,
       genre
FROM   movie AS M
       INNER JOIN genre AS G
               ON G.movie_id = M.id
       INNER JOIN ratings AS R
               ON R.movie_id = M.id
WHERE  avg_rating > 8
       AND title LIKE 'THE%'
ORDER BY avg_rating DESC;

-- we should also try your hand at median rating and check whether the ‘median rating’ column gives any significant insights.

SELECT median_rating, Count(*) AS movie_count
FROM   movie AS M
       INNER JOIN ratings AS R
               ON R.movie_id = M.id
WHERE  median_rating = 8
       AND date_published BETWEEN '2018-04-01' AND '2019-04-01'
GROUP BY median_rating;



SELECT country, sum(total_votes) as total_votes
FROM movie AS m
	INNER JOIN ratings as r ON m.id=r.movie_id
WHERE country = 'Germany' or country = 'Italy'
GROUP BY country;



/* Now that we have analysed the movies, genres and ratings tables, let us now analyse another table, the names table. 
Let’s begin by searching for null values in the tables.*/


SELECT (SELECT Count(*) 
FROM   names
WHERE  NAME IS NULL) AS name_nulls,
(SELECT Count(*)
FROM   names
WHERE  height IS NULL) AS height_nulls,
(SELECT Count(*)
FROM   names
WHERE  date_of_birth IS NULL) AS date_of_birth_nulls,
(SELECT Count(*)
FROM   names
WHERE  known_for_movies IS NULL) AS known_for_movies_nulls;

/* There are no Null value in the column 'name'.
The director is the most important person in a movie crew. 
Let’s find out the top three directors in the top three genres who can be hired by RSVP Movies.*/


WITH top_3_genres AS
(SELECT genre,
		Count(m.id)                            AS movie_count ,
		Rank() OVER(ORDER BY Count(m.id) DESC) AS genre_rank
		FROM movie  AS m
		INNER JOIN genre AS g
		ON g.movie_id = m.id
		INNER JOIN ratings AS r
		ON r.movie_id = m.id
		WHERE avg_rating > 8
		GROUP BY  genre limit 3 )
SELECT  n.NAME AS director_name ,
        Count(d.movie_id) AS movie_count
FROM director_mapping  AS d
INNER JOIN genre G
using (movie_id)
INNER JOIN names AS n
ON n.id = d.name_id
INNER JOIN top_3_genres
using (genre)
INNER JOIN ratings
using (movie_id)
WHERE avg_rating > 8
GROUP BY NAME
ORDER BY movie_count DESC limit 3;

/* James Mangold can be hired as the director for RSVP's next project. Do you remeber his movies, 'Logan' and 'The Wolverine'. 
Now, let’s find out the top two actors.*/



SELECT N.name AS actor_name,
       Count(movie_id) AS movie_count
FROM role_mapping AS RM
	INNER JOIN movie AS M
	ON M.id = RM.movie_id
	INNER JOIN ratings AS R USING(movie_id)
	INNER JOIN names AS N
	ON N.id = RM.name_id
WHERE R.median_rating >= 8
AND category = 'ACTOR'
GROUP BY actor_name
ORDER BY movie_count DESC
LIMIT 2;

/* RSVP Movies plans to partner with other global production houses. 
Let’s find out the top three production houses in the world.*/


SELECT production_company,
		Sum(total_votes) AS vote_count,
		Rank() OVER(ORDER BY Sum(total_votes) DESC) AS prod_comp_rank
FROM  movie AS m
INNER JOIN ratings AS r
ON r.movie_id = m.id
GROUP BY production_company limit 3;

/*Yes Marvel Studios rules the movie world.
So, these are the top three production houses based on the number of votes received by the movies they have produced.

Since RSVP Movies is based out of Mumbai, India also wants to woo its local audience. 
RSVP Movies also wants to hire a few Indian actors for its upcoming project to give a regional feel. 
Let’s find who these actors could be.*/


WITH actor_summary
AS (SELECT N.NAME AS
	actor_name,
	sum(R.total_votes) as total_votes,
	Count(R.movie_id) AS
	movie_count,
	Round(Sum(avg_rating * total_votes) / Sum(total_votes), 2) AS
	actor_avg_rating
FROM movie AS M
	INNER JOIN ratings AS R
	ON M.id = R.movie_id
	INNER JOIN role_mapping AS RM
	ON M.id = RM.movie_id
	INNER JOIN names AS N
	ON RM.name_id = N.id
	WHERE category = 'ACTOR'
	AND country = "india"
GROUP BY NAME
HAVING movie_count >= 5)
SELECT *,
	Rank()
	OVER(ORDER BY actor_avg_rating DESC) AS actor_rank
FROM actor_summary;

-- Top actor is Vijay Sethupathi


WITH actress_summary AS
(SELECT n.NAME AS actress_name,
			sum(total_votes) as total_votes,
			Count(r.movie_id) AS movie_count,
			Round(Sum(avg_rating*total_votes)/Sum(total_votes),2) AS actress_avg_rating
           FROM  movie AS m
           INNER JOIN ratings AS r
           ON m.id=r.movie_id
           INNER JOIN role_mapping AS rm
           ON m.id = rm.movie_id
           INNER JOIN names AS n
           ON rm.name_id = n.id
           WHERE category = 'ACTRESS'
           AND country = "INDIA"
           AND languages LIKE '%HINDI%'
           GROUP BY NAME
           HAVING movie_count>=3 )
SELECT *,
	Rank() OVER(ORDER BY actress_avg_rating DESC) AS actress_rank
FROM  actress_summary LIMIT 5;
/* Taapsee Pannu tops with average rating 7.74. 
Now let us divide all the thriller movies in the following categories and find out their numbers.*/



WITH thriller_movies
     AS (SELECT DISTINCT title,
		avg_rating
         FROM  movie AS M
		INNER JOIN ratings AS R
		ON R.movie_id = M.id
		INNER JOIN genre AS G using(movie_id)
         WHERE  genre LIKE 'THRILLER')
SELECT *,
       CASE
         WHEN avg_rating > 8 THEN 'Superhit movies'
         WHEN avg_rating BETWEEN 7 AND 8 THEN 'Hit movies'
         WHEN avg_rating BETWEEN 5 AND 7 THEN 'One-time-watch movies'
         ELSE 'Flop movies'
       END AS avg_rating_category
FROM   thriller_movies; 

/* Until now, we have analysed various tables of the data set. 
Now, we will perform some tasks that will give you a broader understanding of the data in this segment.*/


SELECT genre,
		ROUND(AVG(duration),2) AS avg_duration,
        SUM(ROUND(AVG(duration),2)) OVER(ORDER BY genre ROWS UNBOUNDED PRECEDING) AS running_total_duration,
        AVG(ROUND(AVG(duration),2)) OVER(ORDER BY genre ROWS 10 PRECEDING) AS moving_avg_duration
FROM movie AS m 
INNER JOIN genre AS g 
ON m.id= g.movie_id
GROUP BY genre
ORDER BY genre;
-- Round is good to have and not a must have; Same thing applies to sorting


-- Let us find top 5 movies of each year with top 3 genres.

-- Top 3 Genres based on most number of movies
WITH top_genres AS
(SELECT genre,
		Count(m.id) AS movie_count ,
		Rank() OVER(ORDER BY Count(m.id) DESC) AS genre_rank
		FROM movie AS m
		INNER JOIN genre AS g
		ON g.movie_id = m.id
		INNER JOIN ratings AS r
		ON r.movie_id = m.id
          WHERE avg_rating > 8
		GROUP BY genre limit 3 ), movie_summary AS
(
  SELECT genre,
		year,
		title AS movie_name,
		CAST(replace(replace(ifnull(worlwide_gross_income,0),'INR',''),'$','') AS decimal(10)) AS worlwide_gross_income ,
		DENSE_RANK() OVER(partition BY year ORDER BY CAST(replace(replace(ifnull(worlwide_gross_income,0),'INR',''),'$','') AS decimal(10))  DESC ) AS movie_rank
           FROM movie AS m
           INNER JOIN genre AS g
           ON  m.id = g.movie_id
           WHERE genre IN
		(
			SELECT genre
			FROM top_genres)
           )
SELECT *
FROM   movie_summary
WHERE  movie_rank<=5
ORDER BY YEAR;

-- Finally, let’s find out the names of the top two production houses that have produced the highest number of hits among multilingual movies.


WITH production_company_summary
     AS (SELECT production_company,
		Count(*) AS movie_count
         FROM movie AS m
		inner join ratings AS r
		ON r.movie_id = m.id
         WHERE median_rating >= 8
		AND production_company IS NOT NULL
		AND Position(',' IN languages) > 0
         GROUP BY production_company
         ORDER BY movie_count DESC)
SELECT *,
       Rank() over(
           ORDER BY movie_count DESC) AS prod_comp_rank
FROM   production_company_summary
LIMIT 2; 


-- Multilingual is the important piece in the above question. It was created using POSITION(',' IN languages)>0 logic
-- If there is a comma, that means the movie is of more than one language

WITH actress_summary AS
(SELECT n.NAME AS actress_name,
		SUM(total_votes) AS total_votes,
		Count(r.movie_id) AS movie_count,
		Round(Sum(avg_rating*total_votes)/Sum(total_votes),2) AS actress_avg_rating
           FROM movie AS m
           INNER JOIN ratings AS r
           ON m.id=r.movie_id
           INNER JOIN role_mapping AS rm
           ON m.id = rm.movie_id
           INNER JOIN names AS n
           ON rm.name_id = n.id
           INNER JOIN GENRE AS g
           ON g.movie_id = m.id
           WHERE category = 'ACTRESS'
           AND avg_rating>8
           AND genre = "Drama"
           GROUP BY NAME )
SELECT   *,
	Rank() OVER(ORDER BY movie_count DESC) AS actress_rank
FROM  actress_summary LIMIT 3;


WITH next_date_published_summary AS
(SELECT d.name_id,
		NAME,
		d.movie_id,
		duration,
		r.avg_rating,
		total_votes,
		m.date_published,
		Lead(date_published,1) OVER(partition BY d.name_id ORDER BY date_published,movie_id ) AS next_date_published
           FROM  director_mapping AS d
           INNER JOIN names AS n
           ON n.id = d.name_id
           INNER JOIN movie AS m
           ON m.id = d.movie_id
           INNER JOIN ratings AS r
           ON r.movie_id = m.id ), top_director_summary AS
(SELECT *,
		Datediff(next_date_published, date_published) AS date_difference
       FROM next_date_published_summary )
SELECT  name_id AS director_id,
         NAME AS director_name,
         Count(movie_id) AS number_of_movies,
         Round(Avg(date_difference),2) AS avg_inter_movie_days,
         Round(Avg(avg_rating),2) AS avg_rating,
         Sum(total_votes) AS total_votes,
         Min(avg_rating) AS min_rating,
         Max(avg_rating) AS max_rating,
         Sum(duration) AS total_duration
FROM     top_director_summary
GROUP BY director_id
ORDER BY Count(movie_id) DESC limit 9;
