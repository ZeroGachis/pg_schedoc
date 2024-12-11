--
-- We assume that ddl_historization is installed in public schema
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(5);

SELECT has_extension('schedoc');
SELECT has_table('schedoc_column_raw');
SELECT has_view('schedoc_column_comments');

SELECT has_enum('schedoc_status');

SELECT enum_has_labels('schedoc_status', ARRAY['public', 'private', 'legacy', 'wip']);

ROLLBACK;
