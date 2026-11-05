begin;
create table if not exists udam_private.kinship_checks(request_id uuid primary key references public.lineage_requests(id) on delete cascade,requester_statement text not null default '',target_statement text not null default '',verified_by uuid references auth.users(id),verified_at timestamptz);
create table if not exists udam_private.share_scopes(owner_id uuid not null references auth.users(id) on delete cascade,peer_id uuid not null references auth.users(id) on delete cascade,person_ids text[] not null default '{}',include_birth boolean not null default false,updated_at timestamptz not null default now(),primary key(owner_id,peer_id),check(owner_id<>peer_id));
create table if not exists udam_private.sharing_audit(id bigint generated always as identity primary key,actor uuid,action text not null,request_id uuid,created_at timestamptz not null default now());
alter table udam_private.kinship_checks enable row level security;
alter table udam_private.share_scopes enable row level security;
alter table udam_private.sharing_audit enable row level security;
revoke all on udam_private.kinship_checks,udam_private.share_scopes,udam_private.sharing_audit from public,anon,authenticated;
create or replace function udam_private.kinship_action(action text,request_id uuid default null,statement text default '',peer_id uuid default null,person_ids text[] default '{}',include_birth boolean default false) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable

declare me uuid:=auth.uid(); r public.lineage_requests; c udam_private.kinship_checks; result jsonb; other uuid;
begin
 if me is null or not udam_private.is_approved() then raise exception 'Approval required'; end if;
 if action='list' then
 select coalesce(jsonb_agg(jsonb_build_object('id',q.id,'requester',q.requester_user_id,'target',q.target_user_id,'status',q.status,'requester_name',coalesce(p.display_name,'Хэрэглэгч'),'target_name',coalesce(t.display_name,'Хэрэглэгч'),'requester_statement',coalesce(k.requester_statement,''),'target_statement',coalesce(k.target_statement,''),'verified',k.verified_by is not null,'selected_ids',coalesce(to_jsonb(s.person_ids),'[]'),'include_birth',coalesce(s.include_birth,false))), '[]') into result from public.lineage_requests q left join udam_private.kinship_checks k on k.request_id=q.id left join public.lineage_profiles p on p.user_id=q.requester_user_id left join public.lineage_profiles t on t.user_id=q.target_user_id left join udam_private.share_scopes s on s.owner_id=me and s.peer_id=case when me=q.requester_user_id then q.target_user_id else q.requester_user_id end where me in(q.requester_user_id,q.target_user_id) or udam_private.is_admin();return result;
 end if;
 select * into r from public.lineage_requests q where q.id=kinship_action.request_id for update;
 if not found or r.status not in ('pending','accepted') then raise exception 'Active request required';end if;
 if action='attest' then
 if me not in(r.requester_user_id,r.target_user_id) or length(trim(statement))<20 or length(statement)>1500 then raise exception 'Describe the relationship in 20–1500 characters';end if;
 insert into udam_private.kinship_checks(request_id) values(r.id) on conflict do nothing;
 update udam_private.kinship_checks k set requester_statement=case when me=r.requester_user_id then statement else k.requester_statement end,target_statement=case when me=r.target_user_id then statement else k.target_statement end,verified_by=null,verified_at=null where k.request_id=r.id;
 elsif action='verify' then
 if not udam_private.is_admin() or r.status<>'accepted' then raise exception 'Admin and mutual consent required';end if;
 select * into c from udam_private.kinship_checks k where k.request_id=r.id;
 if length(c.requester_statement)<20 or length(c.target_statement)<20 or c.request_id is null then raise exception 'Both relationship statements required';end if;
 update udam_private.kinship_checks k set verified_by=me,verified_at=now() where k.request_id=r.id;
 elsif action in ('scope','stop') then
 if me not in(r.requester_user_id,r.target_user_id) then raise exception 'Owner only';end if;
 other:=case when me=r.requester_user_id then r.target_user_id else r.requester_user_id end;
 if action='scope' and not exists(select 1 from udam_private.kinship_checks k where k.request_id=r.id and k.verified_by is not null) then raise exception 'Relationship review required';end if;
 if cardinality(person_ids)>300 or exists(select 1 from unnest(person_ids) pid where not exists(select 1 from public.family_records f cross join lateral jsonb_array_elements(f.people) n where f.user_id=me and n->>'id'=pid)) then raise exception 'Invalid owner records';end if;
 insert into udam_private.share_scopes(owner_id,peer_id,person_ids,include_birth) values(me,other,case when action='stop' then '{}'::text[] else person_ids end,include_birth) on conflict on constraint share_scopes_pkey do update set person_ids=excluded.person_ids,include_birth=excluded.include_birth,updated_at=now();
 else raise exception 'Unknown action';end if;
 insert into udam_private.sharing_audit(actor,action,request_id) values(me,action,r.id);
 return jsonb_build_object('ok',true);
