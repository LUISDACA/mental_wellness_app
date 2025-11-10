-- ================================================================
-- Supabase bootstrap: tablas + triggers + RLS + storage
-- Idempotente y en orden seguro de ejecución
-- ================================================================

create extension if not exists pgcrypto;

-- ================================================================
-- 1) TABLAS (tu esquema exacto)
-- ================================================================

-- PROFILES
create table if not exists public.profiles (
  id uuid not null,
  email text null,
  full_name text null,
  created_at timestamptz not null default now(),
  phone text null,
  address text null,
  avatar_path text null,
  updated_at timestamptz not null default now(),
  first_name text null,
  last_name text null,
  birth_date date null,
  gender text null,
  constraint profiles_pkey primary key (id),
  constraint profiles_email_key unique (email),
  constraint profiles_id_fkey foreign key (id) references auth.users (id) on delete cascade,
  constraint profiles_gender_check check (gender = any (array['female','male','custom']))
);

-- EMOTION ENTRIES
create table if not exists public.emotion_entries (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  text_input text null,
  detected_emotion text not null,
  score numeric null,
  severity integer null,
  model text null,
  advice text null,
  created_at timestamptz not null default now(),
  constraint emotion_entries_pkey primary key (id),
  constraint emotion_entries_user_id_fkey foreign key (user_id) references auth.users (id) on delete cascade,
  constraint emotion_entries_score_check check (score >= 0::numeric and score <= 1::numeric),
  constraint emotion_entries_severity_check check (severity >= 0 and severity <= 100)
);

-- MESSAGES
create table if not exists public.messages (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  role text not null,
  content text not null,
  created_at timestamptz not null default now(),
  constraint messages_pkey primary key (id),
  constraint messages_user_id_fkey foreign key (user_id) references auth.users (id) on delete cascade,
  constraint messages_role_check check (role = any (array['user','assistant']))
);

-- POSTS
create table if not exists public.posts (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  author_name text not null,
  content text not null,
  media_path text null,
  media_type text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  author_avatar_path text null,
  constraint posts_pkey primary key (id),
  constraint posts_user_id_fkey foreign key (user_id) references auth.users (id) on delete cascade,
  constraint posts_media_type_check check (media_type = any (array['image','pdf']))
);
create index if not exists idx_posts_created_at on public.posts (created_at desc);

-- RECOMMENDATIONS
create table if not exists public.recommendations (
  id uuid not null default gen_random_uuid(),
  emotion text not null,
  title text not null,
  kind text not null,
  payload jsonb null,
  active boolean not null default true,
  constraint recommendations_pkey primary key (id)
);

-- SOS_CONTACTS
create table if not exists public.sos_contacts (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  label text not null,
  phone text null,
  email text null,
  created_at timestamptz not null default now(),
  avatar_path text null,
  constraint sos_contacts_pkey primary key (id),
  constraint sos_contacts_user_id_fkey foreign key (user_id) references auth.users (id) on delete cascade
);

-- ================================================================
-- 2) FUNCIONES + TRIGGERS
-- ================================================================

-- Función usada por tus triggers de updated_at
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  if tg_op in ('INSERT','UPDATE') then
    if exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name=tg_table_name and column_name='updated_at'
    ) then
      new.updated_at := now();
    end if;
  end if;
  return new;
end $$;

-- Trigger PROFILES (solo si no existe)
do $$
begin
  if not exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid=t.tgrelid
    join pg_namespace n on n.oid=c.relnamespace
    where t.tgname='trg_profiles_updated_at'
      and c.relname='profiles' and n.nspname='public'
  ) then
    execute 'create trigger trg_profiles_updated_at
             before update on public.profiles
             for each row execute function public.handle_updated_at()';
  end if;
end $$;

-- Trigger POSTS (solo si no existe)
do $$
begin
  if not exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid=t.tgrelid
    join pg_namespace n on n.oid=c.relnamespace
    where t.tgname='trg_posts_updated_at'
      and c.relname='posts' and n.nspname='public'
  ) then
    execute 'create trigger trg_posts_updated_at
             before update on public.posts
             for each row execute function public.handle_updated_at()';
  end if;
end $$;

