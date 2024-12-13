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
