# create database
CREATE DATABASE PKDD_99_financial;
USE PKDD_99_financial;

# load data from "bank_data" folder into database with table data import wizard

#Queries
# 1. The distribution of male and female clients.
SELECT gender, 
COUNT(gender) AS number_of_clients, 
100 * COUNT(gender) /SUM(COUNT(*)) OVER () AS client_percentage
FROM client 
GROUP BY gender;

# 2. The distribution of clients by age.
CREATE TABLE age_group AS
SELECT 
CASE 
WHEN age_1999 <= 20 THEN 'age <=20'
WHEN age_1999 >20 and age_1999 <= 25 THEN '20 < age <= 25'
WHEN age_1999 >25 and age_1999 <= 30 THEN '25 < age <= 30'
WHEN age_1999 >30 and age_1999 <= 35 THEN '30 < age <= 35'
WHEN age_1999 >35 and age_1999 <= 40 THEN '35 < age <= 40'
WHEN age_1999 >40 and age_1999 <= 45 THEN '40 < age <= 45'
WHEN age_1999 >45 and age_1999 <= 50 THEN '45 < age <= 50'
WHEN age_1999 >50 and age_1999 <= 55 THEN '50 < age <= 55'
WHEN age_1999 >55 and age_1999 <= 60 THEN '55 < age <= 60'
 ELSE 'age > 60'
END AS age_range, 
COUNT(*) AS number_of_clients
FROM (SELECT timestampdiff(Year, birth_date,'1999-01-01') AS age_1999
FROM client) AS age
GROUP BY age_range
ORDER BY age_range;
SELECT * FROM age_group;

# 3. The distribution of clients by district in descending order.
SELECT district.district_id, district_name, region_name,
COUNT(account_id) AS number_of_accounts
FROM district
INNER JOIN account 
ON district.district_id = account.district_id
GROUP BY account.district_id
ORDER BY number_of_accounts DESC;

# 4. Profiling loan borrowers by age and gender. 
## a. Both the sum and average male and female borrowings in each age range and order by mean_loan_amount from the highest to lowest.
CREATE TABLE age_mapping AS
SELECT client_id, timestampdiff(Year, birth_date, '1999-01-01') AS age_1999, 
CASE
	WHEN timestampdiff(Year, birth_date, '1999-01-01') <= 20 THEN 'age <=20'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >20 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 25 THEN '20 < age <= 25'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 30 THEN '25 < age <= 30'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 35 THEN '30 < age <= 35'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >35 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 40 THEN '35 < age <= 40'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >40 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 45 THEN '40 < age <= 45'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >45 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 50 THEN '45 < age <= 50'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >50 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 55 THEN '50 < age <= 55'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >55 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 60 THEN '55 < age <= 60'
 ELSE 'age > 60'
END AS age_range
FROM client;

SELECT * FROM age_mapping;
SELECT age_mapping.age_range, gender, SUM(amount) AS total_loan_amount, 
AVG(amount) AS mean_loan_amount
FROM loan 
JOIN disposition ON loan.account_id = disposition.account_id
JOIN client ON disposition.client_id = client.client_id
JOIN age_mapping ON age_mapping.client_id = client.client_id
GROUP BY gender, age_mapping.age_range
ORDER BY mean_loan_amount DESC;

# b. Gender differences: what are the statistics on borrowings for males and females?
SELECT gender, AVG(timestampdiff(Year, birth_date,'1999-01-01')) AS mean_age, 
COUNT(*) AS number_of_loans, SUM(amount) AS total_loan_amount, AVG(amount) AS 
mean_loan_amount
FROM loan
JOIN disposition ON loan.account_id = disposition.account_id
JOIN client ON disposition.client_id = client.client_id
GROUP BY gender;

# c. Which are the groups of people who borrow the most?
SELECT age_mapping.age_range, gender, SUM(amount) AS total_loan_amount, 
AVG(amount) AS mean_loan_amount, COUNT(*) AS number_of_loans
FROM loan 
JOIN disposition ON loan.account_id = disposition.account_id
JOIN client ON disposition.client_id = client.client_id
JOIN age_mapping ON age_mapping.client_id = client.client_id
GROUP BY age_mapping.age_range, gender
ORDER BY mean_loan_amount DESC
LIMIT 3;

# d. By mean loan amount of the group
SELECT age_mapping.age_range, gender, SUM(amount) AS total_loan_amount, 
AVG(amount) AS mean_loan_amount, COUNT(*) AS number_of_loans
FROM loan 
JOIN disposition ON loan.account_id = disposition.account_id
JOIN client ON disposition.client_id = client.client_id
JOIN age_mapping ON age_mapping.client_id = client.client_id
GROUP BY age_mapping.age_range, gender
ORDER BY total_loan_amount DESC
LIMIT 3;

# e. Which are the groups that have the most status ‘A’ loans
SELECT age_mapping.age_range, gender, loan.status, SUM(amount) AS 
total_loan_amount, AVG(amount) AS mean_loan_amount, COUNT(*) AS 
number_of_loans
FROM loan 
JOIN disposition ON loan.account_id = disposition.account_id
JOIN client ON disposition.client_id = client.client_id
JOIN age_mapping ON age_mapping.client_id = client.client_id
GROUP BY gender, age_mapping.age_range
HAVING loan.status = 'A'
ORDER BY total_loan_amount DESC;


