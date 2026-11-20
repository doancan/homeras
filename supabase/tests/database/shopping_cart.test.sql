-- Category, note, cart state and deletion on shopping items, plus their tenant isolation.
begin;
create extension if not exists pgtap with schema extensions;

select plan(33);

insert into auth.users (id, email, aud, role) values
    ('11111111-1111-4111-8111-111111111111', 'alice@example.test', 'authenticated', 'authenticated'),
    ('22222222-2222-4222-8222-222222222222', 'bora@example.test', 'authenticated', 'authenticated'),
    ('33333333-3333-4333-8333-333333333333', 'carol@example.test', 'authenticated', 'authenticated');

create temporary table ctx (household_id uuid) on commit drop;
grant all on ctx to authenticated, anon;

-- Alice owns a household
set local role authenticated;
select set_config(
    'request.jwt.claims',
    '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
    true
);
insert into ctx select id from public.create_household('Yılmaz Ailesi');

-- Carol joins Alice's household as a second member (membership is seeded as the owner role).
reset role;
insert into public.household_members (household_id, user_id, role)
select household_id, '33333333-3333-4333-8333-333333333333', 'member' from ctx;
set local role authenticated;

select lives_ok(
    $$ insert into public.shopping_items (id, household_id, name)
       select 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', household_id, 'Süt' from ctx $$,
    'a member adds an item without category or note'
);
select is(
    (select category from public.shopping_items where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
    'other',
    'category defaults to other'
);
select lives_ok(
    $$ insert into public.shopping_items (id, household_id, name, category, note)
       select 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', household_id, 'Yoğurt', 'dairy', 'yarım yağlı'
       from ctx $$,
    'a member adds an item with a category and note'
);
select results_eq(
    $$ select category, note from public.shopping_items
       where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' $$,
    $$ values ('dairy'::text, 'yarım yağlı'::text) $$,
    'category and note are stored'
);
select throws_ok(
    $$ insert into public.shopping_items (id, household_id, name, category)
       select gen_random_uuid(), household_id, 'Ekmek', 'snacks' from ctx $$,
    '23514',
    null,
    'an insert with a category outside the list is rejected'
);
select throws_ok(
    $$ insert into public.shopping_items (id, household_id, name, note)
       select gen_random_uuid(), household_id, 'Ekmek', repeat('x', 61) from ctx $$,
    '23514',
    null,
    'a note longer than 60 characters is rejected'
);
select throws_ok(
    $$ insert into public.shopping_items (id, household_id, name, note)
       select gen_random_uuid(), household_id, 'Ekmek', '   ' from ctx $$,
    '23514',
    null,
    'a blank note is rejected'
);

-- Cart state
select is(
    (select count(*)::int from public.shopping_items
     where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' and in_cart_at is null and in_cart_by is null),
    1,
    'new items are not in the cart'
);
select lives_ok(
    $$ update public.shopping_items set in_cart_at = now()
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    'a member puts an item in the cart'
);
select is(
    (select in_cart_by from public.shopping_items where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
    '11111111-1111-4111-8111-111111111111'::uuid,
    'in_cart_by is assigned from the session'
);
select lives_ok(
    $$ update public.shopping_items set in_cart_at = null
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    'a member takes an item out of the cart'
);
select is(
    (select in_cart_by from public.shopping_items where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
    null,
    'in_cart_by is cleared when the item leaves the cart'
);
select lives_ok(
    $$ update public.shopping_items set category = 'bakery', note = 'taze'
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    'a member edits category and note'
);

-- Attribution: editing other columns keeps who put the item in the cart; re-carting reassigns it.
select lives_ok(
    $$ update public.shopping_items set in_cart_at = now()
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    'the first member puts the item in the cart'
);
select lives_ok(
    $$ update public.shopping_items set note = 'yeni', category = 'pantry'
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    'the first member edits an item that is in the cart'
);
select is(
    (select in_cart_by from public.shopping_items where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
    '11111111-1111-4111-8111-111111111111'::uuid,
    'editing note and category keeps in_cart_by'
);
select set_config(
    'request.jwt.claims',
    '{"sub":"33333333-3333-4333-8333-333333333333","role":"authenticated"}',
    true
);
select lives_ok(
    $$ update public.shopping_items set note = 'başka not'
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    'a second member edits the note of an item in the cart'
);
select is(
    (select in_cart_by from public.shopping_items where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
    '11111111-1111-4111-8111-111111111111'::uuid,
    'the second member editing the note does not take over in_cart_by'
);
select lives_ok(
    $$ update public.shopping_items set in_cart_at = now() + interval '1 second'
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    'the second member re-carts the item'
);
select is(
    (select in_cart_by from public.shopping_items where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'),
    '33333333-3333-4333-8333-333333333333'::uuid,
    're-carting assigns in_cart_by to the new member'
);
select set_config(
    'request.jwt.claims',
    '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
    true
);
select lives_ok(
    $$ update public.shopping_items set in_cart_at = null
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    'the first member takes the item out of the cart again'
);
select throws_ok(
    $$ update public.shopping_items set category = 'snacks'
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    '23514',
    null,
    'an update to a category outside the list is rejected'
);
select throws_ok(
    $$ update public.shopping_items set in_cart_by = '22222222-2222-4222-8222-222222222222'
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    '42501',
    null,
    'clients cannot write in_cart_by'
);
select throws_ok(
    $$ update public.shopping_items set household_id = gen_random_uuid()
       where id = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa' $$,
    '42501',
    null,
    'clients cannot move an item to another household'
);

-- Bora belongs to a different household
select set_config(
    'request.jwt.claims',
    '{"sub":"22222222-2222-4222-8222-222222222222","role":"authenticated"}',
    true
);
select lives_ok($$ select public.create_household('Demir Evi') $$, 'the other user has a household');
select lives_ok(
    $$ update public.shopping_items set in_cart_at = now() $$,
    'another household updating items is a silent no-op'
);
select lives_ok(
    $$ delete from public.shopping_items $$,
    'another household deleting items is a silent no-op'
);

-- Alice again: nothing changed, and she can delete
select set_config(
    'request.jwt.claims',
    '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
    true
);
select is(
    (select count(*)::int from public.shopping_items where in_cart_at is not null),
    0,
    'the other household did not change the cart'
);
select is(
    (select count(*)::int from public.shopping_items),
    2,
    'the other household did not delete anything'
);
select lives_ok(
    $$ delete from public.shopping_items where id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb' $$,
    'a member deletes an item'
);
select is(
    (select count(*)::int from public.shopping_items),
    1,
    'the deleted item is gone'
);

-- Anonymous
reset role;
set local role anon;
select throws_ok(
    $$ update public.shopping_items set in_cart_at = now() $$,
    '42501',
    null,
    'anon cannot update items'
);
select throws_ok(
    $$ delete from public.shopping_items $$,
    '42501',
    null,
    'anon cannot delete items'
);

select * from finish();
rollback;
