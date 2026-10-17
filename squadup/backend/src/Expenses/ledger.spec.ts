import {
  computeBalances,
  settleUp,
  splitEvenly,
  MemberBalance,
  ParticipantRow,
  PaymentRow,
} from './ledger';

const members = [
  { user_id: 'A', name: 'Ana' },
  { user_id: 'B', name: 'Bruno' },
  { user_id: 'C', name: 'Carla' },
];

// Partes de uma despesa paga por `payer`, dividida igualmente por `userIds`.
function expense(payer: string, amount: number, userIds: string[]): ParticipantRow[] {
  return splitEvenly(amount, userIds).map(share => ({
    topayid: share.user_id,
    toreceiveid: payer,
    amount: share.amount,
  }));
}

function balanceOf(balances: MemberBalance[], userId: string): number {
  const balance = balances.find(b => b.userId === userId)!;
  return balance.toReceive - balance.toPay;
}

// Aplica as transferências sugeridas como pagamentos.
function pay(transfers: { from: string; to: string; amount: number }[]): PaymentRow[] {
  return transfers.map(t => ({ from_user_id: t.from, to_user_id: t.to, amount: t.amount }));
}

describe('splitEvenly', () => {
  it('splits exactly when divisible', () => {
    expect(splitEvenly(30, ['A', 'B', 'C']).map(s => s.amount)).toEqual([10, 10, 10]);
  });

  it('gives leftover cents to the first participants and keeps the exact total', () => {
    const shares = splitEvenly(10, ['A', 'B', 'C']);
    expect(shares.map(s => s.amount)).toEqual([3.34, 3.33, 3.33]);
    expect(shares.reduce((sum, s) => sum + Math.round(s.amount * 100), 0)).toBe(1000);
  });

  it('handles a single participant', () => {
    expect(splitEvenly(12.5, ['A'])).toEqual([{ user_id: 'A', amount: 12.5 }]);
  });

  it('rejects an empty participant list', () => {
    expect(() => splitEvenly(10, [])).toThrow();
  });
});

describe('computeBalances', () => {
  it('ignores the payer own share', () => {
    const balances = computeBalances(members, expense('A', 30, ['A', 'B', 'C']), []);
    expect(balanceOf(balances, 'A')).toBe(20);
    expect(balanceOf(balances, 'B')).toBe(-10);
    expect(balanceOf(balances, 'C')).toBe(-10);
  });

  it('supports a payer who is not part of the split', () => {
    const balances = computeBalances(members, expense('A', 20, ['B', 'C']), []);
    expect(balanceOf(balances, 'A')).toBe(20);
    expect(balanceOf(balances, 'B')).toBe(-10);
  });

  it('reduces debts with payments without touching the expense shares', () => {
    const participants = expense('A', 30, ['A', 'B', 'C']);
    const balances = computeBalances(members, participants, [
      { from_user_id: 'B', to_user_id: 'A', amount: 4 },
    ]);
    expect(balanceOf(balances, 'A')).toBe(16);
    expect(balanceOf(balances, 'B')).toBe(-6);
    expect(participants).toHaveLength(3);
  });

  it('turns an overpayment into a credit', () => {
    const balances = computeBalances(members, expense('A', 20, ['A', 'B']), [
      { from_user_id: 'B', to_user_id: 'A', amount: 15 },
    ]);
    expect(balanceOf(balances, 'A')).toBe(-5);
    expect(balanceOf(balances, 'B')).toBe(5);
  });

  it('always sums to zero across the group', () => {
    const participants = [
      ...expense('A', 10, ['A', 'B', 'C']),
      ...expense('B', 7.77, ['A', 'B', 'C']),
      ...expense('C', 100, ['A', 'C']),
    ];
    const balances = computeBalances(members, participants, [
      { from_user_id: 'C', to_user_id: 'B', amount: 1.11 },
    ]);
    const totalCents = balances.reduce((sum, b) => sum + Math.round(balanceOf([b], b.userId) * 100), 0);
    expect(totalCents).toBe(0);
  });
});

describe('settleUp', () => {
  it('suggests nothing when everyone is even', () => {
    expect(settleUp(computeBalances(members, [], []))).toEqual([]);
  });

  // Caso que estava partido: A paga 30 entre A e B; B paga 30 entre B e C.
  // A sugestão simplificada é "C paga 15 a A", que antes não reduzia nenhuma dívida.
  it('settles simplified debts that were never direct debts', () => {
    const participants = [...expense('A', 30, ['A', 'B']), ...expense('B', 30, ['B', 'C'])];

    const transfers = settleUp(computeBalances(members, participants, []));
    expect(transfers).toEqual([{ from: 'C', fromName: 'Carla', to: 'A', toName: 'Ana', amount: 15 }]);

    const after = computeBalances(members, participants, pay(transfers));
    expect(after.every(b => b.toPay === 0 && b.toReceive === 0)).toBe(true);
    expect(settleUp(after)).toEqual([]);
  });

  it('leaves everyone at zero after paying all suggested transfers, including odd cents', () => {
    const participants = [
      ...expense('A', 10, ['A', 'B', 'C']),
      ...expense('B', 7.77, ['A', 'B', 'C']),
      ...expense('C', 0.05, ['A', 'B']),
    ];

    const transfers = settleUp(computeBalances(members, participants, []));
    const after = computeBalances(members, participants, pay(transfers));

    expect(after.every(b => b.toPay === 0 && b.toReceive === 0)).toBe(true);
    expect(transfers.length).toBeLessThanOrEqual(members.length - 1);
  });

  // Caso que estava partido: editar uma despesa depois de pagar fazia reaparecer a dívida.
  it('keeps payments counted after an expense is edited', () => {
    const before = expense('A', 30, ['A', 'B', 'C']);
    const payments = pay(settleUp(computeBalances(members, before, [])));

    // A despesa é editada (mesmo valor e participantes): as partes são recriadas.
    const edited = expense('A', 30, ['A', 'B', 'C']);
    const balances = computeBalances(members, edited, payments);
    expect(balances.every(b => b.toPay === 0 && b.toReceive === 0)).toBe(true);

    // Se o valor subir, só a diferença fica em dívida.
    const increased = computeBalances(members, expense('A', 36, ['A', 'B', 'C']), payments);
    expect(balanceOf(increased, 'B')).toBe(-2);
    expect(balanceOf(increased, 'C')).toBe(-2);
  });
});
