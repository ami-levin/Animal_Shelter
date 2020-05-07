/*
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@ IMPORTANT - Each of my courses uses its own subset of the data and tables from this projcet.               @@
@@ If you are looking for the practice demo database I use in my courses, follow these links:                 @@
@@ 1. Query Processing - https://github.com/ami-levin/LinkedIn/tree/master/Query%20Processing/Demo%20Database @@ 
@@ 2. Window Functions - https://github.com/ami-levin/LinkedIn/tree/master/Window%20Functions/Demo%20Database @@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
*/

-- Create database and reference data tables
-- SQL Server

USE master;
GO

IF	DB_ID('Animal_Shelter') IS NOT NULL
BEGIN
	ALTER DATABASE Animal_Shelter SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE Animal_Shelter;
END;
GO

CREATE DATABASE Animal_Shelter;
GO

USE Animal_Shelter;
GO

CREATE SCHEMA Reference;
GO

-- Random convenience function
CREATE OR ALTER VIEW dbo.V_Random
AS
	SELECT	RAND()	AS Random;
GO

CREATE OR ALTER FUNCTION dbo.Random (@low INT, @high INT)
RETURNS INT
AS
BEGIN
	RETURN
		(
			SELECT	CASE
						WHEN @low >= 0 THEN
							@low + (Random * (@high - @low + 1))
						ELSE
							@low + (Random * (@high - @low + 2)) - 1 -- correct for rounding
					END
			FROM	V_Random
		);
END;
GO

-- Variable declaration
DECLARE @Min_Population		INT  = 10000;				-- Min population for a city to be included
DECLARE @Min_Date_Calendar	DATE = '19900101';			-- Calendar start date
DECLARE @Max_Date_Calendar	DATE = '20500101';			-- Calendar end date

-- Common person names in the US
-- Source https://names.mongabay.com/ (was all caps in source)
CREATE TABLE Reference.Common_Person_Names
(
	[Rank]	TINYINT		NOT NULL PRIMARY KEY,
	Surname VARCHAR(20) NOT NULL UNIQUE,
	Male	VARCHAR(20) NOT NULL UNIQUE,
	Female	VARCHAR(20) NOT NULL UNIQUE
);

INSERT	INTO Reference.Common_Person_Names ([Rank], Surname, Male, Female)
SELECT	n.RANK,
		LEFT(n.Surname, 1)	+ RIGHT(LOWER(n.Surname), LEN(n.Surname) - 1)	AS Surname,
		LEFT(n.Male, 1)		+ RIGHT(LOWER(n.Male), LEN(n.Male) - 1)			AS Male,
		LEFT(n.Female, 1)	+ RIGHT(LOWER(n.Female), LEN(n.Female) - 1)		AS Female
FROM
		(
			VALUES (1, 'SMITH', 'MARY', 'JAMES'), (2, 'JOHNSON', 'PATRICIA', 'JOHN'), (3, 'WILLIAMS', 'LINDA', 'ROBERT'), (4, 'BROWN', 'BARBARA', 'MICHAEL'),
				(5, 'JONES', 'ELIZABETH', 'WILLIAM'), (6, 'GARCIA', 'JENNIFER', 'DAVID'), (7, 'MILLER', 'MARIA', 'RICHARD'), (8, 'DAVIS', 'SUSAN', 'CHARLES'),
				(9, 'RODRIGUEZ', 'MARGARET', 'JOSEPH'), (10, 'MARTINEZ', 'DOROTHY', 'THOMAS'), (11, 'HERNANDEZ', 'LISA', 'CHRISTOPHER'), (12, 'LOPEZ', 'NANCY', 'DANIEL'),
				(13, 'GONZALEZ', 'KAREN', 'PAUL'), (14, 'WILSON', 'BETTY', 'MARK'), (15, 'ANDERSON', 'HELEN', 'DONALD'), (16, 'THOMAS', 'SANDRA', 'GEORGE'),
				(17, 'TAYLOR', 'DONNA', 'KENNETH'), (18, 'MOORE', 'CAROL', 'STEVEN'), (19, 'JACKSON', 'RUTH', 'EDWARD'), (20, 'MARTIN', 'SHARON', 'BRIAN'),
				(21, 'LEE', 'MICHELLE', 'RONALD'), (22, 'PEREZ', 'LAURA', 'ANTHONY'), (23, 'THOMPSON', 'SARAH', 'KEVIN'), (24, 'WHITE', 'KIMBERLY', 'JASON'),
				(25, 'HARRIS', 'DEBORAH', 'MATTHEW'), (26, 'SANCHEZ', 'JESSICA', 'GARY'), (27, 'CLARK', 'SHIRLEY', 'TIMOTHY'), (28, 'RAMIREZ', 'CYNTHIA', 'JOSE'),
				(29, 'LEWIS', 'ANGELA', 'LARRY'), (30, 'ROBINSON', 'MELISSA', 'JEFFREY'), (31, 'WALKER', 'BRENDA', 'FRANK'), (32, 'YOUNG', 'AMY', 'SCOTT'),
				(33, 'ALLEN', 'ANNA', 'ERIC'), (34, 'KING', 'REBECCA', 'STEPHEN'), (35, 'WRIGHT', 'VIRGINIA', 'ANDREW'), (36, 'SCOTT', 'KATHLEEN', 'RAYMOND'),
				(37, 'TORRES', 'PAMELA', 'GREGORY'), (38, 'NGUYEN', 'MARTHA', 'JOSHUA'), (39, 'HILL', 'DEBRA', 'JERRY'), (40, 'FLORES', 'AMANDA', 'DENNIS'),
				(41, 'GREEN', 'STEPHANIE', 'WALTER'), (42, 'ADAMS', 'CAROLYN', 'PATRICK'), (43, 'NELSON', 'CHRISTINE', 'PETER'), (44, 'BAKER', 'MARIE', 'HAROLD'),
				(45, 'HALL', 'JANET', 'DOUGLAS'), (46, 'RIVERA', 'CATHERINE', 'HENRY'), (47, 'CAMPBELL', 'FRANCES', 'CARL'), (48, 'MITCHELL', 'ANN', 'ARTHUR'),
				(49, 'CARTER', 'JOYCE', 'RYAN'), (50, 'ROBERTS', 'DIANE', 'ROGER'), (51, 'GOMEZ', 'ALICE', 'JOE'), (52, 'PHILLIPS', 'JULIE', 'JUAN'),
				(53, 'EVANS', 'HEATHER', 'JACK'), (54, 'TURNER', 'TERESA', 'ALBERT'), (55, 'DIAZ', 'DORIS', 'JONATHAN'), (56, 'PARKER', 'GLORIA', 'JUSTIN'),
				(57, 'CRUZ', 'EVELYN', 'TERRY'), (58, 'EDWARDS', 'JEAN', 'GERALD'), (59, 'COLLINS', 'CHERYL', 'KEITH'), (60, 'REYES', 'MILDRED', 'SAMUEL'),
				(61, 'STEWART', 'KATHERINE', 'WILLIE'), (62, 'MORRIS', 'JOAN', 'RALPH'), (63, 'MORALES', 'ASHLEY', 'LAWRENCE'), (64, 'MURPHY', 'JUDITH', 'NICHOLAS'),
				(65, 'COOK', 'ROSE', 'ROY'), (66, 'ROGERS', 'JANICE', 'BENJAMIN'), (67, 'GUTIERREZ', 'KELLY', 'BRUCE'), (68, 'ORTIZ', 'NICOLE', 'BRANDON'),
				(69, 'MORGAN', 'JUDY', 'ADAM'), (70, 'COOPER', 'CHRISTINA', 'HARRY'), (71, 'PETERSON', 'KATHY', 'FRED'), (72, 'BAILEY', 'THERESA', 'WAYNE'),
				(73, 'REED', 'BEVERLY', 'BILLY'), (74, 'KELLY', 'DENISE', 'STEVE'), (75, 'HOWARD', 'TAMMY', 'LOUIS'), (76, 'RAMOS', 'IRENE', 'JEREMY'),
				(77, 'KIM', 'JANE', 'AARON'), (78, 'COX', 'LORI', 'RANDY'), (79, 'WARD', 'RACHEL', 'HOWARD'), (80, 'RICHARDSON', 'MARILYN', 'EUGENE'),
				(81, 'WATSON', 'ANDREA', 'CARLOS'), (82, 'BROOKS', 'KATHRYN', 'RUSSELL'), (83, 'CHAVEZ', 'LOUISE', 'BOBBY'), (84, 'WOOD', 'SARA', 'VICTOR'),
				(85, 'JAMES', 'ANNE', 'MARTIN'), (86, 'BENNETT', 'JACQUELINE', 'ERNEST'), (87, 'GRAY', 'WANDA', 'PHILLIP'), (88, 'MENDOZA', 'BONNIE', 'TODD'),
				(89, 'RUIZ', 'JULIA', 'JESSE'), (90, 'HUGHES', 'RUBY', 'CRAIG'), (91, 'PRICE', 'LOIS', 'ALAN'), (92, 'ALVAREZ', 'TINA', 'SHAWN'),
				(93, 'CASTILLO', 'PHYLLIS', 'CLARENCE'), (94, 'SANDERS', 'NORMA', 'SEAN'), (95, 'PATEL', 'PAULA', 'PHILIP'), (96, 'MYERS', 'DIANA', 'CHRIS'),
				(97, 'LONG', 'ANNIE', 'JOHNNY'), (98, 'ROSS', 'LILLIAN', 'EARL'), (99, 'FOSTER', 'EMILY', 'JIMMY'), (100, 'JIMENEZ', 'ROBIN', 'ANTONIO')
		) AS n ([RANK], Surname, Female, Male);

-- Species
CREATE TABLE Reference.Species 
(
	Species VARCHAR(10) NOT NULL PRIMARY KEY
);

-- Populate with species accepted in shelter
INSERT INTO Reference.Species (Species)
VALUES ('Dog'), ('Cat'), ('Rabbit'),
('Ferret'), ('Raccoon');-- And a couple species for which we won't have any animals

-- Species vital signs normal ranges
CREATE TABLE Reference.Species_Vital_Signs_Ranges
(
	Species					VARCHAR(10)		NOT NULL PRIMARY KEY
		REFERENCES Reference.Species (Species),
	Temperature_Low			DECIMAL(4, 1)	NOT NULL,
	Temperature_High		DECIMAL(4, 1)	NOT NULL,
	Heart_Rate_Low			TINYINT			NOT NULL,
	Heart_Rate_high			TINYINT			NOT NULL,
	Respiratory_Rate_Low	TINYINT			NOT NULL,
	Respiratory_Rate_High	TINYINT			NOT NULL
);

-- Source - various online veterinary sources 
INSERT	INTO Reference.Species_Vital_Signs_Ranges
(Species, Temperature_Low, Temperature_High, Heart_Rate_Low, Heart_Rate_high, Respiratory_Rate_Low, Respiratory_Rate_High)
VALUES
('Dog', 99.5, 102.5, 60, 140, 10, 35),
('Cat', 99.5, 102.5, 140, 220, 20, 30),
('Rabbit', 100.5, 103.5, 120, 150, 30, 60);

-- Breeds
-- Sources:
-- https://en.wikipedia.org/wiki/Lists_of_breeds
-- https://github.com/paiv/fci-breeds/blob/master/fci-breeds.csv 
-- https://tica.org/breeds/browse-all-breeds
-- https://rabbitpedia.com/
CREATE TABLE Reference.Breeds
(
	Species VARCHAR(10)		NOT NULL
		REFERENCES Reference.Species (Species),
	Breed	VARCHAR(50)		NOT NULL,
	URL		VARCHAR(128)	NULL,
	PRIMARY KEY (Species, Breed),
	INDEX NCIDX_Breeds_Breed(Breed)
);

