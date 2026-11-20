-- Tenant isolation and write rules for households, memberships and the shopping list.
begin;
create extension if not exists pgtap with schema extensions;

select plan(25);

insert into auth.users (id, email, aud, role) values
    ('11111111-1111-4111-8111-111111111111', 'alice@example.test', 'authenticated', 'authenticated'),
    ('22222222-2222-4222-8222-222222222222', 'bora@example.test', 'authenticated', 'authenticated');

-- Shares Alice's household id with later steps that run as other users.
create temporary table ctx (household_id uuid) on commit drop;
grant all on ctx to authenticated, anon;

select is(
    (select count(*)::int from pg_tables where schemaname = 'public' and not rowsecurity),
    0,
    'every public table has row level security enabled'
);

-- Alice
set local role authenticated;
select set_config(
    'request.jwt.claims',
    '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
    true
);

select lives_ok(
    $$ insert into ctx select id from public.create_household('  Yılmaz Ailesi  ') $$,
    'a signed-in user creates a household'
);
select is((select name from public.households), 'Yılmaz Ailesi', 'household name is trimmed');
select is(
    (select role::text from public.household_members),
    'owner',
    'creator becomes the owner'
);
select throws_ok(
    $$ select public.create_household('İkinci Ev') $$,
    'HM001',
    'user already belongs to a household',
    'a user cannot create a second household'
);
select lives_ok(
    $$ insert into public.shopping_items (id, household_id, name)
       select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', household_id, 'Deterjan' from ctx $$,
    'a member adds an item to their household list'
);
select is(
    (select created_by from public.shopping_items),
    '11111111-1111-4111-8111-111111111111'::uuid,
    'created_by is assigned from the session'
);
select lives_ok(
    $$ insert into public.shopping_items (id, household_id, name)
       select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', household_id, 'Deterjan' from ctx
       on conflict (id) do nothing $$,
    'retrying the same item id is idempotent'
);
select is((select count(*)::int from public.shopping_items), 1, 'retry did not duplicate the item');
select throws_ok(
    $$ insert into public.shopping_items (id, household_id, name)
       select gen_random_uuid(), household_id, '   ' from ctx $$,
    '23514',
    null,
    'blank item names are rejected'
);
select throws_ok(
    $$ insert into public.shopping_items (id, household_id, name, created_by)
       select gen_random_uuid(), household_id, 'Süt', '22222222-2222-4222-8222-222222222222'
       from ctx $$,
    '42501',
    null,
    'clients cannot set created_by'
);

-- Bora: signed in, member of no household yet
select set_config(
    'request.jwt.claims',
    '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',
    true
);

select is((select count(*)::int from public.households), 0, 'another user cannot see the household');
select is(
    (select count(*)::int from public.household_members),
    0,
    'another user cannot see its members'
);
select is(
    (select count(*)::int from public.shopping_items),
    0,
    'another user cannot see its shopping items'
);
select throws_ok(
    $$ insert into public.shopping_items (id, household_id, name)
       select gen_random_uuid(), household_id, 'Sızma' from ctx $$,
    '42501',
    null,
    'another user cannot add items to the household'
);
select lives_ok(
    $$ delete from public.shopping_items $$,
    'a user outside the household deleting items is a silent no-op'
);
select lives_ok(
    $$ update public.shopping_items set category = 'dairy' $$,
    'a user outside the household updating items is a silent no-op'
);
-- Owner-side check, then back to Bora for the remaining steps.
select set_config(
    'request.jwt.claims',
    '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
    true
);
select is(
    (select count(*)::int from public.shopping_items),
    1,
    'the outsider did not delete the household item'
);
select is(
    (select category from public.shopping_items),
    'other',
    'the outsider did not change the household item'
);
select set_config(
    'request.jwt.claims',
    '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',
    true
);
select throws_ok(
    $$ select public.create_household('') $$,
    '23514',
    null,
    'empty household names are rejected'
);
select throws_ok(
    $$ select public.create_household(repeat('x', 61)) $$,
    '23514',
    null,
    'household names longer than 60 characters are rejected'
);
select lives_ok(
    $$ select public.create_household('Demir Evi') $$,
    'the other user creates their own household'
);
select is(
    (select count(*)::int from public.households),
    1,
    'each user sees only their own household'
);

-- Anonymous
reset role;
set local role anon;
select throws_ok(
    $$ select * from public.shopping_items $$,
    '42501',
    null,
    'anon cannot read shopping items'
);
select throws_ok(
    $$ select public.create_household('Anonim') $$,
    '42501',
    null,
    'anon cannot create households'
);

select * from finish();
rollback;
