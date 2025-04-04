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
CREATE TABLE @extschema@.schedoc_table_exclusion (
  schema_name name,
  table_name name,
  tag text,
  created_at timestamp with time zone DEFAULT current_timestamp,
  created_by text DEFAULT current_user,
  PRIMARY KEY (schema_name, table_name)
);

CREATE TABLE @extschema@.schedoc_table_exclusion_templates (
  schema_name name,
  table_name name,
  tags text[],
  created_at timestamp with time zone DEFAULT current_timestamp,
  created_by text DEFAULT current_user,
  PRIMARY KEY (schema_name, table_name)
);

--
--
--
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
      JOIN @extschema@.schedoc_table_exclusion ste ON ste.table_name = c.relname
      JOIN pg_namespace n ON (n.oid = c.relnamespace AND n.nspname = ste.schema_name)
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
--
--

CREATE VIEW schedoc_column_comments AS

    SELECT current_database() as databasename, c.relname as tablename, a.attname as columnname, status
    FROM schedoc_column_raw ccr
    JOIN pg_class c ON c.oid = ccr.objoid
    JOIN pg_attribute a ON (a.attnum = ccr.objsubid AND a.attrelid = ccr.objoid);
--
--
--
CREATE OR REPLACE VIEW schedoc_object_tables AS

    SELECT n.nspname, c.relname
    FROM pg_depend d
    JOIN pg_class c ON c.oid = d.objid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_extension e ON e.oid = d.refobjid
    WHERE e.extname in ('schedoc', 'ddl_historization')
    AND c.relkind = 'r';
--
--
--
DROP VIEW IF EXISTS schedoc_column_existing_comments;
CREATE OR REPLACE VIEW schedoc_column_existing_comments AS

    WITH descr AS (
      SELECT c.oid as objoid, d.objsubid, c.relname, d.description
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
      LEFT JOIN pg_description d ON d.objoid = c.oid
      LEFT JOIN schedoc_table_exclusion e ON  e.table_name = c.relname
      WHERE c.relkind = 'r' AND n.nspname='public'
      AND  e.table_name IS NULL
      AND c.relname NOT IN (
            SELECT relname FROM @extschema@.schedoc_object_tables)
    )
    SELECT objoid, objsubid, relname, description, description IS NOT NULL AND  description IS JSON as is_ok
    FROM descr

ORDER BY relname
;
--
-- Debezium
--

INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES

('public', 'celery_results_taskresult', ARRAY['celery']),
('public', 'celery_taskmeta', ARRAY['celery']),
('public', 'celery_tasksetmeta', ARRAY['celery']),

('public', 'djcelery_crontabschedule', ARRAY['celery']),
('public', 'djcelery_intervalschedule', ARRAY['celery']),
('public', 'djcelery_periodictask', ARRAY['celery']),
('public', 'djcelery_taskstate', ARRAY['celery']),
('public', 'djcelery_workerstate', ARRAY['celery']);
--
-- Debezium
--

INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES

('public', 'dbz_signal', ARRAY['debezium']),
('public', 'dbz_heartbeat', ARRAY['debezium']);
--
-- Exclude tables created by Django Framework
--
-- https://www.djangoproject.com/
--
INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES
('public', 'auth_group', ARRAY['django']),
('public', 'auth_group_permissions', ARRAY['django']),
('public', 'auth_permission', ARRAY['django']),
('public', 'auth_user', ARRAY['django']),
('public', 'auth_user_groups', ARRAY['django']),
('public', 'auth_user_user_permissions', ARRAY['django']),
('public', 'django_admin_log', ARRAY['django']),
('public', 'django_content_type', ARRAY['django']),
('public', 'django_migrations', ARRAY['django']),
('public', 'django_session', ARRAY['django']);
--
-- Debezium
--

INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES

('public', 'procrastinate_events', ARRAY['procrastinate']),
('public', 'procrastinate_jobs', ARRAY['procrastinate']),
('public', 'procrastinate_periodic_defers', ARRAY['procrastinate']);
--
--
--

INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES

('public', 'tastypie_apiaccess', ARRAY['tastypie']),
('public', 'tastypie_apikey', ARRAY['tastypie']);
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
--
--
