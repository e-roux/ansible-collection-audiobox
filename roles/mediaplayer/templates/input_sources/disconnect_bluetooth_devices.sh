set -eou pipefail
devices=$(bluetoothctl devices | awk '{print $2}')

# Loop through each device and disconnect it
for device in $devices; do
    echo "Disconnecting $device"
    echo -e "disconnect $device\n" | bluetoothctl
done

# Exit bluetoothctl
echo -e "exit\n" | bluetoothctl
