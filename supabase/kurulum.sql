-- =====================================================================
-- Minik Kodcular · Supabase kurulumu
-- Supabase panelinde: SQL Editor → New query → bu dosyanın tamamını
-- yapıştırın → aşağıdaki YONETICI_EPOSTASI satırını kendi e-postanızla
-- değiştirin → Run.
-- Dosya birden çok kez çalıştırılabilir; var olan verileri silmez.
-- =====================================================================

-- 1) Kurum yöneticisinin e-postası (bu adresle kayıt olan hesap yönetici olur)
create table if not exists public.ayar (anahtar text primary key, deger text not null);
insert into public.ayar (anahtar, deger) values ('yonetici_eposta', lower('YONETICI_EPOSTASI@ornek.com'))
  on conflict (anahtar) do update set deger = excluded.deger;

create extension if not exists pgcrypto with schema extensions;

-- 2) Tablolar -----------------------------------------------------------
create table if not exists public.okul (
  id uuid primary key default gen_random_uuid(),
  ad text not null check (length(ad) between 1 and 80)
);
create table if not exists public.sinif (
  id uuid primary key default gen_random_uuid(),
  okul_id uuid not null references public.okul on delete cascade,
  ad text not null check (length(ad) between 1 and 40)
);
create table if not exists public.ogrenci (
  id uuid primary key default gen_random_uuid(),
  sinif_id uuid not null references public.sinif on delete cascade,
  ad text not null check (length(ad) between 1 and 80),
  k text not null,                       -- küçük harfli ad (girişte karşılaştırma için)
  unique (sinif_id, k)
);
-- Öğretmen ve yöneticiler (Supabase hesabıyla eşleşir). rol boşsa: onay bekliyor.
create table if not exists public.yetkili (
  id uuid primary key references auth.users on delete cascade,
  ad text not null default '',
  email text,
  rol text check (rol in ('yonetici', 'ogretmen')),
  olusturma timestamptz not null default now()
);
create table if not exists public.yetkili_sinif (
  yetkili_id uuid not null references public.yetkili on delete cascade,
  sinif_id uuid not null references public.sinif on delete cascade,
  primary key (yetkili_id, sinif_id)
);
create table if not exists public.ilerleme (
  ogrenci_id uuid primary key references public.ogrenci on delete cascade,
  prog jsonb not null default '{}'::jsonb,
  t timestamptz not null default now()
);
create table if not exists public.ozet (
  ogrenci_id uuid primary key references public.ogrenci on delete cascade,
  s jsonb not null,
  t timestamptz not null default now()
);
create table if not exists public.kayit (
  ogrenci_id uuid not null references public.ogrenci on delete cascade,
  wk int not null,
  ev jsonb not null default '[]'::jsonb,
  primary key (ogrenci_id, wk)
);
-- Çocuk girişinde verilen anahtar (çocuğun hesabı yok; tablet bu anahtarla yalnızca o çocuğun kaydını yazar)
create table if not exists public.ogr_oturum (
  tok text primary key,
  ogrenci_id uuid not null references public.ogrenci on delete cascade,
  olusturma timestamptz not null default now()
);
create index if not exists sinif_okul_i on public.sinif (okul_id);
create index if not exists ogrenci_sinif_i on public.ogrenci (sinif_id);
create index if not exists ogr_oturum_ogr_i on public.ogr_oturum (ogrenci_id);

