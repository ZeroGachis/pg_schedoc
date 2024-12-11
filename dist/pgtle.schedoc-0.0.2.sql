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
CREATE TABLE schedoc_valid (status boolean NOT NULL PRIMARY KEY CHECK (status = true));
INSERT INTO schedoc_valid (status) VALUES (true);
--
-- The column is_valid references schedoc_status to make sure we have
-- true in this column but in a way that permits to deferre the check
-- of the constraint.
--
-- When adding a new column there is no COMMENT on it, but this way we
-- enforce that any new column creation must include in the same
-- transaction a COMMENT statement.
--
CREATE TABLE schedoc_column_raw (
  objoid    oid,
  objsubid  oid,
  comment   jsonb,
  is_valid  boolean DEFAULT false REFERENCES schedoc_valid (status) DEFERRABLE INITIALLY DEFERRED,
  status    schedoc_status,
  PRIMARY KEY (objoid, objsubid)
);

CREATE VIEW schedoc_column_comments AS

    SELECT current_database() as databasename, c.relname as tablename, a.attname as columnname, status
    FROM schedoc_column_raw ccr
    JOIN pg_class c ON c.oid = ccr.objoid
    JOIN pg_attribute a ON (a.attnum = ccr.objsubid AND a.attrelid = ccr.objoid);

--
--
--
--
--
CREATE OR REPLACE FUNCTION schedoc_start()
RETURNS void
    LANGUAGE plpgsql AS
$EOF$
DECLARE
  schemaname TEXT;
BEGIN
  SELECT n.nspname FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace WHERE e.extname='ddl_historization' INTO schemaname;

   --
   -- Function to manage INSERT statements
   --

   EXECUTE format('CREATE OR REPLACE FUNCTION %s.schedoc_trg()
        RETURNS trigger LANGUAGE plpgsql AS $$
    BEGIN
    INSERT INTO %s.schedoc_column_raw (objoid, objsubid, comment, status)
    VALUES (
      NEW.objoid,
      NEW.objsubid,
      %s.schedoc_get_column_description(NEW.objoid, NEW.objsubid)::jsonb,
      %s.schedoc_get_column_status(NEW.objoid, NEW.objsubid)::public.schedoc_status,
    ) ON CONFLICT (objoid, objsubid)
    DO UPDATE SET
      comment = %s.schedoc_get_column_description(EXCLUDED.objoid, EXCLUDED.objsubid)::jsonb,
      status = %s.schedoc_get_column_status(EXCLUDED.objoid, EXCLUDED.objsubid)::public.schedoc_status;
    RETURN NEW;
    END;
$$', schemaname, schemaname, schemaname, schemaname, schemaname, schemaname);

   --
   -- Create two triggers, one for UPDATE and one for INSERT
   --

   EXECUTE format('
     CREATE TRIGGER schedoc_trg
       BEFORE INSERT ON %s.ddl_history
       FOR EACH ROW
       WHEN (NEW.ddl_tag = ''COMMENT'')
       EXECUTE PROCEDURE %s.schedoc_trg()',
     schemaname,schemaname);

END;
$EOF$;

--
--
--
CREATE OR REPLACE FUNCTION schedoc_get_column_description(bjoid oid, bjsubid oid)
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
CREATE OR REPLACE FUNCTION schedoc_get_column_status(bjoid oid, bjsubid oid)
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
--
SELECT schedoc_start();
$_pg_tle_$
);
