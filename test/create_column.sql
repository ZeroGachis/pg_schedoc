--
--
--
SET search_path=public,pgtap;

BEGIN;

SELECT plan(4);

TRUNCATE ddl_history;

-- 2
CREATE TABLE schedoc_unit_t (id int);

DROP EXTENSION IF EXISTS schedoc CASCADE;
CREATE EXTENSION schedoc CASCADE;


-- create some objects non concerned by the extension
ALTER TABLE schedoc_unit_t ADD COLUMN toto int;
CREATE INDEX ON schedoc_unit_t (toto);

--
TRUNCATE ddl_history;
COMMENT ON COLUMN schedoc_unit_t.id IS '{"status": "private"}';

--
SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(1 as bigint)',
    'We have 1 row in ddl_history');

SELECT results_eq(
    'SELECT count(*) FROM schedoc_column_raw',
    'SELECT CAST(1 as bigint)',
    'We have 1 row in schedoc_column_raw');

SELECT results_eq(
    'SELECT comment,status::text FROM schedoc_column_raw LIMIT 1',
    'SELECT ''{"status": "private"}''::jsonb, ''private''::text ',
    'We have right values in schedoc_column_raw');


SELECT results_eq(
    'SELECT status::text FROM schedoc_column_raw',
    'SELECT ''private''::text ',
    'We have right values in schedoc_column_comments');

ROLLBACK;
