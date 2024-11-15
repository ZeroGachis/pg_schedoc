--
-- We assume that ddl_historization is installed in public schema
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(3);

TRUNCATE ddl_history;

-- 2
CREATE TABLE foobar_schedoc (id int);

DROP EXTENSION IF EXISTS schedoc CASCADE;
CREATE EXTENSION schedoc CASCADE;

-- add test on schema to fail fast
SELECT has_extension('schedoc');
SELECT has_table('schedoc_column_raw');
SELECT has_view('schedoc_column_comments');

COMMENT ON COLUMN foobar_schedoc.id IS '{"status": "private"}';

--
-- DROP manually the trigger and recreate it
--
DROP TRIGGER schedoc_trg ON ddl_history ;
SELECT schedoc_start();

COMMENT ON COLUMN foobar_schedoc.id IS '{"status": "private"}';

ROLLBACK;
