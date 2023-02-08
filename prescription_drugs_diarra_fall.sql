--SELECT * --COUNT(DISTINCT drug_name)
--FROM fips_county;

--**MVP**--

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

-- Given: prescription
-- Find: npi, sum of total_claim_count, for prescriber with the max sum(total_claim_count)

SELECT 
	npi,
	sum(total_claim_count) AS total_claims_all_drugs
FROM prescription
GROUP BY npi
ORDER BY sum(total_claim_count) DESC;
-- provider with npi: 1881634483 had the highest total number of claims
    
--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

-- Given: prescriber, prescription
-- Find: nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, sum of total_claim_count, for prescriber with the max sum(total_claim_count)

SELECT 
	nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description,
	sum(total_claim_count) AS total_claims_all_drugs
FROM prescription
	LEFT JOIN prescriber
	USING (npi) 
GROUP BY npi, 
	nppes_provider_first_name, 
	nppes_provider_last_org_name, 
	specialty_description
ORDER BY sum(total_claim_count) DESC;
-- Brian Pendley had the highest total number of claims

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

-- Given: prescriber, prescription
-- Find: specialty_description, sum(total_claim_count), for specialty with the max sum(total_claim_count)

SELECT 
	specialty_description,
	sum(total_claim_count) AS total_claims_all_drugs
FROM prescription
	LEFT JOIN prescriber
	USING (npi) 
GROUP BY specialty_description
ORDER BY sum(total_claim_count) DESC;
-- Family Practice had the highest total number of claims

--     b. Which specialty had the most total number of claims for opioids?

-- Given: prescriber, prescription, drug
-- Find: specialty_description, for specialty with highest total opiod claims 

SELECT 
	specialty_description,
	sum(total_claim_count) AS total_claims_opioids
FROM prescription
	LEFT JOIN prescriber
	USING (npi) 
	LEFT JOIN drug
	USING (drug_name) 
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY sum(total_claim_count) DESC;
-- Nurse Practitioners had the highest total number of opioid claims

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

-- Given: prescriber, prescription
-- Find: are there any specialties with no prescriptions?

SELECT 
	specialty_description,
	sum(total_claim_count) AS total_claims_all_drugs
FROM prescriber
	LEFT JOIN prescription
	USING (npi) 
GROUP BY specialty_description
HAVING sum(total_claim_count) IS NULL;
-- There are 15 specialties with no prescriptions


--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

-- Given: prescription, prescription, drug
-- Find: specialty_description, opioid_perc: (opioid_count/total_count)*100 -- sort by opioid_perc, desc

SELECT
	specialty_description,
	ROUND(sum(total_claim_count)*100/avg(sub.spec_total),2) AS perc_opioids
	FROM prescription
	LEFT JOIN prescriber AS pres
	USING (npi) 
	LEFT JOIN drug
	USING (drug_name)
	LEFT JOIN
	(SELECT 
	 	specialty_description,
		sum(total_claim_count) AS spec_total
	FROM prescription
		LEFT JOIN prescriber
		USING (npi) 
		LEFT JOIN drug
		USING (drug_name) 
	GROUP BY specialty_description) AS sub
	USING (specialty_description)
WHERE opioid_drug_flag = 'Y' 
GROUP BY specialty_description
ORDER BY perc_opioids DESC;
-- Case Manager/Care Coordinator, Orthopaedic Surgery, Interventional Pain Management


-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

-- Given: prescription, drug
-- Find: generic_name, total_drug_cost, for drug with highest total_drug_cost

SELECT 
	generic_name,
	sum(total_drug_cost) AS grand_total_drug_cost
FROM drug
	LEFT JOIN prescription
	USING (drug_name) 
GROUP BY generic_name
ORDER BY sum(total_drug_cost) DESC NULLS LAST;
-- INSULIN GLARGINE,HUM.REC.ANLOG had the highest total drug cost

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

-- Given: prescription, drug
-- Find: generic_name, total cost/day: total_drug_cost/total_day_supply, for drug with max sum(total_drug_cost/total_day_supply) - round to 2 decimal places

SELECT 
	generic_name,
	ROUND(sum(total_drug_cost)/sum(total_day_supply), 2) AS cost_per_day
FROM drug
	LEFT JOIN prescription
	USING (drug_name) 
