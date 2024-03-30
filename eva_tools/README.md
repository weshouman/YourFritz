# Files in this folder

## `eva_discover`

It is used to find and interact with the EVA bootloader of AVM devices within the network. The script accepts several parameters to control its behavior, allowing to specify details such as source and target IP addresses, network interface, and operation modes.

### In a Nutshell
- It's a script to detect a starting FRITZ!OS device in your network
- Has a BusyBox 'ash' compatible syntax
- 'socat' utility (<http://www.dest-unreach.org/socat/>) is needed for network access
- Command line parameter utilization is incomplete yet

### Parameters:

- **`FROM`**: source IP address to use for packets sent by the script. Useful if your machine has multiple IP addresses and you want to control which one is used for communication.

- **`TO`**: Specifies the IP address of the target device. This is crucial for directing the script's actions to the correct device.

- **`INTERFACE`**: Indicates the network interface the script should use to connect to the device. This is **necessary** if the system has multiple network interfaces.

- **`WAIT`**: Determines the number of discovery packets to send, with a *1-second* delay between each. This can be useful for increasing the chances of discovering the bootloader if it doesn't respond immediately.

- **`BLIP`**: Shows a visual indicator (blip) on stderr for each discovery packet sent. This provides a simple way to monitor the script's activity.

- **`HOLD`**: Instructs the bootloader to wait for FTP connections after the script has made initial contact. This option is useful for holding the device in the bootloader mode to perform firmware flashing or other recovery actions.

- **`SOCAT`**: Specifies the path to the `socat` utility if it's not in the default location. `socat` is used by the script for network communication.

### Usage Example:

From your machine's command line run. For example:

```bash
./eva_discover TO=192.168.178.1 FROM=192.168.178.2 INTERFACE=eth0 WAIT=5 HOLD=1
```

This command would attempt to discover and hold the EVA bootloader on the device with the IP address `192.168.178.1`, using `192.168.178.2` as the source IP, through the `eth0` interface, sending 5 discovery packets, and holding the device in the bootloader mode for FTP connections.

### Important Notes:

- **Restart Required**: The device needs to be restarted to activate the EVA loader. This is usually done by powering off the device and then turning it back on while holding down a specific button (e.g., the reset button) to enter the bootloader/recovery mode.
- **Multiple Interfaces**: If your system has multiple network interfaces, you may need to specify both an interface and a local IP address (`FROM`) to ensure the script can correctly identify and use the appropriate interface for communication.
- **Correct Script Usage**: The correct usage of parameters is crucial for the script's success in discovering and interacting with the EVA bootloader. Make sure to adjust the parameters based on:
    1. Your network setup.
    2. The specific requirements of your recovery or flashing session.

## `EVA-Discover.ps1`

- Powershell script to detect a booting FRITZ!Box device in your network and set up an IPv4 address for FTP access to EVA

`EVA-FTP-Client.ps1`

- Powershell script to access the FTP service provided by the bootloader (EVA) of a FRITZ!Box (and some other) device(s)
- this may be customized to run a predefined command/action sequence or you may specify a script block with the requested actions while calling it
- the following actions are predefined:
  - `GetEnvironmentFile [ "env" | "count" ]`
  - `GetEnvironmentValue <name>`
  - `SetEnvironmentValue <name> [ <value> ]`
  - `RebootTheDevice`
  - `SwitchSystem`
  - `BootDeviceFromImage <image_file>`
  - `UploadFlashFile <flash_file> <target_partition>`
  - or you may use lower-level functions to create your own actions

## `eva_get_environment`
## `eva_store_tffs`
## `eva_switch_system`
## `eva_to_memory`

- these scripts are more or less only proofs of concept, how to access the FTP server in the bootloader from a limited environment like another FRITZ!OS instance
- they are usable with BusyBox 'ash' and 'nc' applets
- there's usually no usage screen and only very limited support for error detection and notification
- an image needed for `eva_to_memory` may be created from a "normal" image (tarball) with the `image2ram` script

## `prepare_jffs2_image`

- simple script to create a JFFS2 image from predefined content
- intended to be used on a FRITZ!Box device, because the geometry of the partition to create is read from /proc/mtd

## `build_in_memory_image`

- very incomplete script to create an (universal) in-memory image from vendor's firmware
- the resulting image does not contain closed-source components, so it may be shared without copyright violations, 'cause only redistributable parts from the original firmware are used

# Other sources of information

If you need help using these files to access the FTP server of AVM's EVA loader, have a look at this thread:

https://www.ip-phone-forum.de/threads/wie-verwende-ich-denn-nun-die-skript-dateien-aus-yourfritz-eva_tools.298591/
