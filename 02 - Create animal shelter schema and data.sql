/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ IMPORTANT - Each of my courses uses its own subset of the data and tables from this projcet.               @@
@@ If you are looking for the practice demo database I use in my courses, follow these links:                 @@
@@ 1. Query Processing - https://github.com/ami-levin/LinkedIn/tree/master/Query%20Processing/Demo%20Database @@ 
@@ 2. Window Functions - https://github.com/ami-levin/LinkedIn/tree/master/Window%20Functions/Demo%20Database @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

-- Animal shelter tables and data

USE Animal_Shelter;
GO

-- Variable assignment
DECLARE @Shelter_Open		DATE	= '20160101';		-- Shelter open day
DECLARE @Last_Data_Day		DATE	= '20191231';		-- Last day of data
DECLARE @Shelter_State		VARCHAR(20) = 'California';	-- Shelter state
DECLARE @Shelter_County		VARCHAR(20) = 'Los Angeles';-- Shelter county - cities and addresses will be limited to the same county
DECLARE @Max_Zip_Code		CHAR(5) = '91000';			-- Further limit persons to zip areas below this number
DECLARE @Max_Street_Number	INT = 1000;					-- Maximal number used to generate street address
DECLARE @Min_Person_Age		INT = 18;					-- Minimum age of person as of shelter open
DECLARE @Max_Person_Age		INT = 70;					-- Maximum age of person as of shelter open
DECLARE @Num_Persons		INT = 120;					-- Number of persons
DECLARE @Num_Veterinarians	INT = 2;					-- Number of staff vets
DECLARE @Num_Assistants		INT = 4;					-- Number of staff assistants
DECLARE @Num_receptionists	INT = 2;					-- Number of staff receptionists
DECLARE @Num_Managers		INT = 1;					-- Number of managers
DECLARE @Num_Dogs			INT = 60;					-- Number of dogs in shelter
DECLARE @Num_Cats			INT = 30;					-- Number of cats in shelter
DECLARE @Num_Rabbits		INT = 10;					-- Number of rabbits in shelter
DECLARE @Num_Adoptions		INT = 70;					-- Number of total adoptions
DECLARE @Min_Animal_Age_D	INT = 1;					-- Minimal age in days as of admission
DECLARE @Max_Animal_Age_D	INT = 18 * 12 * 30;			-- Maximal age in days as of admission
DECLARE @Min_Adoption_Fee	INT = 50;					-- Minimal adoption fee
DECLARE @Max_Adoption_fee	INT = 100;					-- Maximal adoption fee
DECLARE @Percent_Non_Breed	INT = 75;					-- Percent of non breed animals

BEGIN TRANSACTION; -- easy rollback

-- Operational data
-- Persons
CREATE TABLE Persons
(
	Email		VARCHAR(100)	NOT NULL
		PRIMARY KEY,
	First_Name	VARCHAR(15)		NOT NULL,
	Last_Name	VARCHAR(15)		NOT NULL,
	Birth_Date	DATE			NULL,
	Address		VARCHAR(100)	NOT NULL,
	State		VARCHAR(20)		NOT NULL,
	City		VARCHAR(30)		NOT NULL,
	Zip_Code	CHAR(5)			NOT NULL,
);

WITH All_Possible_Names
AS
(
	SELECT	CASE Genders.Gender
				WHEN 'M' THEN CPN.Male
				ELSE CPN.Female
			END AS First_Name,
			CPN1.Surname AS Last_Name
	FROM	Reference.Common_Person_Names AS CPN
			CROSS JOIN
			Reference.Common_Person_Names AS CPN1
			CROSS JOIN 
			(VALUES ('F'), ('M')) AS Genders(Gender) 
)
INSERT	INTO Persons (Email, First_Name, Last_Name, Birth_Date, Address, State, City, Zip_Code)
SELECT	LOWER(Random_Names.First_Name) + '.' + LOWER(Random_Names.Last_name) + '@'
		+ CASE dbo.Random(1, 6)
			WHEN 1 THEN 'gmail'
			WHEN 2 THEN 'gmail' 
