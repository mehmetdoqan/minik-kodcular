-- =====================================================================
-- Minik Kodcular · Supabase kurulumu
-- Supabase panelinde: SQL Editor → New query → bu dosyanın tamamını
-- yapıştırın → hemen aşağıdaki iki değeri değiştirin → Run.
-- Dosya birden çok kez çalıştırılabilir; var olan verileri silmez.
-- =====================================================================

-- >>> İLK KURUM YÖNETİCİSİ: kullanıcı adı ve şifre (yalnızca hesap henüz yoksa kullanılır)
create temp table if not exists _ilk_yonetici (kullanici text, sifre text, ad text);
truncate _ilk_yonetici;
insert into _ilk_yonetici values ('mudur', 'BURAYA_SIFRE', 'Kurum Yöneticisi');
-- <<<

create extension if not exists pgcrypto with schema extensions;

-- 1) Tablolar -----------------------------------------------------------
create table if not exists public.okul (
  id uuid primary key default gen_random_uuid(),
  ad text not null check (length(ad) between 1 and 80)
);
create table if not exists public.sinif (
  id uuid primary key default gen_random_uuid(),
  okul_id uuid not null references public.okul on delete cascade,
  ad text not null check (length(ad) between 1 and 40)
);
-- Çocuklar: yalnızca ad (aynı ad varsa soyadının ilk harfi: "Ayşe Y.")
create table if not exists public.ogrenci (
  id uuid primary key default gen_random_uuid(),
  sinif_id uuid not null references public.sinif on delete cascade,
  ad text not null check (length(ad) between 1 and 40),
  k text not null,                       -- küçük harfli, noktasız ad (girişte karşılaştırma için)
  unique (sinif_id, k)
);
-- Öğretmen ve yöneticiler: hesabı yönetici açar (e-posta yok)
create table if not exists public.yetkili (
  id uuid primary key default gen_random_uuid(),
  kullanici text not null unique check (kullanici ~ '^[a-z0-9._-]{2,30}$'),
  ad text not null default '',
  rol text not null check (rol in ('yonetici', 'ogretmen')),
  sifre text not null,                   -- bcrypt
  olusturma timestamptz not null default now()
);
create table if not exists public.yetkili_sinif (
  yetkili_id uuid not null references public.yetkili on delete cascade,
  sinif_id uuid not null references public.sinif on delete cascade,
  primary key (yetkili_id, sinif_id)
);
create table if not exists public.yetkili_oturum (
  tok text primary key,
  yetkili_id uuid not null references public.yetkili on delete cascade,
  son timestamptz not null default now()
);
create table if not exists public.giris_deneme (kullanici text not null, t timestamptz not null default now());
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
-- Çocuk girişinde tablete verilen anahtar (çocuğun hesabı yok)
create table if not exists public.ogr_oturum (
  tok text primary key,
  ogrenci_id uuid not null references public.ogrenci on delete cascade,
  olusturma timestamptz not null default now()
);
create index if not exists sinif_okul_i on public.sinif (okul_id);
create index if not exists ogrenci_sinif_i on public.ogrenci (sinif_id);
create index if not exists ogr_oturum_ogr_i on public.ogr_oturum (ogrenci_id);
create index if not exists yetkili_oturum_y_i on public.yetkili_oturum (yetkili_id);
create index if not exists giris_deneme_i on public.giris_deneme (kullanici, t);

