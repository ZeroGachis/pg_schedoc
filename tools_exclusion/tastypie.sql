--
--
--

INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES

('public', 'tastypie_apiaccess', ARRAY['tastypie']),
('public', 'tastypie_apikey', ARRAY['tastypie']);
