/* Analytics through SQL on	Oracle*/	
/*Elena Lahoz Moreno, Claudia Lucio Sarsa, Antonio Martínez Payá y Juan Carlos Pereira Kohatsu*/

---EXERCISE 1:
/*Good comrades: stars in top ten of number of different co-stars they have
worked with */

select * from
	(select actor1, count(*) costars 
	from (select distinct a.actor actor1 , b.actor actor2
		from (CASTS a inner join CASTS b on a.title = b.title) 
		where a.actor != b.actor) 
	group by actor1 order by costars desc)
where rownum <= 10;


---EXERCISE 2
/*Targeted countries: in order to plan marketing actions, we want to retrieve
countries in the highest quartile of avg expenses, though in the lower quartile in
number of clients*/

select t1.country, avgamount,nids from
	(select country, avgamount
	from(select country, avgamount,ntile(4) over (order by avgamount asc) quartile
		from (select country, AVG(amount) avgamount
		from (CONTRACTS c inner join INVOICES i on c.contractID = i.contractID)
		group by country))
	where quartile = 4) t1
inner join 
	(select country, nids
	from 	(select country, nids ,ntile(4) over (order by nids asc) quartile
			from (select country, count(contractID) nids
			from CONTRACTS
			group by country))
	where quartile = 1) t2
on t1.country = t2.country;

---EXERCISE 3
/*Total taps for each episode, for each season, and for each tv series in the base,
restricted to the month of May/16. */

SELECT title, DECODE(grouping(season), 1, 'all seasons', season) num_season,DECODE(grouping(episode), 1, 'all episodes', episode) num_episode, count(*) total_taps 
FROM TAPS_SERIES WHERE EXTRACT(month from view_datetime) = 5 and EXTRACT(year from view_datetime) = 2016 
GROUP BY GROUPING SETS ((title,season,episode),(title,season),(title));

---EXERCISE 4
/*Sales Boost analysis: 5 dates with greater difference between number of
licenses sold and the amount of the inmediate previous day. */

SELECT *  FROM 
(SELECT datetime, abs(total_licenses-lag(total_licenses,1,0)
OVER (ORDER BY datetime)) difference
FROM
(SELECT datetime, sum(licenses) total_licenses FROM (
	(SELECT datetime, count(*) licenses
	FROM LIC_MOVIES
	WHERE datetime is not null	
	GROUP BY datetime)
UNION ALL
	(SELECT datetime, count(*) licenses
	FROM LIC_SERIES
	WHERE datetime is not null
	GROUP BY datetime))
GROUP BY datetime)
ORDER BY difference desc)
WHERE rownum<=5;

---EXERCISE 5
/*For each type of contract during 2016, accumulated monthly income.*/

select contract_type, month, SUM(amount) income
from CONTRACTS natural join INVOICES 
where year = 2016 group by grouping sets ((contract_type,month)) order by contract_type;

---EXERCISE 6
/*For each month, movies in the highest decile of views, in the highest decile of
facebook likes, and also the highest decile of gross (if sorted in ascendant order,
the tenth decile). */

select datemonth, title, nviews, gross, movie_facebook_likes from (
	select title, datemonth,nviews
	from
		(select title, datemonth,nviews,ntile(10) over (order by nviews asc) decile
		from 
		(select title, EXTRACT(month from view_datetime) datemonth ,count(*) nviews 
			from TAPS_MOVIES 
			group by grouping sets ((title, EXTRACT(month from view_datetime)))))
where decile = 10)
inner join 
(select movie_title, gross
from(select movie_title, gross,ntile(10) over (order by gross asc) decile 
	from MOVIES
	where gross is not null)
where decile = 10) gross_table 
on title = movie_title 
inner join 
(select movie_title, movie_facebook_likes
from(select movie_title, movie_facebook_likes,ntile(10) over (order by movie_facebook_likes asc) decile 
	from MOVIES
	where movie_facebook_likes is not null)
where decile = 10) facebook_table
on gross_table.movie_title = facebook_table.movie_title order by datemonth;

---EXERCISE 7
/*Traffic Peak Week: 7-day period of higher traffic (minutes viewed)*/

SELECT CONCAT(day-6,CONCAT('-', day)) interval, total_traffic FROM
(select day, traffic, sum(traffic) OVER (ORDER BY day ROWS 6 PRECEDING) total_traffic FROM
(select movies_table.day day, movies_table.traffic + series_table.traffic traffic from
	(select EXTRACT(day from view_datetime) day, sum(duration*PCT) traffic 
		from MOVIES
		inner join
		TAPS_MOVIES
		on title=movie_title group by EXTRACT(day from view_datetime)) movies_table
inner join
	(select EXTRACT(day from view_datetime) day, sum(avgduration*PCT) traffic from SEASONS
	inner join 
	TAPS_SERIES
	on SEASONS.title=TAPS_SERIES.title group by EXTRACT(day from view_datetime)) series_table
on movies_table.day = series_table.day order by movies_table.day)
ORDER BY traffic desc)
WHERE rownum<=1;
