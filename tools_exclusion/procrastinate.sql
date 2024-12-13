--
-- Debezium
--

INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES

('public', 'procrastinate_events', ARRAY['procrastinate']),
('public', 'procrastinate_jobs', ARRAY['procrastinate']),
('public', 'procrastinate_periodic_defers', ARRAY['procrastinate']);
