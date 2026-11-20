-- Membership lookups by user: the RLS helper and "which household am I in".
create index concurrently if not exists household_members_user_id_idx
    on public.household_members (user_id);
