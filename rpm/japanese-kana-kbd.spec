Name:       japanese-kana-kbd
Version:    0.20.0
Release:    1
Summary:    Japanese Kana Keyboard for Sailfish OS
License:    GPL
URL:        https://github.com/inugamine/SailfishOS-Japanese-Keyboard
BuildArch:  noarch
Requires:   jolla-keyboard
Requires:   anthy-qml-plugin

%description
Japanese Hiragana flick keyboard layout for Sailfish OS.
Features:
- Flick input for hiragana
- Dakuten/Handakuten conversion
- Katakana conversion
- Anthy-based kanji conversion (with SKK dictionary fallback)

%prep
# nothing to do

%build
%qmake5

%install
%qmake5_install

%files
%defattr(-,root,root,-)
/usr/share/maliit/plugins/com/jolla/layouts/ja.conf
/usr/share/maliit/plugins/com/jolla/layouts/ja.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja/FlickKey.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja/FunctionKey.qml
/usr/share/maliit/plugins/com/jolla/layouts/ja/KanaConverter.js
/usr/share/maliit/plugins/com/jolla/layouts/ja/DictEngine.js
/usr/share/maliit/plugins/com/jolla/layouts/ja/dict/SKK-JISYO.L.utf8