-- Autocreación de profile tras alta en auth.users (solo si no existe)
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, null)
  on conflict (id) do nothing;
  return new;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger t
    join pg_class c on c.oid=t.tgrelid
    join pg_namespace n on n.oid=c.relnamespace
    where t.tgname='on_auth_user_created'
      and c.relname='users' and n.nspname='auth'
  ) then
    execute 'create trigger on_auth_user_created
             after insert on auth.users
             for each row execute function public.handle_new_user()';
  end if;
end $$;

-- ================================================================
-- 3) RLS + POLÍTICAS
-- ================================================================

-- PROFILES (id = auth.uid())
alter table public.profiles enable row level security;
drop policy if exists profiles_owner_select on public.profiles;
create policy profiles_owner_select on public.profiles
for select to authenticated using (id = auth.uid());
drop policy if exists profiles_owner_insert on public.profiles;
create policy profiles_owner_insert on public.profiles
for insert to authenticated with check (id = auth.uid());
drop policy if exists profiles_owner_update on public.profiles;
create policy profiles_owner_update on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists profiles_owner_delete on public.profiles;
create policy profiles_owner_delete on public.profiles
for delete to authenticated using (id = auth.uid());

-- EMOTION_ENTRIES (user_id)
alter table public.emotion_entries enable row level security;
drop policy if exists emotion_entries_owner_select on public.emotion_entries;
create policy emotion_entries_owner_select on public.emotion_entries
for select to authenticated using (user_id = auth.uid());
drop policy if exists emotion_entries_owner_insert on public.emotion_entries;
create policy emotion_entries_owner_insert on public.emotion_entries
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists emotion_entries_owner_update on public.emotion_entries;
create policy emotion_entries_owner_update on public.emotion_entries
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists emotion_entries_owner_delete on public.emotion_entries;
create policy emotion_entries_owner_delete on public.emotion_entries
for delete to authenticated using (user_id = auth.uid());
create index if not exists idx_emotion_entries_user_time
  on public.emotion_entries (user_id, created_at desc);

-- MESSAGES (user_id)
alter table public.messages enable row level security;
drop policy if exists messages_owner_select on public.messages;
create policy messages_owner_select on public.messages
for select to authenticated using (user_id = auth.uid());
drop policy if exists messages_owner_insert on public.messages;
create policy messages_owner_insert on public.messages
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists messages_owner_update on public.messages;
create policy messages_owner_update on public.messages
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists messages_owner_delete on public.messages;
create policy messages_owner_delete on public.messages
for delete to authenticated using (user_id = auth.uid());
create index if not exists idx_messages_user_time
  on public.messages (user_id, created_at desc);

-- POSTS (user_id)
alter table public.posts enable row level security;
drop policy if exists posts_owner_select on public.posts;
create policy posts_owner_select on public.posts
for select to authenticated using (user_id = auth.uid());
drop policy if exists posts_owner_insert on public.posts;
create policy posts_owner_insert on public.posts
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists posts_owner_update on public.posts;
create policy posts_owner_update on public.posts
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists posts_owner_delete on public.posts;
create policy posts_owner_delete on public.posts
for delete to authenticated using (user_id = auth.uid());

-- RECOMMENDATIONS (sin user_id): lectura autenticados; escritura vía service_role
alter table public.recommendations enable row level security;
drop policy if exists recommendations_read_all on public.recommendations;
create policy recommendations_read_all on public.recommendations
for select to authenticated using (true);
drop policy if exists recommendations_write_service on public.recommendations;
create policy recommendations_write_service on public.recommendations
for all to service_role using (true) with check (true);

-- SOS_CONTACTS (user_id)
alter table public.sos_contacts enable row level security;
drop policy if exists sos_contacts_owner_select on public.sos_contacts;
create policy sos_contacts_owner_select on public.sos_contacts
for select to authenticated using (user_id = auth.uid());
drop policy if exists sos_contacts_owner_insert on public.sos_contacts;
create policy sos_contacts_owner_insert on public.sos_contacts
for insert to authenticated with check (user_id = auth.uid());
drop policy if exists sos_contacts_owner_update on public.sos_contacts;
create policy sos_contacts_owner_update on public.sos_contacts
for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists sos_contacts_owner_delete on public.sos_contacts;
create policy sos_contacts_owner_delete on public.sos_contacts
for delete to authenticated using (user_id = auth.uid());
create index if not exists idx_sos_contacts_user_time
  on public.sos_contacts (user_id, created_at desc);

