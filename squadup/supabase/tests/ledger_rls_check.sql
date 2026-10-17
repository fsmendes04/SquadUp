-- Verificação da migração 20261017010000_ledger_and_rls.sql (correr DEPOIS de a aplicar).
-- Usa os dados de teste atuais (grupo, utilizadores, despesa e sondagem existentes).
-- Termina sempre com um erro propositado, por isso tudo é revertido: não deixa dados.
-- O resultado aparece na mensagem de erro 'TEST RESULT'. Qualquer 'ALLOWED(BAD)' é uma falha.

DO $test$
DECLARE
  g uuid := 'ee4c6e26-d237-47df-a4fc-d38a49670900';
  a uuid := '491e34e9-ad12-45fb-8379-437dfb183771';
  m uuid := '9e3f88e9-e23e-41c8-b80b-89df316eff9f';
  legacy uuid := '989b5371-4091-4437-8035-3a721e1e4a57';
  poll uuid := 'c6affe7f-2bc7-41eb-b4c7-4290ea426c76';
  o1 uuid; o2 uuid;
  e uuid;
  n int;
  out text := '';
BEGIN
  SELECT id INTO o1 FROM poll_options WHERE poll_id = poll ORDER BY id LIMIT 1;
  SELECT id INTO o2 FROM poll_options WHERE poll_id = poll ORDER BY id OFFSET 1 LIMIT 1;

  out := out || ' | legacy_parts=' || (SELECT count(*) || '/' || sum(amount) FROM expense_participants WHERE expense_id = legacy);
  out := out || ' | anon_exec_create=' || has_function_privilege('anon', 'public.create_expense(uuid,uuid,numeric,text,text,date,jsonb)', 'EXECUTE');
  out := out || ' | anon_exec_members=' || has_function_privilege('anon', 'public.get_group_members_list(uuid)', 'EXECUTE');
  out := out || ' | auth_exec_vote=' || has_function_privilege('authenticated', 'public.cast_vote(uuid,uuid)', 'EXECUTE');

  PERFORM set_config('request.jwt.claims', json_build_object('sub', m, 'role', 'authenticated')::text, true);
  PERFORM set_config('role', 'authenticated', true);

  BEGIN
    PERFORM update_expense(legacy, NULL, 'hack', NULL, NULL, NULL);
    out := out || ' | member_edit_other=ALLOWED(BAD)';
  EXCEPTION WHEN OTHERS THEN out := out || ' | member_edit_other=' || SQLSTATE; END;

  UPDATE expense_participants SET amount_paid = amount WHERE expense_id = legacy;
  GET DIAGNOSTICS n = ROW_COUNT;
  out := out || ' | direct_update_parts_rows=' || n;

  DELETE FROM expense_participants WHERE expense_id = legacy;
  GET DIAGNOSTICS n = ROW_COUNT;
  out := out || ' | direct_delete_parts_rows=' || n;

  BEGIN
    INSERT INTO expenses (group_id, payer_id, amount, description, category, expense_date) VALUES (g, m, 1, 'x', 'x', now());
    out := out || ' | direct_insert_expense=ALLOWED(BAD)';
  EXCEPTION WHEN OTHERS THEN out := out || ' | direct_insert_expense=' || SQLSTATE; END;

  BEGIN
    PERFORM create_expense(g, m, 10, 'd', 'c', '2026-10-17T10:00:00.000Z', jsonb_build_array(jsonb_build_object('user_id', m, 'amount', 5), jsonb_build_object('user_id', a, 'amount', 4)));
    out := out || ' | bad_sum=ALLOWED(BAD)';
  EXCEPTION WHEN OTHERS THEN out := out || ' | bad_sum=' || SQLSTATE || ':' || SQLERRM; END;

  e := create_expense(g, m, 10, 'Jantar', 'Food', '2026-10-17T10:00:00.000Z', jsonb_build_array(jsonb_build_object('user_id', m, 'amount', 5), jsonb_build_object('user_id', a, 'amount', 5)));
  out := out || ' | created_parts=' || (SELECT count(*) || '/' || sum(amount) FROM expense_participants WHERE expense_id = e);
  out := out || ' | created_by_ok=' || (SELECT created_by = m FROM expenses WHERE id = e);

  BEGIN
    PERFORM update_expense(e, 12, NULL, NULL, NULL, NULL);
    out := out || ' | amount_without_shares=ALLOWED(BAD)';
  EXCEPTION WHEN OTHERS THEN out := out || ' | amount_without_shares=' || SQLSTATE; END;

  PERFORM update_expense(e, 12.01, 'Jantar 2', NULL, NULL, jsonb_build_array(jsonb_build_object('user_id', m, 'amount', 6.01), jsonb_build_object('user_id', a, 'amount', 6)));
  out := out || ' | updated=' || (SELECT amount || ' ' || description FROM expenses WHERE id = e) || ' parts=' || (SELECT count(*) || '/' || sum(amount) FROM expense_participants WHERE expense_id = e);

  PERFORM delete_expense(e);
  out := out || ' | visible_after_delete=' || (SELECT count(*) FROM expenses WHERE id = e);

  BEGIN
    INSERT INTO poll_votes (poll_id, option_id, user_id) VALUES (poll, o1, m);
    out := out || ' | direct_vote=ALLOWED(BAD)';
  EXCEPTION WHEN OTHERS THEN out := out || ' | direct_vote=' || SQLSTATE; END;

  UPDATE poll_options SET vote_count = 999 WHERE poll_id = poll;
  GET DIAGNOSTICS n = ROW_COUNT;
  out := out || ' | direct_update_options_rows=' || n;

  PERFORM cast_vote(poll, o1);
  out := out || ' | vote1=' || (SELECT string_agg(vote_count::text, ',' ORDER BY id) FROM poll_options WHERE poll_id = poll);
  PERFORM cast_vote(poll, o2);
  out := out || ' | vote2=' || (SELECT string_agg(vote_count::text, ',' ORDER BY id) FROM poll_options WHERE poll_id = poll);
  out := out || ' | my_votes=' || (SELECT count(*) FROM poll_votes WHERE poll_id = poll AND user_id = m);

  BEGIN
    PERFORM cast_vote(poll, gen_random_uuid());
    out := out || ' | bad_option=ALLOWED(BAD)';
  EXCEPTION WHEN OTHERS THEN out := out || ' | bad_option=' || SQLSTATE; END;

  out := out || ' | members_rpc=' || (SELECT count(*) FROM get_group_members_list(g));

  RAISE EXCEPTION 'TEST RESULT (rolled back): %', out;
END
$test$;