-- Populate Breeds
INSERT INTO Reference.Breeds (Species, Breed, URL)
SELECT	'Dog'												AS Species,
		LEFT(Breeds.Breed, 1) 
		+ RIGHT(LOWER(Breeds.Breed), LEN(Breeds.Breed) - 1) AS Breed,
		Breeds.URL
FROM
		(	-- Data source was all caps to begin with
			VALUES 
				('ENGLISH POINTER', 'http://www.fci.be/en/nomenclature/ENGLISH-POINTER-1.html'), ('ENGLISH SETTER', 'http://www.fci.be/en/nomenclature/ENGLISH-SETTER-2.html'),
				('KERRY BLUE TERRIER', 'http://www.fci.be/en/nomenclature/KERRY-BLUE-TERRIER-3.html'), ('CAIRN TERRIER', 'http://www.fci.be/en/nomenclature/CAIRN-TERRIER-4.html'),
				('ENGLISH COCKER SPANIEL', 'http://www.fci.be/en/nomenclature/ENGLISH-COCKER-SPANIEL-5.html'), ('GORDON SETTER', 'http://www.fci.be/en/nomenclature/GORDON-SETTER-6.html'),
				('AIREDALE TERRIER', 'http://www.fci.be/en/nomenclature/AIREDALE-TERRIER-7.html'), ('AUSTRALIAN TERRIER', 'http://www.fci.be/en/nomenclature/AUSTRALIAN-TERRIER-8.html'),
				('BEDLINGTON TERRIER', 'http://www.fci.be/en/nomenclature/BEDLINGTON-TERRIER-9.html'), ('BORDER TERRIER', 'http://www.fci.be/en/nomenclature/BORDER-TERRIER-10.html'),
				('BULL TERRIER', 'http://www.fci.be/en/nomenclature/BULL-TERRIER-11.html'), ('FOX TERRIER (SMOOTH)', 'http://www.fci.be/en/nomenclature/FOX-TERRIER-SMOOTH-12.html'),
				('ENGLISH TOY TERRIER (BLACK &TAN)', 'http://www.fci.be/en/nomenclature/ENGLISH-TOY-TERRIER-BLACK-TAN-13.html'), ('SWEDISH VALLHUND', 'http://www.fci.be/en/nomenclature/SWEDISH-VALLHUND-14.html'),
				('BELGIAN SHEPHERD', 'http://www.fci.be/en/nomenclature/BELGIAN-SHEPHERD-DOG-15.html'), ('OLD ENGLISH SHEEPDOG', 'http://www.fci.be/en/nomenclature/OLD-ENGLISH-SHEEPDOG-16.html'),
				('GRIFFON NIVERNAIS', 'http://www.fci.be/en/nomenclature/GRIFFON-NIVERNAIS-17.html'), ('BRIQUET GRIFFON VENDEEN', 'http://www.fci.be/en/nomenclature/BRIQUET-GRIFFON-VENDEEN-19.html'),
				('ARIEGEOIS', 'http://www.fci.be/en/nomenclature/ARIEGEOIS-20.html'), ('GASCON SAINTONGEOIS', 'http://www.fci.be/en/nomenclature/GASCON-SAINTONGEOIS-21.html'),
				('GREAT GASCONY BLUE', 'http://www.fci.be/en/nomenclature/GREAT-GASCONY-BLUE-22.html'), ('POITEVIN', 'http://www.fci.be/en/nomenclature/POITEVIN-24.html'), ('BILLY', 'http://www.fci.be/en/nomenclature/BILLY-25.html'),
				('ARTOIS HOUND', 'http://www.fci.be/en/nomenclature/ARTOIS-HOUND-28.html'), ('PORCELAINE', 'http://www.fci.be/en/nomenclature/PORCELAINE-30.html'),
				('SMALL BLUE GASCONY', 'http://www.fci.be/en/nomenclature/SMALL-BLUE-GASCONY-31.html'), ('BLUE GASCONY GRIFFON', 'http://www.fci.be/en/nomenclature/BLUE-GASCONY-GRIFFON-32.html'),
				('GRAND BASSET GRIFFON VENDEEN', 'http://www.fci.be/en/nomenclature/GRAND-BASSET-GRIFFON-VENDEEN-33.html'), ('NORMAN ARTESIEN BASSET', 'http://www.fci.be/en/nomenclature/NORMAN-ARTESIEN-BASSET-34.html'),
				('BLUE GASCONY BASSET', 'http://www.fci.be/en/nomenclature/BLUE-GASCONY-BASSET-35.html'), ('BASSET FAUVE DE BRETAGNE', 'http://www.fci.be/en/nomenclature/BASSET-FAUVE-DE-BRETAGNE-36.html'),
				('PORTUGUESE WATER', 'http://www.fci.be/en/nomenclature/PORTUGUESE-WATER-DOG-37.html'), ('WELSH CORGI (CARDIGAN)', 'http://www.fci.be/en/nomenclature/WELSH-CORGI-CARDIGAN-38.html'),
				('WELSH CORGI (PEMBROKE)', 'http://www.fci.be/en/nomenclature/WELSH-CORGI-PEMBROKE-39.html'), ('IRISH SOFT COATED WHEATEN TERRIER', 'http://www.fci.be/en/nomenclature/IRISH-SOFT-COATED-WHEATEN-TERRIER-40.html'),
				('YUGOSLAVIAN SHEPHERD DOG - SHARPLANINA', 'http://www.fci.be/en/nomenclature/YUGOSLAVIAN-SHEPHERD-DOG-SHARPLANINA-41.html'), ('JÄMTHUND', 'http://www.fci.be/en/nomenclature/JAMTHUND-42.html'),
				('BASENJI', 'http://www.fci.be/en/nomenclature/BASENJI-43.html'), ('BERGER DE BEAUCE', 'http://www.fci.be/en/nomenclature/BERGER-DE-BEAUCE-44.html'),
				('BERNESE MOUNTAIN', 'http://www.fci.be/en/nomenclature/BERNESE-MOUNTAIN-DOG-45.html'), ('APPENZELL CATTLE', 'http://www.fci.be/en/nomenclature/APPENZELL-CATTLE-DOG-46.html'),
				('ENTLEBUCH CATTLE', 'http://www.fci.be/en/nomenclature/ENTLEBUCH-CATTLE-DOG-47.html'), ('KARELIAN BEAR', 'http://www.fci.be/en/nomenclature/KARELIAN-BEAR-DOG-48.html'),
				('FINNISH SPITZ', 'http://www.fci.be/en/nomenclature/FINNISH-SPITZ-49.html'), ('NEWFOUNDLAND', 'http://www.fci.be/en/nomenclature/NEWFOUNDLAND-50.html'),
				('FINNISH HOUND', 'http://www.fci.be/en/nomenclature/FINNISH-HOUND-51.html'), ('POLISH HOUND', 'http://www.fci.be/en/nomenclature/POLISH-HOUND-52.html'),
				('KOMONDOR', 'http://www.fci.be/en/nomenclature/KOMONDOR-53.html'), ('KUVASZ', 'http://www.fci.be/en/nomenclature/KUVASZ-54.html'),
				('PULI', 'http://www.fci.be/en/nomenclature/PULI-55.html'), ('PUMI', 'http://www.fci.be/en/nomenclature/PUMI-56.html'),
				('HUNGARIAN SHORT-HAIRED POINTER (VIZSLA)', 'http://www.fci.be/en/nomenclature/HUNGARIAN-SHORT-HAIRED-POINTER-VIZSLA-57.html'), ('GREAT SWISS MOUNTAIN', 'http://www.fci.be/en/nomenclature/GREAT-SWISS-MOUNTAIN-DOG-58.html'),
				('SWISS HOUND', 'http://www.fci.be/en/nomenclature/SWISS-HOUND-59.html'), ('SMALL SWISS HOUND', 'http://www.fci.be/en/nomenclature/SMALL-SWISS-HOUND-60.html'),
				('ST. BERNARD', 'http://www.fci.be/en/nomenclature/ST-BERNARD-61.html'), ('COARSE-HAIRED STYRIAN HOUND', 'http://www.fci.be/en/nomenclature/COARSE-HAIRED-STYRIAN-HOUND-62.html'),
				('AUSTRIAN BLACK AND TAN HOUND', 'http://www.fci.be/en/nomenclature/AUSTRIAN-BLACK-AND-TAN-HOUND-63.html'), ('AUSTRIAN PINSCHER', 'http://www.fci.be/en/nomenclature/AUSTRIAN-PINSCHER-64.html'),
				('MALTESE', 'http://www.fci.be/en/nomenclature/MALTESE-65.html'), ('FAWN BRITTANY GRIFFON', 'http://www.fci.be/en/nomenclature/FAWN-BRITTANY-GRIFFON-66.html'),
				('PETIT BASSET GRIFFON VENDEEN', 'http://www.fci.be/en/nomenclature/PETIT-BASSET-GRIFFON-VENDEEN-67.html'), ('TYROLEAN HOUND', 'http://www.fci.be/en/nomenclature/YROLEAN-HOUND-68.html'),
				('LAKELAND TERRIER', 'http://www.fci.be/en/nomenclature/LAKELAND-TERRIER-70.html'), ('MANCHESTER TERRIER', 'http://www.fci.be/en/nomenclature/MANCHESTER-TERRIER-71.html'),
				('NORWICH TERRIER', 'http://www.fci.be/en/nomenclature/NORWICH-TERRIER-72.html'), ('SCOTTISH TERRIER', 'http://www.fci.be/en/nomenclature/SCOTTISH-TERRIER-73.html'),
				('SEALYHAM TERRIER', 'http://www.fci.be/en/nomenclature/SEALYHAM-TERRIER-74.html'), ('SKYE TERRIER', 'http://www.fci.be/en/nomenclature/SKYE-TERRIER-75.html'),
				('STAFFORDSHIRE BULL TERRIER', 'http://www.fci.be/en/nomenclature/STAFFORDSHIRE-BULL-TERRIER-76.html'), 
				('CONTINENTAL TOY SPANIEL', 'http://www.fci.be/en/nomenclature/CONTINENTAL-TOY-SPANIEL-77.html'),
				('WELSH TERRIER', 'http://www.fci.be/en/nomenclature/WELSH-TERRIER-78.html'), ('GRIFFON BRUXELLOIS', 'http://www.fci.be/en/nomenclature/GRIFFON-BRUXELLOIS-80.html'),
				('GRIFFON BELGE', 'http://www.fci.be/en/nomenclature/GRIFFON-BELGE-81.html'), ('PETIT BRABANÇON', 'http://www.fci.be/en/nomenclature/PETIT-BRABANCON-82.html'),
				('SCHIPPERKE', 'http://www.fci.be/en/nomenclature/SCHIPPERKE-83.html'), ('BLOODHOUND', 'http://www.fci.be/en/nomenclature/BLOODHOUND-84.html'),
				('WEST HIGHLAND WHITE TERRIER', 'http://www.fci.be/en/nomenclature/WEST-HIGHLAND-WHITE-TERRIER-85.html'), 
				('YORKSHIRE TERRIER', 'http://www.fci.be/en/nomenclature/YORKSHIRE-TERRIER-86.html'),
				('CATALAN SHEEPDOG', 'http://www.fci.be/en/nomenclature/CATALAN-SHEEPDOG-87.html'), ('SHETLAND SHEEPDOG', 'http://www.fci.be/en/nomenclature/SHETLAND-SHEEPDOG-88.html'),
				('IBIZAN PODENCO', 'http://www.fci.be/en/nomenclature/IBIZAN-PODENCO-89.html'), ('BURGOS POINTING', 'http://www.fci.be/en/nomenclature/BURGOS-POINTING-DOG-90.html'),
				('SPANISH MASTIFF', 'http://www.fci.be/en/nomenclature/SPANISH-MASTIFF-91.html'),
				('PYRENEAN MASTIFF', 'http://www.fci.be/en/nomenclature/PYRENEAN-MASTIFF-92.html'),
				('PORTUGUESE SHEEPDOG', 'http://www.fci.be/en/nomenclature/PORTUGUESE-SHEEPDOG-93.html'), ('PORTUGUESE WARREN HOUND-PORTUGUESE PODENGO', 'http://www.fci.be/en/nomenclature/PORTUGUESE-WARREN-HOUND-PORTUGUESE-PODENGO-94.html'),
				('BRITTANY SPANIEL', 'http://www.fci.be/en/nomenclature/BRITTANY-SPANIEL-95.html'), ('RAFEIRO OF ALENTEJO', 'http://www.fci.be/en/nomenclature/RAFEIRO-OF-ALENTEJO-96.html'),
				('GERMAN SPITZ', 'http://www.fci.be/en/nomenclature/GERMAN-SPITZ-97.html'), ('GERMAN WIRE- HAIRED POINTING', 'http://www.fci.be/en/nomenclature/GERMAN-WIRE-HAIRED-POINTING-DOG-98.html'),
				('WEIMARANER', 'http://www.fci.be/en/nomenclature/WEIMARANER-99.html'), ('WESTPHALIAN DACHSBRACKE', 'http://www.fci.be/en/nomenclature/WESTPHALIAN-DACHSBRACKE-100.html'),
				('FRENCH BULLDOG', 'http://www.fci.be/en/nomenclature/FRENCH-BULLDOG-101.html'), ('KLEINER MÜNSTERLÄNDER', 'http://www.fci.be/en/nomenclature/KLEINER-MUNSTERLANDER-102.html'),
				('GERMAN HUNTING TERRIER', 'http://www.fci.be/en/nomenclature/GERMAN-HUNTING-TERRIER-103.html'), ('GERMAN SPANIEL', 'http://www.fci.be/en/nomenclature/GERMAN-SPANIEL-104.html'),
				('FRENCH WATER', 'http://www.fci.be/en/nomenclature/FRENCH-WATER-DOG-105.html'), ('BLUE PICARDY SPANIEL', 'http://www.fci.be/en/nomenclature/BLUE-PICARDY-SPANIEL-106.html'),
				('WIRE-HAIRED POINTING GRIFFON KORTHALS', 'http://www.fci.be/en/nomenclature/WIRE-HAIRED-POINTING-GRIFFON-KORTHALS-107.html'), ('PICARDY SPANIEL', 'http://www.fci.be/en/nomenclature/PICARDY-SPANIEL-108.html'),
				('CLUMBER SPANIEL', 'http://www.fci.be/en/nomenclature/CLUMBER-SPANIEL-109.html'), ('CURLY COATED RETRIEVER', 'http://www.fci.be/en/nomenclature/CURLY-COATED-RETRIEVER-110.html'),
				('GOLDEN RETRIEVER', 'http://www.fci.be/en/nomenclature/GOLDEN-RETRIEVER-111.html'), ('BRIARD', 'http://www.fci.be/en/nomenclature/BRIARD-113.html'),
				('PONT-AUDEMER SPANIEL', 'http://www.fci.be/en/nomenclature/PONT-AUDEMER-SPANIEL-114.html'), ('SAINT GERMAIN POINTER', 'http://www.fci.be/en/nomenclature/SAINT-GERMAIN-POINTER-115.html'),
				('DOGUE DE BORDEAUX', 'http://www.fci.be/en/nomenclature/DOGUE-DE-BORDEAUX-116.html'), ('DEUTSCH LANGHAAR', 'http://www.fci.be/en/nomenclature/DEUTSCH-LANGHAAR-117.html'),
				('LARGE MUNSTERLANDER', 'http://www.fci.be/en/nomenclature/LARGE-MUNSTERLANDER-118.html'), ('GERMAN SHORT- HAIRED POINTING', 'http://www.fci.be/en/nomenclature/GERMAN-SHORT-HAIRED-POINTING-DOG-119.html'),
				('IRISH RED SETTER', 'http://www.fci.be/en/nomenclature/IRISH-RED-SETTER-120.html'), ('FLAT COATED RETRIEVER', 'http://www.fci.be/en/nomenclature/FLAT-COATED-RETRIEVER-121.html'),
				('LABRADOR RETRIEVER', 'http://www.fci.be/en/nomenclature/LABRADOR-RETRIEVER-122.html'), ('FIELD SPANIEL', 'http://www.fci.be/en/nomenclature/FIELD-SPANIEL-123.html'),
				('IRISH WATER SPANIEL', 'http://www.fci.be/en/nomenclature/IRISH-WATER-SPANIEL-124.html'), ('ENGLISH SPRINGER SPANIEL', 'http://www.fci.be/en/nomenclature/ENGLISH-SPRINGER-SPANIEL-125.html'),
				('WELSH SPRINGER SPANIEL', 'http://www.fci.be/en/nomenclature/WELSH-SPRINGER-SPANIEL-126.html'), ('SUSSEX SPANIEL', 'http://www.fci.be/en/nomenclature/SUSSEX-SPANIEL-127.html'),
				('KING CHARLES SPANIEL', 'http://www.fci.be/en/nomenclature/KING-CHARLES-SPANIEL-128.html'), ('SMÅLANDSSTÖVARE', 'http://www.fci.be/en/nomenclature/SMALANDSSTOVARE-129.html'),
				('DREVER', 'http://www.fci.be/en/nomenclature/DREVER-130.html'), ('SCHILLERSTÖVARE', 'http://www.fci.be/en/nomenclature/SCHILLERSTOVARE-131.html'),
				('HAMILTONSTÖVARE', 'http://www.fci.be/en/nomenclature/HAMILTONSTOVARE-132.html'), ('FRENCH POINTING DOG - GASCOGNE TYPE', 'http://www.fci.be/en/nomenclature/FRENCH-POINTING-DOG-GASCOGNE-TYPE-133.html'),
				('FRENCH POINTING DOG - PYRENEAN TYPE', 'http://www.fci.be/en/nomenclature/FRENCH-POINTING-DOG-PYRENEAN-TYPE-134.html'), ('SWEDISH LAPPHUND', 'http://www.fci.be/en/nomenclature/SWEDISH-LAPPHUND-135.html'),
				('CAVALIER KING CHARLES SPANIEL', 'http://www.fci.be/en/nomenclature/CAVALIER-KING-CHARLES-SPANIEL-136.html'), ('PYRENEAN MOUNTAIN', 'http://www.fci.be/en/nomenclature/PYRENEAN-MOUNTAIN-DOG-137.html'),
				('PYRENEAN SHEEPDOG - SMOOTH FACED', 'http://www.fci.be/en/nomenclature/PYRENEAN-SHEEPDOG-SMOOTH-FACED-138.html'), ('IRISH TERRIER', 'http://www.fci.be/en/nomenclature/IRISH-TERRIER-139.html'), 
				('BOSTON TERRIER', 'http://www.fci.be/en/nomenclature/BOSTON-TERRIER-140.html'), ('LONG-HAIRED PYRENEAN SHEEPDOG', 'http://www.fci.be/en/nomenclature/LONG-HAIRED-PYRENEAN-SHEEPDOG-141.html'),
				('SLOVAKIAN CHUVACH', 'http://www.fci.be/en/nomenclature/SLOVAKIAN-CHUVACH-142.html'), 
				('DOBERMANN', 'http://www.fci.be/en/nomenclature/DOBERMANN-143.html'),
				('BOXER', 'http://www.fci.be/en/nomenclature/BOXER-144.html'), ('LEONBERGER', 'http://www.fci.be/en/nomenclature/LEONBERGER-145.html'),
				('RHODESIAN RIDGEBACK', 'http://www.fci.be/en/nomenclature/RHODESIAN-RIDGEBACK-146.html'), ('ROTTWEILER', 'http://www.fci.be/en/nomenclature/ROTTWEILER-147.html'),
				('DACHSHUND', 'http://www.fci.be/en/nomenclature/DACHSHUND-148.html'), ('BULLDOG', 'http://www.fci.be/en/nomenclature/BULLDOG-149.html'),
				('SERBIAN HOUND', 'http://www.fci.be/en/nomenclature/SERBIAN-HOUND-150.html'), ('ISTRIAN SHORT-HAIRED HOUND', 'http://www.fci.be/en/nomenclature/ISTRIAN-SHORT-HAIRED-HOUND-151.html'),
				('ISTRIAN WIRE-HAIRED HOUND', 'http://www.fci.be/en/nomenclature/ISTRIAN-WIRE-HAIRED-HOUND-152.html'), ('DALMATIAN', 'http://www.fci.be/en/nomenclature/DALMATIAN-153.html'),
				('POSAVATZ HOUND', 'http://www.fci.be/en/nomenclature/POSAVATZ-HOUND-154.html'), ('BOSNIAN BROKEN-HAIRED HOUND - CALLED BARAK', 'http://www.fci.be/en/nomenclature/BOSNIAN-BROKEN-HAIRED-HOUND-CALLED-BARAK-155.html'),
				('COLLIE ROUGH', 'http://www.fci.be/en/nomenclature/COLLIE-ROUGH-156.html'), 
				('BULLMASTIFF', 'http://www.fci.be/en/nomenclature/BULLMASTIFF-157.html'),
				('GREYHOUND', 'http://www.fci.be/en/nomenclature/GREYHOUND-158.html'), ('ENGLISH FOXHOUND', 'http://www.fci.be/en/nomenclature/ENGLISH-FOXHOUND-159.html'),
				('IRISH WOLFHOUND', 'http://www.fci.be/en/nomenclature/IRISH-WOLFHOUND-160.html'), 
				('BEAGLE', 'http://www.fci.be/en/nomenclature/BEAGLE-161.html'),
				('WHIPPET', 'http://www.fci.be/en/nomenclature/WHIPPET-162.html'), ('BASSET HOUND', 'http://www.fci.be/en/nomenclature/BASSET-HOUND-163.html'),
				('DEERHOUND', 'http://www.fci.be/en/nomenclature/DEERHOUND-164.html'), ('ITALIAN SPINONE', 'http://www.fci.be/en/nomenclature/ITALIAN-SPINONE-165.html'),
				('GERMAN SHEPHERD', 'http://www.fci.be/en/nomenclature/GERMAN-SHEPHERD-DOG-166.html'), ('AMERICAN COCKER SPANIEL', 'http://www.fci.be/en/nomenclature/AMERICAN-COCKER-SPANIEL-167.html'),
				('DANDIE DINMONT TERRIER', 'http://www.fci.be/en/nomenclature/DANDIE-DINMONT-TERRIER-168.html'), ('FOX TERRIER (WIRE)', 'http://www.fci.be/en/nomenclature/FOX-TERRIER-WIRE-169.html'),
				('CASTRO LABOREIRO', 'http://www.fci.be/en/nomenclature/CASTRO-LABOREIRO-DOG-170.html'), ('BOUVIER DES ARDENNES', 'http://www.fci.be/en/nomenclature/BOUVIER-DES-ARDENNES-171.html'),
				('POODLE', 'http://www.fci.be/en/nomenclature/POODLE-172.html'), ('ESTRELA MOUNTAIN', 'http://www.fci.be/en/nomenclature/ESTRELA-MOUNTAIN-DOG-173.html'),
				('FRENCH SPANIEL', 'http://www.fci.be/en/nomenclature/FRENCH-SPANIEL-175.html'), ('PICARDY SHEEPDOG', 'http://www.fci.be/en/nomenclature/PICARDY-SHEEPDOG-176.html'),
				('ARIEGE POINTING', 'http://www.fci.be/en/nomenclature/ARIEGE-POINTING-DOG-177.html'), ('BOURBONNAIS POINTING', 'http://www.fci.be/en/nomenclature/BOURBONNAIS-POINTING-DOG-179.html'),
				('AUVERGNE POINTER', 'http://www.fci.be/en/nomenclature/AUVERGNE-POINTER-180.html'), 
				('GIANT SCHNAUZER', 'http://www.fci.be/en/nomenclature/GIANT-SCHNAUZER-181.html'),
				('SCHNAUZER', 'http://www.fci.be/en/nomenclature/SCHNAUZER-182.html'), ('MINIATURE SCHNAUZER', 'http://www.fci.be/en/nomenclature/MINIATURE-SCHNAUZER-183.html'),
				('GERMAN PINSCHER', 'http://www.fci.be/en/nomenclature/GERMAN-PINSCHER-184.html'), ('MINIATURE PINSCHER', 'http://www.fci.be/en/nomenclature/MINIATURE-PINSCHER-185.html'),
				('AFFENPINSCHER', 'http://www.fci.be/en/nomenclature/AFFENPINSCHER-186.html'), ('PORTUGUESE POINTING', 'http://www.fci.be/en/nomenclature/PORTUGUESE-POINTING-DOG-187.html'),
				('SLOUGHI', 'http://www.fci.be/en/nomenclature/SLOUGHI-188.html'), ('FINNISH LAPPONIAN', 'http://www.fci.be/en/nomenclature/FINNISH-LAPPONIAN-DOG-189.html'),
				('HOVAWART', 'http://www.fci.be/en/nomenclature/HOVAWART-190.html'), ('BOUVIER DES FLANDRES', 'http://www.fci.be/en/nomenclature/BOUVIER-DES-FLANDRES-191.html'),
				('KROMFOHRLÄNDER', 'http://www.fci.be/en/nomenclature/KROMFOHRLANDER-192.html'), ('BORZOI - RUSSIAN HUNTING SIGHTHOUND', 'http://www.fci.be/en/nomenclature/BORZOI-RUSSIAN-HUNTING-SIGHTHOUND-193.html'),
				('BERGAMASCO SHEPHERD', 'http://www.fci.be/en/nomenclature/BERGAMASCO-SHEPHERD-DOG-194.html'), ('ITALIAN VOLPINO', 'http://www.fci.be/en/nomenclature/ITALIAN-VOLPINO-195.html'),
				('BOLOGNESE', 'http://www.fci.be/en/nomenclature/BOLOGNESE-196.html'), 
				('NEAPOLITAN MASTIFF', 'http://www.fci.be/en/nomenclature/NEAPOLITAN-MASTIFF-197.html'),
				('ITALIAN ROUGH-HAIRED SEGUGIO', 'http://www.fci.be/en/nomenclature/ITALIAN-ROUGH-HAIRED-SEGUGIO-198.html'), ('CIRNECO DELL''ETNA', 'http://www.fci.be/en/nomenclature/CIRNECO-DELL-ETNA-199.html'),
				('ITALIAN SIGHTHOUND', 'http://www.fci.be/en/nomenclature/ITALIAN-SIGHTHOUND-200.html'), ('MAREMMA AND THE ABRUZZES SHEEPDOG', 'http://www.fci.be/en/nomenclature/MAREMMA-AND-THE-ABRUZZES-SHEEPDOG-201.html'),
				('ITALIAN POINTING', 'http://www.fci.be/en/nomenclature/ITALIAN-POINTING-DOG-202.html'), ('NORWEGIAN HOUND', 'http://www.fci.be/en/nomenclature/NORWEGIAN-HOUND-203.html'),
				('SPANISH HOUND', 'http://www.fci.be/en/nomenclature/SPANISH-HOUND-204.html'), 
				('CHOW CHOW', 'http://www.fci.be/en/nomenclature/CHOW-CHOW-205.html'),
				('JAPANESE CHIN', 'http://www.fci.be/en/nomenclature/JAPANESE-CHIN-206.html'), ('PEKINGESE', 'http://www.fci.be/en/nomenclature/PEKINGESE-207.html'),
				('SHIH TZU', 'http://www.fci.be/en/nomenclature/SHIH-TZU-208.html'), ('TIBETAN TERRIER', 'http://www.fci.be/en/nomenclature/TIBETAN-TERRIER-209.html'),
				('CANADIAN ESKIMO', 'http://www.fci.be/en/nomenclature/CANADIAN-ESKIMO-DOG-211.html'), 
				('SAMOYED', 'http://www.fci.be/en/nomenclature/SAMOYED-212.html'),
				('HANOVERIAN SCENT HOUND', 'http://www.fci.be/en/nomenclature/HANOVERIAN-SCENT-HOUND-213.html'), ('HELLENIC HOUND', 'http://www.fci.be/en/nomenclature/HELLENIC-HOUND-214.html'),
				('BICHON FRISE', 'http://www.fci.be/en/nomenclature/BICHON-FRISE-215.html'), ('PUDELPOINTER', 'http://www.fci.be/en/nomenclature/PUDELPOINTER-216.html'),
				('BAVARIAN MOUNTAIN SCENT HOUND', 'http://www.fci.be/en/nomenclature/BAVARIAN-MOUNTAIN-SCENT-HOUND-217.html'), 
				('CHIHUAHUA', 'http://www.fci.be/en/nomenclature/CHIHUAHUA-218.html'),
				('FRENCH TRICOLOUR HOUND', 'http://www.fci.be/en/nomenclature/FRENCH-TRICOLOUR-HOUND-219.html'), ('FRENCH WHITE & BLACK HOUND', 'http://www.fci.be/en/nomenclature/FRENCH-WHITE-BLACK-HOUND-220.html'),
				('FRISIAN WATER', 'http://www.fci.be/en/nomenclature/FRISIAN-WATER-DOG-221.html'), ('STABIJHOUN', 'http://www.fci.be/en/nomenclature/STABIJHOUN-222.html'),
				('DUTCH SHEPHERD', 'http://www.fci.be/en/nomenclature/DUTCH-SHEPHERD-DOG-223.html'), ('DRENTSCHE PARTRIDGE', 'http://www.fci.be/en/nomenclature/DRENTSCHE-PARTRIDGE-DOG-224.html'),
				('FILA BRASILEIRO', 'http://www.fci.be/en/nomenclature/FILA-BRASILEIRO-225.html'), ('LANDSEER (EUROPEAN CONTINENTAL TYPE)', 'http://www.fci.be/en/nomenclature/LANDSEER-EUROPEAN-CONTINENTAL-TYPE-226.html'),
				('LHASA APSO', 'http://www.fci.be/en/nomenclature/LHASA-APSO-227.html'), ('AFGHAN HOUND', 'http://www.fci.be/en/nomenclature/AFGHAN-HOUND-228.html'),
				('SERBIAN TRICOLOUR HOUND', 'http://www.fci.be/en/nomenclature/SERBIAN-TRICOLOUR-HOUND-229.html'), ('TIBETAN MASTIFF', 'http://www.fci.be/en/nomenclature/TIBETAN-MASTIFF-230.html'),
				 ('TIBETAN SPANIEL', 'http://www.fci.be/en/nomenclature/TIBETAN-SPANIEL-231.html'), ('DEUTSCH STICHELHAAR', 'http://www.fci.be/en/nomenclature/DEUTSCH-STICHELHAAR-232.html'),
				('LITTLE LION', 'http://www.fci.be/en/nomenclature/LITTLE-LION-DOG-233.html'), ('XOLOITZCUINTLE', 'http://www.fci.be/en/nomenclature/XOLOITZCUINTLE-234.html'),
				('GREAT DANE', 'http://www.fci.be/en/nomenclature/GREAT-DANE-235.html'), ('AUSTRALIAN SILKY TERRIER', 'http://www.fci.be/en/nomenclature/AUSTRALIAN-SILKY-TERRIER-236.html'),
				('NORWEGIAN BUHUND', 'http://www.fci.be/en/nomenclature/NORWEGIAN-BUHUND-237.html'), ('MUDI', 'http://www.fci.be/en/nomenclature/MUDI-238.html'),
				('HUNGARIAN WIRE-HAIRED POINTER', 'http://www.fci.be/en/nomenclature/HUNGARIAN-WIRE-HAIRED-POINTER-239.html'), ('HUNGARIAN GREYHOUND', 'http://www.fci.be/en/nomenclature/HUNGARIAN-GREYHOUND-240.html'),
				('HUNGARIAN HOUND - TRANSYLVANIAN SCENT HOUND', 'http://www.fci.be/en/nomenclature/HUNGARIAN-HOUND-TRANSYLVANIAN-SCENT-HOUND-241.html'), ('NORWEGIAN ELKHOUND GREY', 'http://www.fci.be/en/nomenclature/NORWEGIAN-ELKHOUND-GREY-242.html'),
				('ALASKAN MALAMUTE', 'http://www.fci.be/en/nomenclature/ALASKAN-MALAMUTE-243.html'), ('SLOVAKIAN HOUND', 'http://www.fci.be/en/nomenclature/SLOVAKIAN-HOUND-244.html'),
				('BOHEMIAN WIRE-HAIRED POINTING GRIFFON', 'http://www.fci.be/en/nomenclature/BOHEMIAN-WIRE-HAIRED-POINTING-GRIFFON-245.html' ), ('CESKY TERRIER', 'http://www.fci.be/en/nomenclature/CESKY-TERRIER-246.html'),
				('ATLAS MOUNTAIN DOG (AIDI)', 'http://www.fci.be/en/nomenclature/ATLAS-MOUNTAIN-DOG-AIDI-247.html'), ('PHARAOH HOUND', 'http://www.fci.be/en/nomenclature/PHARAOH-HOUND-248.html'),
				('MAJORCA MASTIFF', 'http://www.fci.be/en/nomenclature/MAJORCA-MASTIFF-249.html'), ('HAVANESE', 'http://www.fci.be/en/nomenclature/HAVANESE-250.html'),
				('POLISH LOWLAND SHEEPDOG', 'http://www.fci.be/en/nomenclature/POLISH-LOWLAND-SHEEPDOG-251.html'), ('TATRA SHEPHERD', 'http://www.fci.be/en/nomenclature\TATRA-SHEPHERD-DOG-252.html'),
				('PUG', 'http://www.fci.be/en/nomenclature/PUG-253.html'), ('ALPINE DACHSBRACKE', 'http://www.fci.be/en/nomenclature/ALPINE-DACHSBRACKE-254.html'),
				('AKITA', 'http://www.fci.be/en/nomenclature/AKITA-255.html'), ('SHIBA', 'http://www.fci.be/en/nomenclature/SHIBA-257.html'),
				('JAPANESE TERRIER', 'http://www.fci.be/en/nomenclature/JAPANESE-TERRIER-259.html'), ('TOSA', 'http://www.fci.be/en/nomenclature\TOSA-260.html'),
				('HOKKAIDO', 'http://www.fci.be/en/nomenclature/HOKKAIDO-261.html'), ('JAPANESE SPITZ', 'http://www.fci.be/en/nomenclature/JAPANESE-SPITZ-262.html'),
				('CHESAPEAKE BAY RETRIEVER', 'http://www.fci.be/en/nomenclature/CHESAPEAKE-BAY-RETRIEVER-263.html'), ('MASTIFF', 'http://www.fci.be/en/nomenclature/MASTIFF-264.html'),
				('NORWEGIAN LUNDEHUND', 'http://www.fci.be/en/nomenclature/NORWEGIAN-LUNDEHUND-265.html'), ('HYGEN HOUND', 'http://www.fci.be/en/nomenclature/HYGEN-HOUND-266.html'),
				('HALDEN HOUND', 'http://www.fci.be/en/nomenclature/HALDEN-HOUND-267.html'), ('NORWEGIAN ELKHOUND BLACK', 'http://www.fci.be/en/nomenclature/NORWEGIAN-ELKHOUND-BLACK-268.html'),
				('SALUKI', 'http://www.fci.be/en/nomenclature/SALUKI-269.html'), 
				('SIBERIAN HUSKY', 'http://www.fci.be/en/nomenclature/SIBERIAN-HUSKY-270.html'),
				('BEARDED COLLIE', 'http://www.fci.be/en/nomenclature/BEARDED-COLLIE-271.html'), ('NORFOLK TERRIER', 'http://www.fci.be/en/nomenclature/NORFOLK-TERRIER-272.html'),
				('CANAAN', 'http://www.fci.be/en/nomenclature/CANAAN-DOG-273.html'), ('GREENLAND', 'http://www.fci.be/en/nomenclature/GREENLAND-DOG-274.html'),
				('NORRBOTTENSPITZ', 'http://www.fci.be/en/nomenclature/NORRBOTTENSPITZ-276.html'), ('CROATIAN SHEPHERD', 'http://www.fci.be/en/nomenclature/CROATIAN-SHEPHERD-DOG-277.html'),
				('KARST SHEPHERD', 'http://www.fci.be/en/nomenclature/KARST-SHEPHERD-DOG-278.html'), ('MONTENEGRIN MOUNTAIN HOUND', 'http://www.fci.be/en/nomenclature/MONTENEGRIN-MOUNTAIN-HOUND-279.html'),
				('OLD DANISH POINTING', 'http://www.fci.be/en/nomenclature/OLD-DANISH-POINTING-DOG-281.html'), ('GRAND GRIFFON VENDEEN', 'http://www.fci.be/en/nomenclature/GRAND-GRIFFON-VENDEEN-282.html'),
				('COTON DE TULEAR', 'http://www.fci.be/en/nomenclature/COTON-DE-TULEAR-283.html'), ('LAPPONIAN HERDER', 'http://www.fci.be/en/nomenclature/LAPPONIAN-HERDER-284.html'),
				('SPANISH GREYHOUND', 'http://www.fci.be/en/nomenclature/SPANISH-GREYHOUND-285.html'), 
				('AMERICAN STAFFORDSHIRE TERRIER', 'http://www.fci.be/en/nomenclature/AMERICAN-STAFFORDSHIRE-TERRIER-286.html'),
				('AUSTRALIAN CATTLE', 'http://www.fci.be/en/nomenclature/AUSTRALIAN-CATTLE-DOG-287.html'), ('CHINESE CRESTED', 'http://www.fci.be/en/nomenclature/CHINESE-CRESTED-DOG-288.html'),
				('ICELANDIC SHEEPDOG', 'http://www.fci.be/en/nomenclature/ICELANDIC-SHEEPDOG-289.html'), 
				('BEAGLE HARRIER', 'http://www.fci.be/en/nomenclature/BEAGLE-HARRIER-290.html'),
				('EURASIAN', 'http://www.fci.be/en/nomenclature/EURASIAN-291.html'), ('DOGO ARGENTINO', 'http://www.fci.be/en/nomenclature/DOGO-ARGENTINO-292.html'),
				('AUSTRALIAN KELPIE', 'http://www.fci.be/en/nomenclature/AUSTRALIAN-KELPIE-293.html'), ('OTTERHOUND', 'http://www.fci.be/en/nomenclature/OTTERHOUND-294.html'),
				('HARRIER', 'http://www.fci.be/en/nomenclature/HARRIER-295.html'), ('COLLIE SMOOTH', 'http://www.fci.be/en/nomenclature/COLLIE-SMOOTH-296.html'),
				('BORDER COLLIE', 'http://www.fci.be/en/nomenclature/BORDER-COLLIE-297.html'), ('ROMAGNA WATER', 'http://www.fci.be/en/nomenclature/ROMAGNA-WATER-DOG-298.html'),
				('GERMAN HOUND', 'http://www.fci.be/en/nomenclature/GERMAN-HOUND-299.html'), ('BLACK AND TAN COONHOUND', 'http://www.fci.be/en/nomenclature/BLACK-AND-TAN-COONHOUND-300.html'),
				('AMERICAN WATER SPANIEL', 'http://www.fci.be/en/nomenclature/AMERICAN-WATER-SPANIEL-301.html'), ('IRISH GLEN OF IMAAL TERRIER', 'http://www.fci.be/en/nomenclature/IRISH-GLEN-OF-IMAAL-TERRIER-302.html'),
				('AMERICAN FOXHOUND', 'http://www.fci.be/en/nomenclature/AMERICAN-FOXHOUND-303.html'), ('RUSSIAN-EUROPEAN LAIKA', 'http://www.fci.be/en/nomenclature/RUSSIAN-EUROPEAN-LAIKA-304.html'),
				('EAST SIBERIAN LAIKA', 'http://www.fci.be/en/nomenclature/EAST-SIBERIAN-LAIKA-305.html'), ('WEST SIBERIAN LAIKA', 'http://www.fci.be/en/nomenclature/WEST-SIBERIAN-LAIKA-306.html'),
				('AZAWAKH', 'http://www.fci.be/en/nomenclature/AZAWAKH-307.html'), ('DUTCH SMOUSHOND', 'http://www.fci.be/en/nomenclature/DUTCH-SMOUSHOND-308.html'),
				('SHAR PEI', 'http://www.fci.be/en/nomenclature/SHAR-PEI-309.html'), ('PERUVIAN HAIRLESS', 'http://www.fci.be/en/nomenclature/PERUVIAN-HAIRLESS-DOG-310.html'),
				('SAARLOOS WOLFHOND', 'http://www.fci.be/en/nomenclature/SAARLOOS-WOLFHOND-311.html'), ('NOVA SCOTIA DUCK TOLLING RETRIEVER', 'http://www.fci.be/en/nomenclature/NOVA-SCOTIA-DUCK-TOLLING-RETRIEVER-312.html'),
				('DUTCH SCHAPENDOES', 'http://www.fci.be/en/nomenclature/DUTCH-SCHAPENDOES-313.html'), ('NEDERLANDSE KOOIKERHONDJE', 'http://www.fci.be/en/nomenclature/NEDERLANDSE-KOOIKERHONDJE-314.html'),
				('BROHOLMER', 'http://www.fci.be/en/nomenclature/BROHOLMER-315.html'), ('FRENCH WHITE AND ORANGE HOUND', 'http://www.fci.be/en/nomenclature/FRENCH-WHITE-AND-ORANGE-HOUND-316.html'),
				('KAI', 'http://www.fci.be/en/nomenclature/KAI-317.html'), ('KISHU', 'http://www.fci.be/en/nomenclature/KISHU-318.html'),
				('SHIKOKU', 'http://www.fci.be/en/nomenclature/SHIKOKU-319.html'), ('WIREHAIRED SLOVAKIAN POINTER', 'http://www.fci.be/en/nomenclature/WIREHAIRED-SLOVAKIAN-POINTER-320.html'),
				('MAJORCA SHEPHERD', 'http://www.fci.be/en/nomenclature/MAJORCA-SHEPHERD-DOG-321.html'), ('GREAT ANGLO-FRENCH TRICOLOUR HOUND', 'http://www.fci.be/en/nomenclature/GREAT-ANGLO-FRENCH-TRICOLOUR-HOUND-322.html'),
				('GREAT ANGLO-FRENCH WHITE AND BLACK HOUND', 'http://www.fci.be/en/nomenclature/GREAT-ANGLO-FRENCH-WHITE-AND-BLACK-HOUND-323.html'), ('GREAT ANGLO-FRENCH WHITE & ORANGE HOUND', 'http://www.fci.be/en/nomenclature/GREAT-ANGLO-FRENCH-WHITE-ORANGE-HOUND-324.html'),
				('MEDIUM-SIZED ANGLO-FRENCH HOUND', 'http://www.fci.be/en/nomenclature/MEDIUM-SIZED-ANGLO-FRENCH-HOUND-325.html'), ('SOUTH RUSSIAN SHEPHERD', 'http://www.fci.be/en/nomenclature/SOUTH-RUSSIAN-SHEPHERD-DOG-326.html'),
				('RUSSIAN BLACK TERRIER', 'http://www.fci.be/en/nomenclature/RUSSIAN-BLACK-TERRIER-327.html'), ('CAUCASIAN SHEPHERD', 'http://www.fci.be/en/nomenclature/CAUCASIAN-SHEPHERD-DOG-328.html'),
				('CANARIAN WARREN HOUND', 'http://www.fci.be/en/nomenclature/CANARIAN-WARREN-HOUND-329.html'), ('IRISH RED AND WHITE SETTER', 'http://www.fci.be/en/nomenclature/IRISH-RED-AND-WHITE-SETTER-330.html'),
				('KANGAL SHEPHERD', 'http://www.fci.be/en/nomenclature/KANGAL-SHEPHERD-DOG-331.html'), ('CZECHOSLOVAKIAN WOLFDOG', 'http://www.fci.be/en/nomenclature/CZECHOSLOVAKIAN-WOLFDOG-332.html'),
				('POLISH GREYHOUND', 'http://www.fci.be/en/nomenclature/POLISH-GREYHOUND-333.html'), ('KOREA JINDO', 'http://www.fci.be/en/nomenclature/KOREA-JINDO-DOG-334.html'),
				('CENTRAL ASIA SHEPHERD', 'http://www.fci.be/en/nomenclature/CENTRAL-ASIA-SHEPHERD-DOG-335.html'), ('SPANISH WATER', 'http://www.fci.be/en/nomenclature/SPANISH-WATER-DOG-336.html'),
				('ITALIAN SHORT-HAIRED SEGUGIO', 'http://www.fci.be/en/nomenclature/ITALIAN-SHORT-HAIRED-SEGUGIO-337.html'), ('THAI RIDGEBACK', 'http://www.fci.be/en/nomenclature\THAI-RIDGEBACK-DOG-338.html'),
				('PARSON RUSSELL TERRIER', 'http://www.fci.be/en/nomenclature/PARSON-RUSSELL-TERRIER-339.html'), ('SAINT MIGUEL CATTLE', 'http://www.fci.be/en/nomenclature/SAINT-MIGUEL-CATTLE-DOG-340.html'),
				('BRAZILIAN TERRIER', 'http://www.fci.be/en/nomenclature/BRAZILIAN-TERRIER-341.html'), ('AUSTRALIAN SHEPHERD', 'http://www.fci.be/en/nomenclature/AUSTRALIAN-SHEPHERD-342.html'),
				('ITALIAN CANE CORSO', 'http://www.fci.be/en/nomenclature/ITALIAN-CANE-CORSO-343.html'), ('AMERICAN AKITA', 'http://www.fci.be/en/nomenclature/AMERICAN-AKITA-344.html'),
				('JACK RUSSELL TERRIER', 'http://www.fci.be/en/nomenclature/JACK-RUSSELL-TERRIER-345.html'), ('DOGO CANARIO', 'http://www.fci.be/en/nomenclature/DOGO-CANARIO-346.html')--,
				('WHITE SWISS SHEPHERD', 'http://www.fci.be/en/nomenclature/WHITE-SWISS-SHEPHERD-DOG-347.html'), ('TAIWAN', 'http://www.fci.be/en/nomenclature/TAIWAN-DOG-348.html'),
				('ROMANIAN MIORITIC SHEPHERD', 'http://www.fci.be/en/nomenclature/ROMANIAN-MIORITIC-SHEPHERD-DOG-349.html'), ('ROMANIAN CARPATHIAN SHEPHERD', 'http://www.fci.be/en/nomenclature/ROMANIAN-CARPATHIAN-SHEPHERD-DOG-350.html'),
				('AUSTRALIAN STUMPY TAIL CATTLE', 'http://www.fci.be/en/nomenclature/AUSTRALIAN-STUMPY-TAIL-CATTLE-DOG-351.html'), ('RUSSIAN TOY', 'http://www.fci.be/en/nomenclature/RUSSIAN-TOY-352.html'),
				('CIMARRÓN URUGUAYO', 'http://www.fci.be/en/nomenclature/CIMARRON-URUGUAYO-353.html'), ('POLISH HUNTING', 'http://www.fci.be/en/nomenclature/POLISH-HUNTING-DOG-354.html'),
				('BOSNIAN AND HERZEGOVINIAN - CROATIAN SHEPHERD', 'http://www.fci.be/en/nomenclature/BOSNIAN-AND-HERZEGOVINIAN-CROATIAN-SHEPHERD-DOG-355.html'),
				('DANISH-SWEDISH FARMDOG', 'http://www.fci.be/en/nomenclature/DANISH-SWEDISH-FARMDOG-356.html'), ('ROMANIAN BUCOVINA SHEPHERD', 'http://www.fci.be/en/nomenclature/ROMANIAN-BUCOVINA-SHEPHERD-357.html'),
				('THAI BANGKAEW', 'http://www.fci.be/en/nomenclature/THAI-BANGKAEW-DOG-358.html'), ('MINIATURE BULL TERRIER', 'http://www.fci.be/en/nomenclature/MINIATURE-BULL-TERRIER-359.html'),
				('LANCASHIRE HEELER', 'http://www.fci.be/en/nomenclature/LANCASHIRE-HEELER-360.html'), ('SEGUGIO MAREMMANO', 'http://www.fci.be/en/nomenclature/SEGUGIO-MAREMMANO-361.html')
		) AS Breeds (Breed, URL)
