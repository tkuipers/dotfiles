// Floating pill tabs for Hyprland window groups, drawn over the (invisible)
// stock groupbar. Each pill is centred at (i + 1/2)/n of the group's width,
// sized to its title up to the width of "Chat | Settings | Microsoft Teams",
// and longer titles scroll back and forth inside it.
// Left click switches tab, middle click closes that window.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Must match group.groupbar.height in hyprland.lua; the pills fill this strip
    readonly property int stripHeight: 22
    readonly property int pillHeight: 20
    readonly property int pad: 10
    readonly property int gap: 6
    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize: 12
    readonly property string widest: "Chat | Settings | Microsoft Teams"

    // Theme palette, re-read whenever theme-apply rewrites it
    property var pal: ({})
    function c(name, fallback) { return pal[name] || fallback }
    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.local/state/theme/palette.sh"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const p = {}
            for (const line of text().split("\n")) {
                const m = line.match(/^(\w+)=(#[0-9a-fA-F]{6})/)
                if (m) p[m[1]] = m[2]
            }
            root.pal = p
        }
    }

    // groups: key (first member address) -> { monitor, x, y, w, tabs: [{address, title, current}] }
    property var groups: ({})
    property var groupKeys: []

    function parse(out) {
        const parts = out.split("\x1e")
        let clients, monitors
        try {
            clients = JSON.parse(parts[0])
            monitors = JSON.parse(parts[1])
        } catch (e) {
            return
        }
        const mons = {}
        const visible = {}
        for (const m of monitors) {
            mons[m.id] = m
            visible[m.activeWorkspace.id] = true
            if (m.specialWorkspace && m.specialWorkspace.id !== 0) visible[m.specialWorkspace.id] = true
        }
        const byAddr = {}
        for (const cl of clients) byAddr[cl.address] = cl

        const next = {}
        for (const cl of clients) {
            if (!cl.grouped || cl.grouped.length < 2 || cl.grouped[0] !== cl.address) continue
            const members = cl.grouped.map(a => byAddr[a]).filter(Boolean)
            if (members.length < 2) continue
            // The tab in front is the group member focused most recently
            let cur = members[0]
            for (const mb of members) if (mb.focusHistoryID < cur.focusHistoryID) cur = mb
            if (!visible[cur.workspace.id] || cur.fullscreen > 0 || !cur.mapped) continue
            const mon = mons[cur.monitor]
            if (!mon) continue
            next[cl.address] = {
                monitor: mon.name,
                x: cur.at[0] - mon.x,
                y: cur.at[1] - mon.y - stripHeight - 2,
                w: cur.size[0],
                tabs: members.map(mb => ({ address: mb.address, title: mb.title || mb.class, current: mb === cur })),
            }
        }
        root.groups = next
        const keys = Object.keys(next).sort()
        if (JSON.stringify(keys) !== JSON.stringify(root.groupKeys)) root.groupKeys = keys
    }

    Process {
        id: query
        command: ["sh", "-c", "hyprctl -j clients; printf '\\036'; hyprctl -j monitors"]
        stdout: StdioCollector { onStreamFinished: root.parse(this.text) }
    }
    function refresh() { if (!query.running) query.running = true; else again.restart() }
    // Query once right away, and again once window animations have settled
    Timer { id: soon; interval: 30; onTriggered: { root.refresh(); settle.restart() } }
    Timer { id: settle; interval: 450; onTriggered: root.refresh() }
    Timer { id: again; interval: 60; onTriggered: root.refresh() }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") paletteFile.reload()
            soon.restart()
        }
    }
    Component.onCompleted: refresh()

    function dispatch(lua) {
        Quickshell.execDetached(["hyprctl", "dispatch", lua])
    }

    TextMetrics { id: widestMetrics; font.family: root.fontFamily; font.pixelSize: root.fontSize; font.weight: Font.Bold; text: root.widest }

    Variants {
        model: root.groupKeys

        PanelWindow {
            id: strip
            required property string modelData
            readonly property var g: root.groups[modelData] || null

            visible: g !== null
            screen: Quickshell.screens.find(s => g && s.name === g.monitor) || Quickshell.screens[0]
            WlrLayershell.namespace: "grouptabs"
            WlrLayershell.layer: WlrLayer.Top
            exclusionMode: ExclusionMode.Ignore
            anchors { top: true; left: true }
            margins { top: g ? g.y : 0; left: g ? g.x : 0 }
            implicitWidth: g ? g.w : 1
            implicitHeight: root.stripHeight
            color: "transparent"

            Repeater {
                model: strip.g ? strip.g.tabs : []

                Rectangle {
                    id: pill
                    required property var modelData
                    required property int index
                    readonly property int n: strip.g ? strip.g.tabs.length : 1
                    readonly property real slot: strip.width / n
                    readonly property real maxW: widestMetrics.advanceWidth + 2 * root.pad
                    readonly property real wanted: label.implicitWidth + 2 * root.pad
                    readonly property bool overflow: wanted > width + 0.5

                    width: Math.max(root.pillHeight, Math.min(wanted, maxW, slot - root.gap))
                    height: root.pillHeight
                    x: (index + 0.5) * slot - width / 2
                    y: (root.stripHeight - height) / 2
                    radius: height / 2
                    clip: true
                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                    Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                    // Same fill as waybar's workspace buttons: surface0 glass, surface2 on
                    // hover, and the tab in front tinted with the accent
                    readonly property bool current: modelData.current
                    color: hover.hovered ? Qt.alpha(root.c("surface2", "#524b7a"), 0.8)
                                         : Qt.alpha(root.c("surface0", "#29263c"), 0.6)
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Qt.alpha(root.c("lavender", "#61ffca"), 0.16)
                        opacity: pill.current ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 300 } }
                    }
                    // ...and the gradient line along the bottom, drawing in from the left
                    Rectangle {
                        height: 2
                        width: pill.current ? pill.width * 0.7 : 0
                        x: (pill.width - pill.width * 0.7) / 2
                        y: pill.height - height - 1
                        radius: 1
                        Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: root.c("lavender", "#61ffca") }
                            GradientStop { position: 0.5; color: root.c("mauve", "#a277ff") }
                            GradientStop { position: 1; color: root.c("sapphire", "#6fd3ff") }
                        }
                    }

                    // Border: a soft glass rim with a brighter top edge; the tab in front
                    // gets the window border's lavender-mauve-sapphire gradient instead
                    Canvas {
                        id: rim
                        z: 1
                        anchors.fill: parent
                        readonly property var cols: [root.pal, pill.current, hover.hovered, width]
                        onColsChanged: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d")
                            ctx.reset()
                            const w = width, h = height, r = h / 2 - 0.5
                            ctx.beginPath()
                            ctx.moveTo(r + 0.5, 0.5)
                            ctx.lineTo(w - r - 0.5, 0.5)
                            ctx.arc(w - r - 0.5, h / 2, r, -Math.PI / 2, Math.PI / 2)
                            ctx.lineTo(r + 0.5, h - 0.5)
                            ctx.arc(r + 0.5, h / 2, r, Math.PI / 2, Math.PI * 1.5)
                            ctx.closePath()
                            ctx.lineWidth = 1
                            if (pill.current) {
                                const g = ctx.createLinearGradient(0, 0, w, h)
                                g.addColorStop(0, root.c("lavender", "#61ffca"))
                                g.addColorStop(0.5, root.c("mauve", "#a277ff"))
                                g.addColorStop(1, root.c("sapphire", "#6fd3ff"))
                                ctx.strokeStyle = g
                                ctx.globalAlpha = hover.hovered ? 1 : 0.85
                            } else {
                                const g = ctx.createLinearGradient(0, 0, 0, h)
                                g.addColorStop(0, Qt.alpha(root.c("overlay1", "#77748a"), hover.hovered ? 0.9 : 0.6))
                                g.addColorStop(1, Qt.alpha(root.c("surface1", "#3d375e"), hover.hovered ? 0.7 : 0.4))
                                ctx.strokeStyle = g
                            }
                            ctx.stroke()
                        }
                    }

                    // Text is clipped a few px inside the rim, so a scrolling title is cut
                    // off just short of the edge instead of running into it
                    Item {
                        id: textClip
                        x: 4
                        width: pill.width - 8
                        height: pill.height
                        clip: true
                        Text {
                            id: label
                            text: pill.modelData.title
                            font.family: root.fontFamily
                            font.pixelSize: root.fontSize
                            font.weight: pill.current ? Font.Bold : Font.Medium
                            color: pill.current ? root.c("lavender", "#61ffca") : root.c("text", "#edecee")
                            Behavior on color { ColorAnimation { duration: 300 } }
                            anchors.verticalCenter: parent.verticalCenter
                            x: (pill.overflow ? root.pad + scroll.offset : (pill.width - implicitWidth) / 2) - textClip.x

                            // Ping-pong scroll for titles wider than the pill
                            QtObject { id: scroll; property real offset: 0 }
                            SequentialAnimation {
                                running: pill.overflow
                                loops: Animation.Infinite
                                onRunningChanged: if (!running) scroll.offset = 0
                                PauseAnimation { duration: 1500 }
                                NumberAnimation {
                                    target: scroll; property: "offset"
                                    to: pill.width - 2 * root.pad - label.implicitWidth
                                    duration: Math.max(600, (label.implicitWidth - pill.width + 2 * root.pad) * 30)
                                    easing.type: Easing.InOutSine
                                }
                                PauseAnimation { duration: 1500 }
                                NumberAnimation {
                                    target: scroll; property: "offset"; to: 0
                                    duration: Math.max(600, (label.implicitWidth - pill.width + 2 * root.pad) * 30)
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }

                    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.dispatch("hl.dsp.focus({ window = 'address:" + pill.modelData.address + "' })")
                    }
                    TapHandler {
                        acceptedButtons: Qt.MiddleButton
                        onTapped: root.dispatch("hl.dsp.window.close({ window = 'address:" + pill.modelData.address + "' })")
                    }
                }
            }
        }
    }
}
