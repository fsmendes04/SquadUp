export type PollType = 'voting' | 'betting';

export type Reward = {
  amount?: number;
  text?: string;
};

export interface PollOption {
  id: string;
  poll_id: string;
  text: string;
  vote_count: number;
  created_at: string;
  proposer_reward_amount?: number;
  proposer_reward_text?: string;
  challenger_reward_amount?: number;
  challenger_reward_text?: string;
  challenger_user_id?: string;
}

export interface PollVote {
  id: string;
  poll_id: string;
  option_id: string;
  user_id: string;
  created_at: string;
}

export interface Poll {
  id: string;
  group_id: string;
  title: string;
  type: PollType;
  status: 'active' | 'closed';
  correct_option_id?: string;
  options?: PollOption[];
  votes?: PollVote[];
  created_by: string;
  created_at: string;
  updated_at: string;
  closed_at?: string;
  deleted_at?: string;
}