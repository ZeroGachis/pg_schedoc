--
-- Remove the triggers and the functions to stop the process
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_status()
RETURNS text
    LANGUAGE plpgsql AS
$EOF$
DECLARE message text;
BEGIN
   --
   -- Remove all triggers
   --
   IF SELECT count(*) = 2 from pg_proc where proname in ('schedoc_trg','schedoc_column_trg') THEN
     RETURN 'Extension schedoc is started';
   ELSE
     RETURN 'Extension schedoc is stopped';
   END IF;
END;
$EOF$;
