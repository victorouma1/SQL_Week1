CREATE DATABASE HumanitarianProgramDB;

USE HumanitarianProgramDB;

CREATE TABLE jurisdiction_hierarchy (
	id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(30) NOT NULL UNIQUE,
    level VARCHAR(20) NOT NULL CHECK (level IN ('County','Sub-County','Village')),
    parent VARCHAR(30) NULL,
    FOREIGN KEY (parent) REFERENCES jurisdiction_hierarchy(name) ON DELETE CASCADE
);

CREATE TABLE village_locations (
	village_id INT PRIMARY KEY AUTO_INCREMENT,
    village VARCHAR(30) NOT NULL UNIQUE, 
    total_population INT NOT NULL CHECK (total_population >= 0),
    FOREIGN KEY (village) REFERENCES jurisdiction_hierarchy(name) ON DELETE CASCADE
);

CREATE TABLE beneficiary_partner_data (
	partner_id INT PRIMARY KEY AUTO_INCREMENT,
    partner VARCHAR(30) NOT NULL,
    village VARCHAR(30) NOT NULL,
    beneficiaries INT NOT NULL CHECK (beneficiaries >= 0),
    beneficiary_type VARCHAR(30) NOT NULL CHECK (beneficiary_type IN ('Individuals','Households')),
    FOREIGN KEY (village) REFERENCES village_locations(village) ON DELETE CASCADE
);

INSERT INTO jurisdiction_hierarchy (id, name, level, parent)
VALUES
(1, 'Nairobi', 'County', NULL),
(2, 'Kiambu', 'County', NULL),
(3, 'Mombasa', 'County', NULL),
(4, 'Westlands', 'Sub-County', 'Nairobi'),
(5, 'Kasarani', 'Sub-County', 'Nairobi'),
(6, 'Lari', 'Sub-County', 'Kiambu'),
(7, 'Gatundu South', 'Sub-County', 'Kiambu'),
(8, 'Kisauni', 'Sub-County', 'Mombasa'),
(9, 'Likoni', 'Sub-County', 'Mombasa'),
(10, 'Parklands', 'Village', 'Westlands'),
(11, 'Kangemi', 'Village', 'Westlands'),
(12, 'Roysambu', 'Village', 'Kasarani'),
(13, 'Githurai', 'Village', 'Kasarani'),
(14, 'Kiamwangi', 'Village', 'Lari'),
(15, 'Lari Town', 'Village', 'Lari'),
(16, 'Kamwangi', 'Village', 'Gatundu South'),
(17, 'Kisauni Town', 'Village', 'Kisauni'),
(18, 'Mtopanga', 'Village', 'Kisauni'),
(19, 'Likoni Town', 'Village', 'Likoni'),
(20, 'Shika Adabu', 'Village', 'Likoni');

INSERT INTO village_locations (village_id, village, total_population)
VALUES
(1, 'Parklands', 15000),
(2, 'Kangemi', 18000),
(3, 'Roysambu', 13000),
(4, 'Githurai', 12500),
(5, 'Kiamwangi', 12800),
(6, 'Lari Town', 9485),
(7, 'Kamwangi', 5212),
(8, 'Kisauni Town', 20500),
(9, 'Mtopanga', 15500),
(10, 'Likoni Town', 12000),
(11, 'Shika Adabu', 9000);

INSERT INTO beneficiary_partner_data (partner_id, partner, village, beneficiaries, beneficiary_type)
VALUES
(1, 'IRC', 'Parklands', 1450, 'Individuals'),
(2, 'NRC', 'Parklands', 50, 'Households'),
(3, 'SCI', 'Kangemi', 1123, 'Individuals'),
(4, 'IMC', 'Kangemi', 1245, 'Individuals'),
(5, 'CESVI', 'Roysambu', 5200, 'Individuals'),
(6, 'IMC', 'Githurai', 70, 'Households'),
(7, 'IRC', 'Githurai', 2100, 'Individuals'),
(8, 'SCI', 'Kiamwangi', 1800, 'Individuals'),
(9, 'IMC', 'Lari Town', 1340, 'Individuals'),
(10, 'CESVI', 'Kamwangi', 55, 'Households'),
(11, 'IRC', 'Kisauni Town', 4500, 'Individuals'),
(12, 'SCI', 'Kisauni Town', 1670, 'Individuals'),
(13, 'IMC', 'Mtopanga', 1340, 'Individuals'),
(14, 'CESVI', 'Likoni Town', 4090, 'Individuals'),
(15, 'IRC', 'Shika Adabu', 2930, 'Individuals'),
(16, 'SCI', 'Shika Adabu', 5200, 'Individuals');

# Aggregate Functions, GROUP BY & CASE WHEN
-- 1. Total beneficiaries per partner (convert households to individuals).
SELECT 
    partner,
    SUM(
        CASE 
            WHEN beneficiary_type = 'Households' THEN beneficiaries * 5
            ELSE beneficiaries 
        END
    ) AS total_beneficiaries