-- ================================================================
-- 4) STORAGE (buckets + políticas). Ejecuta como rol dueño (postgres).
--    Si tu entorno no deja set role, crea las políticas desde el Dashboard.
-- ================================================================

begin;
  set local role postgres;

  -- Buckets (upsert)
  insert into storage.buckets (id, name, public)
  values ('avatars','avatars', true)
  on conflict (id) do update set public = excluded.public;

  insert into storage.buckets (id, name, public)
  values ('post_media','post_media', true)
  on conflict (id) do update set public = excluded.public;

  insert into storage.buckets (id, name, public)
  values ('sos_avatars','sos_avatars', true)
  on conflict (id) do update set public = excluded.public;

  -- Índice útil (si no hay permisos, omite este bloque)
  do $$
  begin
    begin
      execute 'create index if not exists idx_storage_bucket_name on storage.objects (bucket_id, name)';
    exception when insufficient_privilege then
      null;
    end;
  end $$;

  -- Limpiar posibles políticas antiguas
  drop policy if exists post_images_insert_own on storage.objects;
  drop policy if exists post_images_update_own on storage.objects;
  drop policy if exists post_images_delete_own on storage.objects;
  drop policy if exists post_images_list_own   on storage.objects;

  -- AVATARS
  drop policy if exists avatars_insert_own on storage.objects;
  create policy avatars_insert_own
  on storage.objects for insert to authenticated
  with check (bucket_id='avatars' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists avatars_update_own on storage.objects;
  create policy avatars_update_own
  on storage.objects for update to authenticated
  using     (bucket_id='avatars' and name like ('u_'||auth.uid()::text||'/%'))
  with check(bucket_id='avatars' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists avatars_delete_own on storage.objects;
  create policy avatars_delete_own
  on storage.objects for delete to authenticated
  using (bucket_id='avatars' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists avatars_list_own on storage.objects;
  create policy avatars_list_own
  on storage.objects for select to authenticated
  using (bucket_id='avatars' and name like ('u_'||auth.uid()::text||'/%'));

  -- POST_MEDIA
  drop policy if exists post_media_insert_own on storage.objects;
  create policy post_media_insert_own
  on storage.objects for insert to authenticated
  with check (bucket_id='post_media' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists post_media_update_own on storage.objects;
  create policy post_media_update_own
  on storage.objects for update to authenticated
  using     (bucket_id='post_media' and name like ('u_'||auth.uid()::text||'/%'))
  with check(bucket_id='post_media' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists post_media_delete_own on storage.objects;
  create policy post_media_delete_own
  on storage.objects for delete to authenticated
  using (bucket_id='post_media' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists post_media_list_own on storage.objects;
  create policy post_media_list_own
  on storage.objects for select to authenticated
  using (bucket_id='post_media' and name like ('u_'||auth.uid()::text||'/%'));

  -- SOS_AVATARS
  drop policy if exists sos_avatars_insert_own on storage.objects;
  create policy sos_avatars_insert_own
  on storage.objects for insert to authenticated
  with check (bucket_id='sos_avatars' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists sos_avatars_update_own on storage.objects;
  create policy sos_avatars_update_own
  on storage.objects for update to authenticated
  using     (bucket_id='sos_avatars' and name like ('u_'||auth.uid()::text||'/%'))
  with check(bucket_id='sos_avatars' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists sos_avatars_delete_own on storage.objects;
  create policy sos_avatars_delete_own
  on storage.objects for delete to authenticated
  using (bucket_id='sos_avatars' and name like ('u_'||auth.uid()::text||'/%'));

  drop policy if exists sos_avatars_list_own on storage.objects;
  create policy sos_avatars_list_own
  on storage.objects for select to authenticated
  using (bucket_id='sos_avatars' and name like ('u_'||auth.uid()::text||'/%'));
commit;

-- =========================================
-- EXTENSION NECESARIA
-- =========================================
create extension if not exists "pgcrypto";

-- =========================================
-- 1) TABLA DE PROMPTS: empathy_prompts
-- =========================================

create table if not exists public.empathy_prompts (
  key text primary key,
  content text not null,
  description text,
  updated_at timestamptz not null default now()
);

alter table public.empathy_prompts enable row level security;

-- Lectura pública (solo textos de sistema)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'empathy_prompts'
      and policyname = 'Public read empathy_prompts'
  ) then
    create policy "Public read empathy_prompts"
      on public.empathy_prompts
      for select
      using (true);
  end if;
end$$;

-- (Opcional) permitir a usuarios autenticados modificar (ajusta según rol real)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'empathy_prompts'
      and policyname = 'Auth upsert empathy_prompts'
  ) then
    create policy "Auth upsert empathy_prompts"
      on public.empathy_prompts
      for all
      using (auth.uid() is not null)
      with check (auth.uid() is not null);
  end if;
end$$;

-- =========================================
-- 1.1) SEED / UPSERT DE PROMPTS
-- =========================================

insert into public.empathy_prompts (key, content, description) values

-- Prompt base análisis emoción
('emotion_analysis_base',
 'Eres un asistente empático de bienestar mental. Devuelve SOLO JSON válido (sin markdown, sin texto extra) con este formato exacto: {"emotion":"happiness|sadness|anxiety|anger|neutral","score":0.0-1.0,"severity":0-100,"advice":"breve consejo en español"}. Analiza el siguiente texto del usuario y responde solo con el JSON. Texto: "{text}"',
 'Prompt principal para análisis emocional con salida JSON'),

-- Prompt estricto análisis emoción
('emotion_analysis_strict',
 'SOLO JSON. NADA DE TEXTO EXTRA. Formato exacto: {"emotion":"happiness|sadness|anxiety|anger|neutral","score":0.0-1.0,"severity":0-100,"advice":"breve consejo en español"}. Texto: "{text}"',
 'Prompt de reintento para forzar JSON limpio'),

-- Mensaje cuando el texto no es emocional
('analysis_out_of_scope',
 'No puedo analizar este mensaje porque no está relacionado con tus emociones o tu bienestar emocional. Si lo deseas, cuéntame cómo te sientes y te ayudo con eso.',
 'Mensaje cuando el texto enviado a análisis no es emocional. No debe guardarse en métricas.'),

-- Sistema del chat empático
('chat_system',
 'Eres un asistente empático de bienestar emocional. Respondes en español, de forma breve, cálida y práctica. Solo hablas de emociones, bienestar mental, manejo de estrés, ansiedad, tristeza, autocuidado, límites sanos y cómo pedir ayuda. No das diagnósticos clínicos ni consejos médicos. Si el usuario pregunta algo fuera de ese ámbito (deportes, tecnología, política, finanzas, etc.), explícale amablemente que solo puedes ayudar con temas emocionales.',
 'Instrucciones del asistente empático para el modo chat'),

-- Chat fuera de alcance
('chat_out_of_scope',
 'No te puedo ayudar con ese tema, soy un chat empático enfocado únicamente en cómo te sientes y en tu bienestar emocional.',
 'Respuesta cuando la pregunta no es sobre emociones o bienestar emocional'),

-- Offline crisis
('chat_offline_crisis',
 'Siento mucho que te sientas así. No estás solo/a. Si corres riesgo inmediato, busca ayuda urgente llamando a los servicios de emergencia o a una línea de apoyo emocional en tu país. También puedes contactar a alguien de confianza ahora mismo.',
 'Respuesta en modo offline cuando se detectan indicadores de crisis'),

-- Offline tristeza
('chat_offline_sad',
 'Lamento que te sientas así. Probemos unas respiraciones lentas juntos. Si te apetece, cuéntame qué pasó y buscamos un paso pequeño que pueda ayudarte hoy.',
 'Respuesta en modo offline para tristeza'),

-- Offline ansiedad
('chat_offline_anxiety',
 'La ansiedad puede sentirse muy intensa. Probemos la respiración 4-7-8 durante un minuto. Cuéntame qué es lo que más te preocupa ahora mismo.',
 'Respuesta en modo offline para ansiedad'),

-- Offline enojo
('chat_offline_anger',
 'Es válido sentir enojo. Antes de reaccionar, probemos respirar profundo varias veces o tomar distancia unos minutos. Luego podemos ver cómo expresar lo que sientes de forma segura.',
 'Respuesta en modo offline para enojo'),

-- Offline genérico
('chat_offline_default',
 'Estoy aquí para escucharte y acompañarte. Cuéntame un poco más sobre cómo te estás sintiendo.',
 'Respuesta offline genérica cuando no hay una emoción específica clara'),

-- Fallback error técnico
('chat_fallback_error',
 'Lo siento, tuve un problema técnico. Pero sigo aquí para escucharte. ¿Quieres contarme cómo te sientes en este momento?',
 'Respuesta si falla la generación con el modelo'),

-- Texto SOS sugerido
('sos_footer',
 'Si sientes que corres peligro o que podrías hacerte daño, intenta no quedarte solo/a. Busca ayuda inmediata con servicios de emergencia, líneas de prevención del suicidio o personas de confianza en tu entorno.',
 'Texto sugerido para secciones SOS'),

-- Frases opcionales para UI según severidad
('analysis_prefix_low',
 'Tu emoción parece manejable en este momento. Aun así, es totalmente válido lo que sientes.',
 'Fragmento opcional para severidad baja'),
('analysis_prefix_mid',
    'Estás lidiando con algo importante. Gracias por compartirlo.',
    'Fragmento opcional para severidad media'),
('analysis_prefix_high',
    'Lo que estás viviendo es muy intenso. No tienes por qué cargar con todo esto en soledad.',
    'Fragmento opcional para severidad alta')

on conflict (key)
do update
set content = excluded.content,
    description = excluded.description,
    updated_at = now();

-- =========================================
-- 2) TABLA DE REGLAS: empathy_topic_rules
-- =========================================

create table if not exists public.empathy_topic_rules (
    id bigserial primary key,
    pattern text not null,
    kind text not null check (kind in ('emotion','crisis')),
    match_type text not null default 'contains' check (match_type in ('contains','regex')),
    active boolean not null default true,
    constraint empathy_topic_rules_pattern_kind_unique unique (pattern, kind)
);

alter table public.empathy_topic_rules enable row level security;

-- Lectura pública (solo reglas de sistema)
do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
        and tablename = 'empathy_topic_rules'
        and policyname = 'Public read empathy_topic_rules'
    ) then
        create policy "Public read empathy_topic_rules"
        on public.empathy_topic_rules
        for select
        using (true);
    end if;
end$$;

-- (Opcional) permitir gestión a usuarios autenticados (restringe en tu backend si solo admins)
do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
        and tablename = 'empathy_topic_rules'
        and policyname = 'Auth manage empathy_topic_rules'
    ) then
        create policy "Auth manage empathy_topic_rules"
        on public.empathy_topic_rules
        for all
        using (auth.uid() is not null)
        with check (auth.uid() is not null);
    end if;
end$$;

-- 2.1) Reglas EMOCIÓN (upsert)

