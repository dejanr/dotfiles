import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "tailscale"

    StyledText {
        width: parent.width
        text: "Tailscale config"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Click the widget in your bar/control center to toggle Tailscale."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText {
        width: parent.width
        text: "For non-root toggling, run once: sudo tailscale set --operator=$USER"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.warningText
        wrapMode: Text.WordWrap
    }

    SliderSetting {
        settingKey: "refreshInterval"
        label: "Refresh Interval"
        description: "Status refresh interval (seconds)."
        defaultValue: 5
        minimum: 1
        maximum: 600
        unit: "sec"
        leftIcon: "schedule"
    }

    StringSetting {
        settingKey: "upCommand"
        label: "Connect Command"
        description: "Shell command used to connect Tailscale."
        placeholder: "tailscale up"
        defaultValue: "tailscale up"
    }

    StringSetting {
        settingKey: "downCommand"
        label: "Disconnect Command"
        description: "Shell command used to disconnect Tailscale."
        placeholder: "tailscale down --accept-risk=lose-ssh"
        defaultValue: "tailscale down --accept-risk=lose-ssh"
    }
}
