// Cálculos financeiros puros (sem acesso à base de dados), feitos em cêntimos inteiros.
//
// Modelo: cada despesa guarda a parte de cada participante (incluindo a do pagador).
// Os pagamentos nunca alteram essas partes; entram diretamente no saldo:
//   saldo = (partes que outros lhe devem) - (partes que deve) + (pagamentos enviados) - (pagamentos recebidos)
// Saldo positivo = tem a receber; negativo = tem a pagar.

export interface Share {
  user_id: string;
  amount: number;
}

export interface ParticipantRow {
  topayid: string;
  toreceiveid: string;
  amount: number | string;
}

export interface PaymentRow {
  from_user_id: string;
  to_user_id: string;
  amount: number | string;
}

export interface Member {
  user_id: string;
  name?: string | null;
}

export interface MemberBalance {
  userId: string;
  name: string;
  toReceive: number;
  toPay: number;
}

export interface Transfer {
  from: string;
  fromName: string;
  to: string;
  toName: string;
  amount: number;
}

export function toCents(amount: number | string): number {
  return Math.round(Number(amount) * 100);
}

export function fromCents(cents: number): number {
  return cents / 100;
}

// Divide o valor em partes iguais; os cêntimos que sobram vão para os primeiros participantes,
// para que a soma das partes seja sempre exatamente igual ao valor.
export function splitEvenly(amount: number, userIds: string[]): Share[] {
  if (userIds.length === 0) {
    throw new Error('At least one participant is required');
  }

  const totalCents = toCents(amount);
  const base = Math.floor(totalCents / userIds.length);
  const remainder = totalCents - base * userIds.length;

  return userIds.map((userId, index) => ({
    user_id: userId,
    amount: fromCents(base + (index < remainder ? 1 : 0)),
  }));
}

// Saldo líquido de cada pessoa, em cêntimos.
export function computeNetCents(
  participants: ParticipantRow[],
  payments: PaymentRow[],
): Map<string, number> {
  const net = new Map<string, number>();
  const add = (userId: string, cents: number) => net.set(userId, (net.get(userId) ?? 0) + cents);

  for (const participant of participants) {
    const cents = toCents(participant.amount);
    add(participant.toreceiveid, cents);
    add(participant.topayid, -cents);
  }

  for (const payment of payments) {
    const cents = toCents(payment.amount);
    add(payment.from_user_id, cents);
    add(payment.to_user_id, -cents);
  }

  return net;
}

export function computeBalances(
  members: Member[],
  participants: ParticipantRow[],
  payments: PaymentRow[],
): MemberBalance[] {
  const net = computeNetCents(participants, payments);

  return members.map(member => {
    const cents = net.get(member.user_id) ?? 0;
    return {
      userId: member.user_id,
      name: member.name || 'Usuário',
      toReceive: cents > 0 ? fromCents(cents) : 0,
      toPay: cents < 0 ? fromCents(-cents) : 0,
    };
  });
}

// Número reduzido de transferências que deixa todos os saldos a zero (algoritmo guloso).
export function settleUp(balances: MemberBalance[]): Transfer[] {
  const creditors = balances
    .filter(b => b.toReceive > 0)
    .map(b => ({ userId: b.userId, name: b.name, cents: toCents(b.toReceive) }))
    .sort((a, b) => b.cents - a.cents);

  const debtors = balances
    .filter(b => b.toPay > 0)
    .map(b => ({ userId: b.userId, name: b.name, cents: toCents(b.toPay) }))
    .sort((a, b) => b.cents - a.cents);

  const transfers: Transfer[] = [];
  let i = 0;
  let j = 0;

  while (i < debtors.length && j < creditors.length) {
    const debtor = debtors[i];
    const creditor = creditors[j];
    const cents = Math.min(debtor.cents, creditor.cents);

    if (cents > 0) {
      transfers.push({
        from: debtor.userId,
        fromName: debtor.name,
        to: creditor.userId,
        toName: creditor.name,
        amount: fromCents(cents),
      });
      debtor.cents -= cents;
      creditor.cents -= cents;
    }

    if (debtor.cents === 0) i++;
    if (creditor.cents === 0) j++;
  }

  return transfers;
}
