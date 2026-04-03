-- =============================================================================
-- RLS + Storage (executar no SQL Editor do Supabase após revisar nomes de policies)
-- =============================================================================
-- Antes: faça backup. Linhas com user_id NULL deixam de ser visíveis — atualize ou apague.
--
-- Secrets da Edge Function `generate-variants` (Dashboard → Edge Functions → Secrets):
--   GEMINI_API_KEY (único secret de IA; Gemini 2.5 Flash + Flash Image)
-- A função também precisa de SUPABASE_ANON_KEY (geralmente injetado automaticamente).
-- =============================================================================

-- Dropar policies existentes em public (evita conflito com "Allow all")
DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'generations'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.generations', r.policyname);
  END LOOP;
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'variants'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.variants', r.policyname);
  END LOOP;
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'user_settings'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.user_settings', r.policyname);
  END LOOP;
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'brand_profiles'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.brand_profiles', r.policyname);
  END LOOP;
END $$;

ALTER TABLE public.generations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.brand_profiles ENABLE ROW LEVEL SECURITY;

-- generations: só o dono (auth.uid() = user_id)
CREATE POLICY "generations_select_own"
  ON public.generations FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "generations_insert_own"
  ON public.generations FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "generations_update_own"
  ON public.generations FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "generations_delete_own"
  ON public.generations FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- variants: ligadas a generation do utilizador
CREATE POLICY "variants_select_own"
  ON public.variants FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.generations g
      WHERE g.id = variants.generation_id AND g.user_id = auth.uid()
    )
  );

CREATE POLICY "variants_insert_own"
  ON public.variants FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.generations g
      WHERE g.id = generation_id AND g.user_id = auth.uid()
    )
  );

CREATE POLICY "variants_update_own"
  ON public.variants FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.generations g
      WHERE g.id = variants.generation_id AND g.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.generations g
      WHERE g.id = generation_id AND g.user_id = auth.uid()
    )
  );

CREATE POLICY "variants_delete_own"
  ON public.variants FOR DELETE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.generations g
      WHERE g.id = variants.generation_id AND g.user_id = auth.uid()
    )
  );

-- user_settings
CREATE POLICY "user_settings_select_own"
  ON public.user_settings FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "user_settings_insert_own"
  ON public.user_settings FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_settings_update_own"
  ON public.user_settings FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_settings_delete_own"
  ON public.user_settings FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- brand_profiles
CREATE POLICY "brand_profiles_select_own"
  ON public.brand_profiles FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "brand_profiles_insert_own"
  ON public.brand_profiles FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "brand_profiles_update_own"
  ON public.brand_profiles FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "brand_profiles_delete_own"
  ON public.brand_profiles FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- =============================================================================
-- Storage: bucket `creatives`
-- Uploads do app: {user_id}/...
-- Variantes geradas pela Edge Function: variants/{generation_id}/... (service role ignora RLS)
-- =============================================================================

DO $$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname LIKE 'creatives_%'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', r.policyname);
  END LOOP;
END $$;

-- Ajuste se o bucket tiver outro id
INSERT INTO storage.buckets (id, name, public)
VALUES ('creatives', 'creatives', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

-- Leitura: ficheiros na pasta do utilizador OU variants de uma generation sua
CREATE POLICY "creatives_select_authenticated"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'creatives'
    AND (
      split_part(name, '/', 1) = auth.uid()::text
      OR (
        split_part(name, '/', 1) = 'variants'
        AND EXISTS (
          SELECT 1 FROM public.generations g
          WHERE g.id::text = split_part(name, '/', 2)
            AND g.user_id = auth.uid()
        )
      )
    )
  );

CREATE POLICY "creatives_insert_own_prefix"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'creatives'
    AND split_part(name, '/', 1) = auth.uid()::text
  );

CREATE POLICY "creatives_update_own_prefix"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'creatives'
    AND split_part(name, '/', 1) = auth.uid()::text
  );

CREATE POLICY "creatives_delete_own_prefix"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'creatives'
    AND split_part(name, '/', 1) = auth.uid()::text
  );
