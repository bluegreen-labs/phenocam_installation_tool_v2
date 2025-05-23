# PhenoCam Installation Tool (PIT) v2

PhenoCam Installation Tool (PIT) is a set of scripts to configure Stardot Netcam Live 2 for the use as a phenocam associated with the [PhenoCam network](http://phenocam.nau.edu) or [ICOS](https://www.icos-cp.eu/) network. Version 2 addresses the installation routine for the Stardot Netcam Live2 cameras, which supercede the previous default Netcam SC5 cameras. It would be appreciated that if custom changes are required you hire BlueGreen Labs in a consulting context.

> [!warning]
> The default password on the Stardot cameras is **INSECURE**. Connecting any camera to an open network, without a firewall, will result in your camera being hacked (with [estimated times to infection](https://www.pcgamer.com/hardware/a-windows-xp-machines-life-expectancy-in-2024-seems-to-be-about-10-minutes-before-even-just-an-idle-net-connection-renders-it-a-trojan-riddled-zombie-pc/) ~ 10 min). Instructions on how to change the default password securely are provided in the instructions below. Follow these instructions step by step to ensure a secure install.

## Installation

> [!note]
> Please read these instructions **carefully**, failing to do so might result in a poorly configured camera. Follow these instructions step-by-step for a successful PhenoCam install.

Every PhenoCam US needs to be added to the network (database) and approved using the site survey at the following link:

https://phenocam.nau.edu/webcam/sitesurvey/

Please use this survey to apply for adding your camera to the PhenoCam network. Wait for confirmation before proceeding with the installation of the software on the camera using the steps below.

### 1. Hardware prerequisites

Please connect a computer and the PhenoCam to the same (wireless) router which has **NO** internet access (see warnings regarding the default password above - make sure to set a strong password before the camera is exposed to an unprotected network). A detailed description on how to physically configure the camera (i.e. power, network connections and surge protection) you can find [the PhenoCam website](https://phenocam.nau.edu/pdf/PhenoCam_Install_Instructions.pdf). Once your camera is powered on and connected to the (open) network **you will need to find your camera’s network IP address to configure the camera**.

The easiest way to find the camera’s IP address is to install [StarDot Tools](http://www.stardot.com/downloads). Run the StarDot Tools program and click “refresh”. The camera should be detected and the camera’s IP address shown (you may have to run Tools as administrator in Windows, depending on your settings).

If you are configuring your camera with a non-Windows computer there are other things you can do to find the IP address of the camera. From a Linux or Mac OS X terminal window you should be able to type the following commands (assuming `192.168.1.255` is the network broadcast address reported by `ifconfig`):

```bash
ping -c 3 -b 192.168.1.255
arp -a
```

to get a list of the MAC addresses and IP’s of all the computers on the local network. The StarDot cameras have a MAC address that starts with `00:30` so you may be able to find the camera that way. Again, you may need help from the local network administrator for this step.

### 2. Software prerequisites

For the script to run successfully you will need an `ssh` client and bash support, these are included in both MacOS and Linux default installs and can be provided in Windows by [using the Windows linux subsystem (WSL)](https://learn.microsoft.com/en-us/windows/wsl/install). Follow the instructions on the installation and use of the WSL carefully, and **reboot your system** before opening a WSL (Ubuntu) terminal. At times copying commands into the WSL terminal might fail. In this case **use the (right click) menu** rather than keyboard shortcuts.

Once you have access to a WSL/linux terminal you can download this repository by either a direct download of a [zip file](https://github.com/bluegreen-labs/phenocam_installation_tool_v2/), or if you have git running by cloning the branch with:

```bash
git clone https://github.com/bluegreen-labs/phenocam_installation_tool_v2.git
```

In the (unzipped) project directory you can then execute the below steps, to set the password and configure your camera.

Next, make sure the files are executable. Use the below command to change the permissions on the installation scripts.

```bash
chmod +x PITpass.sh
chmod +x PIT.sh
```

### 3. **Change the default password**

> [!warning]
> **ALWAYS** configure the camera password to a non-default secure password over a secure network, ideally a router with no outside connection and limited devices. BlueGreen Labs (BV) is **not liable** for the abuse of misconfigured cameras as a vector for network breaches and cyber-attacks due to lack of due diligence on part of the user.

Use the included script using the following code to update your password:

```bash
./PITpass.sh -i 192.168.1.xxx
```

using the IP address you retrieved using the above instructions. **Follow the onscreen instructions** to set a new password. Change the default password to a strong password which is unlikely to be brute forced (i.e. 12+ characters in a mix of letters/numbers/special characters). **You will be asked for the password again when logging in using SSH, this is normal!**

> [!note]
> When installing multiple devices in sequence you might encounter the
> below warning:
>
> ```
> @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
> @ WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED! @
> @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
> IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
> ```
>
> You can safely ignore this warning and remove it by
> executing the following command:
> 
> ```ssh-keygen -f "~/.ssh/known_hosts" -R THE_DEVICE_IP```

### 4. The PIT configuration script

To install your phenocam you will use the Phenocam Installation Tool (or PIT) script. The `PIT.sh` script allows you to set the correct parameters, retrieve login keys (for sFTP based transfers), trigger a manual image upload and remove all configuration files (purge the camera). All parameters are listed below, with those which take arguments noted in a **bold** font.

| Parameter     | Description |
| ------------- | ------------------------------ |
| -i            | **ip address of the camera** |
| -p            | **camera password** |
| -n            | **the name of the camera or site** |
| -o            | **difference in hours from UTC/GMT of the timezone in which the camera resides (always use + or - signs to denote differences, with - values for all US time zones)** |
| -s            | **first hour of the scheduled image acquisitions (e.g. 4 in the morning)** |
| -e            | **last hour of the scheduled image acquisitions (e.g. ten at night, so 22 in 24-h notation)** |
| -m            | **interval minutes, at which to take pictures (e.g. 15, every 15 minutes - default phenocam setting is 30)** |
| -f            | **fix a non-random interval (logical TRUE or FALSE - default is FALSE)** |
| -d            | **destination of the images, either the 'phenocam' or 'icos' network** |
| -r            | retrieve previously installed login keys from the camera |
| -x            | purge all settings and scripts from the camera (soft reset) |
| -u            | manually upload images to the server |
| -h            | help menu of the script |

#### 4.1 Configuring the camera

> [!note]
> To configure the camera you do not need to change any settings using the graphical user interface (webpage) of the camera itself. The configuration script (and ancillary scripts) will take care of all required settings from the command line in a consistent and concise way. **Changing settings using the camera webpage might corrupt the data you send to the PhenoCam network**.

To configure a camera for the GMT+1 time zone taking pictures every 30 minutes between nine (9) in the morning and ten (22) at night you would use the following command. Note that you also need to specify your IP address, and password and the camera name you used in the site survey (see above). **You will be asked for the password again when logging in using SSH, this is normal!**

```bash
# PhenoCam US network
./PIT.sh -i 192.168.1.xxx -p "password" -n testcam -o "\-5" -s 9 -e 22 -m 30 -d "phenocam"

# ICOS Europe
./PIT.sh -i 192.168.1.xxx -p "password" -n testcam -o +1 -s 9 -e 22 -m 30 -d "icos"

# I will be using the PhenoCam US network in all the below examples, adjust
# your commands if you are working on the ICOS network
```

Any dash (-) needs to be quoted and escaped when providing it as a parameters. As such, negative GMT offsets (in the US) need to use the escape character \ as shown below:

> [!warning]
> the `-f` parameters should be kept to the default (not completed) to generate random uploads at a set interval. 
> This parameter should only be used to coordinate multiple cameras for cross validation or coordinated uploads.


```bash
./PIT.sh -i 192.168.1.xxx -p "password" -n testcam -o "\-1" -s 9 -e 22 -m 30 -d "phenocam"
```

Similarly, using a dash in your password would require the following structure. Also note that you need to use quotes around the password when using any special characters (i.e. with a good password):

```bash
./PIT.sh -i 192.168.1.xxx -p "my\-password" -n testcam -o "\-1" -s 9 -e 22 -m 30 -d "phenocam"
```

To retrieve the current login key to use when using sFTP use:

```bash
./PIT.sh -i 192.168.1.xxx -r
```

> [!note]
> The above command will put a `phenocam_key.pub` file in your current directory. 

To complete the sFTP install you will have to email this (public) key file to phenocam@nau.edu. If you received confirmation you can validate if the login procedure works with:

```bash
./PIT.sh -i 192.168.1.xxx -v
```

> [!note]
> Internally there is a fallback routine which uploads images via insecure FTP if the key is not validated. 
> With time the service will migrate to sFTP only. Please validate your key upon initial install or continued
> service will not be guaranteed.

#### 4.2 Uploading a test image manually

Once successfully configured make sure the router or camera has internet access. You can trigger this manual upload using:

```bash
./PIT.sh -i 192.168.1.xxx -u
```

Wait until the camera uploads its first images, the process will be verbose and give sufficient feedback on progress. If no explicit warnings are provided you should assume the upload was successful. Once uploaded, verify the upload on the webpage (image) associated with your camera at:

```
https://phenocam.nau.edu/data/latest/YOUR-CAMERA-NAME.jpg
```

This location will be update once every 15-30 minutes, please be patient and do not run the installation script again. If you use key based logins (sFTP) you will have to forward the public key `phenocam_key.pub` created in your current directory. This key will have to be manually added to the PhenoCam network, which might take some time. In this case the upload of your test image might fail. Similarly, uploads will fail if you don't have confirmation on the creation of your PhenoCam site (camera instance).

##### 4.3 Purging all camera settings

> [!warning]
> This will remove the previous installation, including the login key. In short, when you purge your camera you will have to upload a new (public) login key to phenocam@nau.edu for your specific camera. Be careful when using this option to reset your camera.

To purge all settings and scripts use:

```bash
./PIT.sh -i 192.168.1.xxx -x
```

Only use this option as a last resort (or when recycling the camera for a new site). 

> [!note]
> You can call the installation routine, to change your camera settings, **multiple times** without deleting your login credentials.

### Backups and offline use

If a micro-SD card is inserted in the back of the camera all images will be backed up by default to this card in the `phenocam_backup` directory. The card size is limited to 32GB (standard camera/cellphone cards should work). Cards are hot swappable, meaning you can remove a card without further action and replace it with a different one. This allows easy data retrieval in the field (using two cards in rotation). If you are on an unstable internet connection it might be beneficial to use SD cards as backups, so data can be backfilled from storage media.

## FAQ

1. My images don't upload, what can I do?

 - check the connection of the camera to the server (can you reach phenocam.nau.edu from your site)
 - validate if you have login access when using sFTP (see above)

2. I want to change the camera name, can I do this?

 - the configuration script can be rerun and will overwrite old settings
 - note that to establish a true new identity tied to the camera in sFTP mode you will need to purge the old key (see above)
 
3. I want to do a fresh install, what are my options?
 
 - do a factory reset by pressing the recessed button on the back of the camera with a small metal rod
 - a soft reset can be done by purging the camera (see above)

4. My camera is unresponsive, what should I do?

 - reboot the camera by cycling the power or rebooting via the web interface
 - when all else fails, do a factory reset by pressing the recessed button on the back of the camera with a small metal rod (note that this will require you to upload a new key)

5. I want to run a custom setup, where do I find information?

 - the software is provided AS IS and only supports PhenoCam US and ICOS phenocams, for custom setups contanct BlueGreen Labs.
 
