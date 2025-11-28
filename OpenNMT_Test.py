import sentencepiece as spm
from onmt.translate.translator import build_translator
from onmt.utils.parse import ArgumentParser
from onmt.opts import translate_opts

model_path = r"c:\Users\eXample\Downloads\nllb-200-600M-onmt.pt"
sp_model = r"c:\Users\eXample\Downloads\flores200_sacrebleu_tokenizer_spm.model"

# загружаем SentencePiece
sp = spm.SentencePieceProcessor(model_file=sp_model)

parser = ArgumentParser()
translate_opts(parser)
opt = parser.parse_args([
    "-model", model_path,
    "-replace_unk",
    "-src", "src.txt",
    "-output", "pred.txt",
    "-src_lang", "zh",
    "-tgt_lang", "ru"
])

translator = build_translator(opt, report_score=True)

src_text = "测试一下中文到俄文的翻译"

# токенизация + добавляем тег языка
tokens = sp.encode(src_text, out_type=str)
tokens = ["__zh__"] + tokens  # префикс языка источника

with open("src.txt", "w", encoding="utf-8") as f:
    f.write(" ".join(tokens) + "\n")

# перевод
translator.translate(
    src_path=opt.src,
    tgt_path=opt.output,
    src_dir=None,
    batch_size=1
)

with open("pred.txt", "r", encoding="utf-8") as f:
    result = f.read().strip()

print("zh:", src_text)
print("ru:", result)
