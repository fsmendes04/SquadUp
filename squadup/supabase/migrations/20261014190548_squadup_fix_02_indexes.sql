CREATE INDEX IF NOT EXISTS idx_groups_created_by ON public.groups(created_by);

CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group_role ON public.group_members(group_id, role);

CREATE INDEX IF NOT EXISTS idx_expenses_group_id ON public.expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_payer_id ON public.expenses(payer_id);
CREATE INDEX IF NOT EXISTS idx_expenses_deleted_at ON public.expenses(deleted_at);
CREATE INDEX IF NOT EXISTS idx_expenses_group_deleted_date ON public.expenses(group_id, deleted_at, expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON public.expenses(category);

CREATE INDEX IF NOT EXISTS idx_expense_participants_expense_id ON public.expense_participants(expense_id);
CREATE INDEX IF NOT EXISTS idx_expense_participants_topay_torecv ON public.expense_participants(topayid, toreceiveid);

CREATE INDEX IF NOT EXISTS idx_polls_group_id ON public.polls(group_id);
CREATE INDEX IF NOT EXISTS idx_polls_created_by ON public.polls(created_by);
CREATE INDEX IF NOT EXISTS idx_polls_status ON public.polls(status);
CREATE INDEX IF NOT EXISTS idx_polls_deleted_at ON public.polls(deleted_at);
CREATE INDEX IF NOT EXISTS idx_polls_group_status ON public.polls(group_id, status);

CREATE INDEX IF NOT EXISTS idx_poll_options_poll_id ON public.poll_options(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_options_challenger_user_id ON public.poll_options(challenger_user_id);

CREATE INDEX IF NOT EXISTS idx_poll_votes_user_id ON public.poll_votes(user_id);

CREATE INDEX IF NOT EXISTS idx_galleries_group_id ON public.galleries(group_id);
CREATE INDEX IF NOT EXISTS idx_galleries_group_date ON public.galleries(group_id, date);

CREATE INDEX IF NOT EXISTS idx_payments_group_id ON public.payments(group_id);
CREATE INDEX IF NOT EXISTS idx_payments_from_user_id ON public.payments(from_user_id);
CREATE INDEX IF NOT EXISTS idx_payments_to_user_id ON public.payments(to_user_id);
CREATE INDEX IF NOT EXISTS idx_payments_from_to ON public.payments(from_user_id, to_user_id);
CREATE INDEX IF NOT EXISTS idx_payments_expense_id ON public.payments(expense_id);
