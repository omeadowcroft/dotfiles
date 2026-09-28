// Fallout-style terminal login theme for SDDM (Qt 6)
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    width: 3840
    height: 2160
    color: "#08170b"

    // ---- look ------------------------------------------------------------
    readonly property color green:  config.textColor  || "#67d97a"
    readonly property color dim:    config.dimColor   || "#2f8a45"
    readonly property color alert:  config.alertColor || "#d9d967"
    // one font "cell" = N screen pixels; integer so the pixel font stays crisp
    readonly property int cell: Math.max(1, Math.round(height / 1080))
    readonly property int fontPx: 34 * cell
    readonly property int lineH: fontPx
    readonly property int charW: 16 * cell
    readonly property string fam: fixedsys.name

    FontLoader { id: fixedsys; source: "fonts/FixedsysExcelsior.ttf" }

    // ---- state -----------------------------------------------------------
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property int attempts: 4
    property string status: ""
    property bool busy: false

    function userName(i)    { userNames.count; var it = userNames.itemAt(i);    return it ? it.n : "" }
    function sessionName(i) { sessionNames.count; var it = sessionNames.itemAt(i); return it ? it.n : "" }

    Item {
        visible: false
        Repeater { id: userNames;    model: userModel;    delegate: Item { property string n: model.name } }
        Repeater { id: sessionNames; model: sessionModel; delegate: Item { property string n: model.name } }
    }

    function doLogin() {
        if (busy || userField.text.length === 0) return
        busy = true
        status = "> VERIFYING..."
        sddm.login(userField.text, passField.text, sessionIndex)
    }
    function cycleSession() {
        if (sessionNames.count > 0) sessionIndex = (sessionIndex + 1) % sessionNames.count
    }
    function cycleUser() {
        if (userNames.count > 0) {
            userIndex = (userIndex + 1) % userNames.count
            userField.text = userName(userIndex)
            passField.forceActiveFocus()
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            busy = false
            attempts = attempts > 1 ? attempts - 1 : 4
            status = attempts === 1 ? "!!! WARNING: LOCKOUT IMMINENT !!!" : "> ENTRY DENIED"
            passField.text = ""
            passField.forceActiveFocus()
        }
        function onLoginSucceeded() { status = "> EXACT MATCH! PLEASE WAIT WHILE SYSTEM IS ACCESSED." }
    }

    // ---- CRT glass ---------------------------------------------------------
    Image {
        anchors.fill: parent
        source: config.background || "background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: false
    }

    // ---- terminal content (glow applied to the whole block) ----------------
    Item {
        id: screen
        anchors.fill: parent
        anchors.margins: parent.height * 0.08
        anchors.leftMargin: parent.width * 0.07
        anchors.rightMargin: parent.width * 0.07

        layer.enabled: (config.glow || "true") === "true" && GraphicsInfo.api !== GraphicsInfo.Software
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: root.green
            shadowBlur: 0.5
            shadowOpacity: 0.55
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        component T: Text {
            font.family: root.fam
            font.pixelSize: root.fontPx
            color: root.green
            renderType: Text.NativeRendering
        }

        // header
        Column {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            Row {
                T { text: config.headerBrand || "VAULT SYSTEMS" }
                TM {}
                T { text: " " + (config.headerUnit || "UNIT • 42 TERMINAL") }
            }
            T { text: config.headerLine2 || "PLEASE STAND BY" }
            Item { width: 1; height: root.lineH }
            Row {
                spacing: root.charW
                T { text: root.attempts + " ATTEMPT(S) LEFT:" }
                Repeater {
                    model: root.attempts
                    Rectangle { width: root.charW; height: root.lineH * 0.8; y: root.lineH * 0.05; color: root.green }
                }
            }
        }

        T {
            id: clock
            anchors.top: parent.top
            anchors.right: parent.right
            horizontalAlignment: Text.AlignRight
            function tick() { text = Qt.formatDateTime(new Date(), "dd/MM/yyyy\nHH:mm:ss") }
            Component.onCompleted: tick()
            Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.tick() }
        }

        // boot log, typed out on start (one shared character counter)
        Column {
            id: bootLog
            anchors.top: header.bottom
            anchors.topMargin: root.lineH
            anchors.left: parent.left
            property string a: "> " + (config.headerBrand || "VAULT SYSTEMS")
            property string b: "TM"
            property string c: " MF BOOT AGENT"
            property string rest:
                "  LINUX KERNEL ............. LOADED\n" +
                "  NVIDIA-DRM MODESET ....... ENABLED\n" +
                "  " + (root.sessionName(root.sessionIndex).toUpperCase() + " COMPOSITOR ").padEnd(26, ".") + " STANDBY\n" +
                "  HOST ..................... " + sddm.hostName.toUpperCase()
            readonly property int total: a.length + b.length + c.length + rest.length
            property int shown: 0
            function part(str, start) { return str.substring(0, Math.max(0, shown - start)) }
            readonly property bool done: shown >= total
            Row {
                T { color: root.dim; text: bootLog.part(bootLog.a, 0) }
                TM { color: root.dim; text: bootLog.part(bootLog.b, bootLog.a.length) }
                T { color: root.dim; text: bootLog.part(bootLog.c, bootLog.a.length + bootLog.b.length) }
            }
            T { color: root.dim; text: bootLog.part(bootLog.rest, bootLog.a.length + bootLog.b.length + bootLog.c.length) }
            Timer {
                interval: 12; running: !bootLog.done; repeat: true
                onTriggered: bootLog.shown += 2
            }
        }

        // logon prompt
        Column {
            id: prompt
            anchors.top: bootLog.bottom
            anchors.topMargin: root.lineH * 2
            anchors.left: parent.left
            opacity: bootLog.done ? 1 : 0

            Row {
                T { text: "> LOGON " }
                TextInput {
                    id: userField
                    font.family: root.fam; font.pixelSize: root.fontPx
                    color: root.green; selectionColor: root.green; selectedTextColor: "#08170b"
                    renderType: Text.NativeRendering
                    width: root.charW * 24
                    text: userModel.lastUser || root.userName(root.userIndex)
                    font.capitalization: Font.AllUppercase
                    cursorDelegate: BlockCursor { visible: userField.activeFocus }
                    KeyNavigation.tab: passField
                    onAccepted: passField.forceActiveFocus()
                }
            }
            Row {
                T { text: "> PASSWORD: " }
                TextInput {
                    id: passField
                    font.family: root.fam; font.pixelSize: root.fontPx
                    color: root.green
                    renderType: Text.NativeRendering
                    width: root.charW * 32
                    echoMode: TextInput.Password
                    passwordCharacter: "*"
                    passwordMaskDelay: 0
                    focus: true
                    enabled: !root.busy
                    cursorDelegate: BlockCursor { visible: passField.activeFocus }
                    KeyNavigation.tab: userField
                    onAccepted: root.doLogin()
                }
            }
            Item { width: 1; height: root.lineH }
            T {
                text: root.status
                color: root.status.indexOf("WARNING") >= 0 ? root.alert : root.green
                SequentialAnimation on opacity {
                    running: root.status.indexOf("WARNING") >= 0
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.2; duration: 450 }
                    NumberAnimation { to: 1;   duration: 450 }
                }
            }
            T {
                visible: keyboard.capsLock
                color: root.alert
                text: "> CAPS LOCK ENGAGED"
            }
        }

        // footer: clickable, and bound to F-keys
        Row {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            spacing: root.charW * 3

            component Btn: T {
                id: b
                signal clicked()
                property bool hot: ma.containsMouse
                color: hot ? "#08170b" : root.green
                Rectangle { anchors.fill: parent; color: root.green; z: -1; visible: b.hot }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
            }

            Btn { text: "[F1] SESSION: " + root.sessionName(root.sessionIndex).toUpperCase(); onClicked: root.cycleSession() }
            Btn { text: "[F2] USER"; visible: userNames.count > 1; onClicked: root.cycleUser() }
            Btn { text: "[F11] REBOOT";   visible: sddm.canReboot;   onClicked: sddm.reboot() }
            Btn { text: "[F12] SHUTDOWN"; visible: sddm.canPowerOff; onClicked: sddm.powerOff() }
        }

        T {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            color: root.dim
            text: {
                try { return "KB: " + keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() }
                catch (e) { return "" }
            }
        }
    }

    // small superscript "TM": half-size so the pixel font stays on an integer grid at 4K
    component TM: Text {
        text: "TM"
        font.family: root.fam
        font.pixelSize: root.fontPx / 2
        color: root.green
        renderType: Text.NativeRendering
    }

    component BlockCursor: Rectangle {
        width: root.charW
        height: root.lineH
        color: root.green
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 1; duration: 0 }
            PauseAnimation  { duration: 530 }
            NumberAnimation { to: 0; duration: 0 }
            PauseAnimation  { duration: 530 }
        }
    }

    // ---- CRT effects: rolling bright band + faint flicker -----------------
    Rectangle {
        width: parent.width
        height: parent.height * 0.18
        opacity: 0.06
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: root.green }
            GradientStop { position: 1.0; color: "transparent" }
        }
        NumberAnimation on y {
            from: -root.height * 0.2; to: root.height
            duration: 7000; loops: Animation.Infinite
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0; duration: 90 }
            NumberAnimation { to: 0;     duration: 140 }
            PauseAnimation  { duration: 2300 }
            NumberAnimation { to: 0;  duration: 60 }
            NumberAnimation { to: 0;     duration: 60 }
            PauseAnimation  { duration: 4100 }
        }
    }

    // hide the mouse pointer everywhere (topmost item with a cursor wins; NoButton lets clicks through)
    MouseArea {
        anchors.fill: parent
        z: 1000
        enabled: (config.hideCursor || "true") === "true"
        acceptedButtons: Qt.NoButton
        hoverEnabled: true
        cursorShape: Qt.BlankCursor
    }

    // global keys
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_F1)       { cycleSession(); event.accepted = true }
        else if (event.key === Qt.Key_F2)  { cycleUser(); event.accepted = true }
        else if (event.key === Qt.Key_F11) { sddm.reboot(); event.accepted = true }
        else if (event.key === Qt.Key_F12) { sddm.powerOff(); event.accepted = true }
    }
    focus: true

    Component.onCompleted: {
        if (userField.text.length === 0) userField.forceActiveFocus()
        else passField.forceActiveFocus()
    }
}
