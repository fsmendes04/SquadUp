CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.increment_vote_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.poll_options
  SET vote_count = vote_count + 1
  WHERE id = NEW.option_id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.decrement_vote_count()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE public.poll_options
  SET vote_count = GREATEST(vote_count - 1, 0)
  WHERE id = OLD.option_id;
  RETURN OLD;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_vote_count_on_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.option_id IS DISTINCT FROM OLD.option_id THEN
    UPDATE public.poll_options SET vote_count = GREATEST(vote_count - 1, 0) WHERE id = OLD.option_id;
    UPDATE public.poll_options SET vote_count = vote_count + 1 WHERE id = NEW.option_id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.is_member_by_group_id(g_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.group_members
    WHERE group_id = g_id
      AND user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.get_group_members_list(group_id_in uuid)
RETURNS TABLE(id uuid, group_id uuid, user_id uuid, joined_at timestamp with time zone, role text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.group_members
    WHERE group_members.group_id = group_id_in
      AND group_members.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'User is not a member of group %', group_id_in;
  END IF;

  RETURN QUERY
  SELECT gm.id, gm.group_id, gm.user_id, gm.joined_at, gm.role
  FROM public.group_members gm
  WHERE gm.group_id = group_id_in;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$;
