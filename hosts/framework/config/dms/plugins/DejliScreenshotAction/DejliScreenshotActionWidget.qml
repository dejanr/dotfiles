import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool activePulse: false
    property bool triggerInProgress: false
    property double lastTriggerAtMs: 0

    function takeScreenshot() {
        const now = Date.now();
        if (now - lastTriggerAtMs < 500 || triggerInProgress) {
            return;
        }
        lastTriggerAtMs = now;
        triggerInProgress = true;

        activePulse = true;
        Quickshell.execDetached(["/run/current-system/sw/bin/dejli-screenshot"]);
        pulseReset.restart();
    }

    ccWidgetIcon: "photo_camera"
    ccWidgetPrimaryText: "Screenshot"
    ccWidgetSecondaryText: activePulse ? "Capturing" : "Capture"
    ccWidgetIsActive: activePulse

    onCcWidgetToggled: {
        takeScreenshot();
    }

    pillClickAction: () => {
        takeScreenshot();
    }

    Timer {
        id: pulseReset
        interval: 1200
        repeat: false
        onTriggered: {
            root.activePulse = false;
            root.triggerInProgress = false;
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: "photo_camera"
                color: root.activePulse ? Theme.primary : Theme.surfaceVariantText
                size: Theme.iconSize - 4
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: "SHOT"
                color: root.activePulse ? Theme.primary : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: "photo_camera"
                color: root.activePulse ? Theme.primary : Theme.surfaceVariantText
                size: Theme.iconSize - 4
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: "SHOT"
                color: root.activePulse ? Theme.primary : Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
