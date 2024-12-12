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