UNION ALL
SELECT	'Cat',
		Breeds.Breed,
		'https://tica.org/breeds/browse-all-breeds#' + REPLACE(LOWER(Breeds.Breed), ' ', '-')
FROM
		(
			VALUES	('American Bobtail'),('Bengal'), ('Maine Coon'),
					('Persian'),('Ragdoll'),('Russian Blue'), ('Scottish Fold'), ('Siamese'), ('Sphynx'),('Turkish Angora')	
				('Abyssinian'), ('American Bobtail'), ('American Bobtail Shorthair'), ('American Curl'),('American Shorthair'), ('American Wirehair'), ('Australian Mist'), ('Balinese'),
				('Bengal'), ('Bengal Longhair'), ('Birman'), ('Bombay'), ('British Longhair'), ('British Shorthair'), ('Burmese'), ('Burmilla'),
				('Burmilla Longhair'), ('Chartreux'), ('Chausie'), ('Cornish Rex'), ('Cymric'), ('Devon Rex'), ('Donskoy'), ('Egyptian Mau'), ('Exotic Shorthair'), ('Havana'), ('Himalayan'), ('Japanese Bobtail'),
				('Japanese Bobtail Longhair'), ('Khaomanee'), ('Korat'), ('Kurilian Bobtail'), ('Kurilian Bobtail Longhair'), ('LaPerm'), ('LaPerm Shorthair'), ('Lykoi'), ('Maine Coon'), ('Maine Coon Polydactyl'), ('Manx'), ('Minuet'),
				('Minuet Longhair'), ('Munchkin'), ('Munchkin Longhair'), ('Nebelung'), ('Norwegian Forest'), ('Ocicat'), ('Oriental Longhair'), ('Oriental Shorthair'),
				('Persian'), ('Peterbald'), ('Pixiebob'), ('Pixiebob Longhair'), ('Ragdoll'), ('Russian Blue'), ('Savannah'), ('Scottish Fold'),
				('Scottish Fold Longhair'), ('Scottish Straight'), ('Scottish Straight Longhair'), ('Selkirk Rex'), ('Selkirk Rex Longhair'), ('Siamese'), ('Siberian'), ('Singapura'), ('Snowshoe'), ('Somali'), ('Sphynx'), ('Thai'),
				('Tonkinese'), ('Toyger'), ('Turkish Angora'), ('Turkish Van')
		) AS Breeds (Breed)
