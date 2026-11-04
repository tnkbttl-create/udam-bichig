-- READ ONLY. Run against hadrcmqgezevqwyrxpqt before preparing any migration.
select table_schema,table_name,column_name,data_type,is_nullable from information_schema.columns
where table_schema='public' and table_name in ('user_approvals','family_records','lineage_profiles','lineage_requests') order by table_name,ordinal_position;
select schemaname,tablename,policyname,roles,cmd,qual,with_check from pg_policies where schemaname='public' order by tablename,policyname;
select relname,relrowsecurity,relforcerowsecurity from pg_class join pg_namespace n on n.oid=relnamespace where n.nspname='public' and relkind='r';
select routine_schema,routine_name,security_type from information_schema.routines where routine_schema in ('public','private');
select trigger_schema,event_object_table,trigger_name,action_statement from information_schema.triggers where event_object_schema in ('public','auth');
-- Verify the existing administrator's verified auth UID separately; do not list other users' secrets or metadata.
