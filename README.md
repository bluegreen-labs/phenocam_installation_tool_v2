# PhenoCam Installation Tool (PIT) v2

PhenoCam Installation Tool (PIT) is a set of scripts to configure Stardot Netcam Live 2 for the use as a phenocam associated with the [PhenoCam network](http://phenocam.nau.edu). Version 2 addresses the installation routine for the Stardot Netcam Live 2 cameras which supercede the previous default Netcam SC5 cameras within the PhenoCam network. This software is a collaboration between BlueGreen Labs (bv) and the PhenoCam US network. It would be appreciated that if custom changes are required you hire BlueGreen Labs in a consulting context.

> [!warning]
> The default password on the Stardot cameras is INSECURE. Connecting any camera to an open network, without a firewall, will result in your camera being hacked (with [estimated times to infection](https://www.pcgamer.com/hardware/a-windows-xp-machines-life-expectancy-in-2024-seems-to-be-about-10-minutes-before-even-just-an-idle-net-connection-renders-it-a-trojan-riddled-zombie-pc/) ~ 10 min). 
> 
> To configure the camera: 
> 1) hook up the camera to an unconnected router 
> 2) change the default password to a strong password which is unlikely to be brute forced (i.e. 12+ characters in a mix of letters/numbers/special characters) 
> 3) configure the camera using this software 
> 4) connect the camera and verify uploads to the PhenoCam server.
> 
> ALWAYS configure the camera password to a non-default secure password over a secure network. BlueGreen Labs (BV) is not liable for the abuse of misconfigured cameras as a vector for network breaches and cyber-attacks due to lack of due diligence on part of the user.

## Installation

### Hardware prerequisites

Please connect a computer and the PhenoCam to the same (wireless) router which has **NO** internet access (see warnings regarding the default password above - make sure to set a strong password before the camera is exposed to an unprotected network). Once your camera is powered on and connected to the network you will need to find your camera’s network IP address. Make sure that the computer you are using was able to connect to the network and got an IP via DHCP.

The easiest way to find the camera’s IP address is to install [StarDot Tools](http://www.stardot.com/downloads). Run the StarDot Tools program and click “refresh”. The camera should be detected and the camera’s IP address shown (you may have to run Tools as administrator in Windows, depending on your settings).

If you are configuring your camera with a non-Windows computer there are other things you can do to find the IP address of the camera. From a Linux or Mac OS X terminal window you should be able to type the following commands (assuming `192.168.1.255` is the network broadcast address reported by `ifconfig`):

```bash
ping -c 3 -b 192.168.1.255
arp -a
```

to get a list of the MAC addresses and IP’s of all the computers on the local network. The StarDot cameras have a MAC address that starts with 00:30 so you may be able to find the camera that way. Again, you may need help from the local network administrator for this step.

### Software prerequisites

For the script to run successfully you will need an `ssh` client and bash support, these are included in both MacOS and Linux default installs and can be provided in Windows by [using the linux subsystem](https://learn.microsoft.com/en-us/windows/wsl/install). 

You can download this required repository by either a direct download of a [zip file](https://github.com/bluegreen-labs/phenocam_installation_tool_v2/), or if you have git running by cloning the branch with:

```bash
git clone https://github.com/bluegreen-labs/phenocam_installation_tool_v2.git
```

In the (unzipped) project directory you can then execute the below commands. The installation tool uses the following syntax

```bash
./PIT.sh -i 192.168.1.xxx -n testcam -o +1 -s 9 -e 22 -m 13 -p password
```

to enable sFTP support (key based login and encrypted transfers) use:

```bash
./PIT.sh -i 192.168.1.xxx -n testcam -o +1 -s 9 -e 22 -m 13 -p password -k TRUE
```

To retrieve the current login key use:

```bash
./PIT.sh -i 192.168.1.xxx -r TRUE
```

> [!note]
> The above command will put a `phenocam_key.pub` file in your current directory. 
> To complete the sFTP install you will have to email this public key to phenocam@nau.edu.

To purge all settings and scripts use:

```bash
./PIT.sh -i 192.168.1.xxx -x TRUE
```

Where all parameters are listed as:

| Parameter     | Description |
| ------------- | ------------------------------ |
| -i            | ip address of the camera |
| -p            | camera password |
| -n            | the name of the camera / site |
| -o            | difference in hours from UTC of the timezone in which the camera resides (always use + or - signs to denote differences from UTC) |
| -s            | first hour of the scheduled image acquisitions (e.g. 4 in the morning) |
| -e            | last hour of the scheduled image acquisitions (e.g. ten at night, so 22 in 24-h notation) |
| -m            | interval minutes, at which to take pictures (e.g. 15, every 15 minutes - default phenocam setting is 30) |
| -k            | set sFTP key (TRUE or FALSE) use this option to enable sFTP |
| -r            | retrieve previously installed login keys from the camera |
| -x            | purge all settings and scripts from the camera (soft reset) |

Once successfully configured make sure the router or camera has internet access. Wait until the camera uploads its first images to the phenocam server by verifying the webpage associated with your camera at:

```
https://phenocam.nau.edu/webcam/sites/YOURCAMERANAME/
```

If you use key based logins (sFTP) you will have to forward the public key `phenocam_key.pub` created in your current directory. This key will have to be manually copied, which might take some time.

In both cases the first images might not appear until a day or two after the installation (especially with key based logins), please be patient and do not run the installation script again.

### Backups and offline use

If a micro-SD card is inserted in the back of the camera all images will be backed up by default to this card in the `phenocam_backup` directory. The card size is limited to 32GB (standard camera/cellphone cards should work). Cards are hot swappable, meaning you can remove a card without further action and replace it with a different one. This allows easy data retrieval in the field (using two cards in rotation). If you are on an unstable internet connection it might be beneficial to use SD cards as backups, so data can be backfilled from storage media.

