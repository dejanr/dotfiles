import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io

PluginComponent {
    id: root

    property bool isConnected: false
    property bool toggleInProgress: false
    property int refreshInterval: pluginData.refreshInterval || 5
    property string upCommand: pluginData.upCommand || "tailscale up"
    property string downCommand: pluginData.downCommand || "tailscale down --accept-risk=lose-ssh"

    ccWidgetIcon: isConnected ? "vpn_key" : "vpn_key_off"
    ccWidgetPrimaryText: "Tailscale"
    ccWidgetSecondaryText: toggleInProgress ? "Working..." : (isConnected ? "Connected" : "Disconnected")
    ccWidgetIsActive: isConnected || toggleInProgress

    onCcWidgetToggled: {
        toggleTailscale();
    }

    pillClickAction: () => {
        toggleTailscale();
    }

    Timer {
        interval: root.refreshInterval * 1000
        running: true
        repeat: true
        onTriggered: statusCheck.running = true
    }

    Process {
        id: statusCheck
        command: ["tailscale", "status", "--json"]
        running: true

        property bool showToast: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.isConnected = data.BackendState === "Running";
                } catch (e) {
                    root.isConnected = false;
                }
                if (statusCheck.showToast) {
                    ToastService.showInfo(root.isConnected ? "Tailscale Connected" : "Tailscale Disconnected");
                    statusCheck.showToast = false;
                }
            }
        }
    }

    Process {
        id: toggleProcess

        property string errorOutput: ""

        stderr: StdioCollector {
            onStreamFinished: {
                toggleProcess.errorOutput = text.trim();
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.toggleInProgress = false;

            if (exitCode !== 0) {
                const message = toggleProcess.errorOutput || "Command failed with exit code " + exitCode;
                ToastService.showError("Tailscale toggle failed", message);
                statusCheck.showToast = false;
                statusCheck.running = true;
                return;
            }

            statusCheck.showToast = true;
            statusCheck.running = true;
        }
    }

    function toggleTailscale() {
        if (root.toggleInProgress) {
            return;
        }

        root.toggleInProgress = true;
        toggleProcess.errorOutput = "";
        toggleProcess.command = ["sh", "-lc", root.isConnected ? root.downCommand : root.upCommand];
        toggleProcess.running = true;
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.isConnected ? "vpn_key" : "vpn_key_off"
                size: Theme.iconSize - 6
                color: root.isConnected ? Theme.primary : Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.isConnected ? "vpn_key" : "vpn_key_off"
                size: Theme.iconSize - 6
                color: root.isConnected ? Theme.primary : Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
