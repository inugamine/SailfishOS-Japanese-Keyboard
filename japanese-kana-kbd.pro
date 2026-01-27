TEMPLATE = aux

layouts.files = layouts/ja.conf layouts/ja.qml
layouts.path = /usr/share/maliit/plugins/com/jolla/layouts

ja_components.files = layouts/ja/FlickKey.qml \
                      layouts/ja/FunctionKey.qml \
                      layouts/ja/KanaConverter.js \
                      layouts/ja/DictEngine.js
ja_components.path = /usr/share/maliit/plugins/com/jolla/layouts/ja

ja_dict.files = layouts/ja/dict/SKK-JISYO.L.utf8
ja_dict.path = /usr/share/maliit/plugins/com/jolla/layouts/ja/dict

INSTALLS += layouts ja_components ja_dict
