import json
import random
import time
import os
# Kütüphane hatası alırsan terminale: pip install deep-translator
from deep_translator import GoogleTranslator

def create_database_local():
    print("--- Oxford 3000 Yerel Veri Botu ---")
    
    input_file = "kelimeler.txt"
    
    # 1. Dosya Kontrolü
    if not os.path.exists(input_file):
        print(f"HATA: '{input_file}' bulunamadı!")
        print("Lütfen kelime listesini indirip bu dosyanın yanına 'kelimeler.txt' adıyla kaydet.")
        return

    # 2. Dosyayı Oku
    print(f"'{input_file}' okunuyor...")
    with open(input_file, "r", encoding="utf-8") as f:
        # Satır satır oku, boşlukları temizle
        words_list = [line.strip() for line in f if line.strip()]
        
    print(f"Toplam {len(words_list)} kelime bulundu.")
    
    # 3. Çeviri İşlemi
    final_data = []
    translator = GoogleTranslator(source='auto', target='tr')
    
    print("Çeviri işlemi başlıyor... (Pencereyi kapatma)")

    # Test için sayı: Hepsini istiyorsan parantez içini silip sadece words_list yaz.
    # Örnek: target_words = words_list
    target_words = words_list 
    
    count = 0
    total = len(target_words)

    for word in target_words:
        try:
            translated_text = translator.translate(word)
            final_data.append({
                "en": word,
                "tr": translated_text
            })
            count += 1
            # Her 10 kelimede bir bilgi ver
            if count % 10 == 0:
                print(f"İlerliyor... ({count}/{total}) - Son çevrilen: {word} -> {translated_text}")
                
        except Exception as e:
            print(f"Hata ({word}): {e}")
            final_data.append({"en": word, "tr": "..."})

    # 4. Kaydet
    print("Kaydediliyor...")
    random.shuffle(final_data) # Karıştır
    
    with open("words.json", "w", encoding="utf-8") as f:
        json.dump(final_data, f, ensure_ascii=False, indent=2)
        
    print(f"\n--- İŞLEM TAMAM! ---")
    print(f"words.json oluşturuldu. Bunu Flutter assets klasörüne atabilirsin.")

if __name__ == "__main__":
    create_database_local()