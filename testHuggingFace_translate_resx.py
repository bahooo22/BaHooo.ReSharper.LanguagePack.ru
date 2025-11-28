import os
import re
import xml.etree.ElementTree as ET
from tqdm import tqdm
import argparse
from concurrent.futures import ThreadPoolExecutor
import datetime
from transformers import AutoTokenizer, AutoModelForSeq2SeqLM
import torch

# Глобальный кэш переводов
cache = {}

class TwoStepTranslator:
    def __init__(self, zh_en_model_path="./models/opus-mt-zh-en", en_ru_model_name="Helsinki-NLP/opus-mt-en-ru"):
        self.device = self.get_device()
        
        # Загружаем модели для двухэтапного перевода
        self.zh_en_tokenizer = AutoTokenizer.from_pretrained(zh_en_model_path)
        self.zh_en_model = AutoModelForSeq2SeqLM.from_pretrained(zh_en_model_path).to(self.device)
        
        self.en_ru_tokenizer = AutoTokenizer.from_pretrained(en_ru_model_name)
        self.en_ru_model = AutoModelForSeq2SeqLM.from_pretrained(en_ru_model_name).to(self.device)
    
    def get_device(self):
        if torch.cuda.is_available():
            return "cuda"
        elif hasattr(torch.backends, 'mps') and torch.backends.mps.is_available():
            return "mps" 
        else:
            return "cpu"
    
    def translate_zh_to_en(self, text):
        """Перевод китайский -> английский"""
        if not text or not text.strip():
            return text
            
        try:
            inputs = self.zh_en_tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
            inputs = {k: v.to(self.device) for k, v in inputs.items()}
            
            with torch.no_grad():
                outputs = self.zh_en_model.generate(
                    **inputs, 
                    max_length=512, 
                    num_beams=4,
                    early_stopping=True
                )
            
            return self.zh_en_tokenizer.decode(outputs[0], skip_special_tokens=True)
            
        except Exception as e:
            print(f"Ошибка перевода zh->en '{text}': {e}")
            return text
    
    def translate_en_to_ru(self, text):
        """Перевод английский -> русский"""
        if not text or not text.strip():
            return text
            
        try:
            inputs = self.en_ru_tokenizer(text, return_tensors="pt", padding=True, truncation=True, max_length=512)
            inputs = {k: v.to(self.device) for k, v in inputs.items()}
            
            with torch.no_grad():
                outputs = self.en_ru_model.generate(
                    **inputs, 
                    max_length=512, 
                    num_beams=4,
                    early_stopping=True
                )
            
            return self.en_ru_tokenizer.decode(outputs[0], skip_special_tokens=True)
            
        except Exception as e:
            print(f"Ошибка перевода en->ru '{text}': {e}")
            return text

def cached_translate(translator, text, direction):
    """Перевод строки с кэшированием."""
    cache_key = f"{direction}:{text}"
    if cache_key in cache:
        return cache[cache_key]
    
    if direction == "zh_en":
        result = translator.translate_zh_to_en(text)
    else:  # en_ru
        result = translator.translate_en_to_ru(text)
    
    cache[cache_key] = result
    return result

def preserve_placeholders(src_text, translated_text):
    """Гарантируем сохранение {0}, {1}, {N} плейсхолдеров."""
    placeholders = re.findall(r"\{[0-9]+\}", src_text)
    for ph in placeholders:
        if ph not in translated_text:
            translated_text += " " + ph
    return translated_text

