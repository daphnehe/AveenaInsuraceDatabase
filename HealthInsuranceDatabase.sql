CREATE TABLE provider (
	provider_id VARCHAR(2) PRIMARY KEY,
	name VARCHAR(100),
	phone VARCHAR(15),
	email VARCHAR(200)
);
CREATE TABLE InsurancePlan (
	plan_id VARCHAR(3) PRIMARY KEY,
	name VARCHAR(50),
	coverage_percentage INT CHECK (coverage_percentage >= 0),
	remaining_percentage INT CHECK (remaining_percentage >= 0)
);
CREATE TABLE policyholder (
	policyholder_id VARCHAR(8) PRIMARY KEY,
	income  VARCHAR(15)  CHECK (income IN (‘<20,000’, ‘20,000-50,000’, ‘50,000-100,000’, ‘>100,000’)),
	first_name VARCHAR(100),
	last_name VARCHAR(100),
	phone VARCHAR(15),
	email VARCHAR(200),
	address VARCHAR(200)
);

CREATE TABLE patient (
	patient_id VARCHAR(8) PRIMARY KEY,
	first_name VARCHAR(100),
	last_name VARCHAR(100),
	bmi FLOAT CHECK (bmi >= 0),
	race VARCHAR(50) CHECK( race IN(‘White’, ‘Asian’, ‘Black’, ‘Hispanic’, ‘Native American’, ‘Pacific Islander’)),
	age_range VARCHAR(15) CHECK (age_range IN (‘Under 18’, ‘18-24’, ‘25-34’, ‘35-44’, ‘45-54’, ‘55-64’, ‘Over 65’)),
	ssn INT,
	sex VARCHAR(50),
	policyholder_id VARCHAR(8) REFERENCES policyholder(policyholder_id),
	state  VARCHAR(50),
	city VARCHAR(100)
);
CREATE TABLE claim (
	claim_id SERIAL PRIMARY KEY,
	patient_id VARCHAR(8) REFERENCES patient(patient_id),
	policyholder_id VARCHAR(8) REFERENCES policyholder(policyholder_id),
	provider_id VARCHAR(2)  REFERENCES provider(provider_id),
	date_of_service DATE,
	total_amount FLOAT CHECK (total_amount >= 0),
	status VARCHAR(50) CHECK (status IN(‘Complete’, ‘Incomplete’))
);
CREATE TABLE payment (
	payment_number INT,
	claim_id INT REFERENCES claim(claim_id),
	date_of_payment DATE,
	amount FLOAT CHECK (amount >= 0),
	PRIMARY KEY(payment_number, claim_id)
);
CREATE TABLE InsuranceContracts (
	policyholder_id VARCHAR(8) REFERENCES policyholder(policyholder_id),
	plan_id VARCHAR(3) REFERENCES InsurancePlan(plan_id),
	PRIMARY KEY(policyholder_id, plan_id)
);

--Data imported in PSQL
-- Export google sheets as csv file:
-- https://docs.google.com/spreadsheets/d/1zCeMx6B-SNHc_yogMso0vZrqnQU0248NLNkNEV6xVwU/edit?usp=sharing

--QUERIES
-- How many payments have been made to a claim? (Provider, Policyholder, Insurance)
SELECT claim_id, count(*) as number_of_payments
FROM payment
GROUP BY claim_id
ORDER BY count(*) desc;

-- What is the status of the claim for a patient? (Provider, Policyholder, Insurance)
SELECT patient_id, claim_id, status
FROM claim
GROUP BY claim_id, patient_id;

-- How many claims are associated with a policyholder? (Policyholder, Provider)
SELECT policyholder_id, count(claim_id) as number_of_claims
FROM claim
GROUP BY policyholder_id
ORDER BY count(claim_id) desc;

-- Who are the patients associated with a policyholder? (Policyholder, Insurance, Provider)
SELECT policyholder_id, count(patient_id)
FROM patient
GROUP BY policyholder_id
ORDER BY count(patient_id) desc;

-- What type of insurance plan does a policyholder have? (Policyholder)
SELECT policyholder_id, array_agg(plan_id)
FROM insurancecontracts
GROUP BY policyholder_id;

-- Do males account for more claims than females? (Insurance)
SELECT sex, count(claim_id)
FROM patient, claim
WHERE patient.patient_id = claim.patient_id
GROUP BY sex;

-- What is the number of patients that are associated with a policyholder? (Policyholder, Insurance, Provider)
SELECT policyholder_id, COUNT(patient_id)
FROM patient
GROUP BY policyholder_id
ORDER BY COUNT(patient_id) DESC;