GROUP BY generic_name
ORDER BY cost_per_day DESC NULLS LAST;
-- C1 ESTERASE INHIBITOR had the highest total cost per day ($3495.22)

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

-- Given: drug
-- Find: drug_name, drug_type - opioid_drug_flag = 'Y', 'opioid'; antibiotic_drug_flag = 'Y', 'antibiotic'; 'neither' for all other drugs

SELECT 
	drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

-- Given: 4-a, prescription (total_drug_cost::money)
-- Find: was total_drug_cost greater for opioids or antibiotics

SELECT 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type,
	sum(total_drug_cost::money) AS grand_total_drug_cost
FROM drug
	LEFT JOIN prescription
	USING (drug_name) 
GROUP BY drug_type
ORDER BY sum(total_drug_cost) DESC;
-- Opioids had a higher total drug cost


-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

-- Given: cbsa, fips_county (where fips_county is in TN)
-- Find: count of CBSAs in TN

SELECT DISTINCT cbsaname
FROM cbsa
	LEFT JOIN fips_county
	USING (fipscounty) 
WHERE state = 'TN';
--There are 10 CBSAs in TN

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

-- Given: cbsa, population
-- Find: cbsaname, highest population, lowest population -- cbsa can be present in multiple counties -> find sum

SELECT
	cbsaname,
	sum(population) AS total_population
FROM cbsa
	LEFT JOIN population
	USING (fipscounty) 
GROUP BY cbsaname
ORDER BY sum(population) DESC NULLS LAST;
-- Lowest: Morristown, TN - population 116352
-- Highest: Nashville-Davidson--Murfreesboro--Franklin, TN - population 1830410


--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

-- Given: population, fips_county, cbsa
-- Find: county, population, for largest county with no cbsa

SELECT
	county,
	sum(population) AS total_population
FROM fips_county
	LEFT JOIN population
	USING (fipscounty) 
	LEFT JOIN cbsa
	USING (fipscounty) 
WHERE cbsa IS NULL
GROUP BY county
ORDER BY sum(population) DESC NULLS LAST;
-- Sevier County is the largest (in terms of population) which is not included in a CBSA

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

-- Given: prescription
-- Find: drug_name, total_claim_count, where total_claim_count > 3000

SELECT
	drug_name,
	total_claim_count
FROM prescription
WHERE total_claim_count > 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

-- Given: 6-a, drug
-- Find: opioid? column

SELECT
	drug_name,
	total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid' END AS opioid
FROM prescription
	LEFT JOIN drug
	USING (drug_name)
WHERE total_claim_count > 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- Given: 6-b, prescriber
-- Find: nppes_provider_first_name + nppes_provider_last_org_name column

SELECT
	CONCAT(nppes_provider_first_name,' ', nppes_provider_last_org_name) AS name,
	drug_name,
	total_claim_count,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		ELSE 'not opioid' END AS opioid
FROM prescription
	LEFT JOIN drug
	USING (drug_name)
	LEFT JOIN prescriber
	USING (npi)
WHERE total_claim_count > 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opioid_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

-- Given: prescriber, drug
-- Find: all npi/drug_name combinations, where specialty_description = 'Pain Management', nppes_provider_city = 'NASHVILLE', opioid_drug_flag = 'Y'

SELECT 
	npi,
	drug_name
FROM prescriber 
	CROSS JOIN drug 
WHERE 
	specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE' 
	AND opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

-- Given: prescription
-- Find: npi, drug_name, total_claim_count - number of claims per drug per prescriber

SELECT 
	npi,
	drug.drug_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber 
	CROSS JOIN drug 
	LEFT JOIN prescription
	USING (npi)
WHERE 
	specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE' 
	AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name;

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

-- Given: prescription
-- Find: replace null values with 0 in total_claims_count (use COALESCE)

SELECT 
	npi,
	drug.drug_name,
	COALESCE(SUM(total_claim_count), 0) AS total_claims
FROM prescriber 
	CROSS JOIN drug 
	LEFT JOIN prescription
	USING (npi)
WHERE 
	specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE' 
	AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name;

--**BONUS**--


-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

-- Given: prescriber, prescription
-- Find: count of npi in prescriber excluding npi in prescription

SELECT COUNT(*)
FROM 
	((SELECT npi
	FROM prescriber)
	EXCEPT
	(SELECT npi
	FROM prescription)) AS count_of_npi_in_prescriber;

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

