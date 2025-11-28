# chinese_russian_translator.py
from transformers import pipeline
import os

class ChineseRussianTranslator:
    def __init__(self, model_path="./models/nllb-200-distilled-600M"):
        self.model_path = model_path
        self.translator = None
        self.load_model()
    
    def load_model(self):
        """Загружает модель перевода"""
        if not os.path.exists(self.model_path):
            print(f"❌ Модель не найдена в {self.model_path}")
            print("Скачайте модель сначала: python download_nllb.py")
            return False
        
        try:
            print("🔄 Загружаем модель перевода...")
            self.translator = pipeline(
                "translation",
                model=self.model_path,
                src_lang="zho_Hans",  # китайский упрощенный
                tgt_lang="rus_Cyrl",  # русский
                device=-1  # CPU
            )
            print("✅ Модель загружена успешно!")
            return True
        except Exception as e:
            print(f"❌ Ошибка загрузки модели: {e}")
            return False
    
    def translate(self, text):
        """Переводит текст с китайского на русский"""
        if not self.translator:
            return None
        
        try:
            result = self.translator(text)
            return result[0]['translation_text']
        except Exception as e:
            print(f"❌ Ошибка перевода: {e}")
            return None
    
    def translate_batch(self, texts):
        """Переводит список текстов"""
        if not self.translator:
            return None
        
        try:
            results = []
            for text in texts:
                result = self.translate(text)
                results.append(result)
            return results
        except Exception as e:
            print(f"❌ Ошибка пакетного перевода: {e}")
            return None

def demo_translator():
    """Демонстрация работы переводчика"""
    translator = ChineseRussianTranslator()
    
    if not translator.translator:
        return
    
    # Тестовые примеры
    test_cases = [
        "测试一下中文到俄文的翻译",
        "你好世界",
        "今天天气很好",
        "我爱你", 
        "这个餐厅的食物很好吃",
        "请问去火车站怎么走？",
        "明天我要去北京",
        "你会说英语吗？",
        "多少钱？",
        "谢谢你的帮助"
    ]
    
    print("=" * 70)
    print("🇨🇳➡️🇷🇺 КИТАЙСКО-РУССКИЙ ПЕРЕВОДЧИК")
    print("=" * 70)
    
    for i, chinese_text in enumerate(test_cases, 1):
        russian_text = translator.translate(chinese_text)
        if russian_text:
            print(f"{i:2d}. 中文: {chinese_text}")
            print(f"     Рус: {russian_text}")
            print()

def interactive_mode():
    """Интерактивный режим перевода"""
    translator = ChineseRussianTranslator()
    
    if not translator.translator:
        return
    
    print("🎯 ИНТЕРАКТИВНЫЙ РЕЖИМ")
    print("Вводите китайский текст для перевода")
    print("Команды: quit, exit, stop - выход")
    print("-" * 50)
    
    while True:
        try:
            chinese_text = input("\n中文: ").strip()
            
            if chinese_text.lower() in ['quit', 'exit', 'stop', 'выход']:
                print("👋 До свидания!")
                break
            
            if not chinese_text:
                continue
            
            russian_text = translator.translate(chinese_text)
            if russian_text:
                print(f"🇷🇺 Рус: {russian_text}")
            else:
                print("❌ Ошибка перевода")
                
        except KeyboardInterrupt:
            print("\n👋 До свидания!")
            break
        except Exception as e:
            print(f"❌ Ошибка: {e}")

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1:
        # Перевод аргумента командной строки
        translator = ChineseRussianTranslator()
        if translator.translator:
            text = " ".join(sys.argv[1:])
            result = translator.translate(text)
            if result:
                print(f"中文: {text}")
                print(f"Рус:  {result}")
    else:
        # Запуск демо и интерактивного режима
        demo_translator()
        print("\n" + "=" * 70)
        interactive_mode()