UNION ALL
SELECT	'Rabbit',
		Breeds.Breed,
		'https://rabbitpedia.com/' + REPLACE(Breeds.Breed, ' ', '-')
FROM
		(
			VALUES	('Lionhead'),('English Lop'), ('French Lop'),('American'),('Belgian Hare'),('Californian'),('Chinchilla (Giant)'), ('English Angora'),
					('Satin Angora'),('Himalayan'), ('Jersey Wooly'), ('Velveteen Lop')
					
				('Lionhead'), ('Flemish Giant'), ('Continental Giant'), ('Dutch'), ('English Lop'), ('French Lop'), ('Holland Lop'), ('Mini Rex'),
				('Netherland dwarf'), ('Polish'), ('American'), ('American Fuzzy Lop'), ('American Sable'), ('Argente Brun'), ('Argente Crème'), ('Argente de Champagne'),
				('Belgian Hare'), ('Beveren'), ('Blanc de Hotot'), ('Britannia Petite'), ('Californian'), ('Checkered Giant'), ('Chinchilla (Standard)'), ('Chinchilla (American)'),
				('Chinchilla (Giant)'), ('Cinnamon'), ('Dwarf Hotot'), ('Dwarf Lop (Mini Lop in USA)'), ('English Angora'), ('English Spot'), ('Florida White'), ('French Angora'),
				('Giant Angora'), ('Giant Papillon'), ('Harlequin'), ('Havana'), ('Himalayan'), ('Jersey Wooly'), ('Lilac'), ('New Zealand'),
				('Palomino'), ('Rex (Standard)'), ('Rhinelander'), ('Satin'), ('Satin Angora'), ('Silver'), ('Silver Fox'), ('Silver Marten'), ('Tan'), ('Thrianta'), ('Velveteen Lop')
		) AS Breeds (Breed);