-- 3) Yetki yardımcıları ---------------------------------------------------
create or replace function public.is_yonetici() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from yetkili where id = auth.uid() and rol = 'yonetici');
$$;
create or replace function public.sinif_gorur(p_sinif uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select is_yonetici() or exists (
    select 1 from yetkili y join yetkili_sinif ys on ys.yetkili_id = y.id
    where y.id = auth.uid() and y.rol = 'ogretmen' and ys.sinif_id = p_sinif);
$$;
create or replace function public.ogrenci_gorur(p_ogr uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select sinif_gorur((select sinif_id from ogrenci where id = p_ogr));
$$;

-- 4) Satır düzeyi güvenlik (RLS) ------------------------------------------
alter table public.ayar enable row level security;
alter table public.okul enable row level security;
alter table public.sinif enable row level security;
alter table public.ogrenci enable row level security;
alter table public.yetkili enable row level security;
alter table public.yetkili_sinif enable row level security;
alter table public.ilerleme enable row level security;
alter table public.ozet enable row level security;
alter table public.kayit enable row level security;
alter table public.ogr_oturum enable row level security;

do $$ declare r record; begin
  for r in select policyname, tablename from pg_policies where schemaname = 'public'
    and tablename in ('ayar','okul','sinif','ogrenci','yetkili','yetkili_sinif','ilerleme','ozet','kayit','ogr_oturum')
  loop execute format('drop policy %I on public.%I', r.policyname, r.tablename); end loop;
end $$;

-- okul: yönetici hepsini; öğretmen yalnızca sınıfı olduğu okulu görür
create policy okul_oku on public.okul for select to authenticated
  using (is_yonetici() or exists (select 1 from sinif s where s.okul_id = okul.id and sinif_gorur(s.id)));
create policy okul_yaz on public.okul for all to authenticated using (is_yonetici()) with check (is_yonetici());
-- sinif ve ogrenci: yönetici hepsini, öğretmen atandığı sınıfları
create policy sinif_oku on public.sinif for select to authenticated using (sinif_gorur(id));
create policy sinif_yaz on public.sinif for all to authenticated using (is_yonetici()) with check (is_yonetici());
create policy ogrenci_oku on public.ogrenci for select to authenticated using (sinif_gorur(sinif_id));
create policy ogrenci_yaz on public.ogrenci for all to authenticated using (is_yonetici()) with check (is_yonetici());
-- yetkili: herkes kendi satırını; yönetici hepsini görür ve rol/sınıf atar
create policy yetkili_oku on public.yetkili for select to authenticated using (id = auth.uid() or is_yonetici());
create policy yetkili_yaz on public.yetkili for update to authenticated using (is_yonetici()) with check (is_yonetici());
create policy ys_oku on public.yetkili_sinif for select to authenticated using (yetkili_id = auth.uid() or is_yonetici());
create policy ys_yaz on public.yetkili_sinif for all to authenticated using (is_yonetici()) with check (is_yonetici());
-- çocuk verileri: yalnızca okumak için (yazma aşağıdaki fonksiyonlarla)
create policy ilerleme_oku on public.ilerleme for select to authenticated using (ogrenci_gorur(ogrenci_id));
create policy ozet_oku on public.ozet for select to authenticated using (ogrenci_gorur(ogrenci_id));
create policy kayit_oku on public.kayit for select to authenticated using (ogrenci_gorur(ogrenci_id));
-- ayar ve ogr_oturum: hiç kimse doğrudan okuyamaz/yazamaz (kural yok = kapalı)

-- Yönetici kendi rolünü kaldıramasın (kurum yöneticisiz kalmasın)
create or replace function public.yetkili_koru() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.id = auth.uid() and old.rol = 'yonetici' and new.rol is distinct from 'yonetici' then
    raise exception 'Kendi yönetici rolünüzü kaldıramazsınız.';
  end if;
  if new.email is distinct from old.email or new.id is distinct from old.id then
    raise exception 'Bu alan değiştirilemez.';
  end if;
  return new;
end $$;
drop trigger if exists yetkili_koru on public.yetkili;
create trigger yetkili_koru before update on public.yetkili for each row execute function public.yetkili_koru();

-- 5) Yeni hesap açılınca yetkili satırı (rol boş = onay bekliyor; yönetici e-postasıysa yönetici)
create or replace function public.yeni_kullanici() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into yetkili (id, ad, email, rol)
  values (new.id, left(coalesce(new.raw_user_meta_data->>'ad', ''), 80), lower(new.email),
          case when lower(new.email) = (select deger from ayar where anahtar = 'yonetici_eposta') then 'yonetici' end)
  on conflict (id) do nothing;
  return new;
end $$;
drop trigger if exists yeni_kullanici on auth.users;
create trigger yeni_kullanici after insert on auth.users for each row execute function public.yeni_kullanici();
-- Yönetici e-postası sonradan değiştirildiyse ya da hesap dosyadan önce açıldıysa: rolü ver
insert into public.yetkili (id, ad, email, rol)
  select u.id, coalesce(u.raw_user_meta_data->>'ad', ''), lower(u.email), 'yonetici' from auth.users u
  where lower(u.email) = (select deger from public.ayar where anahtar = 'yonetici_eposta')
  on conflict (id) do update set rol = 'yonetici';

-- 6) Çocuk tarafı: hesapsız giriş ve kayıt (yalnızca bu fonksiyonlar) ------
create or replace function public.okul_listesi() returns table (id uuid, ad text)
language sql stable security definer set search_path = public as $$
  select id, ad from okul order by ad;
$$;
create or replace function public.sinif_listesi(p_okul uuid) returns table (id uuid, ad text)
language sql stable security definer set search_path = public as $$
  select id, ad from sinif where okul_id = p_okul order by ad;
$$;
create or replace function public.sinif_bilgi(p_sinif uuid) returns table (id uuid, ad text, okul_id uuid)
language sql stable security definer set search_path = public as $$
  select id, ad, okul_id from sinif where id = p_sinif;
$$;

