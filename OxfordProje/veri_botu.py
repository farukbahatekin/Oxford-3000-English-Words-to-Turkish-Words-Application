import json
import requests
import time
import random
# Yeni kütüphaneyi ekliyoruz
from deep_translator import GoogleTranslator

def create_database():
    print("--- Oxford 3000 Veri Botu (v2) Başlatılıyor ---")
    
    # 1. Kelime Listesini İnternetten Çek
    url = "https://raw.githubusercontent.com/sapbmw/Oxford-3000-Word-List/master/Oxford%203000%20Word%20List.txt"
    print(f"Liste indiriliyor: {url}")
    
    try:
        response = requests.get(url)
        if response.status_code != 200:
            print("Hata: Liste indirilemedi.")
            return
            
        content = response.text
        words_list = [w.strip() for w in content.split('\n') if w.strip()]
        print(f"Toplam {len(words_list)} kelime bulundu.")
        
    except Exception as e:
        print(f"İndirme hatası: {e}")
        return

    # 2. Çeviri İşlemi (Deep Translator ile)
    final_data = []
    translator = GoogleTranslator(source='auto', target='tr')
    
    print("Çeviri işlemi başlıyor... (Bu biraz zaman alabilir)")
    
    # Hepsini çevirmek uzun sürerse test için buradaki sayıyı küçültebilirsin (örn: words_list[:50])
    # Şu an tamamını çevirecek şekilde ayarlı:
    target_words = words_list 
    
    batch_size = 20 # Daha güvenli küçük paketler
    total_processed = 0

    while total_processed < len(target_words):
        batch = target_words[total_processed : total_processed + batch_size]
        
        try:
            # Deep Translator toplu çeviriyi desteklemez, tek tek hızlıca döneceğiz
            # Veya batch çeviri özelliği varsa kullanırız ama en garantisi döngüdür.
            
            for word in batch:
                try:
                    translated_text = translator.translate(word)
                    final_data.append({
                        "en": word,
                        "tr": translated_text
                    })
                    # Konsola yazdıralım ki çalıştığını gör
                    print(f"> {word} -> {translated_text}")
                except:
                    # Çeviri hatası olursa boş geçmeyelim, orjinalini yazalım
                    final_data.append({"en": word, "tr": "..."})
            
            total_processed += len(batch)
            print(f"--- %{int((total_processed / len(target_words)) * 100)} tamamlandı ---")
            
        except Exception as e:
            print(f"Hata oluştu: {e}")
            time.sleep(2)

    # 3. Listeyi Karıştır
    random.shuffle(final_data)

    # 4. Kaydet
    output_file = "words.json"
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(final_data, f, ensure_ascii=False, indent=2)
        
    print(f"\n--- BAŞARILI ---")
    print(f"Dosya '{output_file}' adıyla kaydedildi.")

if __name__ == "__main__":
    create_database()