--
-- We assume that ddl_historization is installed in public schema
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(9);

TRUNCATE ddl_history;

-- 2
CREATE TABLE foobar_schedoc (id int);



DROP EXTENSION IF EXISTS schedoc;
CREATE EXTENSION schedoc;

SELECT has_extension('schedoc');
SELECT has_table('schedoc_column_raw');
SELECT has_view('schedoc_column_comments');


SELECT schedoc_start();

-- 3
ALTER TABLE foobar_schedoc ADD COLUMN toto int;
CREATE INDEX ON foobar_schedoc (toto);

--
TRUNCATE ddl_history;
COMMENT ON COLUMN foobar_schedoc.id IS '{"status": "private"}';

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


CREATE OR REPLACE FUNCTION setcomm_unauthorized_value()
RETURNS void
    LANGUAGE plpgsql AS
$EOF$
BEGIN
  COMMENT ON COLUMN foobar_schedoc.id IS '{"status": "foobar"}';
END;
$EOF$;

PREPARE unauthorized_value AS SELECT * FROM setcomm_unauthorized_value();
SELECT throws_ok(
    'unauthorized_value',
    '22P02',
    'invalid input value for enum data_status: "foobar"',
    'We should get an input value error'
);
--
-- The comment is not in JSONB format
--
CREATE OR REPLACE FUNCTION setcomm_wrong_format()
RETURNS void
    LANGUAGE plpgsql AS
$EOF$
BEGIN
  COMMENT ON COLUMN foobar_schedoc.id IS 'This is not a JSON';
END;
$EOF$;

PREPARE wrong_format AS SELECT * FROM setcomm_wrong_format();
SELECT throws_ok(
    'wrong_format',
    '22P02',
    'invalid input syntax for type json',
    'We should get an input syntax error'
);


ROLLBACK;
