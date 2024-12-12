--
--
--
SET search_path=public,pgtap;

BEGIN;

DROP EXTENSION IF EXISTS schedoc CASCADE;
CREATE EXTENSION schedoc CASCADE;
SELECT schedoc_start();

SELECT plan(3);

TRUNCATE schedoc_column_raw;

-- 2
CREATE TABLE schedoc_unit_t (id int);

COMMENT ON COLUMN schedoc_unit_t.id IS '{"status": "private"}';

-- 1 row for the column id created during the CREATE TABLE
-- 1 row for the column toto created with THE ALTER
--
SELECT results_eq(
    'SELECT count(*) FROM schedoc_column_raw',
    'SELECT CAST(1 as bigint)',
    'We have 1 row in schedoc_column_raw');

--
SELECT results_eq(
    'SELECT comment,status::text FROM schedoc_column_raw',
    'SELECT ''{"status": "private"}''::jsonb, ''private''::text ',
    'We have right values in schedoc_column_raw');

-- add a column
ALTER TABLE schedoc_unit_t ADD COLUMN toto int;

-- 1 row for the column id created during the CREATE TABLE
-- 1 row for the column toto created with THE ALTER

SELECT results_eq(
    'SELECT count(*) FROM schedoc_column_raw',
    'SELECT CAST(2 as bigint)',
    'We have 2 rows in schedoc_column_raw');

ROLLBACK;