-- Popular animal names
-- Sources:
-- https://www.rover.com/blog/dog-names/
-- https://www.rover.com/blog/best-cat-names/
-- https://petset.com/pet-names/popular-bunny-names/
CREATE TABLE Reference.Common_Animal_Names
(
	Species VARCHAR(10) NOT NULL
		REFERENCES Reference.Species (Species),
	[Rank]	TINYINT		NOT NULL,
	Male	VARCHAR(20) NOT NULL,
	Female	VARCHAR(20) NOT NULL,
	PRIMARY KEY (Species, [Rank]),
	INDEX NCIDX_Common_Animal_Names__Rank ([Rank])
);

INSERT	INTO Reference.Common_Animal_Names (Species, [Rank], Male, Female)
SELECT	'Dog',
		CAST(Names.Rank AS TINYINT),
		Names.Male,
		Names.Female
FROM
		(
			VALUES ('Max', 'Bella', '1'), ('Charlie', 'Luna', '2'), ('Cooper', 'Lucy', '3'), ('Buddy', 'Daisy', '4'), 	('Rocky', 'Lily', '5'), ('Milo', 'Zoe', '6'), ('Jack', 'Lola', '7'), ('Bear', 'Molly', '8'),
				('Duke', 'Sadie', '9'), ('Teddy', 'Bailey', '10'), ('Oliver', 'Stella', '11'), ('Bentley', 'Maggie', '12'), ('Tucker', 'Roxy', '13'), ('Beau', 'Sophie', '14'), ('Leo', 'Chloe', '15'), ('Toby', 'Penny', '16'),
				('Jax', 'Coco', '17'), ('Zeus', 'Nala', '18'), ('Winston', 'Rosie', '19'), ('Blue', 'Ruby', '20'), ('Finn', 'Gracie', '21'), ('Louie', 'Ellie', '22'), ('Ollie', 'Mia', '23'), ('Murphy', 'Piper', '24'),
				('Gus', 'Callie', '25'), ('Moose', 'Abby', '26'), ('Jake', 'Lexi', '27'), ('Loki', 'Ginger', '28'), ('Dexter', 'Lulu', '29'), ('Hank', 'Pepper', '30'), ('Bruno', 'Willow', '31'), ('Apollo', 'Riley', '32'),
				('Buster', 'Millie', '33'), ('Thor', 'Harley', '34'), ('Bailey', 'Sasha', '35'), ('Gunnar', 'Lady', '36'), ('Lucky', 'Izzy', '37'), ('Diesel', 'Layla', '38'), ('Harley', 'Charlie', '39'), ('Henry', 'Dixie', '40'),
				('Koda', 'Maya', '41'), ('Jackson', 'Annie', '42'), ('Riley', 'Kona', '43'), ('Ace', 'Hazel', '44'), ('Oscar', 'Winnie', '45'), ('Chewy', 'Olive', '46'), ('Bandit', 'Princess', '47'), ('Baxter', 'Emma', '48'),
				('Scout', 'Athena', '49'), ('Jasper', 'Nova', '50'), ('Maverick', 'Belle', '51'), ('Sam', 'Honey', '52'), ('Cody', 'Ella', '53'), ('Gizmo', 'Marley', '54'), ('Shadow', 'Cookie', '55'), ('Simba', 'Maddie', '56'),
				('Rex', 'Remi / Remy', '57'), ('Brody', 'Phoebe', '58'), ('Tank', 'Scout', '59'), ('Marley', 'Minnie', '60'), ('Otis', 'Dakota', '61'), ('Remi / Remy', 'Holly', '62'), ('Roscoe', 'Angel', '63'), ('Rocco', 'Josie', '64'),
				('Sammy', 'Leia', '65'), ('Cash', 'Harper', '66'), ('Boomer', 'Ava', '67'), ('Prince', 'Missy', '68'), ('Benji', 'Mila', '69'), ('Benny', 'Sugar', '70'), 	('Copper', 'Shelby', '71'), ('Archie', 'Poppy', '72'),
				('Chance', 'Blue', '73'), ('Ranger', 'Mocha', '74'), ('Ziggy', 'Cleo', '75'), ('Luke', 'Penelope', '76'), ('George', 'Ivy', '77'), ('Oreo', 'Peanut', '78'), ('Hunter', 'Fiona', '79'), ('Rusty', 'Xena', '80'),
				('King', 'Gigi', '81'), ('Odin', 'Sandy', '82'), ('Coco', 'Bonnie', '83'), ('Frankie', 'Jasmine', '84'), ('Tyson', 'Baby', '85'), ('Chase', 'Macy', '86'), ('Theo', 'Paisley', '87'), ('Romeo', 'Shadow', '88'),
				('Bruce', 'Koda', '89'), ('Rudy', 'Pearl', '90'), ('Zeke', 'Skye', '91'), ('Kobe', 'Delilah', '92'), ('Peanut', 'Nina', '93'), ('Joey', 'Trixie', '94'), ('Oakley', 'Charlotte', '95'), ('Chico', 'Aspen', '96'),
				('Mac', 'Arya', '97'), ('Walter', 'Diamond', '98'), ('Brutus', 'Georgia', '99'), ('Samson', 'Dolly', '100')
		) AS Names (Male, Female, [Rank])
