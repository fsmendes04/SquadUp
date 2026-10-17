-- 1.1 expense_participants: varchar -> uuid + FK
TRUNCATE TABLE public.expense_participants;

ALTER TABLE public.expense_participants
  ALTER COLUMN topayid TYPE uuid USING topayid::uuid,
  ALTER COLUMN toreceiveid TYPE uuid USING toreceiveid::uuid;

ALTER TABLE public.expense_participants
  DROP CONSTRAINT IF EXISTS expense_participants_topayid_fkey,
  DROP CONSTRAINT IF EXISTS expense_participants_toreceiveid_fkey;

ALTER TABLE public.expense_participants
  ADD CONSTRAINT expense_participants_topayid_fkey
    FOREIGN KEY (topayid) REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD CONSTRAINT expense_participants_toreceiveid_fkey
    FOREIGN KEY (toreceiveid) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.expense_participants
  DROP CONSTRAINT IF EXISTS expense_participants_distinct_users;
ALTER TABLE public.expense_participants
  ADD CONSTRAINT expense_participants_distinct_users
    CHECK (topayid <> toreceiveid);

-- 1.2 poll_options: FK challenger_user_id + checks
ALTER TABLE public.poll_options
  DROP CONSTRAINT IF EXISTS poll_options_challenger_user_id_fkey;
ALTER TABLE public.poll_options
  ADD CONSTRAINT poll_options_challenger_user_id_fkey
    FOREIGN KEY (challenger_user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.poll_options
  DROP CONSTRAINT IF EXISTS poll_options_vote_count_check;
ALTER TABLE public.poll_options
  ADD CONSTRAINT poll_options_vote_count_check CHECK (vote_count >= 0);

ALTER TABLE public.poll_options
  DROP CONSTRAINT IF EXISTS poll_options_proposer_reward_amount_check;
ALTER TABLE public.poll_options
  ADD CONSTRAINT poll_options_proposer_reward_amount_check
    CHECK (proposer_reward_amount IS NULL OR proposer_reward_amount >= 0);

ALTER TABLE public.poll_options
  DROP CONSTRAINT IF EXISTS poll_options_challenger_reward_amount_check;
ALTER TABLE public.poll_options
  ADD CONSTRAINT poll_options_challenger_reward_amount_check
    CHECK (challenger_reward_amount IS NULL OR challenger_reward_amount >= 0);

-- 1.3 polls: FK correct_option_id
ALTER TABLE public.polls
  DROP CONSTRAINT IF EXISTS polls_correct_option_id_fkey;
ALTER TABLE public.polls
  ADD CONSTRAINT polls_correct_option_id_fkey
    FOREIGN KEY (correct_option_id) REFERENCES public.poll_options(id) ON DELETE SET NULL;

-- 1.4 payments: FK from_user_id / to_user_id
ALTER TABLE public.payments
  DROP CONSTRAINT IF EXISTS payments_from_user_id_fkey,
  DROP CONSTRAINT IF EXISTS payments_to_user_id_fkey;
ALTER TABLE public.payments
  ADD CONSTRAINT payments_from_user_id_fkey
    FOREIGN KEY (from_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE,
  ADD CONSTRAINT payments_to_user_id_fkey
    FOREIGN KEY (to_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
