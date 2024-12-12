--
-- We assume that ddl_historization is installed in public schema
--
BEGIN;

DROP EXTENSION IF EXISTS schedoc CASCADE;
CREATE EXTENSION schedoc CASCADE;
SELECT schedoc_start();

-- 2
DROP TABLE IF EXISTS foobar_schedoc;
CREATE TABLE foobar_schedoc (id int, val int, foo int);

--
-- comment are allowed
--
COMMENT ON COLUMN foobar_schedoc.id IS '{"status": "private"}';
COMMENT ON COLUMN foobar_schedoc.val IS '{"status": "private"}';
COMMENT ON COLUMN foobar_schedoc.foo IS '{"status"  "private"}';

DROP TABLE foobar_schedoc;

COMMIT;