insert into public.empathy_topic_rules (pattern, kind, match_type, active) values
    ('ansiedad',                  'emotion', 'contains', true),
    ('ansioso',                   'emotion', 'contains', true),
    ('ansiosa',                   'emotion', 'contains', true),
    ('angustia',                  'emotion', 'contains', true),
    ('estrés',                    'emotion', 'contains', true),
    ('estres',                    'emotion', 'contains', true),
    ('miedo',                     'emotion', 'contains', true),
    ('preocup',                   'emotion', 'contains', true),
    ('triste',                    'emotion', 'contains', true),
    ('tristeza',                  'emotion', 'contains', true),
    ('deprim',                    'emotion', 'contains', true),
    ('soledad',                   'emotion', 'contains', true),
    ('me siento',                 'emotion', 'contains', true),
    ('no me siento bien',         'emotion', 'contains', true),
    ('sin ganas',                 'emotion', 'contains', true),
    ('agotado',                   'emotion', 'contains', true),
    ('agotada',                   'emotion', 'contains', true),
    ('cansado emocionalmente',    'emotion', 'contains', true),
    ('quemado',                   'emotion', 'contains', true),
    ('burnout',                   'emotion', 'contains', true),
    ('estresado',                 'emotion', 'contains', true),
    ('estresada',                 'emotion', 'contains', true),
    ('llorando',                  'emotion', 'contains', true),
    ('llanto',                    'emotion', 'contains', true),
    ('vacío',                     'emotion', 'contains', true),
    ('vacio',                     'emotion', 'contains', true),
    ('frustración',               'emotion', 'contains', true),
    ('frustracion',               'emotion', 'contains', true),
    ('enojo',                     'emotion', 'contains', true),
    ('enojado',                   'emotion', 'contains', true),
    ('enojada',                   'emotion', 'contains', true),
    ('rabia',                     'emotion', 'contains', true),
    ('ira',                       'emotion', 'contains', true),
    ('culpa',                     'emotion', 'contains', true),
    ('vergüenza',                 'emotion', 'contains', true),
    ('verguenza',                 'emotion', 'contains', true),
    ('autoestima',                'emotion', 'contains', true),
    ('crisis de ansiedad',        'emotion', 'contains', true),
    ('ataque de pánico',          'emotion', 'contains', true),
    ('ataque de panico',          'emotion', 'contains', true),
    ('mal emocionalmente',        'emotion', 'contains', true),
    ('ansiedad social',           'emotion', 'contains', true),
    ('me siento solo',            'emotion', 'contains', true),
    ('me siento sola',            'emotion', 'contains', true),
    ('me siento vacío',           'emotion', 'contains', true),
    ('me siento vacio',           'emotion', 'contains', true),
    ('no valgo nada',             'emotion', 'contains', true)
