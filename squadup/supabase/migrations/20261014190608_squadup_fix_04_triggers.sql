DROP TRIGGER IF EXISTS expenses_updated_at_trigger ON public.expenses;
CREATE TRIGGER expenses_updated_at_trigger
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS groups_updated_at_trigger ON public.groups;
CREATE TRIGGER groups_updated_at_trigger
  BEFORE UPDATE ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS polls_updated_at_trigger ON public.polls;
CREATE TRIGGER polls_updated_at_trigger
  BEFORE UPDATE ON public.polls
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS galleries_updated_at_trigger ON public.galleries;
CREATE TRIGGER galleries_updated_at_trigger
  BEFORE UPDATE ON public.galleries
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS poll_votes_increment_trigger ON public.poll_votes;
CREATE TRIGGER poll_votes_increment_trigger
  AFTER INSERT ON public.poll_votes
  FOR EACH ROW EXECUTE FUNCTION public.increment_vote_count();

DROP TRIGGER IF EXISTS poll_votes_decrement_trigger ON public.poll_votes;
CREATE TRIGGER poll_votes_decrement_trigger
  AFTER DELETE ON public.poll_votes
  FOR EACH ROW EXECUTE FUNCTION public.decrement_vote_count();

DROP TRIGGER IF EXISTS poll_votes_update_trigger ON public.poll_votes;
CREATE TRIGGER poll_votes_update_trigger
  AFTER UPDATE ON public.poll_votes
  FOR EACH ROW EXECUTE FUNCTION public.update_vote_count_on_update();
