--
-- Exclude tables created by Django Framework
--
-- https://www.djangoproject.com/
--
INSERT INTO @extschema@.schedoc_table_exclusion_templates (schema_name, table_name, tags)
VALUES
('public', 'auth_group', ARRAY['django']),
('public', 'auth_group_permissions', ARRAY['django']),
('public', 'auth_permission', ARRAY['django']),
('public', 'auth_user', ARRAY['django']),
('public', 'auth_user_groups', ARRAY['django']),
('public', 'auth_user_user_permissions', ARRAY['django']),
('public', 'django_admin_log', ARRAY['django']),
('public', 'django_content_type', ARRAY['django']),
('public', 'django_migrations', ARRAY['django']),
('public', 'django_session', ARRAY['django']);