-- 2) Tablolar dışarıya tamamen kapalı. Her şey aşağıdaki fonksiyonlardan geçer.
do $$ declare t text; begin
  foreach t in array array['okul','sinif','ogrenci','yetkili','yetkili_sinif','yetkili_oturum','giris_deneme','ilerleme','ozet','kayit','ogr_oturum'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('revoke all on public.%I from anon, authenticated', t);
  end loop;
end $$;

-- İlk yönetici
do $$ declare r record; begin
  select * into r from _ilk_yonetici;
  if not exists (select 1 from public.yetkili where rol = 'yonetici') then
    if r.sifre is null or r.sifre = 'BURAYA_SIFRE' or length(r.sifre) < 6 then
      raise exception 'Dosyanın başındaki yönetici şifresini (BURAYA_SIFRE) en az 6 karakterlik bir şifreyle değiştirin.';
    end if;
    insert into public.yetkili (kullanici, ad, rol, sifre)
      values (lower(r.kullanici), r.ad, 'yonetici', extensions.crypt(r.sifre, extensions.gen_salt('bf', 10)));
  end if;
end $$;
drop table if exists _ilk_yonetici;

-- 3) Yardımcılar (dışarıdan çağrılamaz) -----------------------------------
create or replace function public._norm(p text) returns text language sql immutable as $$
  -- Türkçe harfler: İ/I/ı hepsi i sayılır (çocuk "ILKER" de "ilker" de yazsa İlker girer), noktalar atılır
  select btrim(regexp_replace(replace(replace(lower(translate(coalesce(p, ''), 'İIı', 'iii')), chr(775), ''), '.', ''), '\s+', ' ', 'g'));
$$;
-- Oturum anahtarından yetkiliyi bulur; 12 saat kullanılmayan oturum kapanır.
create or replace function public._yetkili(p_tok text) returns public.yetkili
language plpgsql security definer set search_path = public as $$
declare y yetkili;
begin
  select y2.* into y from yetkili_oturum o join yetkili y2 on y2.id = o.yetkili_id
    where o.tok = p_tok and o.son > now() - interval '12 hours';
  if y.id is null then raise exception 'OTURUM' using errcode = 'P0401'; end if;
  update yetkili_oturum set son = now() where tok = p_tok and son < now() - interval '5 minutes';
  return y;
end $$;
create or replace function public._siniflari(y public.yetkili) returns uuid[]
language sql stable security definer set search_path = public as $$
  select case when y.rol = 'yonetici' then (select coalesce(array_agg(id), '{}') from sinif)
              else (select coalesce(array_agg(sinif_id), '{}') from yetkili_sinif where yetkili_id = y.id) end;
$$;
create or replace function public._ben(y public.yetkili) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object('id', y.id, 'kullanici', y.kullanici, 'ad', y.ad, 'rol', y.rol,
    'cids', (select coalesce(jsonb_agg(sinif_id), '[]') from yetkili_sinif where yetkili_id = y.id));
$$;

-- 4) Yetkili (öğretmen / yönetici) fonksiyonları ---------------------------
create or replace function public.yetkili_giris(p_kullanici text, p_sifre text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare y yetkili; yeni_tok text; k text := lower(btrim(coalesce(p_kullanici, '')));
begin
  delete from giris_deneme g where g.t < now() - interval '1 day';
  if (select count(*) from giris_deneme g where g.kullanici = k and g.t > now() - interval '15 minutes') >= 10 then
    return jsonb_build_object('err', 'cok_deneme');
  end if;
  select * into y from yetkili where kullanici = k;
  if y.id is null or y.sifre <> crypt(coalesce(p_sifre, ''), y.sifre) then
    insert into giris_deneme (kullanici) values (k);
    return jsonb_build_object('err', 'yanlis');
  end if;
  delete from giris_deneme g where g.kullanici = k;
  delete from yetkili_oturum where son < now() - interval '12 hours';
  yeni_tok := encode(gen_random_bytes(32), 'hex');
  insert into yetkili_oturum (tok, yetkili_id) values (yeni_tok, y.id);
  return jsonb_build_object('tok', yeni_tok, 'ben', _ben(y));
end $$;

create or replace function public.yetkili_ben(p_tok text) returns jsonb
language plpgsql security definer set search_path = public as $$
begin return _ben(_yetkili(p_tok)); end $$;

create or replace function public.yetkili_cikis(p_tok text) returns void
language sql security definer set search_path = public as $$
  delete from yetkili_oturum where tok = p_tok;
$$;

create or replace function public.kendi_sifrem(p_tok text, p_eski text, p_yeni text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare y yetkili := _yetkili(p_tok);
begin
  if y.sifre <> crypt(coalesce(p_eski, ''), y.sifre) then return jsonb_build_object('err', 'eski_yanlis'); end if;
  if length(coalesce(p_yeni, '')) < 6 then return jsonb_build_object('err', 'kisa'); end if;
  update yetkili set sifre = crypt(p_yeni, gen_salt('bf', 10)) where id = y.id;
  delete from yetkili_oturum where yetkili_id = y.id and tok <> p_tok;
  return '{}'::jsonb;
end $$;

-- Panelin bütün verisi: yönetici her şeyi, öğretmen yalnızca kendi sınıflarını alır.
create or replace function public.panel_veri(p_tok text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare y yetkili := _yetkili(p_tok); c uuid[] := _siniflari(y); yon boolean := y.rol = 'yonetici';
begin
  return jsonb_build_object(
    'ben', _ben(y),
    'okullar', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'ad', o.ad)), '[]') from okul o
                where yon or o.id in (select okul_id from sinif where id = any(c))),
    'siniflar', (select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'ad', s.ad, 'sid', s.okul_id)), '[]') from sinif s where s.id = any(c)),
    'ogr', (select coalesce(jsonb_agg(jsonb_build_object('id', g.id, 'ad', g.ad, 'k', g.k, 'cid', g.sinif_id, 'sid', s.okul_id)), '[]')
            from ogrenci g join sinif s on s.id = g.sinif_id where g.sinif_id = any(c)),
    'ozet', (select coalesce(jsonb_object_agg(z.ogrenci_id, z.s), '{}') from ozet z join ogrenci g on g.id = z.ogrenci_id where g.sinif_id = any(c)),
    'yetkili', (select coalesce(jsonb_agg(_ben(x)), '[]') from yetkili x where yon or x.id = y.id));
