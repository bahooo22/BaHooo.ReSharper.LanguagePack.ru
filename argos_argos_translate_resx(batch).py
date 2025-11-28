import os
import xml.etree.ElementTree as ET
import argostranslate.translate as tr
from tqdm import tqdm
import argparse
from concurrent.futures import ProcessPoolExecutor
import datetime
import multiprocessing

# Глобальный кэш переводов
cache = {}

def cached_translate(translator, texts):
    """Перевод с кэшированием и пакетной обработкой."""
    results = []
    to_translate = []
    indices = []

    for i, text in enumerate(texts):
        if text in cache:
            results.append(cache[text])
        else:
            results.append(None)
            to_translate.append(text)
            indices.append(i)

    if to_translate:
        translated = translator.translate_batch(to_translate)
        for idx, t in zip(indices, translated):
            results[idx] = t
            cache[to_translate[indices.index(idx)]] = t

    return results


def translate_file(src_path, en_path, ru_new_path, log_mode, zh_en, en_ru, resume, log_file):
    if resume and os.path.exists(ru_new_path):
        msg = f"[SKIP] {os.path.basename(src_path)} уже обработан"
        print(msg)
        if log_file: log_file.write(msg + "\n")
        return

    tree = ET.parse(src_path)
    root = tree.getroot()
    values = root.findall("data")

    # zh→en пакетный перевод
    zh_texts = [v.find("value").text for v in values if v.find("value") is not None and v.find("value").text]
    en_texts = cached_translate(zh_en, zh_texts)

    for v, t in zip(values, en_texts):
        if v.find("value") is not None and v.find("value").text:
            v.find("value").text = t

    tree.write(en_path, encoding="utf-8", xml_declaration=True)

    # en→ru пакетный перевод
    tree = ET.parse(en_path)
    root = tree.getroot()
    values = root.findall("data")

    en_texts = [v.find("value").text for v in values if v.find("value") is not None and v.find("value").text]
    ru_texts = cached_translate(en_ru, en_texts)

    for v, t in zip(values, ru_texts):
        if v.find("value") is not None and v.find("value").text:
            v.find("value").text = t

    tree.write(ru_new_path, encoding="utf-8", xml_declaration=True)

    if log_mode == "minimal" and values:
        first_val = values[0].find("value").text
        last_val = values[-1].find("value").text
        msg = f"Файл {os.path.basename(src_path)} обработан\nПервая фраза: {first_val}\nПоследняя фраза: {last_val}"
        print(msg)
        if log_file: log_file.write(msg + "\n")


def main():
    parser = argparse.ArgumentParser(
        description="Batch translation of .resx files: zh→en→ru with caching, batching, logging, progressbar, parallel workers, resume, dry-run, and log saving.",
        formatter_class=argparse.RawTextHelpFormatter,
        epilog="Смотри README.md для примеров запуска."
    )
    parser.add_argument("--original", required=True)
    parser.add_argument("--intermediate", required=True)
    parser.add_argument("--final", required=True)
    parser.add_argument("--single", default=None)
    parser.add_argument("--log", choices=["full", "first5", "every10", "minimal"], default="minimal")
    parser.add_argument("--workers", type=int, default=max(1, multiprocessing.cpu_count() // 2))
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--logfile", default=None)
    args = parser.parse_args()

    langs = tr.get_installed_languages()
    zh = next(l for l in langs if l.code == "zh")
    en = next(l for l in langs if l.code == "en")
    ru = next(l for l in langs if l.code == "ru")
    zh_en = zh.get_translation(en)
    en_ru = en.get_translation(ru)

    if args.single:
        files = [args.single]
    else:
        files = [f for f in os.listdir(args.original) if f.endswith(".Strings.ru-RU.resx")]

    total = len(files)
    print(f"Найдено файлов: {total}")

    if args.dry_run:
        print("Dry-run: будут обработаны следующие файлы:")
        for f in files:
            print(" -", f)
        return

    log_file = None
    if args.logfile:
        os.makedirs(os.path.dirname(args.logfile), exist_ok=True)
        log_file = open(args.logfile, "a", encoding="utf-8")
        log_file.write(f"\n=== Запуск {datetime.datetime.now()} ===\n")

    def task(file):
        src_path = os.path.join(args.original, file)
        en_path = os.path.join(args.intermediate, file.replace(".ru-RU.resx", ".en-US.resx"))
        ru_new_path = os.path.join(args.final, file.replace(".ru-RU.resx", ".ru-RU.resx.new"))

        if args.resume and os.path.exists(ru_new_path):
            msg = f"[SKIP] {file} уже обработан"
            print(msg)
            if log_file: log_file.write(msg + "\n")
            return

        msg = f"Обработка файла: {file}"
        print(msg)
        if log_file: log_file.write(msg + "\n")
        translate_file(src_path, en_path, ru_new_path, args.log, zh_en, en_ru, args.resume, log_file)

    if args.workers > 1:
        with ProcessPoolExecutor(max_workers=args.workers) as executor:
            executor.map(task, files)
    else:
        for file in files:
            task(file)

    if log_file:
        log_file.write(f"=== Завершение {datetime.datetime.now()} ===\n")
        log_file.close()


if __name__ == "__main__":
    main()