end $$;
create or replace function public.manage_kinship(action text,request_id uuid default null,statement text default '',peer_id uuid default null,person_ids text[] default '{}',include_birth boolean default false) returns jsonb language sql security invoker set search_path='' as $$select udam_private.kinship_action(action,request_id,statement,peer_id,person_ids,include_birth)$$;
revoke all on function udam_private.kinship_action(text,uuid,text,uuid,text[],boolean),public.manage_kinship(text,uuid,text,uuid,text[],boolean) from public,anon;
grant execute on function udam_private.kinship_action(text,uuid,text,uuid,text[],boolean),public.manage_kinship(text,uuid,text,uuid,text[],boolean) to authenticated;
create or replace function udam_private.connected(a uuid,b uuid) returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and auth.uid() in(a,b) and exists(select 1 from public.lineage_requests r join udam_private.kinship_checks k on k.request_id=r.id where r.status='accepted' and k.verified_by is not null and ((r.requester_user_id=a and r.target_user_id=b) or(r.requester_user_id=b and r.target_user_id=a)))$$;
create or replace function udam_private.connected_lineage(peer_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable

declare result jsonb;scope udam_private.share_scopes;owner_name text;
begin
 if not udam_private.is_approved() or not udam_private.connected(auth.uid(),peer_id) or not exists(select 1 from public.user_approvals a join auth.users u on u.id=a.user_id where a.user_id=peer_id and a.is_approved and u.email_confirmed_at is not null) then raise exception 'Verified relationship required';end if;
 select * into scope from udam_private.share_scopes s where s.owner_id=peer_id and s.peer_id=auth.uid();
 select display_name into owner_name from public.lineage_profiles where user_id=peer_id;
 select jsonb_build_object('sourceOwner',coalesce(owner_name,'Хуваалцсан модны эзэн'),'people',coalesce(jsonb_agg(jsonb_build_object('id',n->>'id','name',n->>'name','clanName',n->>'clanName','fatherName',n->>'fatherName','givenName',n->>'givenName','birthYear',case when scope.include_birth then n->>'birthYear' else null end,'birthMonth',case when scope.include_birth then n->>'birthMonth' else null end,'birthDay',case when scope.include_birth then n->>'birthDay' else null end,'parentIds',coalesce((select jsonb_agg(pid) from jsonb_array_elements_text(coalesce(n->'parentIds','[]')) pid where pid=any(scope.person_ids)),'[]'),'partnerId',case when n->>'partnerId'=any(scope.person_ids) then n->>'partnerId' else null end,'sourceOwnerName',coalesce(owner_name,'Хуваалцсан модны эзэн'))),'[]')) into result from public.family_records f cross join lateral jsonb_array_elements(f.people) n where f.user_id=peer_id and n->>'id'=any(scope.person_ids);
 return result;
end $$;
revoke execute on function public.rls_auto_enable() from public,anon,authenticated;
notify pgrst,'reload schema';
commit;
begin;
create table if not exists udam_private.kinship_suggestions(id uuid primary key default gen_random_uuid(),sender uuid not null references auth.users(id),recipient uuid not null references auth.users(id),person_id text not null,suggestion text not null check(length(suggestion) between 10 and 1000),created_at timestamptz not null default now(),dismissed boolean not null default false);
alter table udam_private.kinship_suggestions enable row level security;
revoke all on udam_private.kinship_suggestions from public,anon,authenticated;
create or replace function udam_private.suggestion_action(action text,peer_id uuid default null,person_id text default null,suggestion text default null,suggestion_id uuid default null) returns jsonb language plpgsql security definer set search_path='' as $$
#variable_conflict use_variable
declare result jsonb;me uuid:=auth.uid();begin
if not udam_private.is_approved() then raise exception 'Approval required';end if;
if action='send' then
if not udam_private.connected(me,peer_id) or not exists(select 1 from udam_private.share_scopes s where s.owner_id=peer_id and s.peer_id=me and person_id=any(s.person_ids)) then raise exception 'Sharing scope required';end if;
if (select count(*) from udam_private.kinship_suggestions s where s.sender=me and s.created_at>now()-interval '1 day')>=20 then raise exception 'Daily limit';end if;
insert into udam_private.kinship_suggestions(sender,recipient,person_id,suggestion) values(me,peer_id,person_id,suggestion);
elsif action='list' then select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'person_id',s.person_id,'suggestion',s.suggestion)),'[]') into result from udam_private.kinship_suggestions s where s.recipient=me and not s.dismissed;return result;
elsif action='dismiss' then update udam_private.kinship_suggestions s set dismissed=true where s.id=suggestion_id and s.recipient=me;
else raise exception 'Unknown action';end if;return jsonb_build_object('ok',true);end$$;
create or replace function public.send_kinship_suggestion(peer_id uuid,person_id text,suggestion text) returns jsonb language sql security invoker set search_path='' as $$select udam_private.suggestion_action('send',peer_id,person_id,suggestion)$$;
create or replace function public.get_kinship_suggestions() returns jsonb language sql security invoker set search_path='' as $$select udam_private.suggestion_action('list')$$;
create or replace function public.dismiss_kinship_suggestion(suggestion_id uuid) returns jsonb language sql security invoker set search_path='' as $$select udam_private.suggestion_action('dismiss',suggestion_id=>suggestion_id)$$;
revoke all on function udam_private.suggestion_action(text,uuid,text,text,uuid),public.send_kinship_suggestion(uuid,text,text),public.get_kinship_suggestions(),public.dismiss_kinship_suggestion(uuid) from public,anon;
grant execute on function udam_private.suggestion_action(text,uuid,text,text,uuid),public.send_kinship_suggestion(uuid,text,text),public.get_kinship_suggestions(),public.dismiss_kinship_suggestion(uuid) to authenticated;
notify pgrst,'reload schema';commit;
