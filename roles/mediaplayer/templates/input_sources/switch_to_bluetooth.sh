#!/bin/bash

set -eou pipefail

# Stop MPD
mpc stop
# Start Bluetooth audio
pactl load-module source=bluez_source.E8:78:65:81:0C:8B sink=alsa_output.platform-snd_rpi_hifiberry_amp.analog-stereo
