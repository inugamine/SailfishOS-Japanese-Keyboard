import QtQuick 2.0
import Sailfish.Silica 1.0
import com.meego.maliitquick 1.0
import com.jolla.keyboard 1.0

// 機能キー（カーソル移動、モード切替など）
Item {
    id: funcKey
    
    property string caption: ""
    property bool repeat: false  // 長押しリピート有効
    property int repeatDelay: 500  // リピート開始までの遅延（ミリ秒）
    property int repeatInterval: 50  // リピート間隔（ミリ秒）
    
    signal clicked()
    
    // 長押し開始タイマー
    Timer {
        id: repeatDelayTimer
        interval: funcKey.repeatDelay
        repeat: false
        onTriggered: {
            if (funcKey.repeat && mouseArea.pressed) {
                repeatTimer.start()
            }
        }
    }
    
    // リピートタイマー
    Timer {
        id: repeatTimer
        interval: funcKey.repeatInterval
        repeat: true
        onTriggered: {
            if (mouseArea.pressed) {
                funcKey.clicked()
            } else {
                repeatTimer.stop()
            }
        }
    }
    
    // キーの背景
    Rectangle {
        anchors.fill: parent
        color: mouseArea.pressed ? Theme.highlightBackgroundColor : Theme.rgba(Theme.primaryColor, 0.1)
        opacity: mouseArea.pressed ? 0.5 : 1.0
        
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
        text: funcKey.caption
        color: Theme.primaryColor
        font.pixelSize: Theme.fontSizeMedium
        font.family: Theme.fontFamily
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        
        onPressed: {
            if (funcKey.repeat) {
                repeatDelayTimer.start()
            }
        }
        
        onReleased: {
            repeatDelayTimer.stop()
            repeatTimer.stop()
        }
        
        onCanceled: {
            repeatDelayTimer.stop()
            repeatTimer.stop()
        }
        
        onClicked: funcKey.clicked()
    }
}
