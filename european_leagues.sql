/******** The Database has the following Tables
      -  country
      -  league
      -  match
      -  team
      *******************************************************************/

-- Identify the home team as Bayern Munich, Schalke 04, or neither
SELECT
    CASE WHEN hometeam_id = 10189 THEN 'FC Schalke 04'
         WHEN hometeam_id = 9823 THEN 'FC Bayern Munich'
         ELSE 'Other' END AS home_team,
	COUNT(id) AS total_matches
FROM matches_germany
-- Group by the CASE statement alias
GROUP BY home_team;

/******************************************************************/
-- Barcelona Wins matches
SELECT
	m.date,
	t.team_long_name AS opponent,
	-- Complete the CASE statement with an alias
	CASE WHEN m.home_goal > m.away_goal THEN 'Barcelona win!'
         WHEN m.home_goal < m.away_goal THEN 'Barcelona loss :('
         ELSE 'Tie' END AS outcome
FROM matches_spain AS m
LEFT JOIN teams_spain AS t
ON m.awayteam_id = t.team_api_id
-- Filter for Barcelona as the home team
WHERE m.hometeam_id = 8634;

/************************************************************/
-- Counting the number of matched played in each season

SELECT c.name AS country,
      COUNT(CASE WHEN m.season = '2012/2013' THEN m.id END) AS matches_2012_2013,
      COUNT(CASE WHEN m.season = '2013/2014' THEN m.id END) AS matches_2013_2014,
      COUNT(CASE WHEN m.season = '2014/2015' THEN m.id END) AS matches_2014_2015
FROM country AS c
LEFT JOIN match AS m
ON c.id = m.country_id
Group BY 	country;

/***************************************************************/

--  total number of matches won by the home team in each country
-- during the 2012/2013, 2013/2014, and 2014/2015 seasons.
SELECT
	c.name AS country,
    -- Sum the total records in each season where the home team won
	SUM(CASE WHEN m.season = '2012/2013' AND m.home_goal > m.away_goal
        THEN 1 ELSE 0 END) AS matches_2012_2013,
	SUM(CASE WHEN m.season = '2013/2014' AND m.home_goal > m.away_goal
        THEN 1 ELSE 0 END) AS matches_2013_2014,
	SUM(CASE WHEN m.season = '2014/2015' AND m.home_goal > m.away_goal
        THEN 1 ELSE 0 END) AS matches_2014_2015
FROM country AS c
LEFT JOIN match AS m
ON c.id = m.country_id
GROUP BY country;
/******************************************************************/

-- generate a list of matches where the total goals scored (for both teams in
-- total) is more than 3 times the average for games in the matches_2013_2014.

SELECT
	-- Select the date, home goals, and away goals scored
	date,
	home_goal,
	away_goal
FROM matche
WHERE season = '2013/2014'
-- Filter for matches where total goals exceeds 3x the average
WHERE (home_goal + away_goal) >
       (SELECT 3 * AVG(home_goal + away_goal)
        FROM match
          WHERE season = '2013/2014');

/***********************************************************************/
--  list of teams that scored 8 or more goals in a home match.
SELECT
	team_long_name,
	team_short_name
FROM team
-- Filter for teams with 8 or more home goals
WHERE team_api_id IN
	  (SELECT hometeam_id
       FROM match
       WHERE home_goal >= 8);

/*********************************************************************/
-- calculate information about matches with 10 or more goals in total!
SELECT
	-- Select country name and the count match IDs
    c.name AS country_name,
    COUNT(sub.id) AS matches
FROM country AS c
-- Inner join the subquery onto country
-- Select the country id and match id columns
INNER JOIN (SELECT country_id, id
            FROM match
            -- Filter the subquery by matches with 10+ goals
            WHERE (home_goal + away_goal) >= 10) AS sub
ON c.id = sub.country_id
GROUP BY country_name;

/*******************************************************************/
-- Average goals per league against total average goals in all leagues
-- in season 2013/2014

SELECT
	l.name AS league,
    ROUND(AVG(m.home_goal + m.away_goal),2) AS avg_goals,
    -- Select and round the average total goals
    (SELECT ROUND(AVG(home_goal + away_goal),2)
     FROM match
     WHERE season = '2013/2014') AS overall_avg
FROM league AS l
LEFT JOIN match AS m
ON l.country_id = m.country_id
-- Filter for the 2013/2014 season
WHERE m.season = '2013/2014'
GROUP BY l.name;

/***********************************************************/
-- find the stages in which the avearge  total goals exceeds the overall Average
-- of goals in 2012/2013

SELECT
	-- Select the stage and average goals from s
	s.stage,
	ROUND(s.avg_goals,2) AS avg_goal,
    -- Select the overall average for 2012/2013
	(SELECT AVG(home_goal + away_goal) FROM match WHERE season = '2012/2013') AS overall_avg
FROM
	-- Select the stage and average goals in 2012/2013 from match
	(SELECT
         stage,
         AVG(home_goal + away_goal) AS avg_goals
     FROM match
     WHERE season = '2012/2013'
     GROUP BY stage) AS s
WHERE
	-- Filter the main query using the subquery
	s.avg_goals > (SELECT AVG(home_goal + away_goal)
                   FROM match WHERE season = '2012/2013');

/******************************************************************/
-- examine matches with scores that are extreme outliers for 
-- each country -- above 3 times the average score!

SELECT 
	-- Select country ID, date, home, and away goals from match
	main.country_id,
    main.date,
    main.home_goal,
    main.away_goal
FROM match AS main
WHERE 
	-- Filter the main query by the subquery
	(home_goal + away_goal) > 
        (SELECT AVG((sub.home_goal + sub.away_goal) * 3)
         FROM match AS sub
         -- Join the main query to the subquery in WHERE
         WHERE main.country_id = sub.country_id);

/********************************************************************/
-- xamine the highest total number of goals in each season, 
-- overall, and during July across all seasons.
SELECT 
	-- Select the season and max goals scored in a match
	season,
    MAX(home_goal + away_goal) AS max_goals,
    -- Select the overall max goals scored in a match
   (SELECT MAX(home_goal + away_goal) FROM match) AS overall_max_goals,
    -- Select the max number of goals scored in any match in July
   (SELECT MAX(home_goal + away_goal) 
        FROM match
        WHERE id IN (
              SELECT id FROM match WHERE EXTRACT(MONTH FROM date) = 07)) 
              AS july_max_goals
FROM match
GROUP BY season;

/***********************************************************************/
-- What's the average number of matches per season where a team scored 
-- 5 or more goals? How does this differ by country?
-- Count match ids
SELECT
    country_id,
    season,
    COUNT(id) AS matches
-- Set up and alias the subquery
FROM (
	SELECT
    	country_id,
    	season,
    	id
	FROM match
	WHERE home_goal >= 5 OR away_goal >= 5) 
    AS subquery
-- Group by country_id and season
GROUP BY country_id, season;

/**********************************************************************/
-- Getting the matched details

SELECT
    m.date,
   (SELECT team_long_name
    FROM team AS t
    WHERE t.team_api_id = m.hometeam_id) AS hometeam,
    -- Connect the team to the match table
   (SELECT team_long_name
    FROM team AS t
    WHERE t.team_api_id = m.awayteam_id) AS awayteam,
   -- Select home and away goals
    m.home_goal,
    m.away_goal
FROM match AS m;
