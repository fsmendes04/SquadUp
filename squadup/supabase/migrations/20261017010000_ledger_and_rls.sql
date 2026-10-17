-- Modelo financeiro em livro-razão + RLS mais restrito.
--
-- Regras:
--   * expense_participants guarda a parte de CADA participante numa despesa, incluindo a do
--     próprio pagador (topayid = toreceiveid = payer). Estas linhas nunca são alteradas por
--     pagamentos.
--   * payments é só de inserção. O saldo de cada pessoa é:
--       (partes que outros lhe devem) - (partes que deve) + (pagamentos enviados) - (pagamentos recebidos)
--   * Despesas e votos só são escritos através das funções abaixo (transacionais e validadas).

-- ---------------------------------------------------------------------------
-- 1. Esquema
-- ---------------------------------------------------------------------------

ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS created_by uuid DEFAULT auth.uid()
  REFERENCES public.profiles(id) ON DELETE SET NULL;

-- A parte do pagador passa a ser guardada (pagador deve a si próprio = saldo 0).
ALTER TABLE public.expense_participants
  DROP CONSTRAINT IF EXISTS expense_participants_distinct_users;

CREATE UNIQUE INDEX IF NOT EXISTS expense_participants_expense_user_key
  ON public.expense_participants (expense_id, topayid);

-- Despesas antigas não guardavam a parte do pagador: reconstrói-la como o resto do valor.
INSERT INTO public.expense_participants (expense_id, topayid, toreceiveid, amount, amount_paid)
SELECT e.id, e.payer_id, e.payer_id, e.amount - COALESCE(SUM(p.amount), 0), 0
FROM public.expenses e
LEFT JOIN public.expense_participants p ON p.expense_id = e.id
GROUP BY e.id, e.payer_id, e.amount
HAVING e.amount - COALESCE(SUM(p.amount), 0) >= 0.01
   AND NOT EXISTS (
     SELECT 1 FROM public.expense_participants x
     WHERE x.expense_id = e.id AND x.topayid = e.payer_id
   );

-- Pagamentos já não alteram as partes.
UPDATE public.expense_participants SET amount_paid = 0 WHERE amount_paid <> 0;

-- ---------------------------------------------------------------------------
-- 2. Funções
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public._assert_valid_shares(
  p_group_id uuid,
  p_amount numeric,
  p_shares jsonb
) RETURNS void
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
DECLARE
  v_count int;
  v_distinct int;
  v_total numeric;
  v_non_members int;
BEGIN
  IF p_shares IS NULL OR jsonb_typeof(p_shares) <> 'array' OR jsonb_array_length(p_shares) = 0 THEN
    RAISE EXCEPTION 'At least one participant is required';
  END IF;

  IF jsonb_array_length(p_shares) > 50 THEN
    RAISE EXCEPTION 'Cannot have more than 50 participants';
  END IF;

  SELECT count(*), count(DISTINCT s.user_id), COALESCE(sum(s.amount), 0)
  INTO v_count, v_distinct, v_total
  FROM jsonb_to_recordset(p_shares) AS s(user_id uuid, amount numeric);

  IF v_count <> v_distinct THEN
    RAISE EXCEPTION 'Duplicate participant IDs are not allowed';
  END IF;

  IF EXISTS (
    SELECT 1 FROM jsonb_to_recordset(p_shares) AS s(user_id uuid, amount numeric)
    WHERE s.user_id IS NULL OR s.amount IS NULL OR s.amount < 0 OR s.amount <> round(s.amount, 2)
  ) THEN
    RAISE EXCEPTION 'Invalid share amount';
  END IF;

  IF v_total <> p_amount THEN
    RAISE EXCEPTION 'Shares (%) must add up to the expense amount (%)', v_total, p_amount;
  END IF;

  SELECT count(*) INTO v_non_members
  FROM jsonb_to_recordset(p_shares) AS s(user_id uuid, amount numeric)
  WHERE NOT EXISTS (
    SELECT 1 FROM public.group_members gm
    WHERE gm.group_id = p_group_id AND gm.user_id = s.user_id
  );

  IF v_non_members > 0 THEN
    RAISE EXCEPTION 'All participants must be members of the group';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.create_expense(
  p_group_id uuid,
  p_payer_id uuid,
  p_amount numeric,
  p_description text,
  p_category text,
  p_expense_date date,
  p_shares jsonb
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_expense_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM group_members WHERE group_id = p_group_id AND user_id = v_uid) THEN
    RAISE EXCEPTION 'User is not a member of this group' USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM group_members WHERE group_id = p_group_id AND user_id = p_payer_id) THEN
    RAISE EXCEPTION 'Payer must be a member of the group';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 OR p_amount > 999999.99 OR p_amount <> round(p_amount, 2) THEN
    RAISE EXCEPTION 'Invalid amount';
  END IF;

  PERFORM _assert_valid_shares(p_group_id, p_amount, p_shares);

  INSERT INTO expenses (group_id, payer_id, amount, description, category, expense_date, created_by)
  VALUES (p_group_id, p_payer_id, p_amount, p_description, p_category, p_expense_date, v_uid)
  RETURNING id INTO v_expense_id;

  INSERT INTO expense_participants (expense_id, topayid, toreceiveid, amount, amount_paid)
  SELECT v_expense_id, s.user_id, p_payer_id, s.amount, 0
  FROM jsonb_to_recordset(p_shares) AS s(user_id uuid, amount numeric);

  RETURN v_expense_id;
END;
$$;