-- Given: prescriber, prescription, drug
-- Find: generic_name, count of prescriptions, desc, limit 5 -- where specialty_description = 'Family Practice'

SELECT 
	generic_name,
	sum(total_claim_count) AS prescription_count
FROM drug
	LEFT JOIN prescription
	USING (drug_name)
	LEFT JOIN prescriber
	USING (npi) 
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY prescription_count DESC
LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

-- Given: prescriber, prescription, drug
-- Find: generic_name, count of prescriptions, desc, limit 5 -- where specialty_description = 'Cardiology'

SELECT 
	generic_name,
	sum(total_claim_count) AS prescription_count
FROM drug
	LEFT JOIN prescription
	USING (drug_name)
	LEFT JOIN prescriber
	USING (npi) 
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY prescription_count DESC
LIMIT 5;

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

-- Given: prescriber, prescription, drug
-- Find: generic_name, count of prescriptions, desc, limit 5 -- where specialty_description = 'Cardiology' or 'Family Practice'

SELECT 
	generic_name,
	sum(total_claim_count) AS prescription_count
FROM drug
	LEFT JOIN prescription
	USING (drug_name)
	LEFT JOIN prescriber
	USING (npi) 
WHERE specialty_description IN ('Family Practice', 'Cardiology')
GROUP BY generic_name
ORDER BY prescription_count DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

-- Given: prescriber, prescription
-- Find: npi, sum(total_claim_count), and include a column showing the city (for nashville - use nppes_provider_city?) -- desc, limit 5

SELECT
	npi,
	sum(total_claim_count) AS total_claims,
	nppes_provider_city AS city
FROM prescriber
	LEFT JOIN prescription
	USING (npi)
WHERE nppes_provider_city iLIKE '%Nashville%'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC NULLS LAST
LIMIT 5;

--     b. Now, report the same for Memphis.

-- Given: prescriber, prescription
-- Find: npi, sum(total_claim_count), and include a column showing the city (for memphis - use nppes_provider_city?) -- desc, limit 5

SELECT
	npi,
	sum(total_claim_count) AS total_claims,
	nppes_provider_city AS city
FROM prescriber
	LEFT JOIN prescription
	USING (npi)
WHERE nppes_provider_city iLIKE '%Memphis%'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC NULLS LAST
LIMIT 5;

--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga. (is this top five from all four separately? or top 5 overall?)

-- Given: 3-a,b
-- Find: npi, sum(total_claim_count), and include a column showing the city (for nashville, memphis, knoxville, chattanooga - use nppes_provider_city?) -- desc, limit 5

SELECT 
	sub.npi,
	sub.total_claims,
	prescriber.nppes_provider_city AS city
FROM prescriber,
	(SELECT
		npi,
		sum(total_claim_count) AS total_claims
	FROM prescriber
		LEFT JOIN prescription
		USING (npi)
	GROUP BY npi) AS sub
WHERE sub.npi = prescriber.npi AND prescriber.nppes_provider_city  IN ('NASHVILLE', 'MEMPHIS', 'CHATTANOOGA', 'KNOXVILLE')
ORDER BY sub.total_claims DESC NULLS LAST
LIMIT 5;

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

-- Given: fips_county, overdose_deaths
-- Find: county, overdose_deaths -- where overdose_deaths > avg(overdose_deaths)

SELECT 
	county,
	deaths AS overdose_deaths
FROM fips_county
	LEFT JOIN overdoses
	USING (fipscounty)
WHERE deaths > (SELECT avg(deaths) FROM overdoses);

-- 5.
--     a. Write a query that finds the total population of Tennessee.

-- Given: population, fips_county
-- Find: total_tn_pop

SELECT SUM(population) AS total_tn_pop
FROM fips_county
	LEFT JOIN population
	USING(fipscounty)
WHERE state = 'TN';

--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

-- Given: 5-a 
-- Find:county, population, perc_of_tn_pop: (population/total_tn_pop)*100

SELECT
	county,
	sum(population) AS population,
	ROUND(100*sum(population)/(SELECT SUM(population)
							FROM fips_county
								LEFT JOIN population
								USING(fipscounty)
							WHERE state = 'TN'),2) AS perc_tn_pop
FROM fips_county
	LEFT JOIN population
	USING(fipscounty)
WHERE state = 'TN'
GROUP BY county
ORDER BY population DESC NULLS LAST;