import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool recording: false
    property bool toggleInProgress: false
    property double lastToggleAtMs: 0

    function refreshStatus() {
        Proc.runCommand(
            "dejliGifStatus.check",
            [
                "bash",
                "-lc",
                "if [ -f /tmp/dejli-gif.state ]; then . /tmp/dejli-gif.state; if [ -n \"${RECORDER_PID:-}\" ] && kill -0 \"$RECORDER_PID\" 2>/dev/null; then echo 1; else echo 0; fi; else echo 0; fi"
            ],
            (stdout, exitCode) => {
                recording = exitCode === 0 && stdout.trim() === "1";
            },
            50
        );
    }

    function toggleRecording() {
        const now = Date.now();
        if (now - lastToggleAtMs < 700 || toggleInProgress) {
            return;
        }
        lastToggleAtMs = now;
        toggleInProgress = true;

        recording = !recording;
        Quickshell.execDetached(["/run/current-system/sw/bin/dejli-gif", "--toggle"]);
        statusRefresh.restart();
        confirmRefresh.restart();
        toggleRelease.restart();
    }

    ccWidgetIcon: recording ? "radio_button_checked" : "radio_button_unchecked"
    ccWidgetPrimaryText: "GIF"
    ccWidgetSecondaryText: recording ? "Recording" : "Idle"
    ccWidgetIsActive: recording

    onCcWidgetToggled: {
        toggleRecording();
    }

    pillClickAction: () => {
        toggleRecording();
    }

    Timer {
        interval: 1200
        running: true
        repeat: true
        onTriggered: {
            root.refreshStatus();
        }
    }

    Timer {
        id: statusRefresh
        interval: 350
        repeat: false
        onTriggered: {
            root.refreshStatus();
        }
    }

    Timer {
        id: confirmRefresh
        interval: 1000
        repeat: false
        onTriggered: {
            root.refreshStatus();
        }
    }

    Timer {
        id: toggleRelease
        interval: 1200
        repeat: false
        onTriggered: {
            root.toggleInProgress = false;
        }
    }

    Component.onCompleted: {
        refreshStatus();
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.recording ? "radio_button_checked" : "radio_button_unchecked"
                color: root.recording ? Theme.primary : Theme.surfaceVariantText
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "GIF"
                color: root.recording ? Theme.primary : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.recording ? "radio_button_checked" : "radio_button_unchecked"
                color: root.recording ? Theme.primary : Theme.surfaceVariantText
                size: Theme.iconSize - 4
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: "GIF"
                color: root.recording ? Theme.primary : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
