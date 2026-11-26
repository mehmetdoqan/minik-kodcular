# Okul sistemini kurma (Supabase)

Okul sistemi açıkken:
- Çocuklar tablette okulunu ve sınıfını seçip **adıyla** girer. Adı o sınıfta yoksa giremez.
- Çocuğun ilerlemesi ve kayıtları sunucuda birikir. Hangi tablette oynarsa oynasın kaldığı yerden devam eder.
- **Öğretmen** yalnızca kendi sınıfını görür ve öğrencilerini karşılaştırır.
- **Kurum yöneticisi** bütün okulları görür, okul, sınıf ve öğrenci ekler, öğretmenleri onaylar.

Veriler sizin açacağınız ücretsiz bir **Supabase** projesinde durur. Kimin neyi göreceğini veritabanının kendi kuralları belirler. Öğretmen, uygulamayı kurcalasa bile başka sınıfın verisini alamaz.

Kurulum bir kez yapılır, yaklaşık 15 dakika sürer.

---

## 1. Supabase projesi açın

1. https://supabase.com adresine gidin, **Start your project** ile ücretsiz hesap açın.
2. **New project**'e basın:
   - **Name:** `minik-kodcular`
   - **Database Password:** güçlü bir şifre yazıp bir yere not edin. Bu şifreye uygulama için gerek yok.
   - **Region:** **Central EU (Frankfurt)** (Türkiye'ye yakın).
3. **Create new project**'e basın ve proje hazırlanana kadar 1-2 dakika bekleyin.

## 2. Tabloları ve kuralları kurun

1. Soldaki menüden **SQL Editor**'ü, sonra **New query**'yi açın.
2. Bu depodaki `supabase/kurulum.sql` dosyasını açın, tamamını kopyalayıp yapıştırın.
3. Dosyanın başındaki şu satırda `YONETICI_EPOSTASI@ornek.com` yerine **kurum yöneticisinin e-postasını** yazın:
   ```sql
   insert into public.ayar (anahtar, deger) values ('yonetici_eposta', lower('YONETICI_EPOSTASI@ornek.com'))
   ```
   Bu e-postayla kayıt olan hesap otomatik olarak yönetici olur. Başka herkes "onay bekliyor" olarak başlar.
4. **Run**'a basın. Altta "Success. No rows returned" görünmeli.

Dosya sonradan yeniden çalıştırılabilir; var olan verileri silmez. Yönetici e-postasını değiştirmek için satırı düzeltip yeniden çalıştırmanız yeter.

## 3. Giriş (e-posta) ayarları

1. **Authentication → URL Configuration**:
   - **Site URL:** `https://mehmetdoqan.github.io/minik-kodcular/`
   - **Redirect URLs** listesine de aynı adresi ekleyin.

   Doğrulama ve şifre sıfırlama e-postalarındaki bağlantılar bu adrese döner.
2. **Authentication → Sign In / Providers → Email** açık olmalı. Supabase'de varsayılan olarak açıktır.

> **E-posta sınırı:** Supabase'in hazır e-posta servisi saatte yalnızca birkaç e-posta gönderir. Birçok öğretmen aynı anda kayıt olacaksa iki yol var:
> - **Authentication → Emails → SMTP Settings** altında kendi e-posta servisinizi (ör. okulun e-postası) tanımlayın.
> - Ya da kayıt günü **Confirm email** seçeneğini geçici olarak kapatın.
>
> E-posta doğrulaması kapalıyken de yönetici onaylamadıkça kimse hiçbir veriyi göremez.

## 4. Uygulamaya anahtarları girin

1. Supabase'de **Project Settings → API**'yi açın. Gerekli iki değer:
   - **Project URL** (ör. `https://abcdefghijkl.supabase.co`)
   - **Project API keys → anon public** (uzun, `eyJ...` ile başlayan anahtar)
2. GitHub'da bu depodaki `ayarlar.js` dosyasını açın. Kalem simgesine (Edit) basın ve iki değeri tırnakların arasına yapıştırın:
   ```js
   window.MK_SUPABASE = {
     url: 'https://abcdefghijkl.supabase.co',
     key: 'eyJhbGciOi...'
   };
   ```
3. **Commit changes**'e basın. GitHub Pages birkaç dakika içinde güncellenir.

> **service_role** anahtarını hiçbir yere yazmayın, kimseyle paylaşmayın. Bu anahtar bütün kuralları atlar. Uygulamanın ihtiyacı yalnızca **anon public** anahtar; o anahtar zaten herkese açık olacak şekilde tasarlanmıştır.

## 5. İlk kullanım

1. Uygulamayı açın: https://mehmetdoqan.github.io/minik-kodcular/
2. **Eğitmen** düğmesine basın (çocuk giriş ekranı açıksa sağ üstteki **👩‍🏫 Eğitmen**). Sonra **Öğretmen hesabı oluştur**'a basıp **yönetici e-postasıyla** kayıt olun.
3. E-postanıza gelen bağlantıyla hesabı doğrulayın, ardından giriş yapın. Kurum yöneticisi olarak girmiş olursunuz.
4. **Sınıflar ve öğrenciler** sekmesinden:
   - okulu ekleyin,
   - sınıfları ekleyin,
   - her sınıfın öğrencilerini her satıra bir "Ad Soyad" olacak şekilde yapıştırın (Excel'den sütun kopyalanabilir).
5. Öğretmenler aynı yoldan (**Öğretmen hesabı oluştur**) kendi e-postalarıyla kayıt olur. **Öğretmenler** sekmesinde "Onay bekliyor" olarak görünürler. Rolü **Öğretmen** yapıp sınıfını işaretleyin ve **Kaydet**'e basın.
6. Tabletlerde uygulamayı açın. Okul kurulduğu için çocuk giriş ekranı kendiliğinden gelir. Tablet okulu ve sınıfı hatırlar; sıradaki çocuk yalnızca adını yazar.

## Sık sorulanlar

- **Çocuk adını yazdı ama giremedi.**
  - Ad, yöneticinin girdiği listedekiyle aynı olmalı. Büyük/küçük harf önemli değil.
  - Sınıfta o ad tek ise yalnızca ilk ad yeter.
  - Aynı ad iki çocukta varsa soyadı da yazılır.
- **Öğretmen şifresini unuttu.** Giriş ekranındaki **Şifremi unuttum** ile e-postasına sıfırlama bağlantısı gider.
- **Öğretmen ayrıldı.** **Öğretmenler** sekmesinde **Erişimi kaldır**'a basın. Hesap kalır ama hiçbir veri göremez. Hesabı tamamen silmek için Supabase → **Authentication → Users**.
- **Öğrenciyi silmek** onun bütün kayıtlarını da siler.
- **İnternet kesilirse** çocuk oynamaya devam eder. Kayıtlar tablette bekler, bağlantı gelince gönderilir.
- **Supabase'in ücretsiz planı:** bir hafta hiç kullanılmayan proje uyku moduna geçer. Supabase panelinden tek tıkla yeniden açılır. Okul döneminde her gün kullanılacağı için sorun olmaz.
- **Kişisel veri:** Çocukların ad ve soyadları kişisel veridir. Kullanmaya başlamadan önce KVKK açısından veli onayını ve okulunuzun kurallarını kontrol edin. Supabase projesini Frankfurt bölgesinde açmanız verilerin AB'de durmasını sağlar.

## Teknik not

- `index.html`: uygulamanın tamamı. `ayarlar.js`: Supabase bağlantısı. `supabase/kurulum.sql`: tablolar, satır düzeyi güvenlik kuralları ve çocuk girişi için fonksiyonlar.
- **Çocukların hesabı yok.** Giriş, `ogrenci_giris` fonksiyonuyla yapılır: ad sınıfta varsa tablete rastgele bir anahtar verilir. Tablet bu anahtarla yalnızca o çocuğun kaydını yazabilir (`ogrenci_kaydet`).
- **Hesapsız okuma yok.** Hesapsız biri yalnızca okul ve sınıf adlarını görebilir; öğrenci listesini ve verilerini göremez.
- **Öğretmen ve yönetici:** Supabase Auth hesaplarıdır. Öğretmen yalnızca `yetkili_sinif` tablosunda kendisine atanmış sınıfları okuyabilir. Ekleme, silme ve atamayı yalnızca yönetici yapabilir.