-- Ad sınıfta tam olarak varsa ya da yalnızca ilk ad yazıldı ve sınıfta tekse giriş olur.
create or replace function public.ogrenci_giris(p_sinif uuid, p_ad text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare o ogrenci; n int; t text;
begin
  p_ad := btrim(regexp_replace(coalesce(p_ad, ''), '\s+', ' ', 'g'));
  if p_ad = '' then return jsonb_build_object('err', 'yok'); end if;
  select * into o from ogrenci where sinif_id = p_sinif and k = p_ad;
  if o.id is null then
    select count(*) into n from ogrenci where sinif_id = p_sinif and split_part(k, ' ', 1) = p_ad;
    if n > 1 then return jsonb_build_object('err', 'cok'); end if;
    if n = 0 then return jsonb_build_object('err', 'yok'); end if;
    select * into o from ogrenci where sinif_id = p_sinif and split_part(k, ' ', 1) = p_ad;
  end if;
  t := encode(gen_random_bytes(24), 'hex');
  insert into ogr_oturum (tok, ogrenci_id) values (t, o.id);
  -- eski anahtarları temizle (çocuk başına en çok 20 tablet oturumu)
  delete from ogr_oturum where ogrenci_id = o.id and tok not in
    (select tok from ogr_oturum where ogrenci_id = o.id order by olusturma desc limit 20);
  return jsonb_build_object(
    'ogr', jsonb_build_object('id', o.id, 'ad', o.ad, 'cid', o.sinif_id, 'sid', (select okul_id from sinif where id = o.sinif_id), 'tok', t),
    'prog', coalesce((select prog from ilerleme where ogrenci_id = o.id), '{}'::jsonb),
    'ev', coalesce((select jsonb_agg(e) from kayit k, jsonb_array_elements(k.ev) e where k.ogrenci_id = o.id), '[]'::jsonb));
end $$;

-- Tablet, giriş anahtarıyla yalnızca o çocuğun kaydını, ilerlemesini ve özetini yazar.
create or replace function public.ogrenci_kaydet(p_tok text, p_kayit jsonb, p_prog jsonb, p_ozet jsonb) returns boolean
language plpgsql security definer set search_path = public as $$
declare oid uuid; w text; arr jsonb;
begin
  select ogrenci_id into oid from ogr_oturum where tok = p_tok;
  if oid is null then return false; end if;
  if octet_length(coalesce(p_kayit::text, '')) + octet_length(coalesce(p_prog::text, '')) + octet_length(coalesce(p_ozet::text, '')) > 900000 then
    raise exception 'Gönderilen veri çok büyük.';
  end if;
  if p_kayit is not null and jsonb_typeof(p_kayit) = 'object' then
    for w, arr in select key, value from jsonb_each(p_kayit) loop
      continue when jsonb_typeof(arr) <> 'array' or w !~ '^[0-9]{1,6}$';
      insert into kayit (ogrenci_id, wk, ev) values (oid, w::int, '[]'::jsonb) on conflict do nothing;
      update kayit set ev = (
        select coalesce(jsonb_agg(e order by ord), '[]'::jsonb) from (
          select e, row_number() over (order by coalesce((e->>'t')::bigint, 0)) as ord, count(*) over () as n
          from (select distinct e from jsonb_array_elements(kayit.ev || arr) e) d
        ) x where ord > n - 4000)
      where ogrenci_id = oid and wk = w::int;
    end loop;
  end if;
  if p_prog is not null and jsonb_typeof(p_prog) = 'object' then
    insert into ilerleme (ogrenci_id, prog, t) values (oid, p_prog, now())
      on conflict (ogrenci_id) do update set prog = excluded.prog, t = now();
  end if;
  if p_ozet is not null and jsonb_typeof(p_ozet) = 'object' then
    insert into ozet (ogrenci_id, s, t) values (oid, p_ozet, now())
      on conflict (ogrenci_id) do update set s = excluded.s, t = now();
  end if;
  return true;
end $$;

-- 7) İzinler --------------------------------------------------------------
revoke all on function public.ogrenci_giris(uuid, text) from public;
revoke all on function public.ogrenci_kaydet(text, jsonb, jsonb, jsonb) from public;
grant execute on function public.okul_listesi(), public.sinif_listesi(uuid), public.sinif_bilgi(uuid),
  public.ogrenci_giris(uuid, text), public.ogrenci_kaydet(text, jsonb, jsonb, jsonb) to anon, authenticated;
revoke all on public.ayar, public.ogr_oturum from anon, authenticated;
revoke all on public.okul, public.sinif, public.ogrenci, public.yetkili, public.yetkili_sinif, public.ilerleme, public.ozet, public.kayit from anon;
grant select, insert, update, delete on public.okul, public.sinif, public.ogrenci, public.yetkili_sinif to authenticated;
grant select, update on public.yetkili to authenticated;
grant select on public.ilerleme, public.ozet, public.kayit to authenticated;
