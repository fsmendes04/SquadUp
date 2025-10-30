export interface Group {
  id: string;
  name: string;
  avatar_url?: string | null;
  created_at: string;
  updated_at?: string;
  created_by: string;
}

export interface GroupMember {
  id: string;
  group_id: string;
  user_id: string;
  joined_at: string;
  role: 'admin' | 'member';
  name?: string;
  avatar_url?: string;
}

export interface GroupWithMembers extends Group {
  members: GroupMember[];
}