FROM beneficiary_partner_data
GROUP BY partner;

-- 2. Count the number of villages served per partner
SELECT 
	partner,
    COUNT(village) AS villages_served
FROM beneficiary_partner_data
GROUP BY partner;

-- 3. Compute the average beneficiaries per village
SELECT 
	village,
    AVG(beneficiaries) AS average_beneficiaries
FROM beneficiary_partner_data
GROUP BY village;

-- 4. Identify partners serving more than 5000 beneficiaries
SELECT 
	partner,
    SUM(beneficiaries) AS total_beneficiaries
FROM beneficiary_partner_data
GROUP BY partner
HAVING total_beneficiaries > 5000;

-- 5. Find villages with multiple partners
SELECT
	village,
    COUNT(partner) AS total_partners
FROM beneficiary_partner_data
GROUP BY village
HAVING total_partners > 1;

# Joins & Combined Queries
-- 1. Join beneficiary_partner_data and village_locations to calculate coverage per village 
SELECT
	bpd.village,
    SUM(bpd.beneficiaries/vl.total_population) AS coverage
FROM beneficiary_partner_data bpd
JOIN village_locations vl ON bpd.village = vl.village
GROUP BY bpd.village;
-- 2 Create a combined query showing all villages and partners serving them, including villages with no partners 
INSERT INTO jurisdiction_hierarchy (name, level, parent) VALUES ('Limuru','Village', 'Gatundu South');
INSERT INTO village_locations (village, total_population) VALUES ('Limuru',2000);
SELECT 
	vl.village,
    CASE 
		WHEN bpd.partner IS NULL THEN 'No partner' 
        ELSE bpd.partner
	END as partner
FROM village_locations vl
LEFT JOIN beneficiary_partner_data bpd ON vl.village = bpd.village

UNION
SELECT 
	vl.village,
    bpd.partner
FROM village_locations vl
JOIN beneficiary_partner_data bpd ON vl.village = bpd.village;

# Nested Queries / Subqueries
-- 1. Find villages where coverage is above the average village coverage.
SELECT
	bpd.village,
    SUM(bpd.beneficiaries/vl.total_population) AS coverage
FROM beneficiary_partner_data bpd
JOIN village_locations vl ON bpd.village = vl.village
GROUP BY bpd.village
HAVING coverage > (
	SELECT AVG(village_coverage)
    FROM (
        SELECT SUM(bpd1.beneficiaries / vl1.total_population) AS village_coverage
        FROM beneficiary_partner_data bpd1
        JOIN village_locations vl1 ON bpd1.village = vl1.village
        GROUP BY bpd1.village
    ) AS village_sum
);

-- 2. Find partners who serve more than the average number of beneficiaries.
SELECT
	partner,
    SUM(beneficiaries) AS total_beneficiaries
FROM beneficiary_partner_data
GROUP BY partner
HAVING total_beneficiaries > (
	SELECT AVG(number_of_beneficiaries)
    FROM (
		SELECT SUM(beneficiaries) AS number_of_beneficiaries
        FROM beneficiary_partner_data
        GROUP BY partner
    ) AS sum_of_beneficiaries
);

# CTEs (Common Table Expressions)
-- 1. Create a district-level summary showing total beneficiaries, total population, coverage using a CTE.
WITH district_level_summary AS (
	SELECT
		jh.parent,
		SUM(bpd.beneficiaries) AS total_beneficiaries,
        SUM(vl.total_population) AS population,
        SUM(bpd.beneficiaries/vl.total_population) AS coverage
	FROM jurisdiction_hierarchy jh
    JOIN beneficiary_partner_data bpd ON jh.name = bpd.village
    JOIN village_locations vl ON bpd.village = vl.village
    GROUP BY jh.parent
	)

SELECT 
	dls.parent,
	dls.total_beneficiaries,
    dls.population,
    dls.coverage
FROM district_level_summary dls;

-- 2. Rank districts by coverage using a window function inside a CTE.
WITH district_rank AS (
	SELECT
		jh.parent,
        RANK() OVER(ORDER BY SUM(bpd.beneficiaries/vl.total_population) DESC) AS district_rank,
        SUM(bpd.beneficiaries/vl.total_population) AS coverage
	FROM jurisdiction_hierarchy jh
    JOIN beneficiary_partner_data bpd ON jh.name = bpd.village
    JOIN village_locations vl ON bpd.village = vl.village
    GROUP BY jh.parent
	)

SELECT 
	dr.parent,
    dr.coverage,
    dr.district_rank
FROM district_rank dr;
	
#  Window Functions
-- 1. Rank partners based on total beneficiaries
SELECT
	partner,
    SUM(beneficiaries) AS total_beneficiaires,
    RANK() OVER(ORDER BY SUM(beneficiaries)) AS beneficiaires_rank
FROM beneficiary_partner_data
GROUP BY partner;

-- 2. Rank districts within each region based on beneficiaries served
SELECT DISTINCT
	jh.parent,
    SUM(bpd.beneficiaries) OVER(PARTITION BY jh.parent) AS beneficiaries_served
