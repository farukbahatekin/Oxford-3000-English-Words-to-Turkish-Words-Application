import json
import random
import time
import os
from deep_translator import GoogleTranslator

def create_database_local():
    print("--- Oxford 3000 Yerel Veri Botu ---")
    
    # BU KISIM YENİLENDİ:
    # Scriptin çalıştığı klasörü otomatik buluyoruz
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Önce 'kelimeler.txt' yi deniyoruz
    input_file = os.path.join(script_dir, "kelimeler.txt")
    
    # Eğer bulamazsa 'kelimeler.txt.txt' yi (Windows hatası) deniyoruz
    if not os.path.exists(input_file):
        print(f"Uyarı: 'kelimeler.txt' bulunamadı, çift uzantı kontrolü yapılıyor...")
        input_file = os.path.join(script_dir, "kelimeler.txt.txt")

    # Hala yoksa hata ver
    if not os.path.exists(input_file):
        print(f"HATA: Dosya bulunamadı!")
        print(f"Aranan yer: {input_file}")
        print("Lütfen dosya adının sadece 'kelimeler' olduğundan emin ol.")
        return

    # 2. Dosyayı Oku
    print(f"Dosya bulundu, okunuyor...")
    with open(input_file, "r", encoding="utf-8") as f:
        words_list = [line.strip() for line in f if line.strip()]
        
    print(f"Toplam {len(words_list)} kelime bulundu.")
    
    # 3. Çeviri İşlemi
    final_data = []
    translator = GoogleTranslator(source='auto', target='tr')
    
    print("Çeviri işlemi başlıyor... (Pencereyi kapatma)")

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
            if count % 10 == 0:
                print(f"İlerliyor... ({count}/{total}) -> {word}")
                
        except Exception as e:
            print(f"Hata ({word}): {e}")
            final_data.append({"en": word, "tr": "..."})

    # 4. Kaydet
    print("Kaydediliyor...")
    random.shuffle(final_data)
    
    output_path = os.path.join(script_dir, "words.json")
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(final_data, f, ensure_ascii=False, indent=2)
        
    print(f"\n--- İŞLEM TAMAM! ---")
    print(f"words.json şuraya kaydedildi: {output_path}")

if __name__ == "__main__":
    create_database_local()