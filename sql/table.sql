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
-- List the table to exclude
--
CREATE TABLE @extschema@.schedoc_table_exclusion (
  schema_name name,
  table_name name,
  tag text,
  created_at timestamp with time zone DEFAULT current_timestamp,
  created_by text DEFAULT current_user,
  PRIMARY KEY (schema_name, table_name)
);
--
-- Collection of table names related to specific tools identified by tag
--
CREATE TABLE @extschema@.schedoc_table_exclusion_templates (
  schema_name name,
  table_name name,
  tags text[],
  created_at timestamp with time zone DEFAULT current_timestamp,
  created_by text DEFAULT current_user,
  PRIMARY KEY (schema_name, table_name)
);
