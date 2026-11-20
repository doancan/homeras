-- Paged list query: where household_id = ? order by created_at desc, id desc.
create index concurrently if not exists shopping_items_household_created_idx
    on public.shopping_items (household_id, created_at desc, id desc);
