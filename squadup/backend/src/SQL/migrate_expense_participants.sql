-- Migração da tabela expense_participants
-- De: user_id, amount_owed
-- Para: toPayId, toReceiveId, amount
-- Passo 1: Adicionar as novas colunas
ALTER TABLE expense_participants
ADD COLUMN IF NOT EXISTS toPayId UUID,
  ADD COLUMN IF NOT EXISTS toReceiveId UUID,
  ADD COLUMN IF NOT EXISTS amount NUMERIC(12, 2);
-- Passo 2: Migrar dados existentes (se houver)
-- Esta migração assume que os registros negativos (amount_owed < 0) representam quem recebe
-- e os positivos representam quem paga
UPDATE expense_participants ep
SET toPayId = CASE
    WHEN ep.amount_owed > 0 THEN ep.user_id
    ELSE NULL
  END,
  toReceiveId = CASE
    WHEN ep.amount_owed < 0 THEN ep.user_id
    ELSE (
      SELECT e.payer_id
      FROM expenses e
      WHERE e.id = ep.expense_id
    )
  END,
  amount = ABS(ep.amount_owed)
WHERE toPayId IS NULL
  AND toReceiveId IS NULL;
-- Passo 3: Tornar as novas colunas obrigatórias (NOT NULL)
ALTER TABLE expense_participants
ALTER COLUMN toPayId
SET NOT NULL,
  ALTER COLUMN toReceiveId
SET NOT NULL,
  ALTER COLUMN amount
SET NOT NULL;
-- Passo 4: Remover as colunas antigas
ALTER TABLE expense_participants DROP COLUMN IF EXISTS user_id,
  DROP COLUMN IF EXISTS amount_owed;
-- Passo 5: Adicionar índices para performance
CREATE INDEX IF NOT EXISTS idx_expense_participants_topayid ON expense_participants(toPayId);
CREATE INDEX IF NOT EXISTS idx_expense_participants_toreceiveid ON expense_participants(toReceiveId);