SELECT pgtle.install_extension
(
 'schedoc',
 '0.0.2',
 'Schema documentation based on COMMENT',
$_pg_tle_$
--
--
--

CREATE TYPE schedoc_status AS ENUM ('public', 'private', 'legacy', 'wip');

-- The table schedoc_status stores only one value, this table is used
-- as a foreign key target
--
--
CREATE TABLE @extschema@.schedoc_valid (status boolean NOT NULL PRIMARY KEY CHECK (status = true));
INSERT INTO schedoc_valid (status) VALUES (true);
--
--
--
CREATE TABLE @extschema@.schedoc_valid_status (status schedoc_status NOT NULL PRIMARY KEY);
INSERT INTO schedoc_valid_status VALUES ('public'), ('private'), ('legacy'), ('wip');
--
-- The column is_valid references schedoc_status to make sure we have
-- true in this column but in a way that permits to deferre the check
-- of the constraint.
--
-- When adding a new column there is no COMMENT on it, but this way we
-- enforce that any new column creation must include in the same
-- transaction a COMMENT statement.
--
CREATE TABLE @extschema@.schedoc_column_raw (
  objoid    oid,
  objsubid  oid,
  comment   jsonb,
--  is_valid  boolean DEFAULT false REFERENCES @extschema@.schedoc_valid (status) DEFERRABLE INITIALLY DEFERRED,
--  status    schedoc_status REFERENCES @extschema@.schedoc_valid_status (status) DEFERRABLE INITIALLY DEFERRED,
  is_valid  boolean DEFAULT false,
  status    schedoc_status,
  PRIMARY KEY (objoid, objsubid)
);

--
--
--
CREATE TABLE @extschema@.schedoc_column_log (
  objoid    oid,
  objsubid  oid,
  comment   text,
  is_valid  boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT current_timestamp
);
--
--
--

CREATE VIEW @extschema@.schedoc_column_comments AS

    SELECT current_database() as databasename, c.relname as tablename, a.attname as columnname, status
    FROM schedoc_column_raw ccr
    JOIN pg_class c ON c.oid = ccr.objoid
    JOIN pg_attribute a ON (a.attnum = ccr.objsubid AND a.attrelid = ccr.objoid);

--
--
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
      @extschema@.schedoc_get_column_status(NEW.objoid, NEW.objsubid)::@extschema@.schedoc_status,
      @extschema@.schedoc_get_column_description(NEW.objoid, NEW.objsubid) IS JSON
    ) ON CONFLICT (objoid, objsubid)
    DO UPDATE SET
      comment = @extschema@.schedoc_get_column_description(EXCLUDED.objoid, EXCLUDED.objsubid)::jsonb,
      status = @extschema@.schedoc_get_column_status(EXCLUDED.objoid, EXCLUDED.objsubid)::@extschema@.schedoc_status,
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
   IF (SELECT count(*) = 2 from pg_proc where proname in ('schedoc_trg','schedoc_column_trg')) THEN
     RETURN 'Extension schedoc is started';
   ELSE
     RETURN 'Extension schedoc is stopped';
   END IF;
END;
$EOF$;
--
-- Check the schema of installation for schedoc
--
DO
LANGUAGE plpgsql
$check_start$
BEGIN

IF NOT EXISTS (SELECT n.nspname FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace
   WHERE e.extname='ddl_historization' AND n.nspname='@extschema@') THEN

    RAISE EXCEPTION 'schedoc must be installed in the same schema as ddl_historization';

END IF;

END;
$check_start$;
$_pg_tle_$
);
