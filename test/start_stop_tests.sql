--
-- We assume that ddl_historization is installed in public schema
--

SET search_path=public,pgtap;

BEGIN;

SELECT plan(17);

DROP EXTENSION IF EXISTS schedoc CASCADE;
CREATE EXTENSION schedoc CASCADE;

-- fail fast if the extension is not installed
SELECT has_extension('schedoc');

SELECT schedoc_start();

SELECT has_function('schedoc_trg');
SELECT has_function('schedoc_column_trg');
SELECT has_trigger('ddl_history'::name, 'schedoc_comment_trg'::name);
SELECT has_trigger('ddl_history_column'::name, 'schedoc_column_trg'::name);

SELECT schedoc_stop();

SELECT hasnt_function('schedoc_trg');
SELECT hasnt_function('schedoc_column_trg');
SELECT hasnt_trigger('ddl_history'::name, 'schedoc_comment_trg'::name);
SELECT hasnt_trigger('ddl_history_column'::name, 'schedoc_column_trg'::name);

SELECT schedoc_start();

SELECT has_function('schedoc_trg');
SELECT has_function('schedoc_column_trg');
SELECT has_trigger('ddl_history'::name, 'schedoc_comment_trg'::name);
SELECT has_trigger('ddl_history_column'::name, 'schedoc_column_trg'::name);

DROP EXTENSION schedoc;
--
-- objects are dropped without calling schedoc_stop()
--
SELECT hasnt_function('schedoc_trg');
SELECT hasnt_function('schedoc_column_trg');
SELECT hasnt_trigger('ddl_history'::name, 'schedoc_comment_trg'::name);
SELECT hasnt_trigger('ddl_history_column'::name, 'schedoc_column_trg'::name);

--
SELECT finish();

ROLLBACK;
