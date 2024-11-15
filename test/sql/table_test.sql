--
-- We assume that ddl_historization is installed in public schema
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(8);

CREATE EXTENSION schedoc CASCADE;

SELECT has_extension('schedoc');
SELECT has_table('schedoc_column_raw');
SELECT has_view('schedoc_column_comments');

SELECT has_enum('data_status');

SELECT enum_has_labels('data_status', ARRAY['public', 'private', 'legacy', 'wip']);

SELECT has_function('schedoc_start');

SELECT has_function('schedoc_get_column_description', ARRAY['oid', 'oid']);
SELECT has_function('schedoc_get_column_status', ARRAY['oid', 'oid']);


ROLLBACK;
