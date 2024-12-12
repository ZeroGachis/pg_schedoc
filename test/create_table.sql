--
--
--

SET search_path=public,pgtap;

BEGIN;

DROP EXTENSION IF EXISTS schedoc CASCADE;
CREATE EXTENSION schedoc CASCADE;
SELECT schedoc_start();

SELECT plan(2);

TRUNCATE ddl_history;
TRUNCATE ddl_history_column;

-- 2
CREATE TABLE schedoc_unitt (id int, label text);

--
SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(1 as bigint)',
    'We have 1 row in ddl_history');


SELECT results_eq(
    'SELECT count(*) FROM ddl_history_column',
    'SELECT CAST(2 as bigint)',
    'We have 2 rows in ddl_history_column');

DROP TABLE schedoc_unitt;

ROLLBACK;
