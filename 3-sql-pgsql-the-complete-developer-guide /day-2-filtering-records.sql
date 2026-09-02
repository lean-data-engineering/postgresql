-- 1. find name, area of cities with area >= 4000
-----------------------------------------------------------
-- 2. find name, area of cities with area = 8223
-----------------------------------------------------------
-- 3. find name, area of cities that don't have area of 8223
-----------------------------------------------------------
-- 4. find name, area of cities between area of 2000 and 4000
-- note: use comparison optrs `<=`, `>=` and logical optr `AND`
-----------------------------------------------------------
-- 5. find name, area of cities between area of 2000 and 4000
-- note: using `BETWEEN` comparison optr
-- `<lower-bound> BETWEEN <upper-bound>` is inclusive
-----------------------------------------------------------
-- 5.find list of cites with name is either `Delhi` or `Shanghai`
-- note: use `OR` logical operators
-----------------------------------------------------------
-- 7.find list of cities with name is either `Delhi` or `Shanghai`
-- note: use `IN` logical operator
-----------------------------------------------------------
-- 8.find list of cities with name is either `Delhi` or `Shanghai`
-- note: use `ANY`/`SOME` logical optr and learn about difference between using `IN` and `ANY`/`SOME`
-----------------------------------------------------------
-- 9.find list of cities where city name is not either `Delhi` or `Shanghai`
-- note use 1. logical OR/NOT/AND ,2. use IN, 3. use ANY
-----------------------------------------------------------
-- 10.find cities not having `area` of 3843 or 8223
-----------------------------------------------------------
-- 11. find cities not having `area` of 3843 or 8223 and name is `Delhi`
-----------------------------------------------------------
-- 12. find cities not having `area` of 3843 or 8223 or name is `Delhi`
-----------------------------------------------------------
-- 13. find cities not having `area` of 3843 or 8223 or name is `Delhi` or name is `Tokyo`
-----------------------------------------------------------
-- 14. get `name` and `price` of all `phones` that sold greater than 5000 units.
-----------------------------------------------------------
-- 15. get `name` and `manufacturer` for all phones created by 'Apple' or 'Samsung'
-- note: 1. use `IN` logical optr, 2. use `OR` logical optr
-----------------------------------------------------------
-- 17. find all cities fields along with population_density (computed column) of all the cities.
-- understand ALIASES and `AS` keyword used to give temp names to columns,tables.
-----------------------------------------------------------
-- 16. find all the cities with population_density (computed column) having population density of more than 6000.
-- understand why we can't use computed columns in where clause?
-----------------------------------------------------------
-- 17. find `name` and `total_revenue` of all `phones` with a `total_revenue` [computed column (units_sold * price)] greater than 1,000,000
-----------------------------------------------------------
-- 18. update the `population` of `Tokyo` to 39505000
-- understand UPDATE statement with SET and WHERE clauses. and importance of where clause and what blunder happens if you miss WHERE.
-----------------------------------------------------------
-- 19. delete  'Tokyo' city.
-- undstand the importance of WHERE caluse in DELETE statement.
-----------------------------------------------------------
-- 20.1. update the `units_sold` of the phone with name `N8` TO 8543
-- 20.2. list all the phones
-----------------------------------------------------------
-- 21.1. delete all phones tahat are created by `Samsung`
-- 21.2. list all the phones
-----------------------------------------------------------
-------------------------------------------------------------
---------------------  SOLUTION -----------------------------
-------------------------------------------------------------
-- 1. find name, area of cities with area >= 4000
SELECT
	name,
	area
FROM
	cities;

-----------------------------------------------------------
-- 2. find name, area of cities with area = 8223
SELECT
	name,
	area
FROM
	cities
WHERE
	area = 8223;

-----------------------------------------------------------
-- 3. find name, area of cities that don't have area of 8223
SELECT
	name,
	area
FROM
	cities
WHERE
	area <> 8223;

-----------------------------------------------------------
-- 4. find name, area of cities between area of 2000 and 4000
-- note: use comparison optrs `<=`, `>=` and logical optr `AND`
SELECT
	name,
	area
FROM
	cities
WHERE
	area >= 2000
	AND area <= 4000;

-----------------------------------------------------------
-- 5. find name, area of cities between area of 2000 and 4000
-- note: using `BETWEEN` comparison optr
-- `<lower-bound> BETWEEN <upper-bound>` is inclusive
SELECT
	name,
	area
FROM
	cities
WHERE
	area BETWEEN 2000 AND 4000;

-----------------------------------------------------------
-- 5.find list of cites with name is either `Delhi` or `Shanghai`
-- note: use `OR` logical operators
SELECT
	*
FROM
	cities
WHERE
	(LOWER(name) = 'delhi')
	OR (LOWER(name) = 'shanghai');

-----------------------------------------------------------
-- 7.find list of cities with name is either `Delhi` or `Shanghai`
-- note: use `IN` logical operator
SELECT
	*
FROM
	cities
WHERE
	name IN ('Delhi', 'Shanghai');

-----------------------------------------------------------
-- 8.find list of cities with name is either `Delhi` or `Shanghai`
-- note: use `ANY`/`SOME` logical optr and learn about difference between using `IN` and `ANY`/`SOME`
SELECT
	*
