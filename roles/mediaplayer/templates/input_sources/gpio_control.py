import subprocess

from gpiozero import Button


def switch_to_mpd():
    subprocess.call([
        "{{ mediaplayer_install_location }}/mediaplayer/scripts/gpio_control.sh",
        "mpd",
    ])


def switch_to_bluetooth():
    subprocess.call([
        "{{ mediaplayer_install_location }}/mediaplayer/scripts/gpio_control.sh",
        "bluetooth",
    ])


mpd_button = Button(9)
bluetooth_button = Button(10)

mpd_button.when_pressed = switch_to_mpd
bluetooth_button.when_pressed = switch_to_bluetooth