end $$;

create or replace function public.ogrenci_kayitlari(p_tok text, p_ogr uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare y yetkili := _yetkili(p_tok);
begin
  if not exists (select 1 from ogrenci where id = p_ogr and sinif_id = any(_siniflari(y))) then raise exception 'YETKI' using errcode = 'P0403'; end if;
  return coalesce((select jsonb_agg(e) from kayit k, jsonb_array_elements(k.ev) e where k.ogrenci_id = p_ogr), '[]'::jsonb);
end $$;

-- Yalnızca kurum yöneticisinin yapabildiği işler
create or replace function public.yonetim(p_tok text, p_islem text, v jsonb) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare y yetkili := _yetkili(p_tok); yeni uuid; e jsonb; n int := 0; atla jsonb := '[]'::jsonb; k text; kul text;
begin
  if y.rol <> 'yonetici' then raise exception 'YETKI' using errcode = 'P0403'; end if;
  case p_islem
  when 'okul_ekle' then insert into okul (ad) values (btrim(v->>'ad')) returning id into yeni;
  when 'okul_ad' then update okul set ad = btrim(v->>'ad') where id = (v->>'id')::uuid;
  when 'sinif_ekle' then insert into sinif (okul_id, ad) values ((v->>'sid')::uuid, btrim(v->>'ad')) returning id into yeni;
  when 'sinif_ad' then update sinif set ad = btrim(v->>'ad') where id = (v->>'id')::uuid;
  when 'sinif_sil' then
    if exists (select 1 from ogrenci where sinif_id = (v->>'id')::uuid) then raise exception 'Sınıfta öğrenci var.'; end if;
    delete from sinif where id = (v->>'id')::uuid;
  when 'ogr_ekle' then
    for e in select * from jsonb_array_elements(v->'list') loop
      k := _norm(e->>'ad');
      if k = '' then continue; end if;
      insert into ogrenci (sinif_id, ad, k) values ((v->>'cid')::uuid, btrim(e->>'ad'), k) on conflict do nothing;
      if found then n := n + 1; else atla := atla || to_jsonb(e->>'ad'); end if;
    end loop;
    return jsonb_build_object('n', n, 'atla', atla);
  when 'ogr_ad' then update ogrenci set ad = btrim(v->>'ad'), k = _norm(v->>'ad') where id = (v->>'id')::uuid;
  when 'ogr_sil' then delete from ogrenci where id = (v->>'id')::uuid;
  when 'yetkili_ekle' then
    kul := lower(btrim(v->>'kullanici'));
    if kul !~ '^[a-z0-9._-]{2,30}$' then raise exception 'Kullanıcı adı yalnızca küçük harf (Türkçe karaktersiz), rakam, nokta ve tire içerebilir.'; end if;
    if exists (select 1 from yetkili where kullanici = kul) then raise exception 'Bu kullanıcı adı alınmış.'; end if;
    if length(coalesce(v->>'sifre', '')) < 6 then raise exception 'Şifre en az 6 karakter olmalı.'; end if;
    insert into yetkili (kullanici, ad, rol, sifre) values (kul, btrim(v->>'ad'), v->>'rol', crypt(v->>'sifre', gen_salt('bf', 10))) returning id into yeni;
    insert into yetkili_sinif (yetkili_id, sinif_id) select yeni, x::uuid from jsonb_array_elements_text(coalesce(v->'cids', '[]')) x;
  when 'yetkili_ata' then
    if (v->>'id')::uuid = y.id and v->>'rol' <> 'yonetici' then raise exception 'Kendi yönetici rolünüzü kaldıramazsınız.'; end if;
    update yetkili set rol = v->>'rol' where id = (v->>'id')::uuid;
    delete from yetkili_sinif where yetkili_id = (v->>'id')::uuid;
    insert into yetkili_sinif (yetkili_id, sinif_id) select (v->>'id')::uuid, x::uuid from jsonb_array_elements_text(coalesce(v->'cids', '[]')) x;
  when 'yetkili_sil' then
    if (v->>'id')::uuid = y.id then raise exception 'Kendi hesabınızı silemezsiniz.'; end if;
    delete from yetkili where id = (v->>'id')::uuid;
  when 'sifre_koy' then
    if length(coalesce(v->>'sifre', '')) < 6 then raise exception 'Şifre en az 6 karakter olmalı.'; end if;
    update yetkili set sifre = crypt(v->>'sifre', gen_salt('bf', 10)) where id = (v->>'id')::uuid;
    delete from yetkili_oturum where yetkili_id = (v->>'id')::uuid and tok <> p_tok;
  else raise exception 'Bilinmeyen işlem.';
  end case;
  return jsonb_build_object('id', yeni);
end $$;

-- 5) Çocuk tarafı: hesapsız giriş ve kayıt --------------------------------
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
declare o ogrenci; n int; t text; a text := _norm(p_ad);
begin
  if a = '' then return jsonb_build_object('err', 'yok'); end if;
  select * into o from ogrenci where sinif_id = p_sinif and k = a;
  if o.id is null and position(' ' in a) > 0 then  -- "Mehmet Kaya" yazıldıysa "Mehmet K." ile eşleşir
    select * into o from ogrenci where sinif_id = p_sinif and k = split_part(a, ' ', 1) || ' ' || left(split_part(a, ' ', 2), 1);
  end if;
  if o.id is null then
    select count(*) into n from ogrenci where sinif_id = p_sinif and split_part(k, ' ', 1) = a;
    if n > 1 then return jsonb_build_object('err', 'cok'); end if;
    if n = 0 then return jsonb_build_object('err', 'yok'); end if;
    select * into o from ogrenci where sinif_id = p_sinif and split_part(k, ' ', 1) = a;
  end if;
  t := encode(gen_random_bytes(24), 'hex');
  insert into ogr_oturum (tok, ogrenci_id) values (t, o.id);
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

-- 6) İzinler: dışarıdan yalnızca bu fonksiyonlar çağrılabilir --------------
revoke all on function public._norm(text), public._yetkili(text), public._siniflari(public.yetkili), public._ben(public.yetkili) from public, anon, authenticated;
do $$ declare f text; begin
  foreach f in array array['okul_listesi()', 'sinif_listesi(uuid)', 'sinif_bilgi(uuid)', 'ogrenci_giris(uuid,text)', 'ogrenci_kaydet(text,jsonb,jsonb,jsonb)',
    'yetkili_giris(text,text)', 'yetkili_ben(text)', 'yetkili_cikis(text)', 'kendi_sifrem(text,text,text)', 'panel_veri(text)', 'ogrenci_kayitlari(text,uuid)', 'yonetim(text,text,jsonb)'] loop
    execute 'revoke all on function public.' || f || ' from public';
    execute 'grant execute on function public.' || f || ' to anon, authenticated';
  end loop;
end $$;