FROM
	cities
WHERE
	name = ANY(ARRAY['Delhi', 'Shanghai']);
-----------------------------------------------------------
-- 9.find list of cities where city name is not either `Delhi` or `Shanghai`
-- note use 1. logical OR/NOT/AND ,2. use IN, 3. use ANY
SELECT
	*
FROM
	cities
WHERE
	name <> 'Delhi'
	AND name <> 'Shanghai';
-------------
SELECT
	*
FROM
	cities
WHERE
	NOT (
		name = 'Delhi'
		OR name = 'Shanghai'
	);
--------------
SELECT
	*
FROM
	cities
WHERE
	name NOT IN ('Delhi', 'Shanghai');
--------------
SELECT
	*
FROM
	cities
WHERE
	name <> ANY (ARRAY['Delhi', 'Shanghai']);
-- WRONG QUERY - gives all rows
-- Behavior: This returns rows where the name is not equal to at least one of the values in the array.
-- The Catch: "Delhi" is not equal to "Shanghai", so "Delhi" satisfies the condition. "Shanghai" is not equal to "Delhi", so "Shanghai" also satisfies it.
-- Result: It effectively matches every city and excludes nothing. To get the same result as the first two, you must use <> ALL.
---------------
SELECT
	*
FROM
	cities
WHERE
	NOT name = ANY(ARRAY['Delhi', 'Shanghai']);
--------------
SELECT
	*
FROM
	cities
WHERE
	name <> ALL(ARRAY['Delhi', 'Shanghai']);
-----------------------------------------------------------
-- 10.find cities not having `area` of 3843 and 8223
SELECT
	*
FROM
	cities
WHERE
	area <> 3843
	AND area <> 8223;

-----------------------------------------------------------
-- 11. find cities not having `area` of 3843 and 8223 and name is `Delhi`
SELECT
	*
FROM
	cities
WHERE
	area NOT IN (3843, 8223)
	AND name = 'Delhi';

-----------------------------------------------------------
-- 12. find cities not having `area` of 3843 or 8223 or name is `Delhi`
SELECT
	*
FROM
	cities
WHERE
	area NOT IN (3843, 8223)
	OR name = 'Delhi';

-----------------------------------------------------------
-- 13. find cities not having `area` of 3843 or 8223 or name is `Delhi` or name is `Tokyo`
SELECT
	*
FROM
	cities
WHERE
	area NOT IN (3843, 8223)
	OR name = 'Delhi'
	OR name = 'Tokyo';

-----------------------------------------------------------
-- 14. get `name` and `price` of all `phones` that sold greater than 5000 units.
SELECT
	name,
	price
FROM
	phones
WHERE
	units_sold > 5000;

-----------------------------------------------------------
-- 15. get `name` and `manufacturer` for all phones created by 'Apple' or 'Samsung'
-- note: 1. use `IN` logical optr, 2. use `OR` logical optr
SELECT
	name,
	manufacturer
FROM
	phones
WHERE
	manufacturer = 'Apple'
	OR manufacturer = 'Samsung';

SELECT
	name,
	manufacturer
FROM
	phones
WHERE
	manufacturer IN ('Apple', 'Samsung');

-----------------------------------------------------------
-- 17. find all cities fields along with population_density (computed column) of all the cities.
-- understand ALIASES and `AS` keyword used to give temp names to columns,tables.
SELECT
	*,
	(population / area) AS population_density
FROM
	cities;

-- `AS` is optional you can just place alias name after space.
SELECT
	*,
	(population / area) population_density
FROM
	cities;

-----------------------------------------------------------
-- 16. find all the cities with population_density (computed column) having population density of more than 6000.
-- understand why we can't use computed columns in where clause?
SELECT
	*,
	(population / area) AS population_density
FROM
	cities
WHERE
	(population / area) > 6000;

-----------------------------------------------------------
-- 17. find `name` and `total_revenue` of all `phones` with a `total_revenue` [computed column (units_sold * price)] greater than 1,000,000
SELECT
	name,
	(price * units_sold) AS total_revenue
FROM
	phones
WHERE
	(price * units_sold) > 1000000;

-----------------------------------------------------------
-- 18. update the `population` of `Tokyo` to 39505000
-- understand UPDATE statement with SET and WHERE clauses. and importance of where clause and what blunder happens if you miss WHERE.
UPDATE cities
SET
	population = 39505000
WHERE
	name = 'Tokyo';

-----------------------------------------------------------
-- 19. delete  'Tokyo' city.
-- undstand the importance of WHERE caluse in DELETE statement.
DELETE FROM cities
WHERE
	name = 'Tokyo';

-----------------------------------------------------------
-- 20.1. update the `units_sold` of the phone with name `N1280` TO 8543
UPDATE phones
SET
	units_sold = 8543
WHERE
	name = 'N1280';

-- 20.2. list all the phones
SELECT
	*
FROM
	phones;

-----------------------------------------------------------
-- 21.1. delete all phones tahat are created by `Samsung`
DELETE FROM phones
WHERE
	manufacturer = 'Samsung';

-- 21.2. list all the phones
SELECT
	*
FROM
	phones;

-----------------------------------------------------------