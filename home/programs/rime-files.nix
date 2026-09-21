{ inputs }:

{
  "default.custom.yaml" = ../../config/rime/default.custom.yaml;
  "double_pinyin_flypy.schema.yaml" = ../../config/rime/double_pinyin_flypy.schema.yaml;
  "double_pinyin_flypy.custom.yaml" = ../../config/rime/double_pinyin_flypy.custom.yaml;
  "emoji_suggestion.yaml" = "${inputs.rime-emoji}/emoji_suggestion.yaml";
  "opencc/emoji.json" = "${inputs.rime-emoji}/opencc/emoji.json";
  "opencc/emoji_category.txt" = "${inputs.rime-emoji}/opencc/emoji_category.txt";
  "opencc/emoji_word.txt" = "${inputs.rime-emoji}/opencc/emoji_word.txt";
}
