--
-- Debezium
--

INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES

('public', 'celery_results_taskresult', ARRAY['celery']),
('public', 'celery_taskmeta', ARRAY['celery']),
('public', 'celery_tasksetmeta', ARRAY['celery']),

('public', 'djcelery_crontabschedule', ARRAY['celery']),
('public', 'djcelery_intervalschedule', ARRAY['celery']),
('public', 'djcelery_periodictask', ARRAY['celery']),
('public', 'djcelery_taskstate', ARRAY['celery']),
('public', 'djcelery_workerstate', ARRAY['celery']);
