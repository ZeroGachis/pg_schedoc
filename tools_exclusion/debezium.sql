--
-- Debezium
--

INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES

('public', 'dbz_signal', ARRAY['debezium']),
('public', 'dbz_heartbeat', ARRAY['debezium']);