-- Gmail is more popular than other mail providers
			WHEN 3 THEN 'hotmail'
			WHEN 4 THEN 'yahoo'
			WHEN 5 THEN 'outlook'
			ELSE 'icloud'
		END + '.com' AS Email,
		Random_Names.First_Name,
		Random_Names.Last_Name,
		CASE
		WHEN dbo.Random(1,10) > 1 -- 10% did not provide birth date
		THEN
		DATEADD(DAY, dbo.Random(0, 365), DATEADD(YEAR, -dbo.Random(@Min_Person_Age, @Max_Person_Age), @Shelter_Open)) 
		ELSE NULL 
		END AS Birth_Date,
		Addresses.Address,
		@Shelter_State,
		Cities.City,
		Cities.Zip_Code
FROM	(
			SELECT		APN.First_Name,
						APN.Last_Name
			FROM		All_Possible_Names AS APN
			ORDER BY	NEWID()
			OFFSET 0 ROWS FETCH NEXT @Num_Persons ROWS ONLY
		) AS Random_Names
		CROSS APPLY
		(
		SELECT		CZC.City,
					CZC.Zip_Code
		FROM		Reference.City_Zip_Codes	AS CZC
					INNER JOIN
					Reference.Cities			AS C
						ON	C.State = CZC.State
							AND		
							C.City = CZC.City
		WHERE		C.State = @Shelter_State
					AND 
					C.County = @Shelter_County
					AND 
					(CZC.Zip_Code < @Max_Zip_Code OR @Max_Zip_Code IS NULL)
					AND
					Random_Names.First_Name IS NOT NULL -- Force per row execution
		ORDER BY	NEWID()
		OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
	)	AS Cities(City, Zip_Code)
		CROSS APPLY
	(
		SELECT		CAST(dbo.Random(1, @Max_Street_Number) AS VARCHAR(4)) + ' ' + CSN.Street
		FROM		Reference.Common_Street_Names AS CSN
		WHERE		Random_Names.First_Name IS NOT NULL -- Force per row execution
		ORDER BY	NEWID()
		OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
	)	AS Addresses(Address);

-- Staff roles
CREATE TABLE Staff_Roles 
(
	Role VARCHAR(20) NOT NULL PRIMARY KEY
);

INSERT INTO Staff_Roles (Role)
VALUES
('Receptionist'), ('Veterinarian'), ('Assistant'), ('Manager'), 
('Janitor'); -- Latter will not be assigned, everyone helps clean up

-- Staff
CREATE TABLE Staff
(
	Email		VARCHAR(100)	NOT NULL
		PRIMARY KEY
		REFERENCES Persons (Email)
		ON UPDATE CASCADE 
		ON DELETE NO ACTION,
	Hire_Date			DATE			NOT NULL
);

INSERT	INTO Staff (Email, Hire_Date)
SELECT		Email,
			DATEADD(DAY, dbo.Random(0, DATEDIFF(DAY, @Shelter_Open, @Last_Data_Day)), @Shelter_Open)
FROM		Persons
ORDER BY	NEWID()
OFFSET 0 ROWS FETCH NEXT (@Num_receptionists + @Num_Managers + @Num_Assistants + @Num_Veterinarians) ROWS ONLY;

-- Staff use 'animalshelter.com' domain addresses
UPDATE	Persons
SET		Email = LEFT(Email, CHARINDEX('@', Email)) + 'animalshelter.com'
WHERE	Email IN (SELECT Email FROM Staff);

-- Staff roles
CREATE TABLE Staff_Assignments
(
	Email		VARCHAR(100)	NOT NULL
		REFERENCES Staff (Email)
		ON UPDATE CASCADE 
		ON DELETE NO ACTION,
	Role		VARCHAR(20)		NOT NULL
		REFERENCES Staff_Roles (Role)
		ON UPDATE CASCADE 
		ON DELETE NO ACTION,
	Assigned	DATE			NOT NULL,
	PRIMARY KEY (Email, Role),
	INDEX NCIDX_FK_Staff_Assignments__Roles(Role)
);

INSERT	INTO Staff_Assignments (Email, Role, Assigned)
SELECT		S.Email,
			'Veterinarian',
			S.Hire_Date
FROM		Staff AS S
ORDER BY	NEWID() 
OFFSET 0 ROWS FETCH NEXT @Num_Veterinarians ROWS ONLY;

INSERT	INTO Staff_Assignments (Email, Role, Assigned)
SELECT		S.Email,
			'Assistant',
			S.Hire_Date
FROM		Staff AS S
WHERE		Email NOT IN ( SELECT Email FROM Staff_Assignments )
ORDER BY	NEWID() 
OFFSET 0 ROWS FETCH NEXT (@Num_Assistants) ROWS ONLY;

