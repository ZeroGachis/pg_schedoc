--
--
--

CREATE VIEW schedoc_column_comments AS

    SELECT current_database() as databasename, c.relname as tablename, a.attname as columnname, status
    FROM schedoc_column_raw ccr
    JOIN pg_class c ON c.oid = ccr.objoid
    JOIN pg_attribute a ON (a.attnum = ccr.objsubid AND a.attrelid = ccr.objoid);
--
--
--
CREATE OR REPLACE VIEW schedoc_object_tables AS

    SELECT n.nspname, c.relname
    FROM pg_depend d
    JOIN pg_class c ON c.oid = d.objid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_extension e ON e.oid = d.refobjid
    WHERE e.extname in ('schedoc', 'ddl_historization')
    AND c.relkind = 'r';
--
--
--
DROP VIEW IF EXISTS schedoc_column_existing_comments;
CREATE OR REPLACE VIEW schedoc_column_existing_comments AS

    WITH descr AS (
      SELECT c.oid as objoid, d.objsubid, c.relname, d.description
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      LEFT JOIN pg_description d ON d.objoid = c.oid
      LEFT JOIN schedoc_table_exclusion e ON  e.table_name = c.relname
      WHERE c.relkind = 'r' AND n.nspname='public'
      AND  e.table_name IS NULL
      AND c.relname NOT IN (
            SELECT relname FROM @extschema@.schedoc_object_tables)
    )
    SELECT objoid, objsubid, relname, description, description IS NOT NULL AND  description IS JSON as is_ok
    FROM descr

ORDER BY relname
;
