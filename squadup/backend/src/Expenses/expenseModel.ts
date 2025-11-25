export interface Expense {
  id: string;
  group_id: string;
  payer_id: string;
  amount: number;
  description: string;
  category: string;
  expense_date: string;
  created_at: string;
  updated_at: string;
  deleted_at?: string;
}

export interface ExpenseParticipant {
  id: string;
  expense_id: string;
  topayid: string;
  toreceiveid: string;
  amount: number;
  created_at: string;
}

export interface ExpenseWithParticipants extends Expense {
  participants: ExpenseParticipant[];
  payer?: {
    id: string;
    email?: string;
  };
}

export interface ExpenseFilter {
  groupId: string;
  payerId?: string;
  participantId?: string;
  startDate?: string;
  endDate?: string;
  category?: string;
}