UNION ALL
SELECT	'Cat',
		CAST(Names.Rank AS TINYINT),
		Names.Male,
		Names.Female
FROM
		(
			VALUES ('Oliver', 'Luna', '1'), ('Leo', 'Bella', '2'), ('Milo', 'Lily', '3'), ('Charlie', 'Lucy', '4'), ('Max', 'Kitty', '5'), ('Jack', 'Callie', '6'), ('Simba', 'Nala', '7'), ('Loki', 'Zoe', '8'),
				('Oscar', 'Chloe', '9'), ('Jasper', 'Sophie', '10'), ('Buddy', 'Daisy', '11'), ('Tiger', 'Stella', '12'), ('Toby', 'Cleo', '13'), ('George', 'Lola', '14'), ('Smokey', 'Gracie', '15'), ('Simon', 'Mia', '16'),
				('Tigger', 'Molly', '17'), 	('Ollie', 'Penny', '18'), ('Louie', 'Willow', '19'), 	('Felix', 'Olive', '20'), ('Dexter', 'Kiki', '21'), ('Shadow', 'Pepper', '22'), ('Finn', 'Princess', '23'), ('Henry', 'Rosie', '24'),
				('Kitty', 'Ellie', '25'), ('Oreo', 'Maggie', '26'), ('Gus', 'Coco', '27'), ('Binx', 'Piper', '28'), ('Winston', 'Lulu', '29'), ('Sam', 'Sadie', '30'), ('Rocky', 'Izzy', '31'), ('Gizmo', 'Ginger', '32'),
				('Sammy', 'Abby', '33'), ('Jax', 'Sasha', '34'), ('Sebastian', 'Pumpkin', '35'), ('Blu', 'Ruby', '36'), ('Theo', 'Shadow', '37'), ('Beau', 'Phoebe', '38'), ('Salem', 'Millie', '39'), ('Chester', 'Roxy', '40'),
				('Lucky', 'Minnie', '41'), ('Frankie', 'Baby', '42'), ('Boots', 'Fiona', '43'), ('Cooper', 'Jasmine', '44'), ('Thor', 'Penelope', '45'), ('Bear', 'Sassy', '46'), ('Romeo', 'Charlie', '47'), ('Teddy', 'Oreo', '48'),
				('Bandit', 'Mittens', '49'), ('Ziggy', 'Boo', '50'), ('Apollo', 'Belle', '51'), ('Pumpkin', 'Misty', '52'), ('Boo', 'Mimi', '53'), ('Zeus', 'Missy', '54'), ('Bob', 'Emma', '55'), ('Tucker', 'Annie', '56'),
				('Jackson', 'Athena', '57'), ('Tom', 'Hazel', '58'), ('Cosmo', 'Angel', '59'), ('Bruce', 'Ella', '60'), ('Murphy', 'Cookie', '61'), ('Buster', 'Bailey', '62'), ('Midnight', 'Arya', '63'), ('Moose', 'Nova', '64'),
				('Merlin', 'Olivia', '65'), ('Frank', 'Zelda', '66'), ('Joey', 'Maya', '67'), ('Thomas', 'Smokey', '68'), ('Harley', 'Peanut', '69'), ('Prince', 'Poppy', '70'), 	('Archie', 'Midnight', '71'), ('Tommy', 'Winnie', '72'),
				('Marley', 'Patches', '73'), ('Otis', 'Charlotte', '74'), ('Casper', 'Layla', '75'), ('Harry', 'Leia', '76'), ('Benny', 'Delilah', '77'), ('Percy', 'Alice', '78'), ('Bentley', 'Harley', '79'), ('Jake', 'Pearl', '80'),
				('Ozzy', 'Ivy', '81'), ('Ash', 'Lexi', '82'), ('Sylvester', 'Peaches', '83'), ('Mickey', 'Mila', '84'), ('Fred', 'Gypsy', '85'), ('Walter', 'Miss Kitty', '86'), ('Clyde', 'Kitten', '87'), ('Pepper', 'Cat', '88'),
				('Calvin', 'Snickers', '89'), ('Tux', 'Scout', '90'), ('Stanley', 'Blu', '91'), ('Garfield', 'Lucky', '92'), ('Louis', 'Freya', '93'), ('Mowgli', 'Tiger', '94'), ('Mac', 'Stormy', '95'), ('Luke', 'Jade', '96'),
				('Sunny', 'Honey', '97'), ('Duke', 'Marley', '98'), ('Hobbes', 'Frankie', '99'), ('Remi', 'Gigi', '100')
		) AS Names (Male, Female, Rank)
