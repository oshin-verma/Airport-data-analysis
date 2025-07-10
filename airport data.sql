Create database	airport_db;
Use airport_db;
select * from airports;
# Problem Statement 1 : The objective is to calculate the total number of passengers for each pair of origin and destination airports.
SELECT 
    Origin_airport,
    Destination_airport,
    SUM(Passengers) AS Total_Passengers
FROM
    airports
GROUP BY Origin_airport , Destination_airport
ORDER BY Origin_airport , Destination_airport;

#Problem Statement 2 : Here the goal is to calculate the average seat utilization for each flight by dividing the  number of passengers by the total number of seats available. 
SELECT 
    Origin_airport, 
    Destination_airport, 
    AVG(CAST(Passengers AS FLOAT) / NULLIF(Seats, 0)) * 100 AS Average_Seat_Utilization
FROM 
    airports
GROUP BY 
    Origin_airport, 
    Destination_airport
ORDER BY 
    Average_Seat_Utilization DESC;
    
#Problem Statement 3 :The aim is to determine the top 5 origin and destination airport pairs that have the highest total passenger volume. 
SELECT 
    Origin_airport, 
    Destination_airport, 
    SUM(Passengers) AS Total_Passengers
FROM 
    airports
GROUP BY 
    Origin_airport, 
    Destination_airport
ORDER BY 
    Total_Passengers DESC
LIMIT 5;

#Problem Statement 4 :The objective is to calculate the total number of flights and passengers departing from each origin city. 
SELECT 
    Origin_city, 
    COUNT(Flights) AS Total_Flights, 
    SUM(Passengers) AS Total_Passengers
FROM 
    airports
GROUP BY 
    Origin_city
ORDER BY 
    Origin_city;
    
#Problem Statement 5 : The aim is to calculate the total distance flown by flights originating from each airport.
 SELECT 
    Origin_airport, 
    SUM(Distance) AS Total_Distance
FROM 
    airports
GROUP BY 
    Origin_airport
ORDER BY 
    Origin_airport;
    
#Problem Statement 6 : The objective is to group flights by month and year using the Fly_date column to calculate the number of flights,
-- total passengers, and average distance traveled per month. 

SELECT 
    YEAR(Fly_date) AS Year, 
    MONTH(Fly_date) AS Month, 
    COUNT(Flights) AS Total_Flights, 
    SUM(Passengers) AS Total_Passengers, 
    AVG(Distance) AS Avg_Distance
FROM 
    airports
GROUP BY 
    YEAR(Fly_date), 
    MONTH(Fly_date)
ORDER BY 
    Year, 
    Month;
    
# Problem Statement 7 :  The goal is to calculate the passenger-to-seats ratio for each origin and destination route and filter the results to display only those routes where this ratio is less than 0.5. 

SELECT 
    Origin_airport, 
    Destination_airport, 
    SUM(Passengers) AS Total_Passengers, 
    SUM(Seats) AS Total_Seats, 
    (SUM(Passengers) * 1.0 / NULLIF(SUM(Seats), 0)) AS Passenger_to_Seats_Ratio
FROM 
    airports
GROUP BY 
    Origin_airport, 
    Destination_airport
HAVING 
    (SUM(Passengers) * 1.0 / NULLIF(SUM(Seats), 0)) < 0.5
ORDER BY 
    Passenger_to_Seats_Ratio;
    
# Problem Statement 8 : The aim is to determine the top 3 origin airports with the highest frequency of flights. 
SELECT 
    Origin_airport, 
    COUNT(Flights) AS Total_Flights
FROM 
    airports
GROUP BY 
    Origin_airport
ORDER BY 
    Total_Flights DESC
LIMIT 3;

#Problem Statement 9 :The objective is to identify the cities (excluding Bend, OR) that sends the most flights and passengers to Bend, OR. 
SELECT 
    Origin_city, 
    COUNT(Flights) AS Total_Flights, 
    SUM(Passengers) AS Total_Passengers
FROM 
    airports
WHERE 
    Destination_city = 'Bend, OR' AND 
    Origin_city <> 'Bend, OR'
GROUP BY 
    Origin_city
ORDER BY 
    Total_Flights DESC, 
    Total_Passengers DESC
LIMIT 3;

#Problem Statement 10 : The aim is to identify the longest flight route in terms of distance traveled, including both the origin and destination airports. 
SELECT 
    Origin_airport, 
    Destination_airport, 
    MAX(Distance) AS Longest_Distance
FROM 
    airports
GROUP BY 
    Origin_airport, 
    Destination_airport
ORDER BY 
    Longest_Distance DESC
LIMIT 1;

use airport_db;

#Problem Statement 11:The aim is to determine the top 3 origin airports with the highest weighted passenger-to-seats utilization ratio, 
 -- sidering the total number of flights for weighting.
 
WITH Utilization_Ratio AS (
    -- Step 1: Calculate the passenger-to-seats ratio for each flight
    SELECT 
        Origin_airport, 
        SUM(Passengers) AS Total_Passengers, 
        SUM(Seats) AS Total_Seats, 
        COUNT(Flights) AS Total_Flights,
        SUM(Passengers) * 1.0 / SUM(Seats) AS Passenger_Seat_Ratio
    FROM 
        airports
    GROUP BY 
        Origin_airport
),

