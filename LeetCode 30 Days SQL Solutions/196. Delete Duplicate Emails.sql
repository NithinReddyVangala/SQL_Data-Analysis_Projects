-- 196. Delete Duplicate Emails


-- Table: Person

-- +-------------+---------+
-- | Column Name | Type    |
-- +-------------+---------+
-- | id          | int     |
-- | email       | varchar |
-- +-------------+---------+
-- id is the primary key (column with unique values) for this table.
-- Each row of this table contains an email. The emails will not contain uppercase letters.
 

-- Write a solution to delete all duplicate emails, keeping only one unique email with the smallest id.

-- For SQL users, please note that you are supposed to write a DELETE statement and not a SELECT one.

-- For Pandas users, please note that you are supposed to modify Person in place.

-- After running your script, the answer shown is the Person table. The driver will first compile and run your piece of code and then show the Person table. The final order of the Person table does not matter.

-- The result format is in the following example.

 

-- Example 1:

-- Input: 
-- Person table:
-- +----+------------------+
-- | id | email            |
-- +----+------------------+
-- | 1  | john@example.com |
-- | 2  | bob@example.com  |
-- | 3  | john@example.com |
-- +----+------------------+
-- Output: 
-- +----+------------------+
-- | id | email            |
-- +----+------------------+
-- | 1  | john@example.com |
-- | 2  | bob@example.com  |
-- +----+------------------+
-- Explanation: john@example.com is repeated two times. We keep the row with the smallest Id = 1.

--MS SQL Solutions
--Solution 1
WITH CTE AS (
    SELECT 
        ID,
        ROW_NUMBER() OVER (PARTITION BY EMAIL ORDER BY ID) AS RowNum
    FROM 
        PERSON
)
DELETE FROM CTE WHERE RowNum > 1;

--Solution 2:
DELETE  FROM PERSON
WHERE ID NOT IN (SELECT MIN(ID) FROM PERSON GROUP BY EMAIL);

--MySQL Solution:
DELETE P1 FROM PERSON P1,PERSON P2
WHERE  P1.EMAIL = P2.EMAIL AND P1.ID > P2.ID


--PostgreSQL Solutions:

--Solution 1:
DELETE FROM PERSON
WHERE PERSON.ID NOT IN (SELECT MIN(ID) FROM PERSON GROUP BY EMAIL)

--Solution 2:
DELETE FROM PERSON P1
USING PERSON P2
WHERE P1.ID > P2.ID AND P1.EMAIL = P2.EMAIL

