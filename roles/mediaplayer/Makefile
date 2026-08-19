######################################################################
# @author      : Emmanuel Roux
# @file        : Makefile
# @created     : Sam 18 déc 14:52:19 2021
######################################################################

VM_MEMORY_SIZE := 1G
PWD := $(realpath .)
RASPBIAN_BASE_URL := https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-11-08
RASPBIAN_VERSION := 2021-10-30-raspios-bullseye-armhf-lite.img

# TODO: This must be included in mlib
HTMLQ := $(shell command -v htmlq 2> /dev/null)

# ··························································
# Some gum commands
# ··························································

# List the external disks
DISKUTIL_LIST_EXTERNAL = $(shell diskutil list external | $(GREP) ^/dev | cut -d " " -f 1 | xargs)
GUM_CHOOSE_DISK = $(shell gum choose $(DISKUTIL_LIST_EXTERNAL))


# ··························································
# Get raspios archive
# ··························································
# This is the url to the latest 
RASPIOS_BASE_URL := https://downloads.raspberrypi.com/raspios_lite_arm64/images
RASPIOS_BASE_URL := "$(RASPIOS_BASE_URL)/$(shell $(CURL) -Ls  $(RASPIOS_BASE_URL)| $(HTMLQ) --attribute href a | tail -n 1)"

RASPIOS_SRC_URL := "$(RASPIOS_BASE_URL)/$(shell $(CURL) -Ls  $(RASPIOS_BASE_URL)| $(HTMLQ) --attribute href a | $(GREP) img\.xz$$)"

RASPIOS_ARCHIVE := $(XDG_CACHE_HOME)/$(shell basename $(RASPIOS_SRC_URL))
RASPIOS_IMAGE := $(RASPIOS_ARCHIVE:%.xz=%)

$(RASPIOS_ARCHIVE) $(RASPIOS_ARCHIVE).sha256: 
	@$(INFO) getting $(@F)
	@$(CURL) -Ls -o $@ $(RASPIOS_BASE_URL)/$(@F) && $(STATUS_OK) || $(STATUS_KO)
	@if [ -f $(@:%.sha256=%) -a -f $(@:%.sha256=%.sha256)  ]; then \
		$(INFO) Verifying checksum; \
		cd $(@D) && \
			sha256sum --check $(@F:%.sha256=%.sha256) >/dev/null && $(STATUS_OK) || $(STATUS_KO); \
		fi

$(RASPIOS_IMAGE): $(RASPIOS_ARCHIVE) $(RASPIOS_ARCHIVE).sha256
	@$(INFO) Uncompressing $(RASPIOS_ARCHIVE)
	@unxz -k $(RASPIOS_ARCHIVE) && $(STATUS_OK) || $(STATUS_KO)


# ··························································
# Raspios pre-configuration
# ··························································
# Settings http://rptl.io/configtxt can (and must) be adjusted
# to get a headless configuration
.PHONY: raspios.init

RASPIOS_MOUNT_POINT := /Volumes/raspios
RASPIOS_MOUNT_DISK = $(shell hdiutil attach -imagekey diskimage-class=CRawDiskImage $(RASPIOS_IMAGE) -mountpoint $(RASPIOS_MOUNT_POINT) | $(GREP) ^/dev | cut -d " " -f 1 | head -n 1)
RASPIOS_UNMOUNT_DISK = $(shell hdiutil detach $(RASPIOS_MOUNT_DISK))

$(RASPIOS_MOUNT_POINT):
	@hdiutil detach $(RASPIOS_MOUNT_DISK) && $(STATUS_OK) || $(STATUS_KO)
	@$(INFO) Mount image on $@, $(RASPIOS_MOUNT_DISK) && $(STATUS_OK) || $(STATUS_KO)

# extraconfig
$(RASPIOS_MOUNT_POINT)/extraconfig.txt: extraconfig.txt
	@$(INFO) Copying extraconfig.txt
	@cp $< $@ && $(STATUS_OK) || $(STATUS_KO)

