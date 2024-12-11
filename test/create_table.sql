--
--
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(2);

TRUNCATE ddl_history;
TRUNCATE ddl_history_columns;

-- 2
CREATE TABLE foobar_schedoc (id int, label text);

--
SELECT results_eq(
    'SELECT count(*) FROM ddl_history',
    'SELECT CAST(1 as bigint)',
    'We have 1 row in ddl_history');


SELECT results_eq(
    'SELECT count(*) FROM ddl_history_columns',
    'SELECT CAST(2 as bigint)',
    'We have 2 rows in ddl_history_columns');





DROP TABLE foobar_schedoc;


ROLLBACK;
