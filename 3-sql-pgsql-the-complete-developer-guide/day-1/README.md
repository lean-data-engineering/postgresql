# day-1

- create table
- insert data into table
  - without using column name: every column value should be given in order.
  - with specifying column name:
    - list column name and give its values
    - table column order doesn't matter
    - values should be given in order of projection list you are using
- selection/fetching/querying the data
  - use wild card `*` to fetch all columns
  - give project list to get specific columns
  - add calculated columns
  - add aliases to column names
- string scalar/row-level functions
  - concatenate the string columns
    - use double pipe `||` or `CONCAT()`
  - upper case: `UPPER`
  - lower case: `LOWER`
