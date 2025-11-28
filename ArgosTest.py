import argostranslate.translate as tr

langs = tr.get_installed_languages()
zh = next(l for l in langs if l.code == "zh")
en = next(l for l in langs if l.code == "en")
ru = next(l for l in langs if l.code == "ru")

zh_en = zh.get_translation(en)
en_ru = en.get_translation(ru)

text = "测试一下中文到俄文的翻译"
print(en_ru.translate(zh_en.translate(text)))