INSERT	INTO Staff_Assignments (Email, Role, Assigned)
SELECT		S.Email,
			'Receptionist',
			S.Hire_Date
FROM		Staff AS S
WHERE		Email NOT IN ( SELECT Email FROM Staff_Assignments )
ORDER BY	NEWID() 
OFFSET 0 ROWS FETCH NEXT (@Num_receptionists) ROWS ONLY;

INSERT	INTO Staff_Assignments (Email, Role, Assigned)
SELECT		S.Email,
			'Manager',
			S.Hire_Date
FROM		Staff AS S
WHERE		Email NOT IN ( SELECT Email FROM Staff_Assignments )
ORDER BY	NEWID() 
OFFSET 0 ROWS FETCH NEXT @Num_Managers ROWS ONLY;

-- 1 of each role on day 1
WITH Staff_Rn
AS
(
	SELECT	*, 
			ROW_NUMBER() OVER(PARTITION BY role ORDER BY Assigned ASC) AS Rn
	FROM	Staff_Assignments
)
UPDATE	Staff_Rn
SET		Staff_Rn.Assigned = @Shelter_Open
WHERE	Rn = 1;

-- update hire dates to match
UPDATE	Staff
SET		Hire_Date = (SELECT Assigned FROM Staff_Assignments AS SA WHERE SA.Email = Staff.Email);

-- Animals
CREATE TABLE Animals
(
	Name			VARCHAR(20)			NOT NULL,
	Species			VARCHAR(10)			NOT NULL,
	Primary_Color	VARCHAR(10)			NOT NULL
		REFERENCES Reference.Colors (Color),
	CONSTRAINT PK_Animals
	PRIMARY KEY (Name, Species),
	-- Business rule = unique identification of animal as name + species will do for a small sample set 
	-- probably not enough for a real world scenario but depends on shelter naming conventions
	Implant_Chip_ID UNIQUEIDENTIFIER	NOT NULL UNIQUE, 
	-- This is the 'most natural' key, but it's unfamiliar and not very useful for human communication	
	Breed			VARCHAR(50)			NULL,
	Gender			CHAR(1)				NOT NULL 
		CHECK (Gender IN ( 'M', 'F' )), -- no need for gender fluidity in animals :-)
	Birth_Date		DATE				NOT NULL,
	Pattern			VARCHAR(20)			NOT NULL,
	CONSTRAINT FK_Animals__Patterns
		FOREIGN KEY (Species, Pattern)
		REFERENCES Reference.Patterns (Species, Pattern),
	Admission_Date	DATE				NOT NULL,
	CONSTRAINT FK_Animals__Breeds
		FOREIGN KEY (Species, Breed)
		REFERENCES Reference.Breeds (Species, Breed),
	INDEX NCIDX_FK_Animals__Patterns (Species, Pattern),
	INDEX NCIDX_FK_Animals__Breeds (Species, Breed),
	INDEX NCIDX_FK_Animals__Colors (Primary_Color)
);

-- Dogs
WITH	Unpivoted_Names
AS (
	SELECT	CAN.Species,
			Genders.Gender,
			CASE
				WHEN Genders.Gender = 'F' 
					THEN	CAN.Female
				ELSE		CAN.Male
			END	AS Name
	FROM	Reference.Common_Animal_Names AS CAN
			CROSS JOIN 
			(VALUES ('F'), ('M')) AS Genders (Gender)
	),
DeDuped_F_M_Names -- There are identical names for both M and F of the same species which we want to avoid since gender is not part of key
AS
(
	SELECT	UN.Species,
			CASE 
				WHEN dbo.Random(1, 2) = 1
					THEN MAX(Gender)
				ELSE MIN(Gender) -- Pick arbitraty gender when duplicated
			END AS Gender,
			UN.Name
	FROM	Unpivoted_Names AS UN
	GROUP BY UN.Species, UN.Name
)
INSERT INTO Animals (Implant_Chip_ID, Species, Breed, Name, Gender, Birth_Date, Primary_Color, Pattern, Admission_Date)
SELECT	NEWID() AS Implant_Chip_ID,
		D.Species,
		B.Breed,																							-- Non breeds first
		D.Name,
		D.Gender,
		'20001010' AS Birth_Date,	-- Place holder, will update later based on generated admission date
		C.Color,
		CP.Pattern,
		DATEADD(DAY, dbo.Random(0, DATEDIFF(DAY, @Shelter_Open, @Last_Data_Day)), @Shelter_Open) AS Admission_Date
