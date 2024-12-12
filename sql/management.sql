--
--
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
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_is_table_excluded(tableoid oid)
RETURNS boolean
LANGUAGE plpgsql AS
$EOF$
DECLARE
  status boolean;
BEGIN
    SELECT count(1) = 1
    FROM pg_class c
    JOIN @extschema@.schedoc_table_exclusion ste ON ste.table_name = c.relname
    JOIN pg_namespace n ON (n.oid = c.relnamespace AND n.nspname = ste.schema_name)
    WHERE c.oid = tableoid
    INTO status;

    RETURN status;
END;
$EOF$;
