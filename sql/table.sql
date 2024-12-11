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