-- What type of insurance plan does a policyholder have? (Policyholder)
SELECT policyholder_id, ARRAY_AGG(plan_id)
FROM insurancecontracts
GROUP BY policyholder_id;

-- Do males account for more claims than females? (Insurance)
SELECT sex, COUNT(claim_id)
FROM patient, claim
WHERE patient.patient_id = claim.patient_id
GROUP BY sex;

-- How many payments have been made to a claim? (Provider, Policyholder, Insurance)
SELECT claim_id, COUNT(*) AS number_of_payments
FROM payment
GROUP BY claim_id
ORDER BY COUNT(*) DESC;

-- What is the status of the claim for a patient? (Provider, Policyholder, Insurance)
SELECT patient_id, claim_id, status
FROM claim
GROUP BY claim_id, patient_id;

-- How many insurance plans does a policyholder have? (Policyholder, Insurance)
SELECT policyholder, COUNT(*)
FROM InsuranceContracts
GROUP BY policyholder
ORDER BY COUNT(*) DESC;

-- What is the total amount in claims associated with a policyholder? (Insurance, Policyholder)
SELECT policyholder_id, COUNT(*)
FROM claim
GROUP BY policyholder_id
ORDER BY COUNT(*) DESC;

-- Do people living in certain regions account for more claims? (Insurance)
SELECT state, COUNT(*)
FROM claim c, patient p
WHERE c.patient_id = p.patient_id
GROUP BY state
ORDER BY COUNT(*) DESC;

-- Who are the top 10 policyholders with the highest claim amount? (Insurance)
SELECT policyholder_id, SUM(total_amount)
FROM claim
GROUP BY policyholder_id
ORDER BY SUM(total_amount) DESC
LIMIT 10;

-- Who are the top 10 policyholders with the lowest claim amount? (Insurance)
SELECT policyholder_id, SUM(total_amount)
FROM claim
GROUP BY policyholder_id
ORDER BY SUM(total_amount) ASC
LIMIT 10;

-- Which insurance plan is bought by the most policyholders? (Insurance, policyholders)
Select a.plan_id, a.name, count(b.policyholder_id) AS num_of_policyholders
From insuranceplan a, insurancecontracts b
Where a.plan_id = b.plan_id
Group by a.plan_id, a.name
Order by num_of_policyholders DESC;

-- What is the total amount that each provider has submitted each year? (Provider, Insurance)
Select a.provider_id, a.name, date_part('year', b.date_of_service) AS year, sum(b.total_amount) AS total_amount_of_claim
From provider a, claim b
Where a.provider_id = b.provider_id
Group by a.provider_id, a.name, date_part('year', b.date_of_service)
Order by provider_id;

-- How does income levels of policy holders affect the choice of insurance plan a policy holder has? (Policyholder, Insurance)
Select b.income, a.plan_id, c.name, c.coverage_percentage, count(a.policyholder_id) AS num_of_policyholders
From insurancecontracts a, policyholder b, insuranceplan c
Where a.policyholder_id = b.policyholder_id AND a.plan_id = c.plan_id
Group by b.income, a.plan_id, c.name, c.coverage_percentage
Order by income, num_of_policyholders DESC;

-- What is the age range with the highest percentage of patients? (Insurance)
With aa as (Select a.age_range, count(a.patient_id) AS num_patients_by_age
       From patient a
       Group by a.age_range),
         bb as (Select count(a.patient_id) AS num_patients
        From patient a)
Select aa.age_range, Round(1.0 * num_patients_by_age/num_patients * 100, 2) AS percentage_of_patients
From aa, bb
Order by percentage_of_patients DESC;

-- What sex has the highest percentage of patients? (Insurance)
With aa as (Select a.sex, count(a.patient_id) AS num_patients_by_sex
       From patient a
       Group by a.sex),
	 bb as (Select count(a.patient_id) AS num_patients
		From patient a)
Select aa.sex, Round(1.0 * num_patients_by_sex/num_patients * 100, 2) AS percentage_of_patients
From aa, bb
Order by percentage_of_patients DESC;

-- What is the average claim amount per race? (Insurance)
Select aa.race, avg(aa.average_amount_per_patient) AS average_amount_per_race
From (Select a.patient_id, a.race, avg(b.total_amount) AS average_amount_per_patient
           From patient a, claim b
           Where a.patient_id = b.patient_id
           Group by a.patient_id, a.race) aa
Group by aa.race;