raspios.init: $(RASPIOS_MOUNT_POINT)/extraconfig.txt

# remote connectivity
$(RASPIOS_MOUNT_POINT)/ssh:
	@$(INFO) Enabling ssh
	@touch $@ && $(STATUS_OK) || $(STATUS_KO)
raspios.init: $(RASPIOS_MOUNT_POINT)/ssh

WLAN_SSID :=
WLAN_PSK :=

define WPA_SUPPLICANT_CONF =
country=DE
update_config=1
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev

# RETROPIE CONFIG START
network={
 scan_ssid=1
 ssid="$(WLAN_SSID)"
 psk="$(WLAN_PSK)"
}
# RETROPIE CONFIG END
endef
export WPA_SUPPLICANT_CONF

# This is actually the file that is used by the Raspberry Pi to configure WiFi
RPI_CONNECTIVITY_CONF := $(RASPIOS_MOUNT_POINT)/wpa_supplicant.conf

# This is valid for mac OS only
ifeq ($(HOST_OS),darwin)
$(RPI_CONNECTIVITY_CONF): WLAN_SSID=WLAN-9KGUPU
$(RPI_CONNECTIVITY_CONF): WLAN_PSK = $(shell security find-generic-password -a $(WLAN_SSID) -gw)
$(RPI_CONNECTIVITY_CONF):
	@$(INFO) Enabling WiFi
	@echo -e "$$WPA_SUPPLICANT_CONF" > $@ && $(STATUS_OK) || $(STATUS_KO)

raspios.init: | $(RASPIOS_IMAGE) $(RASPIOS_MOUNT_POINT)
	@$(MAKE) $(RPI_CONNECTIVITY_CONF)
	@$(INFO) Unmount image and $(RASPIOS_UNMOUNT_DISK) && $(STATUS_OK) || $(STATUS_KO)


# TODO: unmount volume first
# Do not eject!
raspios.run: | $(RASPIOS_ARCHIVE)
	@$(INFO) Installing $(notdir $(RASPIOS_ARCHIVE))
	@val=$(GUM_CHOOSE_DISK) && \
		gum confirm "Confirm using $${val}?" && \
		diskutil unmountDisk "$${val}" && \
		sudo dd if=$(RASPIOS_IMAGE) of="$${val}" status=progress && \
		diskutil eject "$${val}" && $(STATUS_OK) || $(STATUS_KO)

# @val=$(GUM_CHOOSE_DISK) && \
# 	gum confirm "Confirm using $${val}?" && \
# 	( gum spin --show-output --title "Writing image to $${val}" -- \
# 	sudo dd if=$(RASPIOS_IMAGE) of="$${val}") || \
# 	( $(STATUS_KO)) 
endif

# TODO: set username and password
# TODO: WiFi credentials
# TODO: device hostname
# TODO: time zone
# TODO: keyboard layout


raspbios.distclean:
	@rm $(RASPIOS_ARCHIVE)

distclean: raspbios.distclean

# ··························································
# Some old stuff:
# ··························································
QEMU_SYSTEM := qemu-system-aarch64

RPI_MODEL := raspi2b
ifeq ($(RPI_MODEL),raspi2b)
RPI_DTB := bcm2710-rpi-2-b.dtb
QEMU_SYSTEM := qemu-system-arm
endif
# root=/dev/mmcblk0p2

vm:
	$(QEMU_SYSTEM) \
		-M $(RPI_MODEL) \
		-append "rw earlyprintk rootfstype=ext4 loglevel=8 rootwait root=/dev/mmcblk0p2 dwc_otg.lpm_enable=0" \
		-dtb $(PWD)/rpi/dtb/$(RPI_DTB) \
		-drive file=$(PWD)/$(RASPBIAN_VERSION),if=sd,format=raw \
		-kernel $(PWD)/rpi/img/kernel7.img \
		-m $(VM_MEMORY_SIZE) \
		-smp 4
