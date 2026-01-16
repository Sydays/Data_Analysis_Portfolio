
-- Data cleaning and exploration in SQL
-- Skills : Update, Create , Select , Group By , Order By 

-----------------------------------------------------------------------------------------------------

-- Create a stageing to not alter raw data

Create Table market_dataset_staging
like market_dataset;

Insert market_dataset_staging 
SELECT * from market_dataset;


-----------------------------------------------------------------------------------------------------


-- Clean the ACTIVE table

UPDATE market_dataset_staging 
set active = 'False'
WHERE active ='0';

UPDATE market_dataset_staging 
set active = 'False'
Where active LIKE 'No%';

UPDATE market_dataset_staging 
set active = 'True'
Where active LIKE '1';

UPDATE market_dataset_staging 
set active = 'True'
Where active LIKE 'Y';

UPDATE market_dataset_staging 
set active = 'True'
Where active LIKE 'Yes';



-----------------------------------------------------------------------------------------------------


-- Delete uneeded tables 

Alter Table market_dataset_staging 
Drop column `Clicks_[0]`;



-----------------------------------------------------------------------------------------------------

-- Clean the channel column 

UPDATE market_dataset_staging 
set channel = 'Email'
 WHERE channel LIKE 'E-mail';
 
 UPDATE market_dataset_staging 
set channel = 'Google Ads'
 WHERE channel LIKE 'Gogle';
 
 UPDATE market_dataset_staging 
set channel = 'Instagram'
 WHERE channel LIKE 'Insta_gram';
 
 UPDATE market_dataset_staging 
set channel = 'TikTok'
 WHERE channel LIKE 'Tik_Tok';
 
 UPDATE market_dataset_staging 
set channel = 'Facebook'
 WHERE channel LIKE 'Facebok';
 
 -----------------------------------------------------------------------------------------------------
 
 
--  Clean Start_Date columns

Update market_dataset_staging 
SET Start_Date = TRIM(TRAILING '00:00:00' FROM Start_Date);

Update market_dataset_staging 
SET Start_Date = TRIM(TRAILING ' ' FROM Start_Date);

UPDATE market_dataset_staging
SET Start_Date = DATE_FORMAT(
    STR_TO_DATE(Start_Date, '%d/%m/%Y'),
    '%Y-%m-%d'
)
WHERE Start_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
  AND CAST(SUBSTRING_INDEX(Start_Date,'/',1) AS UNSIGNED) > 12;

UPDATE market_dataset_staging
SET Start_Date = DATE_FORMAT(
    STR_TO_DATE(Start_Date, '%m/%d/%Y'),
    '%Y-%m-%d'
)
WHERE Start_Date REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
  AND CAST(SUBSTRING_INDEX(Start_Date,'/',1) AS UNSIGNED) <= 12;
  

Alter Table market_dataset_staging 
Modify column `Start_Date` DATE NOT NULL;



-----------------------------------------------------------------------------------------------------



-- Clean the End_Date Columns

Alter Table market_dataset_staging 
Modify column `End_Date` DATE NOT NULL;
 
 
 
 
 
-----------------------------------------------------------------------------------------------------
 
 
 
 
-- Check then delete duplicates 

SELECT Campaign_ID ,Campaign_Name,Start_Date,End_Date, COUNT(*) AS Duplicates FROM market_dataset_clean
GROUP BY Campaign_ID,Campaign_Name,Start_Date,End_Date,Channel,Impressions,Clicks,Spend,Conversions,Active,Campaign_Tag
Having COUNT(*) > 1;

Create Table market_dataset_clean AS SELECT * 
FROM market_dataset_staging 
GROUP BY Campaign_ID,Campaign_Name,Start_Date,End_Date,
Channel,Impressions,Clicks,Spend,Conversions,Active,Campaign_Tag;
 
 
 
 
 
-----------------------------------------------------------------------------------------------------
 
-- Which campaign generated the highest number of conversions?

SELECT Campaign_Name , Conversions FROM market_dataset_clean
ORDER BY Conversions desc;


-----------------------------------------------------------------------------------------------------



-- Top 3 peforming based on impressions and the number of conversions  

SELECT Campaign_ID, Campaign_Name, Impressions,Conversions FROM market_dataset_clean 
WHERE Active = "True"
ORDER BY Impressions DESC
limit 3; 


-----------------------------------------------------------------------------------------------------



-- What campaign had the best average on impressions and conversions 

SELECT Campaign_ID,Campaign_Name,(Impressions + Conversions) / 2 AS Average FROM market_dataset_clean
ORDER BY Average DESC;




-----------------------------------------------------------------------------------------------------

-- Total Spent on the campaigns 

SELECT sum(Spend) AS Total_Spent FROM market_dataset_clean;


-----------------------------------------------------------------------------------------------------



-- Total number of conversion 

SELECT sum(Conversions) AS Total_Conversion FROM market_dataset_clean;



-----------------------------------------------------------------------------------------------------

-- Total number of impressions 

Select sum(Impressions) AS Impression_Total FROM  market_dataset_clean;


-----------------------------------------------------------------------------------------------------



-- How much was spent vs how many impressions were made on the top 10 Campaign on conversions

SELECT Campaign_ID,Campaign_Name,Spend,Impressions,Conversions FROM market_dataset_clean
ORDER BY Conversions DESC
LIMIT 10;



-----------------------------------------------------------------------------------------------------



-- Best channel on impressions 

SELECT Channel,SUM(Impressions) AS Total_Impressions,SUM(Clicks) AS Total_Clicks FROM market_dataset_clean
GROUP BY  Channel
ORDER BY Total_Impressions DESC;



-----------------------------------------------------------------------------------------------------




-- Time line of campaigns based on impression with added insight conversions 

SELECT Campaign_ID,Impressions,Conversions,Start_Date,End_Date FROM market_dataset_clean ;




-----------------------------------------------------------------------------------------------------




-- What old campaigns do we need to do some improvments on based on Impressions? 

SELECT Campaign_Name , Conversions AS Conversion_Count FROM market_dataset_clean 
WHERE Active = "false"
ORDER BY Conversions ASC;