FROM jurisdiction_hierarchy jh
JOIN beneficiary_partner_data bpd ON jh.name = bpd.village
ORDER BY beneficiaries_served DESC;
-- 3 Top performing partner per district 
WITH top_performer AS (
SELECT DISTINCT
    jh.parent,
    bpd.partner,
    ROW_NUMBER() OVER(PARTITION BY jh.parent ORDER BY SUM(bpd.beneficiaries)) AS District_no
FROM jurisdiction_hierarchy jh
JOIN beneficiary_partner_data bpd ON jh.name = bpd.village
GROUP BY jh.parent, bpd.partner
)

SELECT 
	tp.parent,
    tp.partner AS top_partner
FROM top_performer tp
WHERE tp.District_no = 1;

# Views
-- 1. Create view district_summary with district-level beneficiaries, population, coverage, number of partners.
CREATE VIEW district_summary AS
SELECT
	jh.parent,
	SUM(bpd.beneficiaries) AS total_beneficiaries,
	SUM(vl.total_population) AS population,
	SUM(bpd.beneficiaries/vl.total_population) AS coverage,
    COUNT(bpd.partner) AS number_of_partners
FROM jurisdiction_hierarchy jh
JOIN beneficiary_partner_data bpd ON jh.name = bpd.village
JOIN village_locations vl ON bpd.village = vl.village
GROUP BY jh.parent;

SELECT * FROM district_summary;

-- 2. Create view partner_summary with partner name, villages served, districts reached, total beneficiaries.
CREATE VIEW partner_summary AS
SELECT
	bpd.partner,
    COUNT(bpd.village) AS villages_served,
    COUNT(jh.parent) AS districts_reached,
    SUM(bpd.beneficiaries) AS total_beneficiaries
FROM beneficiary_partner_data bpd
JOIN jurisdiction_hierarchy jh ON bpd.village = jh.name
GROUP BY bpd.partner;

SELECT * FROM partner_summary;

# Triggers
-- 1. Trigger on beneficiary_partner_data to log a message when a new record is inserted.
CREATE TABLE NewDataLog (
	LogID INT PRIMARY KEY AUTO_INCREMENT,
    Message VARCHAR(50),
    Date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
CREATE TRIGGER new_record 
BEFORE INSERT ON beneficiary_partner_data
FOR EACH ROW
BEGIN
	INSERT INTO NewDataLog (Message) VALUES ("New record has been added");
END
$$

DELIMITER ;

INSERT INTO beneficiary_partner_data(partner,village,beneficiaries,beneficiary_type) 
VALUES
('SCI','Parklands', 2000, 'Individuals');
	
SELECT * FROM NewDataLog;

-- 2. Trigger to prevent inserting negative beneficiaries.
DELIMITER $$
CREATE TRIGGER positive_only
BEFORE INSERT ON beneficiary_partner_data
FOR EACH ROW
BEGIN
	CASE
		WHEN NEW.beneficiaries < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Number of beneficiaries cannot be negative.';
	END CASE;
END
$$
DELIMITER ;
INSERT INTO beneficiary_partner_data(partner,village,beneficiaries,beneficiary_type) 
VALUES
('SCI','Parklands', -2000, 'Individuals');

# Stored Procedures
-- 1 returns villages served, districts served, total beneficiaries, partner ranking.
DELIMITER $$
CREATE PROCEDURE GetPartnerReport(
	IN p_partner VARCHAR(50)
)
BEGIN
	SELECT
		COUNT(bpd.village) AS villages_served,
		COUNT(jh.parent) AS districts_reached,
		SUM(bpd.beneficiaries) AS total_beneficiaries,
        RANK () OVER(PARTITION BY bpd.partner ORDER BY SUM(bpd.beneficiaries)) AS partner_ranking
	FROM beneficiary_partner_data bpd
	JOIN jurisdiction_hierarchy jh ON bpd.village = jh.name
    WHERE bpd.partner = p_partner
	GROUP BY bpd.partner;
END
$$
DELIMITER ;
CALL GetPartnerReport ('IMC');
-- 2. returns region, district population, total beneficiaries, coverage rate, number of partners.
DELIMITER $$
CREATE PROCEDURE GetDistrictImpact(
	IN p_district VARCHAR(50)
)
BEGIN
	SELECT
		(SELECT jh.parent FROM jurisdiction_hierarchy jh WHERE name = p_district) AS region,
		SUM(vl.total_population) AS total_population,
        SUM(bpd.beneficiaries) AS total_beneficiaries,
        SUM(bpd.beneficiaries/vl.total_population) AS coverage,
        COUNT(partner) AS number_of_partners
	FROM beneficiary_partner_data bpd
	JOIN jurisdiction_hierarchy jh ON bpd.village = jh.name
    JOIN village_locations vl ON jh.name = vl.village
    WHERE jh.parent = p_district
	GROUP BY jh.parent;
END
$$
DELIMITER ;

CALL GetDistrictImpact('Kasarani');