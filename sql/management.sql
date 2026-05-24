--
-- schedoc_exclude_tool(tool text)
-- schedoc_exclude_tools_all()
-- schedoc_is_table_excluded(tableoid oid)
--
-- Set up the exclusion list
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_exclude_tool(tool text)
RETURNS text
LANGUAGE plpgsql AS
$EOF$
DECLARE
  nbrows bigint;
BEGIN
   --
   --
   --
   INSERT INTO @extschema@.schedoc_table_exclusion (schema_name, table_name, tag)
   SELECT schema_name, table_name, tool FROM @extschema@.schedoc_table_exclusion_templates
   WHERE tags @> ARRAY[tool];

   SELECT count(1) FROM @extschema@.schedoc_table_exclusion WHERE tag = tool INTO nbrows;

   RETURN format ('Inserted %s row(s) in schedoc_table_exclusion', nbrows);
END;
$EOF$;
--
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_exclude_tools_all()
RETURNS text
LANGUAGE plpgsql AS
$EOF$
DECLARE
  nbrows bigint;
BEGIN
   --
   --
   --
   INSERT INTO @extschema@.schedoc_table_exclusion (schema_name, table_name, tag)
   SELECT schema_name, table_name, tags[0] FROM @extschema@.schedoc_table_exclusion_templates;

   SELECT count(1) FROM @extschema@.schedoc_table_exclusion INTO nbrows;

   RETURN format ('Inserted %s row(s) in schedoc_table_exclusion', nbrows);
END;
$EOF$;
--
-- Check if a table is present in the exclusion list
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_is_table_excluded(tableoid oid)
RETURNS boolean
LANGUAGE plpgsql AS
$EOF$
DECLARE
  status boolean;
BEGIN
    WITH
    excluded AS (
      SELECT c.oid
      FROM pg_class c
      JOIN @extschema@.schedoc_table_exclusion ste ON ste.table_name = c.relname)
    ),
    internals AS (
      SELECT oid FROM excluded
      UNION
      SELECT c.oid FROM pg_class c
      JOIN pg_namespace n ON (n.oid = c.relnamespace)
      WHERE relname IN (
            'ddl_history',
            'ddl_history_column',
            'ddl_history_schema',
            'schedoc_column_log',
            'schedoc_column_raw',
            'schedoc_table_exclusion',
            'schedoc_table_exclusion_templates',
            'schedoc_valid',
            'schedoc_valid_status')
            AND n.nspname = '@extschema@'
     )
     SELECT count(1) > 0 FROM internals WHERE oid = tableoid INTO status;

     RETURN status;
END;
$EOF$;
--
--
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_init_existing_comments()
RETURNS void
LANGUAGE plpgsql AS
$EOF$
DECLARE
  status boolean;
BEGIN

    PERFORM @extschema@.schedoc_fill_raw(objoid, objsubid)
    FROM @extschema@.schedoc_column_existing_comments
    WHERE description IS NOT NULL;

END;
$EOF$;
