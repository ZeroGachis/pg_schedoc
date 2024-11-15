--
-- We assume that ddl_historization is installed in public schema
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(6);

CREATE EXTENSION schedoc CASCADE;

SELECT has_extension('schedoc');
SELECT has_table('schedoc_column_raw');
SELECT has_view('schedoc_column_comments');

SELECT has_enum('data_status');

SELECT enum_has_labels('data_status', ARRAY['public', 'private', 'legacy', 'wip']);

SELECT has_function('schedoc_start');

ROLLBACK;