on conflict (pattern, kind)
do update
set match_type = excluded.match_type,
    active = excluded.active;

-- 2.2) Reglas CRISIS (upsert)

insert into public.empathy_topic_rules (pattern, kind, match_type, active) values
    ('suicid',                          'crisis', 'contains', true),
    ('quitarme la vida',                'crisis', 'contains', true),
    ('no quiero vivir',                 'crisis', 'contains', true),
    ('no quiero seguir viviendo',       'crisis', 'contains', true),
    ('no le encuentro sentido a la vida','crisis', 'contains', true),
    ('hacerme daño',                    'crisis', 'contains', true),
    ('hacerme danio',                   'crisis', 'contains', true),
    ('autolesion',                      'crisis', 'contains', true),
    ('autolesión',                      'crisis', 'contains', true),
    ('lastimarme',                      'crisis', 'contains', true),
    ('ya no puedo más',                 'crisis', 'contains', true),
    ('ya no puedo mas',                 'crisis', 'contains', true),
    ('no aguanto más',                  'crisis', 'contains', true),
    ('no aguanto mas',                  'crisis', 'contains', true),
    ('quisiera desaparecer',            'crisis', 'contains', true)
on conflict (pattern, kind)
do update
set match_type = excluded.match_type,
    active = excluded.active;

