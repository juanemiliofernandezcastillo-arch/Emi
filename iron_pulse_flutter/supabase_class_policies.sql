-- 1. Asegurar que las tablas tengan RLS habilitado
ALTER TABLE public.classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.class_schedules ENABLE ROW LEVEL SECURITY;

-- 2. Políticas para public.classes
-- Lectura pública
DROP POLICY IF EXISTS "Permitir lectura publica de clases" ON public.classes;
CREATE POLICY "Permitir lectura publica de clases" ON public.classes FOR SELECT USING (true);

-- Inserción, Actualización y Borrado solo para administradores
DROP POLICY IF EXISTS "Permitir insercion admin en clases" ON public.classes;
CREATE POLICY "Permitir insercion admin en clases" ON public.classes FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));

DROP POLICY IF EXISTS "Permitir update admin en clases" ON public.classes;
CREATE POLICY "Permitir update admin en clases" ON public.classes FOR UPDATE 
USING (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));

DROP POLICY IF EXISTS "Permitir delete admin en clases" ON public.classes;
CREATE POLICY "Permitir delete admin en clases" ON public.classes FOR DELETE 
USING (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));

-- 3. Políticas para public.class_schedules
-- Lectura pública (para poder ver qué clases hay programadas)
DROP POLICY IF EXISTS "Permitir lectura publica de class_schedules" ON public.class_schedules;
CREATE POLICY "Permitir lectura publica de class_schedules" ON public.class_schedules FOR SELECT USING (true);

-- Modificación solo para administradores
DROP POLICY IF EXISTS "Permitir insercion admin en class_schedules" ON public.class_schedules;
CREATE POLICY "Permitir insercion admin en class_schedules" ON public.class_schedules FOR INSERT 
WITH CHECK (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));

DROP POLICY IF EXISTS "Permitir update admin en class_schedules" ON public.class_schedules;
CREATE POLICY "Permitir update admin en class_schedules" ON public.class_schedules FOR UPDATE 
USING (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));

DROP POLICY IF EXISTS "Permitir delete admin en class_schedules" ON public.class_schedules;
CREATE POLICY "Permitir delete admin en class_schedules" ON public.class_schedules FOR DELETE 
USING (EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin'));

-- 4. Storage Bucket: class-images
INSERT INTO storage.buckets (id, name, public) VALUES ('class-images', 'class-images', true)
ON CONFLICT (id) DO NOTHING;

-- Habilitar RLS en objetos de storage
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Política de lectura pública de imágenes
DROP POLICY IF EXISTS "Lectura publica de imagenes" ON storage.objects;
CREATE POLICY "Lectura publica de imagenes" ON storage.objects FOR SELECT USING (bucket_id = 'class-images');

-- Política de inserción, actualización, eliminación solo para admin
DROP POLICY IF EXISTS "Escritura admin en imagenes" ON storage.objects;
CREATE POLICY "Escritura admin en imagenes" ON storage.objects FOR ALL 
USING (
  bucket_id = 'class-images' 
  AND EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
)
WITH CHECK (
  bucket_id = 'class-images' 
  AND EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
);
