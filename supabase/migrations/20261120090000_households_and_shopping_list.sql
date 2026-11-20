-- Households are the tenant boundary: every household-owned row carries household_id and is
-- guarded by row level security through private.is_household_member.
-- Grants are explicit (least privilege); nothing is exposed to the anon role.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create type public.household_role as enum ('owner', 'admin', 'member');

create table public.households (
    id uuid primary key default gen_random_uuid(),
    name text not null
        constraint households_name_length check (
            name = btrim(name) and char_length(name) between 1 and 60
        ),
    created_at timestamptz not null default now()
);

create table public.household_members (
    household_id uuid not null references public.households (id) on delete cascade,
    user_id uuid not null references auth.users (id) on delete cascade,
    role public.household_role not null,
    joined_at timestamptz not null default now(),
    primary key (household_id, user_id)
);

create table public.shopping_items (
    -- Generated on the device so a retried insert is idempotent.
    id uuid primary key,
    household_id uuid not null references public.households (id) on delete cascade,
    name text not null
        constraint shopping_items_name_length check (
            name = btrim(name) and char_length(name) between 1 and 120
        ),
    -- Null after the author deletes their account; the item stays with the household.
    created_by uuid default auth.uid() references auth.users (id) on delete set null,
    created_at timestamptz not null default now()
);

-- Indexes live in their own single-statement migrations: CREATE INDEX CONCURRENTLY cannot run
-- inside the transaction that wraps a multi-statement migration file.

-- Security definer so policies on household_members can call it without recursing into RLS.
create function private.is_household_member(target uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.household_members m
        where m.household_id = target
          and m.user_id = (select auth.uid())
    );
$$;

revoke all on function private.is_household_member(uuid) from public;
grant execute on function private.is_household_member(uuid) to authenticated;

alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.shopping_items enable row level security;

revoke all on table public.households, public.household_members, public.shopping_items
    from anon, authenticated;

grant select on table public.households to authenticated;
grant select on table public.household_members to authenticated;
grant select on table public.shopping_items to authenticated;
-- created_by and created_at are server-assigned; clients may only write these columns.
grant insert (id, household_id, name) on table public.shopping_items to authenticated;

create policy households_select_member on public.households
    for select to authenticated
    using ((select private.is_household_member(id)));

create policy household_members_select_member on public.household_members
    for select to authenticated
    using ((select private.is_household_member(household_id)));

create policy shopping_items_select_member on public.shopping_items
    for select to authenticated
    using ((select private.is_household_member(household_id)));

create policy shopping_items_insert_member on public.shopping_items
    for insert to authenticated
    with check (
        (select private.is_household_member(household_id))
        and created_by = (select auth.uid())
    );

-- Creates a household and the caller's owner membership in one transaction.
-- MVP rule: a user belongs to at most one household (SQLSTATE HM001 otherwise).
create function public.create_household(household_name text)
returns public.households
language plpgsql
security definer
set search_path = ''
as $$
declare
    caller uuid := auth.uid();
    created public.households;
begin
    if caller is null then
        raise exception 'authentication required' using errcode = '42501';
    end if;

    -- Serialise concurrent calls from the same user so the membership check cannot race.
    perform pg_advisory_xact_lock(hashtextextended(caller::text, 0));

    if exists (select 1 from public.household_members m where m.user_id = caller) then
        raise exception 'user already belongs to a household' using errcode = 'HM001';
    end if;

    insert into public.households (name)
    values (btrim(household_name))
    returning * into created;

    insert into public.household_members (household_id, user_id, role)
    values (created.id, caller, 'owner');

    return created;
end;
$$;

revoke all on function public.create_household(text) from public, anon;
grant execute on function public.create_household(text) to authenticated;