-- =========================================
-- 3) TABLA DE LOGS: empathy_logs
-- =========================================

create table if not exists public.empathy_logs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid,
    kind text not null check (kind in ('analysis','chat')),
    model text,
    request_text text not null,
    response_text text,
    emotion text,
    severity int,
    is_crisis boolean,
    is_ai boolean,
    created_at timestamptz not null default now()
);

alter table public.empathy_logs enable row level security;

-- Ver solo tus logs
do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
        and tablename = 'empathy_logs'
        and policyname = 'Users select own empathy_logs'
    ) then
        create policy "Users select own empathy_logs"
        on public.empathy_logs
        for select
        using (auth.uid() is not null and user_id = auth.uid());
    end if;
end$$;

-- Insertar solo como uno mismo (o user_id null si backend de servicio)
do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
        and tablename = 'empathy_logs'
        and policyname = 'Users insert own empathy_logs'
    ) then
        create policy "Users insert own empathy_logs"
        on public.empathy_logs
        for insert
        with check (auth.uid() is null or user_id = auth.uid());
    end if;
end$$;

-- =========================================
-- 4) TABLA PRINCIPAL: emotion_entries
--    (Historial + gráficas)
-- =========================================

create table if not exists public.emotion_entries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null,
    text_input text not null,
    detected_emotion text not null,
    score numeric not null,
    severity int not null,
    advice text,
    model text,
    created_at timestamptz not null default now()
);

alter table public.emotion_entries enable row level security;

-- Cada usuario ve solo sus entradas
do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
        and tablename = 'emotion_entries'
        and policyname = 'Users select own emotion_entries'
    ) then
        create policy "Users select own emotion_entries"
        on public.emotion_entries
        for select
        using (auth.uid() is not null and user_id = auth.uid());
    end if;
end$$;

-- Cada usuario inserta solo sus entradas
do $$
begin
    if not exists (
        select 1 from pg_policies
        where schemaname = 'public'
        and tablename = 'emotion_entries'
        and policyname = 'Users insert own emotion_entries'
    ) then
        create policy "Users insert own emotion_entries"
        on public.emotion_entries
        for insert
        with check (auth.uid() is not null and user_id = auth.uid());
    end if;
end$$;

-- Índice para historial y gráficas
create index if not exists emotion_entries_user_created_idx
    on public.emotion_entries (user_id, created_at);

-- =========================================
-- FIN
-- =========================================
