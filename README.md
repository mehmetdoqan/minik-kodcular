# Minik Kodcular

5–7 yaş çocuklar için ekransız düşünme becerilerinden kodlamaya geçiş oyunları.

## ▶️ Uygulamayı aç

**https://mehmetdoqan.github.io/minik-kodcular/**

Tablette en iyi yatay tutularak çalışır. Kurulum gerekmez; bağlantıyı tarayıcıda açmak yeterli. İsterseniz tarayıcının "Ana ekrana ekle" seçeneğiyle uygulama gibi açılabilir.

## Oyunlar

| Oyun | Beceri |
|---|---|
| Balon Patlat | Sıralama ve tekrar |
| Sabah Rutini | Algoritma |
| Robot Dansı | Sıralama |
| Hazine Haritası | Koordinat |
| Hata Avcısı | Hata ayıklama |
| Renk Örüntüsü | Örüntü |
| Labirent | Döngü |
| Müzik Kutusu | Tekrar |
| Yağmur Gelirse | Koşul (eğer / değilse) |
| Grupla | Sınıflandırma |
| Bayrak Yarışı | İki bayrak (paralel program) |
| Robot Ressam | Fonksiyon |

Her oyunda 40 bölüm var. Çocuğun ilerlemesi cihazda (tarayıcıda) saklanır.

## Ses

Bütün yönergeler Microsoft Azure'un Türkçe **Emel** sesiyle önceden kaydedilmiştir (`ses/` klasörü), internet bağlantısı yavaş olsa bile aynı sesle konuşur. Üst çubuktaki hoparlör düğmesi son cümleyi tekrar okur. Kaydı olmayan bir cümlede cihazın kendi Türkçe sesi kullanılır.

## Eğitmen paneli

Ana menüdeki **Eğitmen** düğmesi (basit bir çarpma sorusuyla korunur):
- Tüm bölümleri açma
- Ses seçimi (hazır Emel sesi ya da cihaz sesi)
- Oyun oyun ilerleme ve yıldızlar, ilerlemeyi sıfırlama

## Dosyalar

- `index.html` — uygulamanın tamamı
- `ses/manifest.json` — cümle → kayıt eşlemesi
- `ses/pNNNN.mp3`, `ses/paket*.mp3` + `ses/paket.json` — ses kayıtları
