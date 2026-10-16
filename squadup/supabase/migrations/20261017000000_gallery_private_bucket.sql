-- Galeria privada: só membros do grupo podem ler as imagens (via URLs assinadas pelo backend).
-- As imagens ficam em gallery/<group_id>/<evento>/<ficheiro>.

UPDATE storage.buckets
SET public = false,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
WHERE id = 'gallery';

DROP POLICY IF EXISTS "Anyone can view gallery images" ON storage.objects;

CREATE POLICY "Group members can view gallery images"
ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'gallery'
  AND (storage.foldername(name))[1] IN (
    SELECT group_members.group_id::text
    FROM public.group_members
    WHERE group_members.user_id = (SELECT auth.uid())
  )
);

-- A tabela galleries não precisa de ser visível para utilizadores não autenticados.
REVOKE SELECT ON public.galleries FROM anon;
