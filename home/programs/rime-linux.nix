{ inputs, ... }:

let
  rimeDirectory = "fcitx5/rime";
in
{
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    DefaultIM=rime

    [Groups/0/Items/0]
    Name=keyboard-us
    Layout=

    [Groups/0/Items/1]
    Name=rime
    Layout=

    [GroupOrder]
    0=Default
  '';

  # Keep generated state and user dictionaries unmanaged. Home Manager owns
  # only the portable schema and Emoji support files used by Fcitx5 Rime.
  xdg.dataFile = {
    "${rimeDirectory}/default.custom.yaml".source = ../../config/rime/default.custom.yaml;
    "${rimeDirectory}/double_pinyin_flypy.schema.yaml".source =
      ../../config/rime/double_pinyin_flypy.schema.yaml;
    "${rimeDirectory}/double_pinyin_flypy.custom.yaml".source =
      ../../config/rime/double_pinyin_flypy.custom.yaml;
    "${rimeDirectory}/emoji_suggestion.yaml".source = "${inputs.rime-emoji}/emoji_suggestion.yaml";
    "${rimeDirectory}/opencc/emoji.json".source = "${inputs.rime-emoji}/opencc/emoji.json";
    "${rimeDirectory}/opencc/emoji_category.txt".source =
      "${inputs.rime-emoji}/opencc/emoji_category.txt";
    "${rimeDirectory}/opencc/emoji_word.txt".source = "${inputs.rime-emoji}/opencc/emoji_word.txt";
  };
}