CREATE OR REPLACE FUNCTION public._assert_can_edit_expense(p_expense public.expenses)
RETURNS void
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  IF p_expense.created_by = v_uid OR p_expense.payer_id = v_uid THEN
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM group_members
    WHERE group_id = p_expense.group_id AND user_id = v_uid AND role = 'admin'
  ) THEN
    RETURN;
  END IF;

  RAISE EXCEPTION 'Only the creator, the payer or a group admin can change this expense'
    USING ERRCODE = '42501';
END;
$$;

CREATE OR REPLACE FUNCTION public.update_expense(
  p_expense_id uuid,
  p_amount numeric DEFAULT NULL,
  p_description text DEFAULT NULL,
  p_category text DEFAULT NULL,
  p_expense_date date DEFAULT NULL,
  p_shares jsonb DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_expense expenses;
  v_amount numeric;
BEGIN
  SELECT * INTO v_expense FROM expenses
  WHERE id = p_expense_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Expense not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM _assert_can_edit_expense(v_expense);

  v_amount := COALESCE(p_amount, v_expense.amount);

  IF v_amount <= 0 OR v_amount > 999999.99 OR v_amount <> round(v_amount, 2) THEN
    RAISE EXCEPTION 'Invalid amount';
  END IF;

  IF v_amount <> v_expense.amount AND p_shares IS NULL THEN
    RAISE EXCEPTION 'Shares are required when the amount changes';
  END IF;

  UPDATE expenses
  SET amount = v_amount,
      description = COALESCE(p_description, description),
      category = COALESCE(p_category, category),
      expense_date = COALESCE(p_expense_date, expense_date)
  WHERE id = p_expense_id;

  IF p_shares IS NOT NULL THEN
    PERFORM _assert_valid_shares(v_expense.group_id, v_amount, p_shares);

    DELETE FROM expense_participants WHERE expense_id = p_expense_id;

    INSERT INTO expense_participants (expense_id, topayid, toreceiveid, amount, amount_paid)
    SELECT p_expense_id, s.user_id, v_expense.payer_id, s.amount, 0
    FROM jsonb_to_recordset(p_shares) AS s(user_id uuid, amount numeric);
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.delete_expense(p_expense_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_expense expenses;
BEGIN
  SELECT * INTO v_expense FROM expenses
  WHERE id = p_expense_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Expense not found' USING ERRCODE = 'P0002';
  END IF;

  PERFORM _assert_can_edit_expense(v_expense);

  UPDATE expenses SET deleted_at = now() WHERE id = p_expense_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.cast_vote(p_poll_id uuid, p_option_id uuid)
RETURNS public.poll_votes
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_poll polls;
  v_old_option uuid;
  v_vote poll_votes;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_poll FROM polls WHERE id = p_poll_id AND deleted_at IS NULL;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Poll not found' USING ERRCODE = 'P0002';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM group_members WHERE group_id = v_poll.group_id AND user_id = v_uid) THEN
    RAISE EXCEPTION 'You must be a group member to vote' USING ERRCODE = '42501';
  END IF;

  IF v_poll.status <> 'active' OR (v_poll.closed_at IS NOT NULL AND v_poll.closed_at <= now()) THEN
    RAISE EXCEPTION 'This poll is closed';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM poll_options WHERE id = p_option_id AND poll_id = p_poll_id) THEN
    RAISE EXCEPTION 'Invalid option for this poll';
  END IF;

  SELECT option_id INTO v_old_option FROM poll_votes
  WHERE poll_id = p_poll_id AND user_id = v_uid
  FOR UPDATE;

  INSERT INTO poll_votes (poll_id, option_id, user_id)
  VALUES (p_poll_id, p_option_id, v_uid)
  ON CONFLICT (poll_id, user_id) DO UPDATE SET option_id = EXCLUDED.option_id
  RETURNING * INTO v_vote;

  IF v_poll.type = 'betting' AND v_uid <> v_poll.created_by THEN
    IF v_old_option IS NOT NULL AND v_old_option <> p_option_id THEN
      UPDATE poll_options SET challenger_user_id = NULL
      WHERE id = v_old_option AND challenger_user_id = v_uid;
    END IF;

    UPDATE poll_options SET challenger_user_id = v_uid WHERE id = p_option_id;
  END IF;

  RETURN v_vote;
END;
$$;

-- ---------------------------------------------------------------------------
-- 3. RLS: escritas diretas fechadas (só através das funções acima)
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS "Allow group members to insert expenses" ON public.expenses;
DROP POLICY IF EXISTS "Allow group members to update expenses" ON public.expenses;
DROP POLICY IF EXISTS "Allow group members to delete expenses" ON public.expenses;

DROP POLICY IF EXISTS "Allow group members to insert expense participants" ON public.expense_participants;
DROP POLICY IF EXISTS "Allow group members to update expense participants" ON public.expense_participants;
DROP POLICY IF EXISTS "Allow group members to delete expense participants" ON public.expense_participants;

DROP POLICY IF EXISTS "Members can update poll options in their group" ON public.poll_options;

DROP POLICY IF EXISTS "Users can insert their own votes" ON public.poll_votes;
DROP POLICY IF EXISTS "Users can only update their own votes" ON public.poll_votes;

-- ---------------------------------------------------------------------------
-- 4. Permissões de execução: nada para anon, só o necessário para authenticated
-- ---------------------------------------------------------------------------

REVOKE EXECUTE ON ALL FUNCTIONS IN SCHEMA public FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.is_member_by_group_id(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_group_members_list(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_expense(uuid, uuid, numeric, text, text, date, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_expense(uuid, numeric, text, text, date, jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_expense(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.cast_vote(uuid, uuid) TO authenticated;
