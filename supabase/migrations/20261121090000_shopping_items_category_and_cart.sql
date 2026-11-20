-- Shopping items gain an aisle category, a short note and a shared "in cart" state, and
-- household members may now edit and delete them. Columns are added with defaults so rows
-- written (and clients running) before this migration keep working.

alter table public.shopping_items
    add column category text not null default 'other'
        constraint shopping_items_category_allowed check (
            category in ('produce', 'dairy', 'bakery', 'pantry', 'cleaning', 'personalCare', 'other')
        ),
    add column note text
        constraint shopping_items_note_length check (
            note = btrim(note) and char_length(note) between 1 and 60
        ),
    add column in_cart_at timestamptz,
    -- Null after the member deletes their account; the item stays with the household.
    add column in_cart_by uuid references auth.users (id) on delete set null;

-- Server-assigned: who put the item in the cart follows in_cart_at, never client input.
create function private.set_in_cart_by()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if new.in_cart_at is null then
        new.in_cart_by := null;
    elsif tg_op = 'INSERT' or new.in_cart_at is distinct from old.in_cart_at then
        new.in_cart_by := (select auth.uid());
    else
        -- Editing other columns keeps who put the item in the cart.
        new.in_cart_by := old.in_cart_by;
    end if;
    return new;
end;
$$;

revoke all on function private.set_in_cart_by() from public;

create trigger shopping_items_set_in_cart_by
    before insert or update on public.shopping_items
    for each row execute function private.set_in_cart_by();

-- in_cart_by and household_id are not writable after insert; clients only edit these columns.
grant insert (category, note) on table public.shopping_items to authenticated;
grant update (category, note, in_cart_at) on table public.shopping_items to authenticated;
grant delete on table public.shopping_items to authenticated;

create policy shopping_items_update_member on public.shopping_items
    for update to authenticated
    using ((select private.is_household_member(household_id)))
    with check ((select private.is_household_member(household_id)));

create policy shopping_items_delete_member on public.shopping_items
    for delete to authenticated
    using ((select private.is_household_member(household_id)));
