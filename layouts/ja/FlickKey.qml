import QtQuick 2.0
import Sailfish.Silica 1.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0

// フリック入力対応キー
Item {
    id: flickKey
    
    // フリック文字の定義: [中央, 左, 上, 右, 下]
    property var chars: ["", "", "", "", ""]
    
    // 表示用のキャプション（デフォルトは中央の文字）
    property string caption: chars[0]
    
    // フリック判定の閾値（ピクセル）
    property int flickThreshold: 25
    
    // 文字が選択されたときのシグナル
    signal charSelected(string selectedChar)
    
    // キーの背景
    Rectangle {
        anchors.fill: parent
        color: mouseArea.pressed ? Theme.highlightBackgroundColor : "transparent"
        opacity: mouseArea.pressed ? 0.3 : 1.0
        
        // キーの区切り線
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Theme.primaryColor
            opacity: 0.1
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Theme.primaryColor
            opacity: 0.1
        }
    }
    
    // キーのラベル
    Text {
        anchors.centerIn: parent
        text: flickKey.caption
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeLarge
        font.family: Theme.fontFamily
    }
    
    // タッチ処理
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        
        property real startX: 0
        property real startY: 0
        
        onPressed: {
            startX = mouse.x
            startY = mouse.y
        }
        
        onReleased: {
            var dx = mouse.x - startX
            var dy = mouse.y - startY
            var absDx = Math.abs(dx)
            var absDy = Math.abs(dy)
            
            var result = ""
            
            if (absDx < flickThreshold && absDy < flickThreshold) {
                // タップ → 中央
                if (chars[0] !== "") result = chars[0]
            } else if (absDx > absDy) {
                // 横フリック
                if (dx < 0 && chars.length > 1 && chars[1] !== "") {
                    result = chars[1]  // 左
                } else if (dx > 0 && chars.length > 3 && chars[3] !== "") {
                    result = chars[3]  // 右
                }
            } else {
                // 縦フリック
                if (dy < 0 && chars.length > 2 && chars[2] !== "") {
                    result = chars[2]  // 上
                } else if (dy > 0 && chars.length > 4 && chars[4] !== "") {
                    result = chars[4]  // 下
                }
            }
            
            if (result !== "") {
                flickKey.charSelected(result)
            }
        }
    }
}
