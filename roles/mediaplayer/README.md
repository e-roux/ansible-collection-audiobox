# Ansible Role: Mediaplayer

Ansible role to install
[Mediaplayer](https://github.com/PeteManchester/MediaPlayer) on a Raspberry pi.

## Requirements

This role suppose a raspberry pi working installation.

### Raspberry Pi OS installation

#### Step-by-step installation

Raspberry Pi OS can be retrieved from the [download
page](https://downloads.raspberrypi.com/raspios_lite_arm64/images/). For a
headless installation on RPI4:

```shell
curl --create-dirs -o ~/.cache/raspi-arm64-lite.img.xz -L http://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2023-12-11/2023-12-11-raspios-bookworm-arm64-lite.img.xz
```

The image must be written to a storage disk. On Unix like systems, this should work. 

```shell
sudo dd if=~/.cache/raspi-arm64-lite.img.xz of=/dev/sdX bs=4M status=progress
```

```warning
Ensure the proper disk `/dev/sdX` or `/dev/diskX` is beeing selected. On mac OS, external disk can be listed with `diskutil list external`. Pick-up the appropriate disk number 
```

#### Automatic setup

An experimental `Makefile` is provided. It basically perform the step-by-step installation commands. 


#### WiFi

[Create a file](https://retropie.org.uk/docs/Wifi/#connecting-to-wifi-without-a-keyboard) and fill appropriatly. `RETROCOPIE` comments must be included.

```conf
country=US
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1

# RETROPIE CONFIG START
network={
    ssid="your_real_wifi_ssid"
    psk="your_real_password"
}
# RETROPIE CONFIG END
```


## Role Variables

## Dependencies

## Example Playbook

```yaml
- hosts: servers
  roles:
    - role: fesaille.mediaplayer
      log_file_level: error
      log_file_name: /var/log/mediaplayer.log
      mediaplayer_enable_avTransport: false
      mediaplayer_friendly_name: Salon
      mediaplayer_startup_volume: 10
```

## License

BSD

## Author Information
