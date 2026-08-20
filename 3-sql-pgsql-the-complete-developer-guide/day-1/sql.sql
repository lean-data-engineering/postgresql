CREATE TABLE cities (
	name VARCHAR(50), 
  country VARCHAR(50),
  population INTEGER,
  area INTEGER
);


INSERT INTO cities (name, country, population, area)
VALUES ('Tokyo', 'Japan', 38505000, 8223);


INSERT INTO cities (name, country, population, area)
VALUES 
	('Delhi', 'India', 28125000, 2240),
  ('Shanghai', 'China', 22125000, 4015),
  ('Sao Paulo', 'Brazil', 20935000, 3043);


SELECT * FROM cities;


SELECT c.name, c.population/area FROM cities c;


SELECT c.name , c.population/ c.area density 
	FROM cities c


CREATE TABLE phones(
	name VARCHAR(50),
	manufacturer VARCHAR(50),
	price INTEGER,
	units_sold INTEGER
);


INSERT INTO phones
	(name, manufacturer, price, units_sold)
VALUES 
	('N1280', 'Nokia', 199, 1925),
	('Iphone 4', 'Apple', 399, 9436),
	('Galaxy S', 'Samsung', 299, 2359),
	('S5620', 'Samsung', 250, 2385);


SELECT * FROM phones;


SELECT
	p.name,
	p.manufacturer,
	p.price,
	p.units_sold,
	(p.price * p.units_sold) revenue
FROM phones p;

--- STRING FUNCTIONS ---

-- double pipe (||) - for string concatenation
SELECT name || ', ' || country AS location FROM cities;

-- CONCAT() for string concatenation
SELECT CONCAT(name, ', ', country) AS location FROM cities;

--- UPPER() 
SELECT 
	CONCAT(UPPER(name), ', ', UPPER(country)) AS location
FROM 
	cities;

SELECT 
	UPPER(CONCAT(name, ', ', country)) AS location
FROM 
	cities;












