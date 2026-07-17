-- =====================================================================
--  Corse du Sud — « Le séjour » : schéma collaboratif Supabase
--  À lancer UNE FOIS dans : projet Supabase → SQL Editor → New query → Run
--  Sans danger : tout est idempotent (on peut le relancer sans casser).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Pré-requis à activer À LA MAIN dans le tableau de bord (pas en SQL) :
--    Authentication → Providers → Anonymous  ➜  ON
--    (chaque téléphone reçoit une identité anonyme stable = permet
--     « seul l'auteur peut supprimer sa photo » sans créer de compte.)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 1. Membres de la bande (pseudo + couleur, choisis après le code)
-- ---------------------------------------------------------------------
create table if not exists public.members (
  id         uuid primary key references auth.users (id) on delete cascade,
  pseudo     text not null check (char_length(pseudo) between 1 and 30),
  color      text not null default '#FF5324',
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- 2. Photos et vidéos du séjour
--    storage_path  = version affichable (web) pour l'appli
--    original_path = fichier brut, pleine résolution, pour l'album
-- ---------------------------------------------------------------------
create table if not exists public.photos (
  id            uuid primary key default gen_random_uuid(),
  author        uuid not null references auth.users (id) on delete cascade,
  author_name   text not null,            -- copie du pseudo au moment de l'ajout
  author_color  text not null default '#FF5324',
  kind          text not null default 'photo' check (kind in ('photo','video')),
  storage_path  text not null,            -- version légère affichée dans l'appli
  original_path text,                     -- original brut (album fin de séjour)
  lat           double precision,
  lng           double precision,
  placed        text not null default 'exif' check (placed in ('exif','gps','manual')),
  taken_at      timestamptz not null,     -- date de prise (EXIF) sinon date d'ajout
  caption       text,
  width         int,
  height        int,
  created_at    timestamptz not null default now()
);

create index if not exists photos_taken_at_idx on public.photos (taken_at);
create index if not exists photos_geo_idx      on public.photos (lat, lng);

-- ---------------------------------------------------------------------
-- 3. Réactions (emojis) — une par membre / photo / emoji
-- ---------------------------------------------------------------------
create table if not exists public.reactions (
  id         uuid primary key default gen_random_uuid(),
  photo_id   uuid not null references public.photos (id) on delete cascade,
  member     uuid not null references auth.users (id) on delete cascade,
  emoji      text not null,
  created_at timestamptz not null default now(),
  unique (photo_id, member, emoji)
);

create index if not exists reactions_photo_idx on public.reactions (photo_id);

-- ---------------------------------------------------------------------
-- 4. Sécurité (RLS) — tout est réservé aux personnes connectées
--    (l'auth anonyme compte comme « authenticated »). Le code de groupe
--    reste un garde-fou côté appli ; ici on protège au niveau base.
-- ---------------------------------------------------------------------
alter table public.members   enable row level security;
alter table public.photos    enable row level security;
alter table public.reactions enable row level security;

-- Membres : lecture pour tous les connectés ; on ne gère que SA fiche
drop policy if exists members_select on public.members;
create policy members_select on public.members
  for select using (auth.role() = 'authenticated');

drop policy if exists members_upsert on public.members;
create policy members_upsert on public.members
  for insert with check (auth.uid() = id);

drop policy if exists members_update on public.members;
create policy members_update on public.members
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- Photos : lecture pour tous les connectés ; ajout = signé de soi ;
-- modif + suppression = l'auteur uniquement
drop policy if exists photos_select on public.photos;
create policy photos_select on public.photos
  for select using (auth.role() = 'authenticated');

drop policy if exists photos_insert on public.photos;
create policy photos_insert on public.photos
  for insert with check (auth.uid() = author);

drop policy if exists photos_update on public.photos;
create policy photos_update on public.photos
  for update using (auth.uid() = author) with check (auth.uid() = author);

drop policy if exists photos_delete on public.photos;
create policy photos_delete on public.photos
  for delete using (auth.uid() = author);

-- Réactions : lecture pour tous ; on ne pose/retire que les siennes
drop policy if exists reactions_select on public.reactions;
create policy reactions_select on public.reactions
  for select using (auth.role() = 'authenticated');

drop policy if exists reactions_insert on public.reactions;
create policy reactions_insert on public.reactions
  for insert with check (auth.uid() = member);

drop policy if exists reactions_delete on public.reactions;
create policy reactions_delete on public.reactions
  for delete using (auth.uid() = member);

-- ---------------------------------------------------------------------
-- 5. Stockage des fichiers
--    Bucket public en lecture (les <img> marchent direct), chemins en
--    UUID impossibles à deviner. Écriture réservée aux connectés,
--    suppression réservée au propriétaire du fichier.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('sejour', 'sejour', true)
on conflict (id) do update set public = true;

drop policy if exists sejour_read on storage.objects;
create policy sejour_read on storage.objects
  for select using (bucket_id = 'sejour');

drop policy if exists sejour_write on storage.objects;
create policy sejour_write on storage.objects
  for insert to authenticated with check (bucket_id = 'sejour');

drop policy if exists sejour_delete on storage.objects;
create policy sejour_delete on storage.objects
  for delete to authenticated using (bucket_id = 'sejour' and owner = auth.uid());

-- ---------------------------------------------------------------------
-- 6. Temps réel : les nouvelles photos et réactions apparaissent en direct
-- ---------------------------------------------------------------------
alter publication supabase_realtime add table public.photos;
alter publication supabase_realtime add table public.reactions;

-- =====================================================================
--  Fini. Ensuite : Settings → API → me copier « Project URL » + clé « anon ».
-- =====================================================================
