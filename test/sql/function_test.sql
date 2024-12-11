--
-- We assume that ddl_historization is installed in public schema
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(4);

SELECT has_extension('schedoc');

SELECT has_function('schedoc_start');
SELECT has_function('schedoc_get_column_description', ARRAY['oid', 'oid']);
SELECT has_function('schedoc_get_column_status', ARRAY['oid', 'oid']);

ROLLBACK;
