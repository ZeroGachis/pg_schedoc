--
--
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_start()
RETURNS void
    LANGUAGE plpgsql AS
$EOF$
BEGIN
   --
   -- Function to manage INSERT statements
   --
   CREATE OR REPLACE FUNCTION @extschema@.schedoc_trg()
        RETURNS trigger LANGUAGE plpgsql AS $fsub$
    BEGIN

    -- keep a log of all values
    INSERT INTO @extschema@.schedoc_column_log (objoid, objsubid, comment, is_valid)
    VALUES (
      NEW.objoid,
      NEW.objsubid,
      @extschema@.schedoc_get_column_description(NEW.objoid, NEW.objsubid),
      @extschema@.schedoc_get_column_description(NEW.objoid, NEW.objsubid) IS JSON
    );


   -- if the json is valid
   IF schedoc_get_column_description(NEW.objoid, NEW.objsubid) IS JSON THEN
    INSERT INTO @extschema@.schedoc_column_raw (objoid, objsubid, comment, status, is_valid)
    VALUES (
      NEW.objoid,
      NEW.objsubid,
      @extschema@.schedoc_get_column_description(NEW.objoid, NEW.objsubid)::jsonb,
      @extschema@.schedoc_get_column_status(NEW.objoid, NEW.objsubid)::public.schedoc_status,
      @extschema@.schedoc_get_column_description(NEW.objoid, NEW.objsubid) IS JSON
    ) ON CONFLICT (objoid, objsubid)
    DO UPDATE SET
      comment = @extschema@.schedoc_get_column_description(EXCLUDED.objoid, EXCLUDED.objsubid)::jsonb,
      status = @extschema@.schedoc_get_column_status(EXCLUDED.objoid, EXCLUDED.objsubid)::public.schedoc_status,
      is_valid = @extschema@.schedoc_get_column_description(NEW.objoid, NEW.objsubid) IS JSON;
    ELSE
    --
    -- This is not a valid json, we store it
    --
    INSERT INTO @extschema@.schedoc_column_raw (objoid, objsubid, is_valid)
    VALUES (
      NEW.objoid,
      NEW.objsubid,
      @extschema@.schedoc_get_column_description(NEW.objoid, NEW.objsubid) IS JSON
    ) ON CONFLICT (objoid, objsubid)
    DO UPDATE SET
      is_valid = @extschema@.schedoc_get_column_description(NEW.objoid, NEW.objsubid) IS JSON;
    END IF;
    RETURN NEW;
    END;
    $fsub$;

   ALTER ROUTINE @extschema@.schedoc_trg DEPENDS ON EXTENSION schedoc;
   --
   -- Executed when a new column is created
   --
   CREATE OR REPLACE FUNCTION @extschema@.schedoc_column_trg()
        RETURNS trigger LANGUAGE plpgsql AS $fsub$
    BEGIN
    --
    --
    INSERT INTO @extschema@.schedoc_column_raw (objoid, objsubid, is_valid)
    VALUES (
      NEW.attrelid,
      NEW.attnum,
      false
    ) ON CONFLICT (objoid, objsubid)
    DO UPDATE SET
      is_valid = false;

    RETURN NEW;
    END;
    $fsub$;

   ALTER ROUTINE @extschema@.schedoc_column_trg DEPENDS ON EXTENSION schedoc;
   --
   -- Create triggers on INSERT
   --
   CREATE TRIGGER schedoc_comment_trg
     BEFORE INSERT ON @extschema@.ddl_history
     FOR EACH ROW
     WHEN (NEW.ddl_tag = 'COMMENT')
     EXECUTE PROCEDURE @extschema@.schedoc_trg();

   ALTER TRIGGER schedoc_comment_trg ON @extschema@.ddl_history DEPENDS ON EXTENSION schedoc;

   CREATE TRIGGER schedoc_column_trg
     BEFORE INSERT ON @extschema@.ddl_history_column
     FOR EACH ROW
     EXECUTE PROCEDURE @extschema@.schedoc_column_trg();

   ALTER TRIGGER schedoc_column_trg ON @extschema@.ddl_history_column DEPENDS ON EXTENSION schedoc;

END;
$EOF$;

--
--
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_get_column_description(bjoid oid, bjsubid oid)
RETURNS text
    LANGUAGE plpgsql AS
$EOF$
DECLARE
  description TEXT;
BEGIN
    SELECT pg_description.description FROM pg_description
    WHERE pg_description.objoid=bjoid AND pg_description.objsubid=bjsubid INTO description;

    RETURN description;
END;
$EOF$;
--
--
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_get_column_status(bjoid oid, bjsubid oid)
RETURNS text
    LANGUAGE plpgsql AS
$EOF$
DECLARE
  status TEXT;
BEGIN
    SELECT pg_description.description::jsonb->>'status' FROM pg_description
    WHERE pg_description.objoid=bjoid AND pg_description.objsubid=bjsubid INTO status;

    RETURN status;
END;
$EOF$;
