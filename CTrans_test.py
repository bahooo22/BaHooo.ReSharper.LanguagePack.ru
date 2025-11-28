import ctranslate2
import sentencepiece as spm

model_dir = r"c:\Users\eXample\Documents\GitHub\bahooo22\RuReSharper\nllb-ctranslate2"
sp_model = r"c:\Users\eXample\Downloads\flores200_sacrebleu_tokenizer_spm.model"

sp = spm.SentencePieceProcessor(model_file=sp_model)
translator = ctranslate2.Translator(model_dir)

src_text = "测试一下中文到俄文的翻译"

# токенизация + добавляем тег языка источника
tokens = ["__zh_CN__"] + sp.encode(src_text, out_type=str)

# перевод с указанием языка назначения
result = translator.translate_batch(
    [tokens],
    target_prefix=[["__ru__"]],
    beam_size=5
)

translation = " ".join(result[0].hypotheses[0])
print("zh:", src_text)
print("ru:", translation)
