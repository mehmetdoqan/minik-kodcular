// Minik Kodcular · okul sistemi ayarları
// Supabase projenizin iki değerini tırnakların arasına yapıştırın (Supabase → Project Settings → API):
//   url : "Project URL"           ör. https://abcdefghijkl.supabase.co
//   key : "anon public" anahtarı  (eyJ... ile başlayan uzun metin)
// Bu anahtar herkese açık olacak şekilde tasarlanmıştır; burada durmasında sakınca yoktur.
// "service_role" anahtarını ASLA buraya ya da başka bir yere yazmayın.
// İkisi de boş bırakılırsa okul sistemi kapalıdır: oyunlar ve tablet içi profiller çalışır.
window.MK_SUPABASE = {
  url: '',
  key: ''
};
