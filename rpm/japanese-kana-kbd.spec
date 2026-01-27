Name:       japanese-kana-kbd
Version:    0.18.0
Release:    1
Summary:    Japanese Kana Keyboard for Sailfish OS
License:    MIT
URL:        https://github.com/user/japanese-kana-kbd
BuildArch:  noarch
Requires:   jolla-keyboard

%description
Japanese Hiragana flick keyboard layout for Sailfish OS.
Features:
- Flick input for hiragana
- Dakuten/Handakuten conversion
- Katakana conversion
- Dictionary-based kanji conversion (SKK dictionary)

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
