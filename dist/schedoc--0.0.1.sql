--
--
--

CREATE TYPE schedoc_status AS ENUM ('public', 'private', 'legacy', 'wip');

CREATE TABLE schedoc_column_raw (
  objoid    oid,
  objsubid  oid,
  comment   jsonb,
  status    schedoc_status,
  PRIMARY KEY (objoid, objsubid)
);

CREATE VIEW schedoc_column_comments AS

    SELECT current_database() as databasename, c.relname as tablename, a.attname as columnname, status
    FROM schedoc_column_raw ccr
    JOIN pg_class c ON c.oid = ccr.objoid
    JOIN pg_attribute a ON (a.attnum = ccr.objsubid AND a.attrelid = ccr.objoid);