# 5. The amount of loans for different districts
# a. The amount of loans for the 5 districts with the highest total amount of loan
SELECT district.district_id, district_name, region_name, SUM(amount) AS 
total_loan_amount, AVG(amount) AS mean_loan_amount, COUNT(*) AS 
number_of_loans
FROM loan
JOIN account ON loan.account_id = account.account_id
JOIN district ON account.district_id = district.district_id
GROUP BY district_id
ORDER BY total_loan_amount DESC
LIMIT 5;

# b. The amount of loans for the 5 districts with the lowest total amount of loan
SELECT district.district_id, district_name, region_name, SUM(amount) AS 
total_loan_amount, AVG(amount) AS mean_loan_amount, COUNT(*) AS 
number_of_loans
FROM loan
JOIN account ON loan.account_id = account.account_id
JOIN district ON account.district_id = district.district_id
GROUP BY district_id
ORDER BY total_loan_amount
LIMIT 5;


#6. Is the difference between districts big? If so, what are the factors that contribute to it?
# a. Do people from places with higher or lower salaries tend to borrow more? 
SELECT CASE
	WHEN average_salary >8000 and average_salary <9000 THEN '8000 < salary 
	<9000'
	WHEN average_salary >=9000 and average_salary <10000 THEN '9000 <= salary 
	<9000'
	WHEN average_salary >=10000 and average_salary <11000 THEN '10000 <= 
	salary <11000'
	WHEN average_salary >=11000 and average_salary <12000 THEN '11000 <= 
	salary <12000'
	WHEN average_salary >=12000 THEN 'salary >= 12000'
END AS district_salary_range, 
AVG(average_salary) AS mean_salary,
AVG(amount) AS mean_loan_amount
FROM district
JOIN account ON account.district_id = district.district_id
JOIN loan ON loan.account_id = account.account_id
GROUP BY district_salary_range;

# 7. What is the client_id, account_id and credit transactions for clients who own the goldtype card?
SELECT DISTINCT 
disposition.disp_id,disposition.client_id,disposition.account_id,card.type AS 
card_type, SUM(transactions.amount) AS transaction_amount
FROM disposition 
INNER JOIN card ON disposition.disp_id=card.disp_id
INNER JOIN transactions ON disposition.account_id=transactions.account_id
WHERE card.type="gold" AND transactions.type="credit"
GROUP BY transactions.account_id;

# 8. Detect potential gold-card holders.
SELECT AVG(transactions.amount) AS AVG,card.type,transactions.account_id
FROM transactions
INNER JOIN disposition ON disposition.account_id=transactions.account_id
INNER JOIN card ON disposition.disp_id=card.disp_id
WHERE transactions.type="credit" AND card.type="gold";
SELECT transactions.account_id,card.type,SUM(transactions.amount) AS 
transaction_amount
FROM transactions
JOIN disposition ON disposition.account_id=transactions.account_id
JOIN card ON disposition.disp_id=card.disp_id
WHERE transactions.type="credit" 
GROUP BY transactions.account_id
HAVING transaction_amount > 32958.7157;

# 9. Client profiling for clients who use credit cards.
# a. Age
CREATE TABLE age_mapping AS
SELECT client_id, timestampdiff(Year, birth_date, '1999-01-01') AS age_1999, 
CASE
	WHEN timestampdiff(Year, birth_date, '1999-01-01') <= 20 THEN 'age <=20'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >20 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 25 THEN '20 < age <= 25'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 30 THEN '25 < age <= 30'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 35 THEN '30 < age <= 35'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >35 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 40 THEN '35 < age <= 40'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >40 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 45 THEN '40 < age <= 45'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >45 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 50 THEN '45 < age <= 50'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >50 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 55 THEN '50 < age <= 55'
	WHEN timestampdiff(Year, birth_date, '1999-01-01') >55 and 
	timestampdiff(Year, birth_date, '1999-01-01') <= 60 THEN '55 < age <= 60'
 ELSE 'age > 60'
END AS age_range
FROM client;

SELECT * FROM age_mapping;

SELECT age_mapping.age_range AS age_range, 
card.type AS card_type,
SUM(transactions.amount) AS transaction_amount
FROM disposition 
JOIN client ON disposition.client_id = client.client_id
JOIN age_mapping ON age_mapping.client_id = client.client_id
INNER JOIN card ON disposition.disp_id=card.disp_id
INNER JOIN transactions ON 
disposition.account_id=transactions.account_id
GROUP BY card.type, age_mapping.age_range;

# b. Gender
SELECT gender, 
card.type AS card_type,
SUM(transactions.amount) AS transaction_amount
FROM disposition 
JOIN client ON disposition.client_id = client.client_id
INNER JOIN card ON disposition.disp_id=card.disp_id
INNER JOIN transactions ON 
disposition.account_id=transactions.account_id
GROUP BY card.type, gender;

# c. District
SELECT district.district_id,
card.type AS card_type,
SUM(transactions.amount) AS transaction_amount
FROM district
JOIN account ON account.district_id = district.district_id
JOIN transactions ON transactions.account_id=account.account_id
 JOIN disposition ON disposition.account_id=transactions.account_id
JOIN card ON disposition.disp_id=card.disp_id
GROUP BY district_id,card.type;


# 10. Detect inactive accounts by querying account_id where last transfer is more than 1 year ago.
CREATE INDEX trans_date ON transactions(date);
SELECT client.client_id, disposition.account_id, MAX(transactions.date) AS 
last_transaction_date
FROM transactions
JOIN disposition ON disposition.account_id = transactions.account_id
JOIN client ON client.client_id = disposition.client_id
GROUP BY disposition.account_id
HAVING datediff('1999-01-01', last_transaction_date) > 365;