def translate_file(src_path, en_path, ru_new_path, log_mode, translator, resume, log_file):
    if resume and os.path.exists(ru_new_path):
        msg = f"[SKIP] {os.path.basename(src_path)} уже обработан"
        print(msg)
        if log_file: 
            log_file.write(msg + "\n")
            log_file.flush()
        return

    try:
        # Один раз парсим XML
        tree = ET.parse(src_path)
        root = tree.getroot()
        values = root.findall("data")

        logs = []  # собираем логи для одного файла

        # zh→en
        for idx, data in enumerate(tqdm(values, desc=f"{os.path.basename(src_path)} zh→en", unit="строка"), start=1):
            value = data.find("value")
            if value is not None and value.text:
                raw = value.text
                mid = cached_translate(translator, raw, "zh_en")
                value.text = mid
                if log_mode == "full":
                    logs.append(f"[{idx}] zh: {raw} | en: {mid}")
                elif log_mode == "first5" and idx <= 5:
                    logs.append(f"[{idx}] zh: {raw} | en: {mid}")
                elif log_mode == "every10" and idx % 10 == 0:
                    logs.append(f"[{idx}] zh: {raw} | en: {mid}")
        
        # сохранить промежуточный файл
        tree.write(en_path, encoding="utf-8", xml_declaration=True)
        
        # en→ru
        for idx, data in enumerate(tqdm(values, desc=f"{os.path.basename(src_path)} en→ru", unit="строка"), start=1):
            value = data.find("value")
            if value is not None and value.text:
                mid = value.text
                final = cached_translate(translator, mid, "en_ru")
                final = preserve_placeholders(mid, final)
                value.text = final
                if log_mode == "full":
                    logs.append(f"[{idx}] en: {mid} | ru: {final}")
                elif log_mode == "first5" and idx <= 5:
                    logs.append(f"[{idx}] en: {mid} | ru: {final}")
                elif log_mode == "every10" and idx % 10 == 0:
                    logs.append(f"[{idx}] en: {mid} | ru: {final}")

        # Записываем финальный файл
        tree.write(ru_new_path, encoding="utf-8", xml_declaration=True)

        # Лог minimal
        if log_mode == "minimal" and values:
            first_val = values[0].find("value").text if values[0].find("value") is not None else ""
            last_val = values[-1].find("value").text if values[-1].find("value") is not None else ""
            logs.append(f"Файл {os.path.basename(src_path)} обработан")
            logs.append(f"Переведено фраз: {len([v for v in values if v.find('value') is not None and v.find('value').text])}")
            if values and values[0].find("value") is not None and values[0].find("value").text:
                logs.append(f"Первая фраза: {values[0].find('value').text[:50]}...")
                logs.append(f"Последняя фраза: {values[-1].find('value').text[:50]}...")

        # Выводим лог блоком (чтобы при параллельности не перемешивалось)
        if logs:
            block = "\n".join(logs)
            print(block)
            if log_file:
                log_file.write(block + "\n")
                log_file.flush()
                
    except Exception as e:
        error_msg = f"❌ Ошибка при обработке файла {src_path}: {e}"
        print(error_msg)
        if log_file:
            log_file.write(error_msg + "\n")
            log_file.flush()

def process_file(args):
    """Функция для параллельной обработки одного файла"""
    file, original_dir, intermediate_dir, final_dir, log_mode, resume, log_file_path, translator = args
    
    src_path = os.path.join(original_dir, file)
    
    # Формируем пути для промежуточного и финального файлов
    if file.endswith(".Strings.ru-RU.resx"):
        en_path = os.path.join(intermediate_dir, file.replace(".Strings.ru-RU.resx", ".Strings.en-US.resx"))
        ru_new_path = os.path.join(final_dir, file.replace(".Strings.ru-RU.resx", ".Strings.ru-RU.resx.new"))
    else:
        en_path = os.path.join(intermediate_dir, file.replace(".resx", ".en-US.resx"))
        ru_new_path = os.path.join(final_dir, file.replace(".resx", ".ru-RU.resx.new"))

    if resume and os.path.exists(ru_new_path):
        return f"[SKIP] {file}"

    # Открываем лог-файл если указан
    log_file = None
    if log_file_path:
        try:
            log_file = open(log_file_path, "a", encoding="utf-8")
        except Exception as e:
            print(f"❌ Не удалось открыть лог-файл: {e}")

    try:
        msg = f"Обработка файла: {file}"
        print(msg)
        if log_file:
            log_file.write(msg + "\n")
            log_file.flush()
            
        translate_file(src_path, en_path, ru_new_path, log_mode, translator, resume, log_file)
        return f"[OK] {file}"
        
    except Exception as e:
        error_msg = f"[ERROR] {file}: {str(e)}"
        if log_file:
            log_file.write(error_msg + "\n")
            log_file.flush()
        return error_msg
    finally:
        if log_file:
            log_file.close()

