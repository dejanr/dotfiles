#!/usr/bin/env zsh

update_space() {
    echo "INFO: $INFO"
    SPACE_ID=$(echo "$INFO" | jq -r '."display-1"')
    echo "SPACE_ID: $SPACE_ID"

    case $SPACE_ID in
    5)
        ICON=󰅶
        ICON_PADDING_LEFT=7
        ICON_PADDING_RIGHT=7
        ;;
    *)
        ICON=$SPACE_ID
        ICON_PADDING_LEFT=9
        ICON_PADDING_RIGHT=10
        ;;
    esac

    echo "ICON: $ICON"
    echo "ICON_PADDING_LEFT: $ICON_PADDING_LEFT"
    echo "ICON_PADDING_RIGHT: $ICON_PADDING_RIGHT"

    /opt/homebrew/opt/sketchybar/bin/sketchybar --set $NAME \
        icon=$ICON \
        icon.padding_left=$ICON_PADDING_LEFT \
        icon.padding_right=$ICON_PADDING_RIGHT
}

echo "SENDER: $SENDER"
echo "NAME: $NAME"

case "$SENDER" in
*)
    update_space
    ;;
esac
