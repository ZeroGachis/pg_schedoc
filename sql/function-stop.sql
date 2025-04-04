--
-- Remove the triggers and the functions to stop the process
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_stop()
RETURNS void
    LANGUAGE plpgsql AS
$EOF$
BEGIN
   --
   -- Remove all triggers
   --
   DROP TRIGGER schedoc_comment_trg ON @extschema@.ddl_history;
   DROP TRIGGER schedoc_column_trg ON @extschema@.ddl_history_column;

   --
   -- Remove all functions
   --
   DROP FUNCTION @extschema@.schedoc_trg();
   DROP FUNCTION @extschema@.schedoc_column_trg();

END;
$EOF$;
