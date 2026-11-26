# Okul sistemini kurma (Supabase)

Okul sistemi açıkken:
- Çocuklar tablette okulunu ve sınıfını seçip **adıyla** girer. Adı o sınıfta yoksa giremez.
- Çocuğun ilerlemesi ve kayıtları sunucuda birikir. Hangi tablette oynarsa oynasın kaldığı yerden devam eder.
- **Öğretmen** yalnızca kendi sınıfını görür ve öğrencilerini karşılaştırır.
- **Kurum yöneticisi** bütün okulları görür. Okul, sınıf, öğrenci ve öğretmen hesaplarını o açar.

Veriler sizin açacağınız ücretsiz bir **Supabase** projesinde durur. Kimin neyi göreceğini sunucu belirler: öğretmen uygulamayı kurcalasa bile başka sınıfın verisini alamaz. E-posta gerekmez; bütün hesapları kurum yöneticisi kullanıcı adı ve şifreyle açar.

Kurulum bir kez yapılır, yaklaşık 10 dakika sürer.

---

## 1. Supabase projesi açın

1. https://supabase.com adresine gidin, **Start your project** ile ücretsiz hesap açın.
2. **New project**'e basın:
   - **Name:** `minik-kodcular`
   - **Database Password:** güçlü bir şifre yazıp not edin. Bu şifreye uygulama için gerek yok.
   - **Region:** **Central EU (Frankfurt)** (Türkiye'ye yakın, veriler AB'de durur).
3. **Create new project**'e basın ve 1-2 dakika bekleyin.

## 2. Tabloları kurun ve yönetici hesabını açın

1. Soldaki menüden **SQL Editor**'ü, sonra **New query**'yi açın.
2. Bu depodaki `supabase/kurulum.sql` dosyasının tamamını kopyalayıp yapıştırın.
3. En üstteki şu satırda yöneticinin **kullanıcı adını** ve **şifresini** yazın:
   ```sql
   insert into _ilk_yonetici values ('mudur', 'BURAYA_SIFRE', 'Kurum Yöneticisi');
   ```
   - Kullanıcı adı yalnızca Türkçe karaktersiz küçük harf, rakam, nokta ve tire içerebilir.
   - Şifre en az 6 karakter olmalı.
   - Şifreyi değiştirmeden çalıştırırsanız dosya durur ve uyarır.
4. **Run**'a basın. Altta "Success. No rows returned" görünmeli.

Dosya sonradan yeniden çalıştırılabilir; var olan verileri ve hesapları silmez. Yönetici hesabı zaten varsa en üstteki satır dikkate alınmaz.

## 3. Uygulamaya anahtarları girin

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

> **service_role** anahtarını hiçbir yere yazmayın, kimseyle paylaşmayın. Uygulamanın ihtiyacı yalnızca **anon public** anahtar; o anahtar zaten herkese açık olacak şekilde tasarlanmıştır. Bu anahtarla bütün tablolar kapalıdır; yalnızca uygulamanın fonksiyonları çağrılabilir.

## 4. İlk kullanım

1. Uygulamayı açın: https://mehmetdoqan.github.io/minik-kodcular/
2. **Eğitmen** düğmesine basın (çocuk giriş ekranı açıksa sağ üstteki **👩‍🏫 Eğitmen**). 2. adımda yazdığınız kullanıcı adı ve şifreyle girin. Girdikten sonra **🔑 Şifrem**'den şifrenizi değiştirebilirsiniz.
3. **Sınıflar ve öğrenciler** sekmesinden:
   - okulu ekleyin,
   - sınıfları ekleyin,
   - her sınıfın öğrencilerini her satıra bir öğrenci olacak şekilde yapıştırın.
4. **Öğretmenler** sekmesinde her öğretmen için ad, kullanıcı adı ve ilk şifre yazın, sınıfını işaretleyip **Hesabı oluştur**'a basın. Kullanıcı adını ve şifreyi öğretmene siz iletin.
5. Tabletlerde uygulamayı açın. Okul kurulduğu için çocuk giriş ekranı kendiliğinden gelir. Tablet okulu ve sınıfı hatırlar; sıradaki çocuk yalnızca adını yazar.

## Öğrenci adları (KVKK)

- Yalnızca **ad** girin. Sınıfta aynı ad varsa soyadının **ilk harfini** ekleyin: `Ayşe Y.`, `Ayşe D.`
- Listeyi ad soyad olarak yapıştırırsanız uygulama soyadları kendiliğinden ilk harfe kısaltır (`Ayşe Yılmaz` → `Ayşe Y.`). İki adlı öğrenciler varsa ("Ali Kemal") bu kutunun işaretini kaldırın.
- **Çocuk girerken:**
  - sınıfta tek olan ad için yalnızca adını yazar,
  - aynı ad varsa soyadının ilk harfini de yazar (`ayşe y`),
  - tam soyadını yazsa da kabul edilir.
- Büyük/küçük harf ve i/ı farkı önemli değil: "ILKER" de "ilker" de İlker'i bulur.

## Sık sorulanlar

- **Öğretmen şifresini unuttu.** Yönetici, **Öğretmenler** sekmesinde **Yeni şifre**'ye basıp yeni bir şifre verir.
- **Biri şifreyi çok kez yanlış girdi.** O kullanıcı adı 15 dakika kilitlenir, sonra yeniden denenebilir.
- **Öğretmen 12 saat hiç işlem yapmazsa** panel oturumu kapanır, yeniden giriş yapar.
- **Öğretmen ayrıldı.** **Öğretmenler** sekmesinde **Sil**'e basın.
- **Öğrenciyi silmek** onun bütün kayıtlarını da siler.
- **İnternet kesilirse** çocuk oynamaya devam eder. Kayıtlar tablette bekler, bağlantı gelince gönderilir.
- **Supabase'in ücretsiz planı:** bir hafta hiç kullanılmayan proje uyku moduna geçer. Supabase panelinden tek tıkla yeniden açılır. Okul döneminde her gün kullanılacağı için sorun olmaz.

## Teknik not

- `index.html`: uygulamanın tamamı. `ayarlar.js`: Supabase bağlantısı. `supabase/kurulum.sql`: tablolar ve fonksiyonlar.
- **Tablolar dışarıya tamamen kapalı.** Uygulama yalnızca `security definer` fonksiyonlarını çağırır. Her fonksiyon oturum anahtarını ve rolü sunucuda denetler:
  - `panel_veri`: öğretmene yalnızca kendi sınıflarını verir.
  - `yonetim`: yalnızca yönetici çağırabilir.
- **Yetkili hesapları:** Şifreler bcrypt ile karıştırılıp saklanır. Girişte 32 baytlık rastgele bir oturum anahtarı verilir; 12 saat kullanılmayan oturum kapanır.
- **Çocukların hesabı yok.** Ad sınıfta varsa `ogrenci_giris` tablete rastgele bir anahtar verir. Tablet bu anahtarla yalnızca o çocuğun kaydını yazabilir (`ogrenci_kaydet`).