UNION ALL
SELECT	'Rabbit',
		CAST(Names.Rank AS TINYINT),
		LEFT(Names.Male, 1) + RIGHT(LOWER(Names.Male), LEN(Names.Male) - 1),
		LEFT(Names.Female, 1) + RIGHT(LOWER(Names.Female), LEN(Names.Female) - 1)
FROM
		(	-- Data source was all caps to begin with
			VALUES ('JELLY BEAN', 'WILLOW', '1'), ('SNOWBALL', 'PEACHES', '2'), ('PEANUT', 'SPRINKLES', '3'), ('SNOOP', 'SUNNY', '4'), ('THUMPER', 'BON BON', '5'), ('OLIVER', 'MAGGIE', '6'), ('COMET', 'SNOWY', '7'), ('STUART', 'LILLY', '8'),
				('MIDNIGHT', 'FLOWER', '9'), ('BILLY', 'SUGAR', '10'), ('CARAMEL', 'ANGEL', '11'), ('FREDDIE', 'SWEET PEA', '12'), ('PEPPER', 'SNOWFLAKE', '13'), ('RILEY', 'LICORICE', '14'), ('HOPPER', 'LUNA', '15'), ('PANCAKE', 'DAISY', '16'),
				('SPOOKY', 'NALA', '17'), ('CHIP', 'GERTIE', '18'), ('DUSTY', 'MILLY', '19'), ('JESSE', 'COOKIE', '20'), ('BREEZE', 'JULIET', '21'), ('DARRYL', 'TWINKLE', '22'), ('SAGE', 'WHITNEY', '23'), ('JASPER', 'MOLLY', '24'),
				('HUGO', 'APRIL', '25'), ('MARBLE', 'COCO', '26'), ('DANTE', 'REMI', '27'), ('ARCHIE', 'KATRINA', '28'), ('SPANKY', 'OLIVE', '29'), ('SHIPPY', 'PRINCESS', '30'), ('GIZMO', 'NEELA', '31'), ('RIVER', 'ROXANNE', '32'),
				('GUS', 'KYLIE', '33'), ('TINKERBELL', 'KIKI', '34'), ('SPOT', 'JULIA', '35'), ('OREO', 'IVY', '36'), ('GUSSY', 'PEARL', '37'), ('SPENCER', 'POLKA DOT', '38'), ('BUDDY', 'JERRI', '39'), ('JAZZ', 'DEMI', '40'),
				('HERMIE', 'CANDY', '41'), ('JET', 'BELLA', '42'), ('CHOMPER', 'GYPSY', '43'), ('ROSCO', 'FIFI', '44'), ('NACHO', 'LUCY', '45'), ('HONDO', 'PEANUT BUTTER', '46'), ('TORNADO', 'SANDY', '47'), ('BUTTERS', 'BLANCO', '48'),
				('BOB', 'HERSHEY', '49'), ('STOKER', 'DIVA', '50'), ('CHUBBY', 'PARIS', '51'), ('NOVA', 'SOPHIE', '52'), ('PHANTOM', 'DIAMOND', '53'), ('SPIRIT', 'MOCHI', '54'), ('TEX', 'JEMMA', '55'), ('HERBIE', 'ROSIE', '56'),
				('JONAS', 'AMBER', '57'), ('TOBY', 'BUTTERSCOTCH', '58'), ('STANLEY', 'STARLIGHT', '59'), ('AUGGIE', 'BETSY', '60'), ('TEDDY', 'GRACIE', '61'), 	('NINJA', 'DUTCHESS', '62'), ('ARNOLD', 'BINDI', '63'), ('COMATOSE', 'DESTINY', '64'),
				('SMOKEY', 'RUBY', '65'), ('PRINCE', 'GABBY', '66'), ('DALTON', 'ABBY', '67'), ('ROMEO', 'SALT', '68'), ('THOR', 'TRIXIE', '69'), ('ECHO', 'BABY', '70'), ('BANDIT', 'PATCHES', '71'), ('MYSTIC', 'CASSIDY', '72'),
				('BALOO', 'SURI', '73'), ('BLAZE', 'ELLA', '74'), ('CHARLIE', 'CINDERELLA', '75'), ('HUMPHREY', 'FLUFFY', '76'), ('DELTA', 'HADLEY', '77'), ('KODO', 'SASSY', '78'), ('KIRBY', 'PENNY', '79'), ('STEWIE', 'BUN BUN', '80'),
				('IGGY', 'ELEANOR', '81'), ('DOBBY', 'DOLLY', '82'), ('LENNY', 'ROXIE', '83'), ('ZIGGY', 'SUZI', '84'), ('MOMO', 'WONDER', '85'), ('FORREST', 'CINDER', '86'), ('GUINNESS', 'CHARM', '87'), ('BRUNO', 'STORM', '88'),
				('HUDINI', 'BETTY', '89'), ('HIP HOP', 'SCARLETT', '90'), ('MAXWELL', 'OPHELIA', '91'), ('YOGI', 'CELIA', '92'), ('HONEY', 'BLONDIE', '93'), ('MILLY', 'ABIGAIL', '94'), ('HAL', 'JADE', '95'), ('DUNCAN', 'SNOW WHITE', '96'),
				('MURPHY', 'ZOEY', '97'), ('SHADOW', 'FARRAH', '98'), ('SCOUT', 'LIQUORICE', '99'), ('KOBIE', 'SUKI', '100')
		) AS Names (Male, Female, Rank);

-- Colors
CREATE TABLE Reference.Colors 
(
	Color VARCHAR(10) NOT NULL PRIMARY KEY
);

-- Populate colors
-- Source - Wikipedia (not all 'standard' colors included here)
INSERT INTO Reference.Colors (Color)
VALUES
('Ginger'), ('Brown'), ('Black'), ('White'), ('Gray'), ('Cream'), 
('Red'), ('Gold'), ('Fawn'), ('Blue'), ('Cinnamon'), ('Beige'), ('Lilach'), ('Opal');

-- Common color patterns
-- Source: Wikipedia
CREATE TABLE Reference.Patterns
(
	Species VARCHAR(10) NOT NULL
		REFERENCES Reference.Species (Species),
	Pattern VARCHAR(20) NOT NULL,
	PRIMARY KEY (Species, Pattern),
	INDEX NCIDX_Patterns_Pattern(Pattern)
);

