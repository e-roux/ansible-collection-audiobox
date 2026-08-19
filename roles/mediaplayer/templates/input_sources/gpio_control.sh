#!/bin/bash

disconnect_bluetooth_devices() {

    devices=$(bluetoothctl devices | awk '{print $2}')

    # Loop through each device and disconnect it
    for device in $devices; do
        echo "Disconnecting $device"
        echo -e "disconnect $device\n" | bluetoothctl
    done

    # Exit bluetoothctl
    echo -e "exit\n" | bluetoothctl
}

case "$1" in
mpd)
    # Stop Bluetooth audio
    # pactl unload-module module-loopback
    # Start MPD
    mpc play
    ;;
bluetooth)
    # Stop MPD
    mpc stop
    # Start Bluetooth audio
    pactl load-module source=luez_source.E8_78_65_81_0C_8B.a2dp_source sink=alsa_output.platform-soc_sound.stereo-fallback
    ;;
*)
    echo "Usage: $0 {mpd|bluetooth}"
    exit 1
    ;;
esac