FROM	DeDuped_F_M_Names	AS D
		CROSS APPLY
		(	SELECT	Color 
			FROM	Reference.Colors	AS C
			ORDER BY NEWID(), D.Name
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS C
		CROSS APPLY
		(
			SELECT	Pattern
			FROM	Reference.Patterns AS P
			WHERE	P.Species = D.Species
			ORDER BY NEWID(), C.Color
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS CP
		CROSS APPLY
		(
			SELECT	Breed
			FROM	Reference.Breeds AS B
			WHERE	B.Species = D.Species
			ORDER BY NEWID(), C.Color
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS B(Breed)
WHERE	D.Species = 'Dog'
ORDER BY	NEWID()
OFFSET 0 ROWS FETCH NEXT (@Num_Dogs) ROWS ONLY;

-- Cats
WITH	Unpivoted_Names
AS (
	SELECT	CAN.Species,
			Genders.Gender,
			CASE
				WHEN Genders.Gender = 'F' 
					THEN	CAN.Female
				ELSE		CAN.Male
			END	AS Name
	FROM	Reference.Common_Animal_Names AS CAN
			CROSS JOIN 
			(VALUES ('F'), ('M')) AS Genders (Gender)
	),
DeDuped_F_M_Names -- There are identical names for both M and F of the same species-avoid since we don't have gender in key
AS
(
	SELECT	UN.Species,
			CASE 
				WHEN dbo.Random(1, 2) = 1
					THEN MAX(Gender)
				ELSE MIN(Gender) -- Pick arbitraty gender when duplicated
			END AS Gender,
			UN.Name
	FROM	Unpivoted_Names AS UN
	GROUP BY UN.Species, UN.Name
)
INSERT INTO Animals (Implant_Chip_ID, Species, Breed, Name, Gender, Birth_Date, Primary_Color, Pattern, Admission_Date)
SELECT	NEWID() AS Implant_Chip_ID,
		D.Species,
		B.Breed,																							-- Non breeds first
		D.Name,
		D.Gender,
		'20001010' AS Birth_Date,	-- Place holder, will update later based on generated admission date
		CASE WHEN B.Breed LIKE '%Blue%' THEN 'Gray' ELSE C.Color END,
		CP.Pattern,
		DATEADD(DAY, dbo.Random(0, DATEDIFF(DAY, @Shelter_Open, @Last_Data_Day)), @Shelter_Open) AS Admission_Date
FROM	DeDuped_F_M_Names	AS D
		CROSS APPLY
		(	SELECT	Color 
			FROM	Reference.Colors	AS C
			ORDER BY NEWID(), D.Name
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS C
		CROSS APPLY
		(
			SELECT	Pattern
			FROM	Reference.Patterns AS P
			WHERE	P.Species = D.Species
			ORDER BY NEWID(), C.Color, D.Name
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS CP
		CROSS APPLY
		(
			SELECT	Breed
			FROM	Reference.Breeds AS B
			WHERE	B.Species = D.Species
			ORDER BY NEWID(), C.Color, D.Name, CP.Pattern
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS B(Breed)
WHERE	D.Species = 'Cat'
ORDER BY	NEWID()
OFFSET 0 ROWS FETCH NEXT (@Num_Cats) ROWS ONLY;

-- Rabbits
WITH	Unpivoted_Names
AS (
	SELECT	CAN.Species,
			Genders.Gender,
			CASE
				WHEN Genders.Gender = 'F' 
					THEN	CAN.Female
				ELSE		CAN.Male
			END	AS Name
	FROM	Reference.Common_Animal_Names AS CAN
			CROSS JOIN 
			(VALUES ('F'), ('M')) AS Genders (Gender)
	),
DeDuped_F_M_Names -- There are identical names for both M and F of the same species-avoid since we don't have gender in key
AS
(
	SELECT	UN.Species,
			CASE 
				WHEN dbo.Random(1, 2) = 1
					THEN MAX(Gender)
				ELSE MIN(Gender) -- Pick arbitraty gender when duplicated
			END AS Gender,
			UN.Name
	FROM	Unpivoted_Names AS UN
	GROUP BY UN.Species, UN.Name
)
INSERT INTO Animals (Implant_Chip_ID, Species, Breed, Name, Gender, Birth_Date, Primary_Color, Pattern, Admission_Date)
SELECT	NEWID() AS Implant_Chip_ID,
		D.Species,
		B.Breed,																							-- Non breeds first
		D.Name,
		D.Gender,
		'20001010' AS Birth_Date,	-- Place holder, will update later based on generated admission date
		C.Color,
		CP.Pattern,
		DATEADD(DAY, dbo.Random(0, DATEDIFF(DAY, @Shelter_Open, @Last_Data_Day)), @Shelter_Open) AS Admission_Date
FROM	DeDuped_F_M_Names	AS D
		CROSS APPLY
		(	SELECT	Color 
			FROM	Reference.Colors	AS C
			ORDER BY NEWID(), D.Name
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS C
		CROSS APPLY
		(
			SELECT	Pattern
			FROM	Reference.Patterns AS P
			WHERE	P.Species = D.Species
			ORDER BY NEWID(), C.Color
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS CP
		CROSS APPLY
		(
			SELECT	Breed
			FROM	Reference.Breeds AS B
			WHERE	B.Species = D.Species
			ORDER BY NEWID(), C.Color
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		) AS B(Breed)
WHERE	D.Species = 'Rabbit'
ORDER BY	NEWID()
OFFSET 0 ROWS FETCH NEXT (@Num_Rabbits) ROWS ONLY;

-- Most animals are non breed
UPDATE	Animals
SET		Breed = CASE 
					WHEN dbo.Random(1, 100)  > @Percent_Non_Breed
					THEN Breed
					ELSE NULL
				END;

-- Now update to 'real' birth dates based on generated admission date
UPDATE	Animals
SET		Birth_Date = DATEADD(DAY, -dbo.Random(@Min_Animal_Age_D, @Max_Animal_Age_D), Admission_Date);

-- Adoptions
CREATE TABLE Adoptions
(
	Name				VARCHAR(20)		NOT NULL,
	Species				VARCHAR(10)		NOT NULL,
	CONSTRAINT FK_Adoptions__Animals
	FOREIGN KEY (Name, Species)
		REFERENCES Animals (Name, Species)
		ON UPDATE CASCADE 
		ON DELETE NO ACTION,
	Adopter_Email		VARCHAR(100)	NOT NULL
		REFERENCES Persons (Email)
		ON UPDATE CASCADE 
		ON DELETE NO ACTION,
	PRIMARY KEY (Name, Species, Adopter_Email),
	-- An animal may be adopted only once by the same person (allows for future implementation of adoption returns)
	Adoption_Date	DATE				NOT NULL,
	Adoption_Fee	SMALLINT			NOT NULL CHECK (Adoption_Fee >= 0),
	INDEX NCIDX_FK_Adoptions__Persons (Adopter_Email),
);

INSERT	INTO Adoptions (Name, Species, Adopter_Email, Adoption_Date, Adoption_Fee)
SELECT	A.Name,
		A.Species,
		Adopter.Email,
		Adoption.Date,
		dbo.Random(@Min_Adoption_Fee, @Max_Adoption_fee)
FROM	Animals AS A
		CROSS APPLY
		(
			SELECT		C.Date
			FROM		Reference.Calendar AS C
			WHERE		C.Date > A.Admission_Date
						AND 
						C.Date < @Last_Data_Day
			ORDER BY	NEWID() 
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		)			AS Adoption(Date)
			CROSS APPLY
		(
			SELECT		Email
			FROM		Persons
			WHERE		Adoption.Date IS NOT NULL	-- dummy reference to force row execution
			ORDER BY	NEWID() 
			OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
		)	AS Adopter
ORDER BY NEWID()
OFFSET 0 ROWS FETCH NEXT @Num_Adoptions ROWS ONLY;

/* -- Future optional
-- Animal routine checkups
CREATE TABLE Routine_Checkups
(
	Name				VARCHAR(20)		NOT NULL,
	Species				VARCHAR(10)		NOT NULL,
	CONSTRAINT FK_Routine_Checkups__Animals
	FOREIGN KEY (Name, Species)
	REFERENCES Animals (Name, Species),
	Checkup_Time	DATETIME2		NOT NULL,
	Temperature_F	DECIMAL(4, 1)	NOT NULL,
	Heart_Rate		TINYINT			NOT NULL,
	Respiration		TINYINT			NOT NULL,
	Weight_Lbs		DECIMAL(4, 1)	NOT NULL,
	Comments		VARCHAR(500)	NULL,
	Performed_By	VARCHAR(100)	NOT NULL
		REFERENCES Staff (Email)
		ON UPDATE CASCADE 
		ON DELETE NO ACTION,	
	PRIMARY KEY (Name, Species, Checkup_Time),
	INDEX NCIDX_FK_Routine_Checkups__Staff(Performed_By)
);

INSERT	INTO Routine_Checkups 
(Name, Species, Checkup_Time, Temperature_F, Heart_Rate, Respiration, Weight_Lbs, Comments, Performed_By)
SELECT	A.Name,
		A.Species,
		DATEADD(MINUTE, (7 * 60) + dbo.Random(0, (8 * 60)), CAST(C.Date AS DATETIME2)) AS Checkup_Time,
		ROUND(
				(SNR.Temperature_Low + ((SNR.Temperature_High - SNR.Temperature_Low) / 2.00)) -- Middle of range
				+ ((dbo.Random(-10, 10) / 30.00) * (SNR.Temperature_High - SNR.Temperature_Low)) -- +/- 30% around the middle of the range
				+ CASE
					WHEN dbo.Random(1, 100) < 100 -- 1 in 100 rows give abnormal reading 
				THEN
						0
					ELSE
				(dbo.Random(-10, 10) / 30.00) * (SNR.Temperature_High - SNR.Temperature_Low) -- by +/- 1/3 of range
				END,
				1
			)																		AS Temperature,
		ROUND(
				(SNR.Heart_Rate_Low + ((SNR.Heart_Rate_high - SNR.Heart_Rate_Low) / 2.00)) -- Middle of range
				+ ((dbo.Random(-10, 10) / 30.00) * (SNR.Heart_Rate_high - SNR.Heart_Rate_Low)) -- +/- 30% around the middle of the range
				+ CASE
					WHEN dbo.Random(1, 100) < 100 -- 1 in 100 rows give abnormal reading 
				THEN
						0
					ELSE
				(dbo.Random(-10, 10) / 30.00) * (SNR.Heart_Rate_high - SNR.Heart_Rate_Low) -- by +/- 1/3 of range
				END,
				0
			)																		AS Heart_Rate,
		ROUND(
				(SNR.Respiratory_Rate_Low + ((SNR.Respiratory_Rate_High - SNR.Respiratory_Rate_Low) / 2.00)) -- Middle of range
				+ ((dbo.Random(-10, 10) / 30.00) * (SNR.Respiratory_Rate_High - SNR.Respiratory_Rate_Low)) -- +/- 30% around the middle of the range
				+ CASE
					WHEN dbo.Random(1, 100) < 100 -- 1 in 100 rows give abnormal reading 
				THEN
						0
					ELSE
				(dbo.Random(-10, 10) / 30.00) * (SNR.Respiratory_Rate_High - SNR.Respiratory_Rate_Low) -- by +/- 1/3 of range
				END,
				0
			)																		AS Respistory_Rate,
		ROUND(
				CASE A.Species
					WHEN 'Cat' THEN
						6.00 + ((ABS(CHECKSUM(A.Breed)) % 24) / 2) -- consistent base weight / breed
						+ ((CASE WHEN dbo.Random(1, 10) < 10 THEN 0 ELSE 1 END) * (dbo.Random(-10, 10) / 20.00))	-- cats (6 - 17 lbs) +/- 0.5 lbs 1 in 10 
					WHEN 'Dog' THEN
						15.00 + ((ABS(CHECKSUM(A.Breed)) % 72) / 2)
						+ ((CASE WHEN dbo.Random(1, 10) < 10 THEN 0 ELSE 1 END) * (dbo.Random(-15, 15) / 10.00))	-- dogs (15 - 50 lbs) + / 1.5 lbs 1 in 10 
					ELSE
						2.00 + (ABS(CHECKSUM(A.Breed) % 21)) / 3
						+ ((CASE WHEN dbo.Random(1, 20) < 20 THEN 0 ELSE 1 END) * (dbo.Random(-10, 10) / 50.00))	-- rabbits (2 - 8 lbs) +/ 0.2 lbs 1 in 20
				END,
				1
			)	AS Weight,
		NULL	AS Comments,
		Staff.Email
FROM	(
			Animals	AS A
			LEFT OUTER JOIN
			Adoptions	AS AD
				ON	A.Name = AD.Name
					AND
					A.Species = AD.Species
		)
		INNER JOIN
		Reference.Species_Vital_Signs_Ranges AS SNR
			ON A.Species = SNR.Species
		CROSS JOIN 
		Reference.Calendar AS C
		CROSS APPLY (	SELECT	Email 
						FROM	Staff 
						WHERE	C.Date >= Staff.Hire_Date
								AND
								Email IN (SELECT Email FROM Staff_Assignments WHERE Role IN ('Veterinarian', 'Assistant'))
								-- Dirty shortcut but Emails are unique...
						ORDER BY NEWID() 
						OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
					 )	AS Staff
WHERE	C.Date BETWEEN @Shelter_Open AND @Last_Data_Day
		AND 
		C.Weekday BETWEEN 2 AND 6
		AND 
		C.US_Federal_Holiday IS NULL
		AND 
		(ABS(CHECKSUM(A.Name + A.Species)) % 5) + 2 = C.Weekday -- every animal checked weekly
		AND 
		C.Date >= A.Admission_Date -- only post admission
		AND 
		C.Date <= ISNULL(AD.Adoption_Date, @Last_Data_Day) -- only pre-adoption
		AND 
		ABS(CHECKSUM(A.Name + A.Species + CAST(C.Date AS VARCHAR(20))) % 100) > 74; -- only 1/4 of all possible combinations
*/

CREATE TABLE Vaccinations
(
	Name				VARCHAR(20)		NOT NULL,
	Species				VARCHAR(10)		NOT NULL,
	CONSTRAINT FK_Vaccinations__Animals
	FOREIGN KEY (Name, Species)
	REFERENCES Animals (Name, Species),
	Vaccination_Time	DATETIME2		NOT NULL,
	Vaccine				VARCHAR(50)		NOT NULL,
	CONSTRAINT FK_Vaccinations__Species_Vaccines 
		FOREIGN KEY (Species, Vaccine)
		REFERENCES Reference.Species_Vaccines (Species, Vaccine)
		ON UPDATE CASCADE 
		ON DELETE NO ACTION,
	Batch				VARCHAR(20)		NOT NULL,
	Comments			VARCHAR(500)	NULL,
	Email				VARCHAR(100)	NOT NULL
		REFERENCES Staff (Email)
		ON UPDATE CASCADE 
		ON DELETE NO ACTION,
	PRIMARY KEY (Name, Species, Vaccine, Vaccination_Time),
	INDEX NCIDX_FK_Vaccinations__Vaccines(Species, Vaccine),
	INDEX NCIDX_FK_Vaccinations__Staff(Email)
);

INSERT	INTO Vaccinations (Name, Species, Vaccination_Time, Vaccine, Batch, Comments, Email)
SELECT	A.Name,
		A.Species,
		DATEADD(MINUTE, (7 * 60) + dbo.Random(0, (8 * 60)), CAST(C.Date AS DATETIME2)) AS Vaccination_Time,
		V.Vaccine,
		CHAR(dbo.Random(ASCII('A'), ASCII('Z'))) + '-' + CAST(dbo.Random(500000000, 99000000) AS CHAR(9)),
		NULL,
		Staff.Email
FROM	(	Animals	AS A
			LEFT OUTER JOIN
			Adoptions AS AD
				ON	A.Name = AD.Name
					AND
					A.Species = AD.Species
		)
		INNER JOIN
		Reference.Species_Vaccines		AS V
			ON V.Species = A.Species
		CROSS JOIN 
		Reference.Calendar AS C
		CROSS APPLY
	(
		SELECT		Email
		FROM		Staff
		WHERE		C.Date >= Staff.Hire_Date	-- After hire date
					AND
					A.name IS NOT NULL AND V.Vaccine IS NOT NULL
					AND
					Email IN (SELECT Email FROM Staff_Assignments WHERE Role IN ('Veterinarian', 'Assistant'))
					-- Dirty shortcut but Emails are unique...
		ORDER BY	NEWID() OFFSET 0 ROWS FETCH NEXT 1 ROW ONLY
	)	AS Staff
WHERE	V.Species = A.Species
		AND 
		C.Date BETWEEN @Shelter_Open AND @Last_Data_Day
		AND 
		(ABS(CHECKSUM(A.Species + A.Name)) % 365) + 1 = C.Day_of_Year -- every animal vaccinated annualy
		AND 
		C.Weekday BETWEEN 2 AND 6 -- on weekdays only
		AND 
		C.US_Federal_Holiday IS NULL -- not on holidays
		AND 
		C.Date >= A.Admission_Date -- only post admission
		AND 
		C.Date <= ISNULL(AD.Adoption_Date, @Last_Data_Day) -- only pre-adoption
		AND 
		1 = CASE
				WHEN DATEDIFF(WEEK, A.Birth_Date, C.Date) NOT BETWEEN 14 AND 16 -- Parvo between 14 and 16 weeks only
					AND V.Vaccine = 'Parvovirus' THEN
					0
				ELSE
					1
			END
		AND 
		ABS(CHECKSUM(A.Name + V.Vaccine + CAST(C.Date AS VARCHAR(20))) % 100) > 66 -- only 1/3 of all possible combinations
		
-----------------------
-- Sanity check data --
-----------------------

SELECT		'Persons'	AS Table_Name,
			*
FROM		Persons
ORDER BY	Email OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

SELECT		'Staff' AS Table_Name,
			*
FROM		Staff
ORDER BY	Email OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

SELECT		'Staff_Assignments' AS Table_Name,
			*
FROM		Staff_Assignments
ORDER BY	Email OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

SELECT		'Animals'	AS Table_Name,
			*
FROM		Animals
ORDER BY	Species,
			Breed,
			Name OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

SELECT		'Adoptions' AS Table_Name,
			*
FROM		Adoptions
ORDER BY	Adoption_Date OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

--SELECT		'Routine_Checkups'	AS Table_Name,
--			*
--FROM		Routine_Checkups
--ORDER BY	Checkup_Time OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

SELECT		'Vaccinations'	AS Table_Name,
			*
FROM		Vaccinations
ORDER BY	Vaccination_Time OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;

SELECT	COUNT(*)		AS Num_Persons,
		MIN(Birth_Date) AS Min_Birth_Date,
		MAX(Birth_Date) AS Max_Birth_Date
FROM	Persons;

SELECT	COUNT(*)		AS Num_Staff,
		MIN(Hire_Date)	AS Min_Hire_Date,
		MAX(Hire_Date)	AS Max_Hire_Date
FROM	Staff;

SELECT	COUNT(*)		AS Num_Assignments,
		MIN(Assigned)	AS Min_A,
		MAX(Assigned)	AS Max_A
FROM	Staff_Assignments;

SELECT		Species,
			Breed,
			COUNT(*)	AS Num_Animals
FROM		Animals
GROUP BY	GROUPING SETS (Species), (Breed)
ORDER BY	Species,
			Breed,
			Num_Animals DESC;

--SELECT		COUNT(*) AS Total_Routine_Checkups
--FROM		Routine_Checkups;

SELECT		COUNT(*) AS Total_Vaccinations
FROM		Vaccinations AS V

SELECT	COUNT(*)			AS Num_Adoptions,
		MIN(Adoption_Date)	AS Min_Adoption_Date,
		MAX(Adoption_Date)	AS Max_Adoption_Date
FROM	Adoptions;

SELECT		Adopter_Email,
			COUNT(*)	AS Num_Adopted
FROM		Adoptions
GROUP BY	Adopter_Email;

--SELECT		A.Species,
--			COUNT(*)				AS Num_Rows,
--			MIN(RC.Temperature_F)	AS Min_Temp,
--			MAX(RC.Temperature_F)	AS Max_Temp,
--			AVG(RC.Temperature_F)	AS Avg_Temp,
--			MIN(RC.Heart_Rate)		AS Min_Heart,
--			MAX(RC.Heart_Rate)		AS Max_Heart,
--			AVG(RC.Heart_Rate)		AS Avg_Heart,
--			MIN(RC.Respiration)		AS Min_Resp,
--			MAX(RC.Respiration)		AS Max_Resp,
--			AVG(RC.Respiration)		AS Avg_Resp,
--			MIN(RC.Weight_Lbs)		AS Min_Weight,
--			MAX(RC.Weight_Lbs)		AS Max_Weight,
--			AVG(RC.Weight_Lbs)		AS Avg_Weight
--FROM		Routine_Checkups	AS RC
--			INNER JOIN
--			Animals				AS A
--			ON	A.Name = RC.Name
--				AND
--				A.Species = RC.Species
--GROUP BY	A.Species;

COMMIT TRANSACTION;
