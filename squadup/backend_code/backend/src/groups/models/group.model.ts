export interface Group {
  id: string;
  name: string;
  created_at: string;
  updated_at: string;
  created_by: string;
}

export interface GroupMember {
  id: string;
  group_id: string;
  user_id: string;
  joined_at: string;
  role: 'admin' | 'member';
}

export interface GroupWithMembers extends Group {
  members: GroupMember[];
}