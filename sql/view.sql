DROP VIEW IF EXISTS schedoc_column_existing_comments;
CREATE OR REPLACE VIEW schedoc_column_existing_comments AS


    WITH descr AS (
      SELECT c.relname, d.description
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      LEFT JOIN pg_description d ON d.objoid = c.oid
      LEFT JOIN schedoc_table_exclusion e ON  e.table_name = c.relname
      WHERE c.relkind = 'r' AND n.nspname='public'
      AND  e.table_name IS NULL
AND c.relname NOT IN (

            'ddl_history',
            'ddl_history_column',
            'ddl_history_schema',
            'schedoc_column_log',
            'schedoc_column_raw',
            'schedoc_table_exclusion',
            'schedoc_table_exclusion_templates',
            'schedoc_valid',
            'schedoc_valid_status')
    )
    SELECT relname, description, description IS NOT NULL AND  description IS JSON as is_ok
    FROM descr

ORDER BY relname
;
