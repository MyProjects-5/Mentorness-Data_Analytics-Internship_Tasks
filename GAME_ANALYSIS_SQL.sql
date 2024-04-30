create database game_analysis;

use game_analysis;

alter table player_details modify L1_Status varchar(30);
alter table player_details modify L2_Status varchar(30);
alter table player_details modify P_ID int primary key;
alter table player_details drop myunknowncolumn;

select * from player_details;
desc player_details;

alter table level_details drop myunknowncolumn;
alter table level_details change timestamp start_datetime datetime;
alter table level_details modify Dev_Id varchar(10);
alter table level_details modify Difficulty varchar(15);
alter table level_details add primary key(P_ID,Dev_id,start_datetime);

select * from level_details;
desc level_details;


-- Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
-- at level 0
-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
-- 3 stages are crossed
-- Q3) Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.
-- Q4) Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.
-- Q5) Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.
-- Q6)  Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.
-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well. 
-- Q8) Find first_login datetime for each device id
-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.
-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.
-- Q11) For each player and date, how many kill_count played so far by the player.  
-- That is, the total number of games played by the player until that date.
-- a) window function
-- b) without window function
-- Q12) Find the cumulative sum of stages crossed over a start_datetime 
-- Q13) Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetime
-- Q14) Extract top 3 highest sum of score for each device id and the corresponding player_id
-- Q15) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id
-- Q16) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.
-- Q17) Create a function to return sum of Score for a given player_id.

-- Q1
select level_details.P_ID,Dev_ID,PName,difficulty 
from level_details left join  player_details 
on level_details.P_ID=player_details.P_ID
where Level=0;

-- Q2
select L1_code,avg(kill_count) as Average_Kill_Count 
from player_details left join level_details 
on level_details.P_ID=player_details.P_ID 
where lives_earned=2 and stages_crossed>=3 
group by L1_code 
order by Average_Kill_Count;

-- Q3
select P_ID,difficulty,stages_crossed as total_number_of_stages 
from level_details 
where level=2 and Dev_ID like 'zm_%'  
order by stages_crossed desc;

-- Q4
select P_ID,count(distinct(date(start_datetime))) as Total_Number_Of_Unique_Dates 
from level_details 
group by P_ID 
having count(distinct(date(start_datetime)))>1;

-- Q5
select 	P_ID,level,sum(Kill_Count) AS Level_Wise_Count 
from level_details 
where Difficulty="Medium" 
group by P_ID,
level having avg(Kill_Count)>
(select avg(Kill_Count) from level_details where Difficulty="Medium");

-- Q6
select Level,L1_code,L2_Code,sum(lives_earned) as Total_Lives_Earned 
from level_details left join player_details on level_details.P_ID=player_details.P_ID  
group by level,L1_Code,L2_Code 
having level !=0 order by level;

-- Q7
select Dev_ID,score,difficulty,Rank1 from(
select Dev_ID,score,difficulty,row_number() over (partition by Dev_ID order by score asc) as Rank1 from  level_details) 
as ranked where Rank1<=3;

-- Q8
select Dev_ID,min(start_datetime)as first_login_datetime 
from level_details 
group by Dev_Id;

-- Q9
select difficulty,score,Dev_ID,Rank1 from(
select difficulty,score,Dev_ID,rank() over (partition by Difficulty order by score asc) as Rank1 from  level_details ) 
as ranked where Rank1<=5;

-- Q10
select P_ID,Dev_Id,min(start_datetime)as first_login_datetime 
from level_details 
group by P_ID,Dev_Id;

-- Q11 -- Using Window Function
SELECT 
    P_ID,
    start_datetime,
    SUM(kill_count) OVER (PARTITION BY P_ID ORDER BY start_datetime) AS total_kills_played
FROM 
level_details;

-- Q11 -- Without Using Window Function
SELECT 
    t1.P_ID,
    t1.start_datetime,
    (SELECT SUM(t2.kill_count) 
     FROM level_details t2 
     WHERE t2.P_ID = t1.P_ID AND t2.start_datetime <= t1.start_datetime) AS total_kills_played
FROM 
    level_details t1
ORDER BY 
    t1.P_ID,t1.start_datetime;
    
-- Q12
select start_datetime,stages_crossed,sum(stages_crossed)  over (order  by start_datetime)as cumulative_sum from level_details;

-- Q13
select P_ID,start_datetime,stages_crossed,
sum(Stages_crossed)  over (partition by P_ID order  by start_datetime asc rows between unbounded preceding and 1 preceding )as cumulative_sum 
from level_details order by P_ID,start_datetime;

-- Q14
select Dev_ID,P_ID,Top_3_Score from(
select Dev_ID,P_ID,sum(score) As Top_3_Score,row_number() over(partition by Dev_Id order by sum(score)desc)as rank1 
from level_details
group by Dev_Id,P_ID)as subquery 
where rank1<=3;

-- Q15
SELECT 
    P_ID,
    SUM(score) AS Total_score
FROM 
    level_details
GROUP BY 
    P_ID
HAVING 
    SUM(score) > (
        SELECT 
            0.5 * AVG(Total_score)
        FROM (
            SELECT 
                P_ID,
                SUM(score) AS Total_score
            FROM 
                level_details
            GROUP BY 
                P_ID
		)
    );

-- Q16
DELIMITER //

CREATE PROCEDURE FindTopNHeadshotCount(in n INT)
BEGIN
 SELECT Dev_ID, headshots_count, difficulty,rank1 from(
    SELECT Dev_ID, headshots_count, difficulty, 
           ROW_NUMBER() OVER(PARTITION BY Dev_ID ORDER BY headshots_count ) AS rank1
    FROM level_details) as ranked_data
    where rank1<=n
    ORDER BY Dev_ID, headshots_count ;
END //
DELIMITER ;

call game_analysis.FindTopNHeadshotCount(6);

-- Q17
DELIMITER //

CREATE FUNCTION GetTotalScore(player_id INT) RETURNS INT
BEGIN
    DECLARE total_score INT;
    
    SELECT sum(score) INTO total_score
    FROM level_details
    WHERE P_ID = player_id;
    RETURN total_score ;
END //

DELIMITER ;

set Global log_bin_trust_function_creators=1;
select game_analysis.GetTotalScore(211);