def main():
    parser = argparse.ArgumentParser(
        description="Translation of .resx files: zh→en→ru with Hugging Face models, caching, placeholder preservation, single XML parse, grouped logging, parallel workers, resume, dry-run.",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog="""
Примеры запуска:

1. Все файлы (минимальный лог):
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru

2. Один файл для отладки:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --single MyPlugin.Strings.ru-RU.resx

3. Полный лог:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --log full

4. Первые 5 фраз:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --log first5

5. Каждая 10-я фраза:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --log every10

6. Параллельная обработка 4 файлов:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --workers 4

7. Продолжение обработки:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --resume

8. Комбинация: один файл, полный лог, resume:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --single MyPlugin.Strings.ru-RU.resx --log full --resume

9. Все файлы, каждая 10-я фраза, 2 воркера:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --log every10 --workers 2

10. Проверка списка файлов без перевода:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --dry-run

11. Сохранение лога в файл:
   python translate_resx_hf.py --original C:\\src --intermediate C:\\en --final C:\\ru --log full --workers 2 --resume --logfile C:\\logs\\translate.log
"""
    )
    parser.add_argument("--original", required=True, help="Папка с оригинальными .resx файлами (китайский текст).")
    parser.add_argument("--intermediate", required=True, help="Папка для промежуточных файлов (английский перевод).")
    parser.add_argument("--final", required=True, help="Папка для финальных файлов (русский перевод).")
    parser.add_argument("--single", default=None, help="Имя одного файла для отладки.")
    parser.add_argument("--log", choices=["full", "first5", "every10", "minimal"], default="minimal",
                        help="Уровень логирования.")
    parser.add_argument("--workers", type=int, default=1,
                        help="Количество параллельных потоков для обработки файлов.")
    parser.add_argument("--resume", action="store_true",
                        help="Пропускать уже обработанные файлы (если финальный .resx.new существует).")
    parser.add_argument("--dry-run", action="store_true",
                        help="Только показать список файлов, которые будут обработаны, без перевода.")
    parser.add_argument("--logfile", default=None,
                        help="Путь к файлу для сохранения лога (например, C:\\logs\\translate.log).")
    parser.add_argument("--zh-en-model", default="./models/opus-mt-zh-en",
                        help="Путь к китайско-английской модели.")
    parser.add_argument("--en-ru-model", default="Helsinki-NLP/opus-mt-en-ru",
                        help="Имя англо-русской модели.")
    args = parser.parse_args()

    print("🔄 Инициализация переводчика...")
    try:
        translator = TwoStepTranslator(args.zh_en_model, args.en_ru_model)
        print("✅ Переводчик инициализирован")
    except Exception as e:
        print(f"❌ Ошибка инициализации переводчика: {e}")
        return

    if args.single:
        files = [args.single]
    else:
        files = [f for f in os.listdir(args.original) if f.endswith(".Strings.ru-RU.resx")]
        # Если не нашли .Strings.ru-RU.resx, ищем обычные .resx
        if not files:
            files = [f for f in os.listdir(args.original) if f.endswith(".resx")]

    total = len(files)
    print(f"📁 Найдено файлов: {total}")

    if args.dry_run:
        print("🔍 Dry-run: будут обработаны следующие файлы:")
        for f in files:
            print(" -", f)
        return

    # Создаем выходные папки
    os.makedirs(args.intermediate, exist_ok=True)
    os.makedirs(args.final, exist_ok=True)

    log_file_path = None
    if args.logfile:
        os.makedirs(os.path.dirname(args.logfile), exist_ok=True)
        log_file_path = args.logfile
        with open(log_file_path, "a", encoding="utf-8") as log_file:
            log_file.write(f"\n=== Запуск {datetime.datetime.now()} ===\n")
            log_file.write(f"Файлов для обработки: {total}\n")
            log_file.write(f"Воркеров: {args.workers}, Лог: {args.log}\n")

    # Подготавливаем аргументы для параллельной обработки
    task_args = [
        (f, args.original, args.intermediate, args.final, args.log, args.resume, log_file_path, translator) 
        for f in files
    ]

    if args.workers > 1:
        print(f"🚀 Запускаем {args.workers} параллельных потоков...")
        with ThreadPoolExecutor(max_workers=args.workers) as executor:
            results = list(tqdm(
                executor.map(process_file, task_args),
                total=len(files),
                desc="📄 Обработка файлов"
            ))
    else:
        print("🚀 Запускаем последовательную обработку...")
        results = []
        for task_arg in tqdm(task_args, desc="📄 Обработка файлов"):
            results.append(process_file(task_arg))

    # Выводим итоги
    print("\n📊 РЕЗУЛЬТАТЫ ОБРАБОТКИ:")
    for result in results:
        print(result)

    success = sum(1 for r in results if "[OK]" in r)
    skipped = sum(1 for r in results if "[SKIP]" in r)
    errors = sum(1 for r in results if "[ERROR]" in r)
    
    print(f"\n✅ Успешно: {success}, ⏭️ Пропущено: {skipped}, ❌ Ошибок: {errors}")

    if log_file_path:
        with open(log_file_path, "a", encoding="utf-8") as log_file:
            log_file.write(f"=== Завершение {datetime.datetime.now()} ===\n")
            log_file.write(f"Успешно: {success}, Пропущено: {skipped}, Ошибок: {errors}\n")

    print("✅ Обработка завершена!")


if __name__ == "__main__":
    main()