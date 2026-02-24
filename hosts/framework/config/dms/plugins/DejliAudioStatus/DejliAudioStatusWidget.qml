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
            "dejliAudioStatus.check",
            [
                "bash",
                "-lc",
                "if [ -f /tmp/dejli-audio.state ]; then . /tmp/dejli-audio.state; if [ -n \"${FFMPEG_PID:-}\" ] && kill -0 \"$FFMPEG_PID\" 2>/dev/null; then echo 1; else echo 0; fi; else echo 0; fi"
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
        Quickshell.execDetached(["/run/current-system/sw/bin/dejli-audio", "--toggle"]);
        statusRefresh.restart();
        confirmRefresh.restart();
        toggleRelease.restart();
    }

    ccWidgetIcon: recording ? "mic" : "mic_off"
    ccWidgetPrimaryText: "Audio"
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
                name: root.recording ? "mic" : "mic_off"
                color: root.recording ? Theme.primary : Theme.surfaceVariantText
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "AUD"
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
                name: root.recording ? "mic" : "mic_off"
                color: root.recording ? Theme.primary : Theme.surfaceVariantText
                size: Theme.iconSize - 4
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: "AUD"
                color: root.recording ? Theme.primary : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
