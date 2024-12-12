--
-- We assume that ddl_historization is installed in public schema
--
SET search_path=public,pgtap;

BEGIN;

SELECT plan(2);

SELECT has_extension('schedoc');

SELECT has_function('schedoc_status');

ROLLBACK;
