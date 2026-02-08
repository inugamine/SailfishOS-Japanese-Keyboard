import QtQuick 2.0
import Sailfish.Silica 1.0
import com.meego.maliitquick 1.0
import jp.anthy 1.0
import ".."
import "./ja"
import "./ja/KanaConverter.js" as KanaConverter
import "./ja/DictEngine.js" as DictEngine

KeyboardLayout {
    id: main
    splitSupported: false

    height: column.height
    
    // 入力モード: "hiragana", "alphabet", "symbol"
    property string inputMode: "hiragana"
    
    // 未確定文字列（preedit）
    property string preedit: ""
    
    // 変換候補リスト
    property var candidates: []
    
    // Anthy が使用可能かどうか
    property bool anthyAvailable: false
    
    // Anthy エンジン
    AnthyEngine {
        id: anthy
        Component.onCompleted: {
            anthyAvailable = true
            console.log("AnthyEngine initialized")
        }
    }
    
    // 辞書読み込み（フォールバック用）
    Component.onCompleted: {
        loadDictionary()
    }
    
    function loadDictionary() {
        var xhr = new XMLHttpRequest()
        xhr.open("GET", "ja/dict/SKK-JISYO.L.utf8")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200 || xhr.status === 0) {
                    DictEngine.loadDictionary(xhr.responseText)
                    console.log("Dictionary loaded successfully (fallback)")
                } else {
                    console.log("Failed to load dictionary: " + xhr.status)
                }
            }
        }
        xhr.send()
    }
    
    // 変換候補を更新
    function updateCandidates() {
        if (preedit === "") {
            candidates = []
            return
        }
        
        // Anthy が使用可能なら Anthy を使用
        if (anthyAvailable) {
            if (anthy.convert(preedit)) {
                // 最初の文節の候補を取得
                var anthyCandidates = anthy.getCandidates(0)
                if (anthyCandidates.length > 0) {
                    candidates = anthyCandidates.slice(0, 10)
                    return
                }
            }
        }
        
        // Anthy が使えない場合は SKK 辞書にフォールバック
        candidates = DictEngine.getCandidates(preedit, 10)
    }
    
    // 文字を追加する関数（未確定状態で表示）
    function addChar(c) {
        if (c !== "") {
            preedit += c
            MInputMethodQuick.sendPreedit(preedit)
            updateCandidates()
        }
    }
    
    // 確定する関数
    function commit() {
        if (preedit !== "") {
            // Anthy で変換中なら Anthy の結果を確定
            if (anthyAvailable && anthy.segments.length > 0) {
                var result = anthy.commit()
                MInputMethodQuick.sendCommit(result)
            } else {
                MInputMethodQuick.sendCommit(preedit)
            }
            preedit = ""
            candidates = []
        }
    }
    
    // 候補を選択して確定
    function selectCandidate(text) {
        // Anthy で変換中の場合
        if (anthyAvailable && anthy.segments.length > 0) {
            // 選択された候補のインデックスを探す
            var anthyCandidates = anthy.getCandidates(0)
            var index = anthyCandidates.indexOf(text)
            if (index >= 0) {
                anthy.selectCandidate(0, index)
            }
        }
        
        MInputMethodQuick.sendCommit(text)
        preedit = ""
        candidates = []
        
        // Anthy をリセット
        if (anthyAvailable) {
            anthy.reset()
        }
    }
    
    // 濁点/半濁点/小文字変換（preeditの最後の文字）
    function convertLastChar() {
        if (preedit === "") return
        
        var lastChar = preedit.slice(-1)
        var converted = KanaConverter.convert(lastChar)
        
        if (converted !== lastChar) {
            preedit = preedit.slice(0, -1) + converted
            MInputMethodQuick.sendPreedit(preedit)
            updateCandidates()
        }
    }
    
    // モード切り替え
    function switchToHiragana() {
        inputMode = "hiragana"
    }
    
    function switchToAlphabet() {
        // アルファベットモードに切り替える前に確定
        commit()
        inputMode = "alphabet"
    }
    
    function switchToSymbol() {
        // 記号モードに切り替える前に確定
        commit()
        inputMode = "symbol"
    }
    
    // 大文字/小文字切り替え（アルファベットモード用）
    function toggleCase() {
        if (preedit === "") return
        
        var lastChar = preedit.slice(-1)
        var code = lastChar.charCodeAt(0)
        var converted = ""
        
        // 小文字 → 大文字
        if (code >= 97 && code <= 122) {
            converted = String.fromCharCode(code - 32)
        }
        // 大文字 → 小文字
        else if (code >= 65 && code <= 90) {
            converted = String.fromCharCode(code + 32)
        }
        
        if (converted !== "") {
            preedit = preedit.slice(0, -1) + converted
            MInputMethodQuick.sendPreedit(preedit)
        }
    }
    
    // ひらがな⇔カタカナ変換（preedit全体）
    function toggleKana() {
        if (preedit === "") return
        
        // preeditの最初の文字で判定
        var firstCode = preedit.charCodeAt(0)
        var converted = ""
        
        // ひらがなが含まれている → カタカナに変換
        if (firstCode >= 0x3041 && firstCode <= 0x3096) {
            converted = KanaConverter.toKatakana(preedit)
        }
        // カタカナが含まれている → ひらがなに変換
        else if (firstCode >= 0x30A1 && firstCode <= 0x30F6) {
            converted = KanaConverter.toHiragana(preedit)
        }
        
        if (converted !== "" && converted !== preedit) {
            preedit = converted
            MInputMethodQuick.sendPreedit(preedit)
            updateCandidates()
        }
    }
    
    // バックスペース（preeditから1文字削除、空なら通常のBackspace）
    function backspace() {
        if (preedit !== "") {
            preedit = preedit.slice(0, -1)
            MInputMethodQuick.sendPreedit(preedit)
            updateCandidates()
        } else {
            MInputMethodQuick.sendKey(Qt.Key_Backspace)
        }
    }

    Column {
        id: column
        width: parent.width

        // ==================== 変換候補バー ====================
        Item {
            width: parent.width
            height: candidates.length > 0 ? geometry.keyHeightPortrait * 0.8 : 0
            visible: candidates.length > 0
            
            Rectangle {
                anchors.fill: parent
                color: Theme.rgba(Theme.highlightBackgroundColor, 0.1)
            }
            
            ListView {
                id: candidateList
                anchors.fill: parent
                anchors.leftMargin: Theme.paddingSmall
                anchors.rightMargin: Theme.paddingSmall
                orientation: ListView.Horizontal
                spacing: Theme.paddingSmall
                clip: true
                
                model: candidates
                
                delegate: Rectangle {
                    height: parent.height
                    width: candidateText.width + Theme.paddingLarge
                    color: candidateMouseArea.pressed ? Theme.highlightBackgroundColor : "transparent"
                    radius: Theme.paddingSmall
                    
                    Text {
                        id: candidateText
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.primaryColor
                        font.pixelSize: Theme.fontSizeMedium
                    }
                    
                    MouseArea {
                        id: candidateMouseArea
                        anchors.fill: parent
                        onClicked: main.selectCandidate(modelData)
                    }
                }
            }
        }

        // ==================== ひらがなモード ====================
        Column {
            id: hiraganaMode
            width: parent.width
            visible: inputMode === "hiragana"

            // 1行目: [記号モード] あ か さ [バックスペースキー]
            Row {
                width: parent.width
                height: geometry.keyHeightPortrait

                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "☆123"
                    onClicked: main.switchToSymbol()
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["あ", "い", "う", "え", "お"]
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["か", "き", "く", "け", "こ"]
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["さ", "し", "す", "せ", "そ"]
                    onCharSelected: main.addChar(selectedChar)
                }
                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "⌫"
                    repeat: true
                    onClicked: main.backspace()
                }
            }

            // 2行目: [英数モード] た な は [空白/カナ]
            Row {
                width: parent.width
                height: geometry.keyHeightPortrait

                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "ABC"
                    onClicked: main.switchToAlphabet()
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["た", "ち", "つ", "て", "と"]
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["な", "に", "ぬ", "ね", "の"]
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["は", "ひ", "ふ", "へ", "ほ"]
                    onCharSelected: main.addChar(selectedChar)
                }
                // 空白/カナ切り替えキー
                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: preedit !== "" ? "カナ" : "空白"
                    onClicked: {
                        if (preedit !== "") {
                            main.toggleKana()
                        } else {
                            MInputMethodQuick.sendCommit(" ")
                        }
                    }
                }
            }

            // 3行目と4行目をラップ（Enterキー2マス対応）
            Item {
                width: parent.width
                height: geometry.keyHeightPortrait * 2

                // 3行目: [日本語モード] ま や ら
                Row {
                    id: hiraganaRow3
                    width: parent.width * 4 / 5
                    height: geometry.keyHeightPortrait

                    FunctionKey {
                        width: parent.width / 4
                        height: parent.height
                        caption: "あいう"
                        enabled: false
                        opacity: 0.5
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["ま", "み", "む", "め", "も"]
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["や", "（", "ゆ", "）", "よ"]
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["ら", "り", "る", "れ", "ろ"]
                        onCharSelected: main.addChar(selectedChar)
                    }
                }

                // 4行目: [←][→][小゛゜] わをん [、。?!]
                Row {
                    anchors.top: hiraganaRow3.bottom
                    width: parent.width * 4 / 5
                    height: geometry.keyHeightPortrait

                    // カーソル左
                    FunctionKey {
                        width: parent.width / 8
                        height: parent.height
                        caption: "←"
                        repeat: true
                        onClicked: {
                            main.commit()
                            MInputMethodQuick.sendKey(Qt.Key_Left)
                        }
                    }
                    // カーソル右
                    FunctionKey {
                        width: parent.width / 8
                        height: parent.height
                        caption: "→"
                        repeat: true
                        onClicked: {
                            main.commit()
                            MInputMethodQuick.sendKey(Qt.Key_Right)
                        }
                    }
                    // 濁点/半濁点/小文字
                    FunctionKey {
                        width: parent.width / 4
                        height: parent.height
                        caption: "小゛゜"
                        onClicked: main.convertLastChar()
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["わ", "を", "ん", "ー", "〜"]
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["、", "。", "？", "！", "…"]
                        caption: "、。?!"
                        onCharSelected: main.addChar(selectedChar)
                    }
                }

                // Enterキー（2行分）- 未確定中は確定、それ以外は改行
                FunctionKey {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: parent.width / 5
                    height: parent.height
                    caption: preedit !== "" ? "確定" : "改行"
                    onClicked: {
                        if (preedit !== "") {
                            main.commit()
                        } else {
                            MInputMethodQuick.sendKey(Qt.Key_Return)
                        }
                    }
                }
            }
        }

        // ==================== 英数モード ====================
        Column {
            id: alphabetMode
            width: parent.width
            visible: inputMode === "alphabet"

            // 1行目: [☆123] [記号] ABC DEF [BS]
            Row {
                width: parent.width
                height: geometry.keyHeightPortrait

                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "☆123"
                    onClicked: main.switchToSymbol()
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["@", "#", "/", "&", "_"]
                    caption: "@#/&_"
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["a", "b", "c"]
                    caption: "ABC"
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["d", "e", "f"]
                    caption: "DEF"
                    onCharSelected: main.addChar(selectedChar)
                }
                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "⌫"
                    repeat: true
                    onClicked: main.backspace()
                }
            }

            // 2行目: [ABC] GHI JKL MNO [Space]
            Row {
                width: parent.width
                height: geometry.keyHeightPortrait

                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "ABC"
                    enabled: false
                    opacity: 0.5
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["g", "h", "i"]
                    caption: "GHI"
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["j", "k", "l"]
                    caption: "JKL"
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["m", "n", "o"]
                    caption: "MNO"
                    onCharSelected: main.addChar(selectedChar)
                }
                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "空白"
                    onClicked: {
                        main.commit()
                        MInputMethodQuick.sendCommit(" ")
                    }
                }
            }

            // 3行目と4行目をラップ（Enterキー2マス対応）
            Item {
                width: parent.width
                height: geometry.keyHeightPortrait * 2

                // 3行目: [あいう] PQRS TUV WXYZ
                Row {
                    id: alphabetRow3
                    width: parent.width * 4 / 5
                    height: geometry.keyHeightPortrait

                    FunctionKey {
                        width: parent.width / 4
                        height: parent.height
                        caption: "あいう"
                        onClicked: main.switchToHiragana()
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["p", "q", "r", "s"]
                        caption: "PQRS"
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["t", "u", "v"]
                        caption: "TUV"
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["w", "x", "y", "z"]
                        caption: "WXYZ"
                        onCharSelected: main.addChar(selectedChar)
                    }
                }

                // 4行目: [←][→] [大小] '"() .,!?
                Row {
                    anchors.top: alphabetRow3.bottom
                    width: parent.width * 4 / 5
                    height: geometry.keyHeightPortrait

                    // カーソル左
                    FunctionKey {
                        width: parent.width / 8
                        height: parent.height
                        caption: "←"
                        repeat: true
                        onClicked: {
                            main.commit()
                            MInputMethodQuick.sendKey(Qt.Key_Left)
                        }
                    }
                    // カーソル右
                    FunctionKey {
                        width: parent.width / 8
                        height: parent.height
                        caption: "→"
                        repeat: true
                        onClicked: {
                            main.commit()
                            MInputMethodQuick.sendKey(Qt.Key_Right)
                        }
                    }
                    FunctionKey {
                        width: parent.width / 4
                        height: parent.height
                        caption: "A⇔a"
                        onClicked: main.toggleCase()
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["'", "\"", "(", ")"]
                        caption: "\'\"()"
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: [".", ",", "?", "!"]
                        caption: ".,?!"
                        onCharSelected: main.addChar(selectedChar)
                    }
                }

                // Enterキー（2行分）
                FunctionKey {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: parent.width / 5
                    height: parent.height
                    caption: preedit !== "" ? "確定" : "改行"
                    onClicked: {
                        if (preedit !== "") {
                            main.commit()
                        } else {
                            MInputMethodQuick.sendKey(Qt.Key_Return)
                        }
                    }
                }
            }
        }

        // ==================== 記号モード ====================
        Column {
            id: symbolMode
            width: parent.width
            visible: inputMode === "symbol"

            // 1行目: [☆123] 1 2 3 [BS]
            Row {
                width: parent.width
                height: geometry.keyHeightPortrait

                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "☆123"
                    enabled: false
                    opacity: 0.5
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["1", "☆", "♪", "→", ""]
                    caption: "1\n☆♪→"
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["2", "¥", "$", "€", ""]
                    caption: "2\n¥$€"
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["3", "%", "°", "#", ""]
                    caption: "3\n%°#"
                    onCharSelected: main.addChar(selectedChar)
                }
                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "⌫"
                    repeat: true
                    onClicked: main.backspace()
                }
            }

            // 2行目: [ABC] 4 5 6 [Space]
            Row {
                width: parent.width
                height: geometry.keyHeightPortrait

                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "ABC"
                    onClicked: main.switchToAlphabet()
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["4", "○", "*", "・", ""]
                    caption: "4\n○*・"
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["5", "+", "×", "÷", ""]
                    caption: "5\n+×÷"
                    onCharSelected: main.addChar(selectedChar)
                }
                FlickKey {
                    width: parent.width / 5
                    height: parent.height
                    chars: ["6", "<", "=", ">", ""]
                    caption: "6\n<=>"
                    onCharSelected: main.addChar(selectedChar)
                }
                FunctionKey {
                    width: parent.width / 5
                    height: parent.height
                    caption: "空白"
                    onClicked: {
                        main.commit()
                        MInputMethodQuick.sendCommit(" ")
                    }
                }
            }

            // 3行目と4行目をラップ（Enterキー2マス対応）
            Item {
                width: parent.width
                height: geometry.keyHeightPortrait * 2

                // 3行目: [あいう] 7 8 9
                Row {
                    id: symbolRow3
                    width: parent.width * 4 / 5
                    height: geometry.keyHeightPortrait

                    FunctionKey {
                        width: parent.width / 4
                        height: parent.height
                        caption: "あいう"
                        onClicked: main.switchToHiragana()
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["7", "「", "」", ":", ""]
                        caption: "7\n「」:"
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["8", "〒", "々", "〆", ""]
                        caption: "8\n〒々〆"
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["9", "^", "|", "\\", ""]
                        caption: "9\n^|\\"
                        onCharSelected: main.addChar(selectedChar)
                    }
                }

                // 4行目: [←][→] ()[] 0 .,-/
                Row {
                    anchors.top: symbolRow3.bottom
                    width: parent.width * 4 / 5
                    height: geometry.keyHeightPortrait

                    // カーソル左
                    FunctionKey {
                        width: parent.width / 8
                        height: parent.height
                        caption: "←"
                        repeat: true
                        onClicked: {
                            main.commit()
                            MInputMethodQuick.sendKey(Qt.Key_Left)
                        }
                    }
                    // カーソル右
                    FunctionKey {
                        width: parent.width / 8
                        height: parent.height
                        caption: "→"
                        repeat: true
                        onClicked: {
                            main.commit()
                            MInputMethodQuick.sendKey(Qt.Key_Right)
                        }
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["(", ")", "[", "]", ""]
                        caption: "()[]"
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: ["0", "〜", "…", "", ""]
                        caption: "0\n〜…"
                        onCharSelected: main.addChar(selectedChar)
                    }
                    FlickKey {
                        width: parent.width / 4
                        height: parent.height
                        chars: [".", ",", "-", "/", ""]
                        caption: ".,-/"
                        onCharSelected: main.addChar(selectedChar)
                    }
                }

                // Enterキー（2行分）
                FunctionKey {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    width: parent.width / 5
                    height: parent.height
                    caption: preedit !== "" ? "確定" : "改行"
                    onClicked: {
                        if (preedit !== "") {
                            main.commit()
                        } else {
                            MInputMethodQuick.sendKey(Qt.Key_Return)
                        }
                    }
                }
            }
        }
    }
}