Weighted_Utilization AS (
    -- Step 2: Calculate the weighted utilization by flights for each origin airport
    SELECT 
        Origin_airport, 
        Total_Passengers, 
        Total_Seats, 
        Total_Flights,
        Passenger_Seat_Ratio, 
        -- Weight the passenger-to-seat ratio by the total number of flights
        (Passenger_Seat_Ratio * Total_Flights) / SUM(Total_Flights) OVER () AS Weighted_Utilization
    FROM 
        Utilization_Ratio
)

-- Step 3: Select the top 3 airports by weighted utilization
SELECT 
    Origin_airport, 
    Total_Passengers, 
    Total_Seats, 
    Total_Flights, 
    Weighted_Utilization
FROM 
    Weighted_Utilization
ORDER BY 
    Weighted_Utilization DESC
LIMIT 3;

#Problem Statement 12 : The aim is to calculate the year-over-year percentage growth in the total number of passengers for each origin and destination airport pair.
WITH Passenger_Summary AS (
    SELECT 
        Origin_airport, 
        Destination_airport, 
        right(Fly_date,4) AS Year, 
        SUM(Passengers) AS Total_Passengers
    FROM 
        airports
    GROUP BY 
        Origin_airport, 
        Destination_airport, 
        YEAR
),

Passenger_Growth AS (
    SELECT 
        Origin_airport, 
        Destination_airport, 
        Year, 
        Total_Passengers,
        LAG(Total_Passengers) OVER (PARTITION BY Origin_airport, Destination_airport ORDER BY Year) AS Previous_Year_Passengers
    FROM 
        Passenger_Summary
)

SELECT 
    Origin_airport, 
    Destination_airport, 
    Year, 
    Total_Passengers, 
    CASE 
        WHEN Previous_Year_Passengers IS NOT NULL THEN 
            ((Total_Passengers - Previous_Year_Passengers) * 100.0 / NULLIF(Previous_Year_Passengers, 0))
        ELSE NULL 
    END AS Growth_Percentage
FROM 
    Passenger_Growth
ORDER BY 
    Origin_airport, 
    Destination_airport, 
    Year;
    
 # Problem Statement 13 : The objective is to identify the peak traffic month for each origin city based on the highest number of passengers, 
-- including any ties where multiple months have the same passenger count. 

WITH Monthly_Passenger_Count AS (
    SELECT 
        Origin_city,
        YEAR(Fly_date) AS Year,
        MONTH(Fly_date) AS Month,
        SUM(Passengers) AS Total_Passengers  -- Handling NULLs and non-integer values
    FROM 
        airports
    GROUP BY 
        Origin_city, 
        YEAR(Fly_date), 
        MONTH(Fly_date)
),

Max_Passengers_Per_City AS (
    SELECT 
        Origin_city, 
        MAX(Total_Passengers) AS Peak_Passengers
    FROM 
        Monthly_Passenger_Count
    GROUP BY 
        Origin_city
)

SELECT 
    mpc.Origin_city, 
    mpc.Year, 
    mpc.Month, 
    mpc.Total_Passengers
FROM 
    Monthly_Passenger_Count mpc
JOIN 
    Max_Passengers_Per_City mp ON mpc.Origin_city = mp.Origin_city 
                               AND mpc.Total_Passengers = mp.Peak_Passengers
ORDER BY 
    mpc.Origin_city, 
    mpc.Year, 
    mpc.Month;
    
  #Problem Statement 14 : The aim is to calculate the average flight distance for each unique city-to-city pair (origin and destination) 
-- and identify the routes with the longest average distance. 

WITH Distance_Stats AS (
    SELECT 
        Origin_city,
        Destination_city,
        AVG(Distance) AS Avg_Flight_Distance
    FROM 
        airports
    GROUP BY 
        Origin_city, 
        Destination_city
)

SELECT 
    Origin_city,
    Destination_city,
    ROUND(Avg_Flight_Distance, 2) AS Avg_Flight_Distance
FROM 
    Distance_Stats
ORDER BY 
    Avg_Flight_Distance DESC; 
    
#Problem Statement 15 : The aim is to identify the top 3 busiest routes (origin-destination pairs) based on the total distance flown,
--  weighted by the number of flights. 

WITH Route_Distance AS (
    SELECT 
        Origin_airport,
        Destination_airport,
        SUM(Distance) AS Total_Distance,
        SUM(Flights) AS Total_Flights
    FROM 
        airports
    GROUP BY 
        Origin_airport, 
        Destination_airport
),

Weighted_Routes AS (
    SELECT 
        Origin_airport,
        Destination_airport,
        Total_Distance,
        Total_Flights,
        Total_Distance * Total_Flights AS Weighted_Distance
    FROM 
        Route_Distance
)

SELECT 
    Origin_airport,
    Destination_airport,
    Total_Distance,
    Total_Flights,
    Weighted_Distance
FROM 
    Weighted_Routes
ORDER BY 
    Weighted_Distance DESC
LIMIT 3; 