-- Populate color patterns
-- Source: Wikipedia
INSERT INTO Reference.Patterns (Species, Pattern)
VALUES
('Cat', 'Solid'), ('Cat', 'Bicolor'), ('Cat', 'Tricolor'), ('Cat', 'Calico'), ('Cat', 'Spotted'), ('Cat', 'Tabby'), ('Cat', 'Tortoiseshell'), 
('Dog', 'Solid'), ('Dog', 'Bicolor'), ('Dog', 'Tricolor'), ('Dog', 'Tuxedo'), ('Dog', 'Spotted'), ('Dog', 'Flecked'), ('Dog', 'Merle'), ('Dog', 'Harlequin'), 
('Rabbit', 'Solid'), ('Rabbit', 'Brindle'), ('Rabbit', 'Broken'), ('Rabbit', 'Marked'), ('Rabbit', 'Ticked'), ('Rabbit', 'Wide Band'), ('Rabbit', 'Shaded'),
('Ferret', 'Sable'), ('Ferret', 'Albino'), ('Ferret', 'Solid'), 
('Raccoon', 'Bandit Mask');

-- Vaccines
-- Source https://www.vetmed.ucdavis.edu/hospital/animal-health-topics/vaccination-guidelines
CREATE TABLE Reference.Vaccines 
(
	Vaccine VARCHAR(50) NOT NULL PRIMARY KEY
);

INSERT INTO Reference.Vaccines (Vaccine)
VALUES
('Rabies'), ('Parvovirus'), ('Distemper Virus'), ('Adenovirus'), ('Herpesvirus'), ('Calicivirus'), ('Panleukopenia Virus'), ('Leukemia Virus'), ('Myxomatosis'), ('Viral Haemorrhagic Disease');

CREATE TABLE Reference.Species_Vaccines
(
	Species VARCHAR(10) NOT NULL
		REFERENCES Reference.Species (Species),
	Vaccine VARCHAR(50) NOT NULL
		REFERENCES Reference.Vaccines (Vaccine),
	PRIMARY KEY (Species, Vaccine),
	INDEX NCIDX_FK_Species_Vaccines__Vaccines (Vaccine)
);

INSERT	INTO Reference.Species_Vaccines (Vaccine, Species)
VALUES
('Rabies', 'Dog'), ('Parvovirus', 'Dog'), ('Distemper Virus', 'Dog'), ('Adenovirus', 'Dog'),
('Rabies', 'Cat'), ('Herpesvirus', 'Cat'), ('Calicivirus', 'Cat'), ('Panleukopenia Virus', 'Cat'), ('Leukemia Virus', 'Cat'), 
('Rabies', 'Rabbit'), ('Myxomatosis', 'Rabbit'), ('Viral Haemorrhagic Disease', 'Rabbit');

-- States
-- Source: https://simplemaps.com/data/us-cities
-- NOTE: You must download and import the above into a table named US_Cities in a database named US_Cities to run the following queries

CREATE TABLE Reference.States 
(
	State		VARCHAR(20)	NOT NULL PRIMARY KEY, 
	State_Code	CHAR(2)		NOT NULL UNIQUE
);

INSERT INTO Reference.States (State, State_Code)
SELECT	DISTINCT state_name,
				state_id
FROM	US_Cities.dbo.us_cities;

-- Cities
CREATE TABLE Reference.Cities
(
	State		VARCHAR(20) NOT NULL
		REFERENCES Reference.States (State),
	City		VARCHAR(30) NOT NULL,
	County		VARCHAR(30) NOT NULL,
	Population	INT			NOT NULL,
	PRIMARY KEY (State, City),
	INDEX NCIDX_Cities_City (City)
);

-- Populate Cities
-- Source: https://simplemaps.com/data/us-cities
INSERT INTO Reference.Cities (State, City, County, Population)
SELECT	state_name,
		city,
		county_name,
		population
FROM	US_Cities.dbo.us_cities
WHERE	Population >= @Min_Population; -- Limit sample DB only to main cities

-- City Zip Codes
CREATE TABLE Reference.City_Zip_Codes
(
	State		VARCHAR(20) NOT NULL,
	City		VARCHAR(30) NOT NULL,
	CONSTRAINT FK_City_Zip_Codes__Cities
		FOREIGN KEY (State, City)
		REFERENCES Reference.Cities (State, City),
	Zip_Code	CHAR(5)		NOT NULL
	PRIMARY KEY (State, City, Zip_Code),
	INDEX NCIDX_City_Zip_Codes_City (City)
);

-- Populate Zip Codes
INSERT INTO Reference.City_Zip_Codes (State, City, Zip_Code)
SELECT	Source.state_name,
		Source.city,
		X.value AS Zip_Code
FROM
		US_Cities.dbo.us_cities						AS Source
		CROSS APPLY STRING_SPLIT(Source.zips, ' ')	AS X
WHERE	EXISTS (	
				SELECT	NULL 
				FROM	Reference .Cities	AS C
				WHERE	C.City = Source.city 
						AND 
						C.State = Source.state_name
				);

-- Street names
-- Source: https://www.reddit.com/r/dataisbeautiful/comments/2oo23a/the_50_most_popular_street_names_in_the_us_oc/
CREATE TABLE Reference.Common_Street_Names 
(
	[Rank] TINYINT		NOT NULL PRIMARY KEY, 
	Street VARCHAR(20)	NOT NULL UNIQUE
);

INSERT INTO Reference.Common_Street_Names ([Rank], Street)
VALUES
(1, 'Main'), (2, 'Second'), (3, 'First'), (4, 'Third'), (5, 'Fourth'), (6, 'Fifth'), (7, 'Park'), (8, 'Sixth'),
(9, 'Oak'), (10, 'Seventh'), (11, 'Maple'), (12, 'Pine'), (13, 'Washington'), (14, 'Eighth'), (15, 'Cedar'), (16, 'Elm'),
(17, 'Walnut'), (18, 'Ninth'), (19, 'Tenth'), (20, 'Lake'), (21, 'Sunset'), (22, 'Lincoln'), (23, 'Jackson'), (24, 'Church'),
(25, 'River'), (26, 'Eleventh'), (27, 'Willow'), (28, 'Jefferson'), (29, 'Center'), (30, 'Twelfth'), (31, 'North'), (32, 'Lake view'),
(33, 'Ridge'), (34, 'Hickory'), (35, 'Adams'), (36, 'Cherry'), (37, 'Highland'), (38, 'Johnson'), (39, 'South'), (40, 'Dogwood'),
(41, 'West'), (42, 'Chestnut'), (43, 'Thirteenth'), (44, 'Spruce'), (45, 'Fourteenth'), (46, 'Wilson'), (47, 'Meadow'), (48, 'Forest'),
(49, 'Hill'), (50, 'Madison');

-- Integers
CREATE TABLE Reference.Integers 
(
	Number INT NOT NULL PRIMARY KEY
);

-- Populate with 65536 integers
WITH Level0
AS (SELECT 1 AS constant UNION ALL SELECT		1),
	Level1
AS (SELECT 1 AS constant FROM Level0 AS A CROSS JOIN Level0 AS B),
	Level2
AS (SELECT 1 AS constant FROM Level1 AS A CROSS JOIN Level1 AS B),
	Level3
AS (SELECT 1 AS constant FROM Level2 AS A CROSS JOIN Level2 AS B),
	Level4
AS (SELECT 1 AS constant FROM Level3 AS A CROSS JOIN Level3 AS B),
	Sequential_Integers
AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Number FROM Level4)
INSERT INTO Reference.Integers (Number)
SELECT	Sequential_Integers.Number
FROM	Sequential_Integers;

-- Fixed federal holidays
-- Source: https://en.wikipedia.org/wiki/Federal_holidays_in_the_United_States
CREATE TABLE Reference.Federal_Holidays_Fixed 
(
	Holiday			VARCHAR(50)	NOT NULL PRIMARY KEY, 
	Month			TINYINT		NOT NULL, 
	Day_of_Month	TINYINT		NOT NULL
);

INSERT INTO Reference.Federal_Holidays_Fixed (Holiday, Month, Day_of_Month)
VALUES
('New Year''s Day', 1, 1), ('Independence Day', 7, 4), ('Veterans Day', 11, 11), ('Christmas Day', 12, 25);

-- Floating federal holidays
-- Source: https://en.wikipedia.org/wiki/Federal_holidays_in_the_United_States
CREATE TABLE Reference.Federal_Holidays_Floating
(
	Holiday		VARCHAR(50) NOT NULL PRIMARY KEY,
	Month		TINYINT		NOT NULL,
	Date_Min	TINYINT		NOT NULL,
	Date_Max	TINYINT		NOT NULL,
	Day_of_Week TINYINT NOT NULL,
);

INSERT	INTO Reference.Federal_Holidays_Floating (Holiday, Month, Date_Min, Date_Max, Day_of_Week)
VALUES
('Birthday of Martin Luther King Jr.', 1, 15, 21, 2), ('Washington''s Birthday', 2, 15, 21, 2), ('Memorial Day', 5, 25, 31, 2), ('Labor Day', 9, 1, 7, 2), ('Columbus Day', 10, 8, 14, 2), ('Thanksgiving Day', 11, 22, 28, 5);

-- Calendar
CREATE TABLE Reference.Calendar
(
	Date				DATE		NOT NULL PRIMARY KEY,
	Year				SMALLINT	NOT NULL,
	Month				TINYINT		NOT NULL,
	Month_Name			VARCHAR(10) NOT NULL,
	Day					TINYINT		NOT NULL,
	Day_Name			VARCHAR(10) NOT NULL,
	Day_of_Year			SMALLINT	NOT NULL,
	Weekday				TINYINT		NOT NULL,
	Year_Week			TINYINT		NOT NULL,
	US_Federal_Holiday	VARCHAR(50) NULL,
);

-- Populate Calendar with dates between @Min_Date_Calendar and @Max_Date_Calendar
INSERT	Reference.Calendar (Date, Year, Month, Month_Name, Day, Day_Name, Day_of_Year, Weekday, Year_Week)
SELECT	DATEADD(DAY, Number - 1, @Min_Date_Calendar),
		YEAR(DATEADD(DAY, Number - 1, @Min_Date_Calendar)),
		MONTH(DATEADD(DAY, Number - 1, @Min_Date_Calendar)),
		DATENAME(MONTH, (DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
		DAY((DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
		DATENAME(WEEKDAY, (DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
		DATEPART(DAYOFYEAR, (DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
		DATEPART(WEEKDAY, (DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
		DATEPART(WEEK, (DATEADD(DAY, Number - 1, @Min_Date_Calendar)))
FROM	Reference.Integers
WHERE	Number <= 1 + DATEDIFF(DAY, @Min_Date_Calendar, @Max_Date_Calendar);

-- Update fixed holidays
WITH Calendar_Holidays
AS (SELECT	C.Date,
			C.US_Federal_Holiday,
			FHF.Holiday
	FROM	Reference.Calendar					AS C
			INNER JOIN
			Reference.Federal_Holidays_Fixed	AS FHF
				ON C.Month = FHF.Month
				AND 
				C.Day = FHF.Day_of_Month
	)
UPDATE	Calendar_Holidays
SET		Calendar_Holidays.US_Federal_Holiday = Calendar_Holidays.Holiday;

-- Update floating holidays
WITH Calendar_Holidays
AS (SELECT	C.Date,
			C.US_Federal_Holiday,
			FHF.Holiday
	FROM	Reference.Calendar					AS C
			INNER JOIN
			Reference.Federal_Holidays_Floating AS FHF
				ON C.Month = FHF.Month
				AND 
				C.Day BETWEEN FHF.Date_Min AND FHF.Date_Max
				AND 
				FHF.Day_of_Week = C.Weekday
	)
UPDATE	Calendar_Holidays
SET		Calendar_Holidays.US_Federal_Holiday = Calendar_Holidays.Holiday;

-----------------------------------------------------------------
-- Make reference data read-only except for admins --------------
-- DENY INSERT, UPDATE, DELETE ON SCHEMA::Reference TO PUBLIC; --
-----------------------------------------------------------------
-----------------------------------------------------------------
