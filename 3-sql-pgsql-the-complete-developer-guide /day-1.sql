-- 1. create table 'cities' with columns
-- 'name' - max 50 chars,
-- 'country' - max 50 chars,
-- 'population' - integer,
-- 'area' - integer
----------------------------------------------
-- 2. insert single record in 'cities' table
-- ('Tokyo', 'Japan', 38505000, 8223)
----------------------------------------------
-- 3. insert multiple records in 'cities' table
-- ('Delhi', 'India', 28125000, 2240),
-- ('Shanghai', 'China', 22125000, 4015),
-- ('Sao Paulo', 'Brazil', 20935000, 3043)
----------------------------------------------
-- 4. calculate population density of each city and add a computed column 'density'
----------------------------------------------
-- 5. create table 'phones' with columns
-- 'name' - max 50 chars,
-- 'manufacturer' - max 50 chars,
-- 'price' - integer,
-- 'units_sold' - integer
----------------------------------------------
-- 6. add multiple records in 'phones' table
-- ('N1280', 'Nokia', 199, 1925),
-- ('Iphone 4', 'Apple', 399, 9436),
-- ('Galaxy S', 'Samsung', 299, 2359),
-- ('S5620', 'Samsung', 250, 2385)
----------------------------------------------
-- 7. fetch all the mobiles
----------------------------------------------
-- 8. calculate revenu earned per phone . add a computed column 'revenue'
----------------------------------------------
-- 9. calculate 'location' with the format '<name> , <country>' using double pipe operator (||) and using 'CONCAT()' scalar string function.
----------------------------------------------
-- 9.1. print the 'location' in upper case. use 'UPPER()' string scalar/row-level function.
----------------------------------------------
----------------------------------------------
-- ============ SOLUTION ==================
-- 1. create table 'cities' with columns
-- 'name' - max 50 chars,
-- 'country' - max 50 chars,
-- 'population' - integer,
-- 'area' - integer
CREATE TABLE
	cities (
		name VARCHAR(50),
		country VARCHAR(50),
		population INTEGER,
		area INTEGER
	);

-- check if table is creted or not
SELECT
	*
FROM
	cities;

-- 2. insert single record in 'cities' table
-- ('Tokyo', 'Japan', 38505000, 8223)
INSERT INTO
	cities (name, country, population, area)
VALUES
	('Tokyo', 'Japan', 38505000, 8223);

-- 3. insert multiple records in 'cities' table
-- ('Delhi', 'India', 28125000, 2240),
-- ('Shanghai', 'China', 22125000, 4015),
-- ('Sao Paulo', 'Brazil', 20935000, 3043)
INSERT INTO
	cities (name, country, population, area)
VALUES
	('Delhi', 'India', 28125000, 2240),
	('Shanghai', 'China', 22125000, 4015),
	('Sao Paulo', 'Brazil', 20935000, 3043);

-- 4. calculate population density of each city and add a computed column 'density'
SELECT
	name,
	country,
	population,
	area,
	(population / area) density
FROM
	cities;

-- 5. create table 'phones' with columns
-- 'name' - max 50 chars,
-- 'manufacturer' - max 50 chars,
-- 'price' - integer,
-- 'units_sold' - integer
CREATE TABLE
	phones (
		name VARCHAR(50),
		manufacturer VARCHAR(50),
		price INTEGER,
		units_sold INTEGER
	);

-- check if table is created
SELECT
	*
FROM
	phones;

-- 6. add multiple records in 'phones' table
-- ('N1280', 'Nokia', 199, 1925),
-- ('Iphone 4', 'Apple', 399, 9436),
-- ('Galaxy S', 'Samsung', 299, 2359),
-- ('S5620', 'Samsung', 250, 2385)
INSERT INTO
	phones (name, manufacturer, price, units_sold)
VALUES
	('N1280', 'Nokia', 199, 1925),
	('Iphone 4', 'Apple', 399, 9436),
	('Galaxy S', 'Samsung', 299, 2359),
	('S5620', 'Samsung', 250, 2385);

-- 7. fetch all the phones
SELECT
	*
FROM
	phones;

-- 8. calculate revenue earned per phone . add a computed column 'revenue'
SELECT
	name,
	manufacturer,
	price,
	units_sold,
	(price * units_sold) revenue
FROM
	phones;

-- 9. calculate 'location' with the format '<name> , <country>' using double pipe operator (||) and using 'CONCAT()' scalar string function.
-- using double pipe (||) operator
SELECT
	name,
	country,
	population,
	area,
	(name || ', ' || country) location
FROM
	cities;

-- using CONCAT() scalar/row-level scalar function
SELECT
	name,
	country,
	population,
	area,
	CONCAT (name, ', ', country) location
FROM
	cities;

-- 9.1. print the 'location' in upper case. use 'UPPER()' string scalar/row-level function.
SELECT
	name,
	country,
	area,
	UPPER(name || ', ' || country) location
FROM
	cities;