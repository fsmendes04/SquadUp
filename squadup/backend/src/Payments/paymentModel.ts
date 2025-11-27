export interface Payment {
  id: string;
  group_id: string;
  from_user_id: string;
  to_user_id: string;
  amount: number;
  payment_date: string;
  expense_id?: string;
  created_at: string;
}
