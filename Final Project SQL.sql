create database Project;
use Project;

-- updating the date which was stored as text to dateformat
UPDATE stolen_vehicles
SET date_stolen = STR_TO_DATE(date_stolen, '%m/%d/%y')
WHERE date_stolen IS NOT NULL;

-- 1. Which regions has most motor theft cases?
SELECT row_number() 
OVER (ORDER BY COUNT(vehicle_id)
 DESC) AS TheftRank,
region,
 COUNT(vehicle_id) AS TheftCases
FROM stolen_vehicles sv
JOIN locations l ON 
sv.location_id = l.location_id
GROUP BY region;

-- 2. Is there any pattern in theft with respect to vehicle type?
SELECT vehicle_type,
COUNT(vehicle_id) AS TheftCases
FROM stolen_vehicles sv
JOIN make_details md ON sv.make_id = 
md.make_id
GROUP BY sv.vehicle_type
ORDER BY TheftCases DESC
limit 10 ;

-- 3. what are the yearly trends in motor theft cases in new Zealand?
WITH cte1 AS (
    SELECT YEAR(date_stolen) AS _Year,
    COUNT(vehicle_id) AS TheftCount
    FROM stolen_vehicles
    WHERE YEAR(date_stolen) BETWEEN 2021 AND 2022
    GROUP BY _Year)
SELECT cte1._Year,(TheftCount - LAG(TheftCount, 1, 0) 
OVER (ORDER BY _Year)) AS YoYChange,cte1.TheftCount
FROM cte1
ORDER BY _Year;

-- 4. Do motor theft cases depends on population density?
WITH cte2 AS (
    SELECT locations.region, locations.density,
    COUNT(stolen_vehicles .vehicle_id) AS TheftCases
    FROM stolen_vehicles 
    JOIN locations  ON 
    stolen_vehicles.location_id = locations.location_id
    GROUP BY locations.region, locations.density)
SELECT cte2.region, cte2.density,AVG(cte2.TheftCases) OVER
 (ORDER BY cte2.density ASC ROWS BETWEEN
 2 PRECEDING AND 2 FOLLOWING) 
 AS MovgAvgTheftCases
FROM cte2 
ORDER BY MovgAvgTheftCases desc;



-- 5. What are the distribution on theft cases on the basis of  vehicle name?
select make_details.make_name ,
count(stolen_vehicles .vehicle_id) as theftcases 
from stolen_vehicles 
join make_details 
on stolen_vehicles.make_id = 
make_details.make_id 
group by make_details.make_name
order by theftcases desc
limit 10;

-- 6. Show the top  stolen vehicle by location?

with cte3 AS (select count(vehicle_id) as theftcases,
region,make_id,
RANK() OVER (PARTITION BY region 
ORDER BY count(vehicle_id) DESC) as LRK
from stolen_vehicles sv join locations l 
on sv.location_id = l.location_id
group by l.region,sv.make_id)
select region,make_name,theftcases
from cte3 c3 join make_details md on 
md.make_id = c3.make_id
WHERE c3.LRK <= 1
ORDER BY region, LRK;

SELECT 
    make_details.make_name, 
    COUNT(stolen_vehicles.vehicle_id) AS total_thefts
FROM stolen_vehicles
JOIN make_details ON stolen_vehicles.make_id = make_details.make_id
GROUP BY make_details.make_name
ORDER BY total_thefts DESC
LIMIT 1;

WITH theft_counts AS (
    SELECT 
        locations.region,
        make_details.make_name,
        COUNT(stolen_vehicles.vehicle_id) AS total_thefts,
        RANK() OVER (PARTITION BY locations.region ORDER BY COUNT(stolen_vehicles.vehicle_id) DESC) AS rnk
    FROM stolen_vehicles
    JOIN locations ON stolen_vehicles.location_id = locations.location_id
    JOIN make_details ON stolen_vehicles.make_id = make_details.make_id
    GROUP BY locations.region, make_details.make_name
)
SELECT region, make_name, total_thefts
FROM theft_counts
WHERE rnk = 1
ORDER BY region;


-- 7. What percentage of stolen vehicle records contain 'Unknown' in key  attributes (vehicle type, brand, model year, description, and color)?

SELECT(SUM(CASE
	WHEN vehicle_type = 'Unknown'
	OR make_id = 'Unknown'
	OR model_year = 'Unknown'
	OR vehicle_desc = 'Unknown'
	OR color = 'Unknown' THEN 1
	ELSE 0 END)   / COUNT(vehicle_id))AS unknown_Records_Percentage,
 (SUM(CASE 
        WHEN vehicle_type <> 'Unknown'
        AND make_id <> 'Unknown'
        AND model_year <> 'Unknown'
        AND vehicle_desc <> 'Unknown'
        AND color <> 'Unknown' THEN 1
        ELSE 0 
    END)  / COUNT(vehicle_id)) AS Known_Records_Percentage
FROM stolen_vehicles;

-- 7. What is the most common stolen vehicle colour?








