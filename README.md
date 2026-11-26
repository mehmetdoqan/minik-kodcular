# Minik Kodcular

5–7 yaş çocuklar için ekransız düşünme becerilerinden kodlamaya geçiş oyunları.

## ▶️ Uygulamayı aç

**https://mehmetdoqan.github.io/minik-kodcular/**

Tablette en iyi yatay tutularak çalışır. Kurulum gerekmez; bağlantıyı tarayıcıda açmak yeterli. İsterseniz tarayıcının "Ana ekrana ekle" seçeneğiyle uygulama gibi açılabilir.

## Oyunlar

42 oyun, 9 kategoride. Oyunların çoğunda 40 bölüm var.

| Kategori | Oyunlar |
|---|---|
| 👣 Sıralama ve Plan | Sabah Rutini, Labirent, Blok İten Robot, Yük Treni, Çöp Toplayan Robot, Parça Birleştirici, Postacı Robot, Kendi Bölümünü Yap |
| 🌈 Örüntü | Robot Dansı, Renk Örüntüsü, Müzik Kutusu, Lamba Yakıcı |
| 🔁 Tekrar | Balon Patlat, Çit Ören Robot, Duvara Kadar Git |
| 🐞 Hata Ayıklama | Hata Avcısı, Dedektif, Renk Kodlu Yol, Çit Böceği, Işık Böceği |
| 🚦 Şart Blokları | Yağmur Gelirse, Bahçıvan Robot, Trafik Işığı, Sisli Labirent |
| 👆 Olaylar ve Takım | Dokununca, Bayrak Yarışı, Renk Yarışı, İkimiz Birlikte, Ayna Robot, Kurbağa Nehri |
| ⭐ Fonksiyon | Robot Ressam, Tarif Bloğu, Şekil Bloğu, Desen Bloğu |
| 🔢 Sayı ve Uzay | Hazine Haritası, Sayı Doğrusu, Grupla, Pastacı Robot |
| 👀 Dikkat | Robot Derse, Kutular Karıştı, Aynısını Bul, Kaç Kez? |

## Okul sistemi

İsteğe bağlıdır. Kurulduğunda:

- Çocuk tablette okulunu ve sınıfını seçip adıyla girer. Adı sınıfta yoksa giremez. İlerlemesi hangi tablette oynarsa oynasın sürer.
- **Öğretmen** kendi sınıfını görür. Öğrencilerini biten bölüm, yıldız, ilk denemede başarı, süre, dikkat doğruluğu, tepki süresi ve yanlış dokunuşa göre karşılaştırır. Beceri haritasında her çocuğun her kategorideki ilerlemesini görür ve her çocuğun ayrıntılı raporunu açar.
- **Kurum yöneticisi** bütün okulları ve sınıfları karşılaştırır. Okul, sınıf ve öğrenci ekler, öğretmen hesaplarını (kullanıcı adı + şifre) açar. E-posta gerekmez.
- Çocuklar için yalnızca ad tutulur; sınıfta aynı ad varsa soyadının ilk harfi eklenir (Ayşe Y.).

Veriler kurumun kendi ücretsiz **Supabase** projesinde durur. Kurulum adımları: **[OKU-BENI.md](OKU-BENI.md)**. Okul sistemi kurulmadıysa uygulama eskisi gibi çalışır: ilerleme tablette saklanır, tablet içinde çocuk profilleri seçilebilir.

## Ses

Bütün yönergeler Microsoft Azure'un Türkçe **Emel** sesiyle önceden kaydedilmiştir (`ses/` klasörü). İnternet bağlantısı yavaş olsa bile aynı sesle konuşur. Üst çubuktaki hoparlör düğmesi son cümleyi tekrar okur. Kaydı olmayan bir cümlede (yeni oyunların bazı yönergeleri gibi) cihazın kendi Türkçe sesi kullanılır.

## Eğitmen paneli

Ana menüdeki **Eğitmen** düğmesi:
- Okul sistemi kuruluysa öğretmen ve yönetici girişini açar (kullanıcı adı + şifre).
- Okul sistemi yoksa basit bir çarpma sorusuyla korunan tablet panelini açar: tüm bölümleri açma, ses seçimi, oyun oyun ilerleme ve sıfırlama, çocuk raporu.

## Dosyalar

- `index.html`: uygulamanın tamamı
- `ayarlar.js`: okul sistemi için Supabase bağlantısı (boşsa okul sistemi kapalı)
- `supabase/kurulum.sql`: okul sistemi tabloları ve güvenlik kuralları
- `OKU-BENI.md`: okul sistemi kurulum rehberi
- `ses/manifest.json`: cümle → kayıt eşlemesi
- `ses/pNNNN.mp3`, `ses/paket*.mp3` + `ses/paket.json`: ses kayıtları
- `MinikKodcular-1.1.apk`, `android-proje.md`: Android paketi (eski sürüm, 12 oyun)
