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
   -- This function is called by a trigger on ddl_history
   CREATE OR REPLACE FUNCTION @extschema@.schedoc_trg()
        RETURNS trigger LANGUAGE plpgsql AS $fsub$
    BEGIN

    PERFORM @extschema@.schedoc_fill_raw(NEW.objoid, NEW.objsubid);

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
    IF NOT @extschema@.schedoc_is_table_excluded(NEW.attrelid) THEN
    INSERT INTO @extschema@.schedoc_column_raw (objoid, objsubid, is_valid)
    VALUES (
      NEW.attrelid,
      NEW.attnum,
      false
    ) ON CONFLICT (objoid, objsubid)
    DO UPDATE SET
      is_valid = false;
    END IF;
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
-- schedoc_fill_raw
--
CREATE OR REPLACE FUNCTION @extschema@.schedoc_fill_raw(p_oid oid, p_subid oid)
RETURNS void
    LANGUAGE plpgsql AS
$EOF$
BEGIN
    --
    --
    -- keep a log of all values
    INSERT INTO @extschema@.schedoc_column_log (objoid, objsubid, comment, is_valid)
    VALUES (
        p_oid,
        p_subid,
        @extschema@.schedoc_get_column_description(p_oid, p_subid),
        @extschema@.schedoc_get_column_description(p_oid, p_subid) IS JSON
    );

    IF NOT @extschema@.schedoc_is_table_excluded(p_oid) THEN
       -- if the json is valid
       IF schedoc_get_column_description(p_oid, p_subid) IS JSON THEN
          INSERT INTO @extschema@.schedoc_column_raw (objoid, objsubid, comment, status, is_valid)
          VALUES (
             p_oid,
             p_subid,
             @extschema@.schedoc_get_column_description(p_oid, p_subid)::jsonb,
             @extschema@.schedoc_get_column_status(p_oid, p_subid)::@extschema@.schedoc_status,
             @extschema@.schedoc_get_column_description(p_oid, p_subid) IS JSON
          ) ON CONFLICT (objoid, objsubid)
          DO UPDATE SET
             comment = @extschema@.schedoc_get_column_description(EXCLUDED.objoid, EXCLUDED.objsubid)::jsonb,
             status = @extschema@.schedoc_get_column_status(EXCLUDED.objoid, EXCLUDED.objsubid)::@extschema@.schedoc_status,
             is_valid = @extschema@.schedoc_get_column_description(p_oid, p_subid) IS JSON;
       ELSE
           --
           -- This is not a valid json, we store it
           --
           INSERT INTO @extschema@.schedoc_column_raw (objoid, objsubid, is_valid)
           VALUES (
               p_oid,
               p_subid,
               @extschema@.schedoc_get_column_description(p_oid, p_subid) IS JSON
           ) ON CONFLICT (objoid, objsubid)
           DO UPDATE SET
               is_valid = @extschema@.schedoc_get_column_description(EXCLUDED.objoid, EXCLUDED.objsubid) IS JSON;
       END IF;
    END IF;
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
