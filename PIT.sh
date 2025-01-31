#!/bin/bash

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#
# This script installs all necessary configuration
# files as required to upload images to the PhenoCam server
# (phenocam.nau.edu) on your NetCam Live2 camera REMOTELY with
# minimum interaction with the camera.
#
# Use is permitted within the context of the PhenoCam US network,
# in its standard configuration. For all exceptions contact
# BlueGreen Labs
#
#--------------------------------------------------------------------

#---- global login banner ----

echo ""
echo "===================================================================="
echo ""
echo " Phenocam Installation Tool (PIT) V2 for NetCam Live2 cameras"
echo ""
echo " (c) BlueGreen Labs (BV) 2024 - https://bluegreenlabs.org"
echo ""
echo " -----------------------------------------------------------"
echo ""

#---- subroutines ----

# error handling installation subroutines
error_exit(){
  echo ""
  echo " NOTE: If no confirmation of a successful upload is provided,"
  echo " or warnings are shown, check all script parameters."
  echo ""
  echo "===================================================================="
  exit 0
}

# error handling key retrieval routine
error_key(){
  echo ""
  echo " WARNING: No login key (pair) 'phenocam_key' found... "
  echo " (please run the installation routine)"
  echo ""
  echo "===================================================================="
  exit 0
}

# error handling purging routine
error_purge(){
  echo ""
  echo " WARNING: Purging of system settings failed, please try again!"
  echo ""
  echo "===================================================================="
  exit 0
}

# error handling test routine
error_upload(){
  echo ""
  echo " WARNING: Image upload failed, check your network connection"
  echo " and settings!"
  echo ""
  echo "===================================================================="
  exit 0
}

# define usage
usage() { 
 echo "
 
 This scripts covers the installation of your
 Stardot NetCam Live2 PhenoCam
 please use the following arguments.
 
 Arguments which require an additional parameter
 have descriptions enclosed in <> brackets. Other
 arguments are binary choices.
 
 Usage: $0
  [-i <camera ip address>]
  [-p <camera password>]
  [-n <camera name>]
  [-o <time offset from UTC/GMT>]
  [-s <start time 0-23>]
  [-e <end time 0-23>]  
  [-m <interval minutes>]
  [-d <destination> which network to use, either 'phenocam' or 'icos']
  [-u uploads images if specified, requires -i to be specified]
  [-v validate login credentials for sFTP transfers]
  [-r retrieves login key if specified, requires -i to be specified]
  [-x purges all previous settings and keys if specified, requires -i to be specified]
  [-h calls this menu if specified]
  " 1>&2
  
  exit 0
 }

validate() {
 echo " Trying to validate sFTP login"
 echo ""
 
  # check if IP is provided
 if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_upload
 fi
 
 # create command
 command="
  sh /mnt/cfg1/scripts/phenocam_validate.sh
 "
 
 # execute command
 ssh admin@${ip} ${command} 2>/dev/null

 echo ""
 echo "[if no warnings are given your logins were successful]"
 echo ""
 echo "===================================================================="
 exit 0
 }

upload() {
 echo " Trying to upload image to the server"
 echo ""
 
  # check if IP is provided
 if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_upload
 fi
 
 # create command
 command="
  sh /mnt/cfg1/scripts/phenocam_upload.sh
 "
 
 # execute command
 ssh admin@${ip} ${command} || error_upload 2> /dev/null
 
 echo ""
 echo "===================================================================="
 exit 0
 }

# if the retrieve the public key
retrieve() {
 
 # check if IP is provided
 if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_key
 fi
 
 # create command
 command="
  if [ -f '/mnt/cfg1/phenocam_key' ]; then dropbearkey -t ecdsa -s 521 -f /mnt/cfg1/phenocam_key -y; else exit 1; fi
 "

 echo " Retrieving the public key login credentials"
 echo ""
 
 # execute command
 ssh admin@${ip} ${command} > tmp.pub || error_key 2>/dev/null
 
 # strip out the public key
 # no header or footer
 grep "ecdsa-sha2" tmp.pub > phenocam_key.pub
 rm -rf tmp.pub
 
 echo "" 
 echo " The public key was written to the 'phenocam_key.pub' file"
 echo " in your current working directory!"
 echo ""
 echo " Forward this file to phenocam@nau.edu to finalize your"
 echo " sFTP installation."
 echo ""
 echo "===================================================================="
 exit 0
}

# if the retrieve argument is active retrieve the
# public private keys, check if there are more than
# two arguments given to avoid accidental purging
purge() {

 echo " Purging all previous settings and login credentials"
 echo ""
 
  # check if IP is provided
 if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_purge
 fi
 
 # ASK FOR CONFIRMATION!!!
 read -p "Do you wish to perform this action?" yesno
 case $yesno in
        [Yy]* ) 
            echo "Purging the system settings..."
        ;;
        [Nn]* ) 
            echo "You answered no, exiting"
            exit_purge
        ;;
        * ) 
            exit_purge
        ;;
 esac 
 
 # create command
 command="
  rm -rf /mnt/cfg1/settings.txt
  rm -rf /mnt/cfg1/.password
  rm -rf /mnt/cfg1/phenocam_key
  rm -rf /mnt/cfg1/update.txt
  rm -rf /mnt/cfg1/scripts/
 "
 
 # execute command
 ssh admin@${ip} ${command} || error_purge 2>/dev/null
 
 echo ""
 echo " Done, cleaned the camera settings!"
 echo ""
 echo "===================================================================="
 exit 0
}

#---- parse arguments (and/or execute subroutine calls) ----

# grab arguments
while getopts "hi:p:n:o:s:e:m:d:uvrx" option;
do
    case "${option}"
        in
        i) ip=${OPTARG} ;;
        p) pass=${OPTARG} ;;
        n) name=${OPTARG} ;;
        o) offset=${OPTARG} ;;
        s) start=${OPTARG} ;;
        e) end=${OPTARG} ;;
        m) int=${OPTARG} ;;
        d) dest=${OPTARG} ;;
        u) upload ;;
        v) validate ;;
        r) retrieve ;;
        x) purge ;;
        h | *) usage; exit 0 ;;
    esac
done

#---- installation routine ----

# validating parameters
if [[ -z ${ip} || ${ip} == -* ]]; then
 echo " WARNING: No IP address provided"
 error_exit
fi

if [[ -z ${pass} || ${pass} == -* ]]; then
 echo " WARNING: No password provided"
 error_exit
fi

if [[ -z ${name} || ${name} == -* ]]; then
 echo " WARNING: No camera name provided"
 error_exit
fi

if [[ -z ${offset} || ${offset} == -* ]]; then
 echo " WARNING: No GMT time offset provided"
 error_exit
fi

if [[ -z ${dest} || ${dest} == -* ]]; then
 echo " WARNING: provided destination argument is empty"
 error_exit
fi

if [[ "${dest}" != "phenocam" && "${dest}" != "icos" ]]; then
 echo " WARNING: network option is not valid (should be 'phenocam' or 'icos')"
 error_exit
fi

if [[ -z ${start} || ${start} == -* ]]; then
 echo " NOTE: No start time (24h format) provided, using the default (9h)"
 start='9'
fi

if [[ -z ${end} || ${end} == -* ]]; then
 echo " NOTE: No end time (24h format) provided, using the default (22h)"
 end='22'
fi

if [[ -z ${int} || ${int} == -* ]]; then
 echo " NOTE: No interval (in minutes) provided, using the default (30 min)"
 int='30'
fi

# Rename server variables to URLs
if [[ ${dest} == "phenocam" ]]; then
 url="phenocam.nau.edu"
else
 url="icos01.uantwerpen.be"
fi

# Default to GMT time zone
tz="GMT"

# colour settings
red="220"
green="125"
blue="220"
brightness="128"
contrast="128"
sharpness="128"
hue="128"
saturation="100"
backlight="0"

command="
 echo TRUE > /mnt/cfg1/update.txt &&
 echo ${name} > /mnt/cfg1/settings.txt &&
 echo ${offset} >> /mnt/cfg1/settings.txt &&
 echo ${tz} >> /mnt/cfg1/settings.txt &&
 echo ${start} >> /mnt/cfg1/settings.txt &&
 echo ${end} >> /mnt/cfg1/settings.txt &&
 echo ${int} >> /mnt/cfg1/settings.txt &&
 echo ${red} >> /mnt/cfg1/settings.txt &&
 echo ${green} >> /mnt/cfg1/settings.txt &&
 echo ${blue} >> /mnt/cfg1/settings.txt &&
 echo ${brightness} >> /mnt/cfg1/settings.txt &&
 echo ${sharpness} >> /mnt/cfg1/settings.txt &&
 echo ${hue} >> /mnt/cfg1/settings.txt &&
 echo ${contrast} >> /mnt/cfg1/settings.txt &&
 echo ${saturation} >> /mnt/cfg1/settings.txt &&
 echo ${backlight} >> /mnt/cfg1/settings.txt &&
 echo ${dest} >> /mnt/cfg1/settings.txt &&
 echo ${pass} > /mnt/cfg1/.password &&
 echo ${url} > /mnt/cfg1/server.txt &&
 if [ ! -f /mnt/cfg1/phenocam_key ]; then dropbearkey -t ecdsa -s 521 -f /mnt/cfg1/phenocam_key >/dev/null; fi &&
 cd /var/tmp; cat | base64 -d | tar -x &&
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi && 
 cp /var/tmp/files/* /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
 sh /mnt/cfg1/scripts/check_firmware.sh || return 1 &&
 echo '#!/bin/sh' > /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh' >> /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_upload.sh' >> /mnt/cfg1/userboot.sh &&
 echo '' &&
 echo ' Successfully uploaded install instructions.' &&
 echo ' The camera configuration will take effect on reboot.' &&
 echo '' &&
 echo ' The following options have been set:' &&
 echo ' ------------------------------------' &&
 echo '' &&
 echo ' Sitename: ${name} | Timezone: GMT${offset}' &&
 echo ' Upload start - end: ${start} - ${end} (h)' &&
 echo ' Upload interval: every ${int} (min)' &&
 echo '' &&
 echo ' And the following colour settings:' &&
 echo ' ----------------------------------' &&
 echo '' &&
 echo ' Gain values (R G B): ${red} ${green} ${blue}' &&
 echo ' Brightness: ${brightness} | Sharpness: ${sharpness}' &&
 echo ' Hue: ${hue} | Contrast: ${contrast}' &&
 echo ' Saturation: ${saturation} | Backlight: ${backlight}' &&
 echo '' &&
 echo ' ----------------------------------' &&
 echo '' &&
 echo ' NOTE:' &&
 echo ' A key (pair) exists or was generated, please run:' &&
 echo ' ./PIT.sh -i ${ip} -r' &&
 echo ' to display/retrieve the current login key' &&
 echo ' and send this key to phenocam@nau.edu to' &&
 echo ' or phenocam@uantwerpen.be to complete the install.' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 echo ' --> SUCCESSFUL UPLOAD OF THE INSTALLATION SCRIPT' &&
 echo ' --> THE CAMERA WILL REBOOT TO COMPLETE THE INSTALL' &&
 echo ' --> THIS CONFIGURATION USES THE - ${dest} - NETWORK' &&
 echo ' --> USING THE - ${url} - SERVER' &&
 echo '' &&
 echo ' [NOTE: the full install will take several reboot cycles (~5 min !!),' && 
 echo ' please wait before logging in or triggering the script again. The' &&
 echo ' current SSH connection will be closed for reboot in 30 sec.]' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 sh /mnt/cfg1/scripts/reboot_camera.sh
"

echo ""
echo " Please login to execute the installation script."
echo ""


# install command
BINLINE=$(awk '/^__BINARY__/ { print NR + 1; exit 0; }' $0)
tail -n +${BINLINE} $0 | ssh admin@${ip} ${command} || error_exit 2>/dev/null

#---- purge password from history ----

# remove last lines from history
# containing the password
history -d -1--2

# exit
exit 0

__BINARY__
ZmlsZXMvY2hlY2tfZmlybXdhcmUuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA2NjQAMDAwMTc1
MAAwMDAxNzUwADAwMDAwMDAzMTc0ADE0NzIxMTA0MjMzADAxNTcwNwAgMAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAj
IS9iaW4vc2gKCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIChjKSBLb2VuIEh1ZmtlbnMgZm9yIEJsdWVHcmVlbiBM
YWJzIChCVikKIwojIFVuYXV0aG9yaXplZCBjaGFuZ2VzIHRvIHRoaXMgc2NyaXB0IGFyZSBjb25z
aWRlcmVkIGEgY29weXJpZ2h0CiMgdmlvbGF0aW9uIGFuZCB3aWxsIGJlIHByb3NlY3V0ZWQuCiMK
Iy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tCgojIGVycm9yIGhhbmRsaW5nIGtleSByZXRyaWV2YWwgcm91dGluZQplcnJv
cl9wYXNzKCl7CiAgZWNobyAiIgogIGVjaG8gIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09IgogIGVjaG8gIiIKICBlY2hv
ICIgV0FSTklORzogVGhlIHByb3ZpZGVkIGNvbW1hbmRsaW5lIGFyZ3VybWVudCBwYXNzd29yZCB3
YXMgaW5jb3JyZWN0IgogIGVjaG8gIiBbcGxlYXNlIGNoZWNrIHRoZSBwYXNzd29yZCBhbmQgdGhl
IHByb3BlciB1c2Ugb2YgZXNjYXBlIGNoYXJhY3RlcnNdIgogIGVjaG8gIiIKICBlY2hvICI9PT09
PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PSIKICBleGl0IDEKfQoKIyBoYXJkIGNvZGUgcGF0aCB3aGljaCBhcmUgbG9zdCBpbiBz
b21lIGluc3RhbmNlcwojIHdoZW4gY2FsbGluZyB0aGUgc2NyaXB0IHRocm91Z2ggc3NoIApQQVRI
PSIvdXNyL2xvY2FsL2JpbjovdXNyL2xvY2FsL3NiaW46L3Vzci9iaW46L3Vzci9zYmluOi9iaW46
L3NiaW4iCgojIGdyYWIgcGFzc3dvcmQKcGFzcz1gYXdrICdOUj09MScgL21udC9jZmcxLy5wYXNz
d29yZGAKCiMgbW92ZSBpbnRvIHRlbXBvcmFyeSBkaXJlY3RvcnkKY2QgL3Zhci90bXAKCiMgZHVt
cCBkZXZpY2UgaW5mbwp3Z2V0IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/
RGV2aWNlSW5mbyA+L2Rldi9udWxsIDI+L2Rldi9udWxsIHx8IGVycm9yX3Bhc3MKCiMgZXh0cmFj
dCBmaXJtd2FyZSB2ZXJzaW9uCnZlcnNpb249YGNhdCB2Yi5odG0/RGV2aWNlSW5mbyB8IGN1dCAt
ZCctJyAtZjMgfCBjdXQgLWQgJyAnIC1mMSB8IHRyIC1kICdCJyBgCgojIGNsZWFuIHVwIGRldHJp
dHVzCnJtIHZiKgoKaWYgW1sgJHZlcnNpb24gLWx0IDkxMDggXV07IHRoZW4KCiAjIGVycm9yIHN0
YXRlbWVudCArIHRyaWdnZXJpbmcKICMgdGhlIHNzaCBlcnJvciBzdWZmaXgKIGVjaG8gIiIKIGVj
aG8gIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09IgogZWNobyAiIgogZWNobyAiIFdBUk5JTkc6IHlvdXIgZmlybXdhcmUg
dmVyc2lvbiAkdmVyc2lvbiBpcyBub3Qgc3VwcG9ydGVkLCIKIGVjaG8gIiBwbGVhc2UgdXBkYXRl
IHlvdXIgY2FtZXJhIGZpcm13YXJlIHRvIHZlcnNpb24gQjkxMDggb3IgbGF0ZXIuIgogZWNobyAi
IgogZWNobyAiPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT0iCiBleGl0IDEKCmVsc2UKIAogIyBjbGVhbiBleGl0CiBleGl0
IDAKZmkKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZpbGVz
L3BoZW5vY2FtX2luc3RhbGwuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzc1ADAwMDE3NTAAMDAw
MTc1MAAwMDAwMDAxMjUzNQAxNDcyNzA2NTI0MwAwMTYyNzcAIDAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXN0YXIgIABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyEvYmlu
L3NoCgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0KIyAoYykgS29lbiBIdWZrZW5zIGZvciBCbHVlR3JlZW4gTGFicyAo
QlYpCiMKIyBVbmF1dGhvcml6ZWQgY2hhbmdlcyB0byB0aGlzIHNjcmlwdCBhcmUgY29uc2lkZXJl
ZCBhIGNvcHlyaWdodAojIHZpb2xhdGlvbiBhbmQgd2lsbCBiZSBwcm9zZWN1dGVkLgojCiMtLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLQoKIyBoYXJkIGNvZGUgcGF0aCB3aGljaCBhcmUgbG9zdCBpbiBzb21lIGluc3RhbmNl
cwojIHdoZW4gY2FsbGluZyB0aGUgc2NyaXB0IHRocm91Z2ggc3NoIApQQVRIPSIvdXNyL2xvY2Fs
L2JpbjovdXNyL2xvY2FsL3NiaW46L3Vzci9iaW46L3Vzci9zYmluOi9iaW46L3NiaW4iCgpzbGVl
cCAzMApjZCAvdmFyL3RtcAoKIyB1cGRhdGUgcGVybWlzc2lvbnMgc2NyaXB0cwpjaG1vZCBhK3J3
eCAvbW50L2NmZzEvc2NyaXB0cy8qCgojIGdldCB0b2RheXMgZGF0ZQp0b2RheT1gZGF0ZSArIiVZ
ICVtICVkICVIOiVNOiVTImAKCiMgc2V0IGNhbWVyYSBtb2RlbCBuYW1lCm1vZGVsPSJOZXRDYW0g
TGl2ZTIiCgojIHVwbG9hZCAvIGRvd25sb2FkIHNlcnZlciAtIGxvY2F0aW9uIGZyb20gd2hpY2gg
dG8gZ3JhYiBhbmQKIyBhbmQgd2hlcmUgdG8gcHV0IGNvbmZpZyBmaWxlcwpob3N0PSdwaGVub2Nh
bS5uYXUuZWR1JwoKIyBjcmVhdGUgZGVmYXVsdCBzZXJ2ZXIKaWYgWyAhIC1mICcvbW50L2NmZzEv
c2VydmVyLnR4dCcgXTsgdGhlbgogIGVjaG8gJHtob3N0fSA+IC9tbnQvY2ZnMS9zZXJ2ZXIudHh0
CiAgZWNobyAidXNpbmcgZGVmYXVsdCBob3N0OiAke2hvc3R9IiA+PiAvdmFyL3RtcC9pbnN0YWxs
X2xvZy50eHQKICBjaG1vZCBhK3J3IC9tbnQvY2ZnMS9zZXJ2ZXIudHh0CmZpCgojIE9ubHkgdXBk
YXRlIHRoZSBzZXR0aW5ncyBpZiBleHBsaWNpdGx5CiMgaW5zdHJ1Y3RlZCB0byBkbyBzbywgdGhp
cyBmaWxlIHdpbGwgYmUKIyBzZXQgdG8gVFJVRSBieSB0aGUgUElULnNoIHNjcmlwdCwgd2hpY2gK
IyB1cG9uIHJlYm9vdCB3aWxsIHRoZW4gYmUgcnVuLgoKaWYgWyBgY2F0IC9tbnQvY2ZnMS91cGRh
dGUudHh0YCA9ICJUUlVFIiBdOyB0aGVuIAoKCSMgc3RhcnQgbG9nZ2luZwoJZWNobyAiLS0tLS0g
JHt0b2RheX0gLS0tLS0iID4+IC92YXIvdG1wL2luc3RhbGxfbG9nLnR4dAoKCSMtLS0tLSByZWFk
IGluIHNldHRpbmdzCglpZiBbIC1mICcvbW50L2NmZzEvc2V0dGluZ3MudHh0JyBdOyB0aGVuCgkg
Y2FtZXJhPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIHRpbWVfb2Zmc2V0
PWBhd2sgJ05SPT0yJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIGNyb25fc3RhcnQ9YGF3ayAn
TlI9PTQnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgY3Jvbl9lbmQ9YGF3ayAnTlI9PTUnIC9t
bnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgY3Jvbl9pbnQ9YGF3ayAnTlI9PTYnIC9tbnQvY2ZnMS9z
ZXR0aW5ncy50eHRgCgkgCgkgIyBjb2xvdXIgYmFsYW5jZQogCSByZWQ9YGF3ayAnTlI9PTcnIC9t
bnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgZ3JlZW49YGF3ayAnTlI9PTgnIC9tbnQvY2ZnMS9zZXR0
aW5ncy50eHRgCgkgYmx1ZT1gYXdrICdOUj09OScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSAK
CSAjIHJlYWQgaW4gdGhlIGJyaWdodG5lc3Mvc2hhcnBuZXNzL2h1ZS9zYXR1cmF0aW9uIHZhbHVl
cwoJIGJyaWdodG5lc3M9YGF3ayAnTlI9PTEwJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIHNo
YXJwbmVzcz1gYXdrICdOUj09MTEnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgaHVlPWBhd2sg
J05SPT0xMicgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBjb250cmFzdD1gYXdrICdOUj09MTMn
IC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCSAKCSBzYXR1cmF0aW9uPWBhd2sgJ05SPT0xNCcgL21u
dC9jZmcxL3NldHRpbmdzLnR4dGAKCSBibGM9YGF3ayAnTlI9PTE1JyAvbW50L2NmZzEvc2V0dGlu
Z3MudHh0YAoJIG5ldHdvcms9YGF3ayAnTlI9PTE2JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJ
ZWxzZQoJIGVjaG8gIlNldHRpbmdzIGZpbGUgbWlzc2luZywgYWJvcnRpbmcgaW5zdGFsbCByb3V0
aW5lISIgPj4gL3Zhci90bXAvaW5zdGFsbF9sb2cudHh0CglmaQoJCiAgICAgICAgcGFzcz1gYXdr
ICdOUj09MScgL21udC9jZmcxLy5wYXNzd29yZGAKCgkjLS0tLS0gc2V0IHRpbWUgem9uZSBvZmZz
ZXQgKGZyb20gR01UKQoJCgkjIHNldCBzaWduIHRpbWUgem9uZQoJU0lHTj1gZWNobyAke3RpbWVf
b2Zmc2V0fSB8IGN1dCAtYycxJ2AKCgkjIG5vdGUgdGhlIHdlaXJkIGZsaXAgaW4gdGhlIG5ldGNh
bSBjYW1lcmFzCglpZiBbICIkU0lHTiIgPSAiKyIgXTsgdGhlbgoJIFRaPWBlY2hvICJHTVQke3Rp
bWVfb2Zmc2V0fSIgfCBzZWQgJ3MvKy8lMkQvZydgCgllbHNlCgkgVFo9YGVjaG8gIkdNVCR7dGlt
ZV9vZmZzZXR9IiB8IHNlZCAncy8tLyUyQi9nJ2AKCWZpCgoJIyBjYWxsIEFQSSB0byBzZXQgdGhl
IHRpbWUgCgl3Z2V0IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/dGltZXpv
bmU9JHtUWn0KCQoJIyBjbGVhbiB1cCBkZXRyaXR1cwoJcm0gdmIqCgkKCWVjaG8gInRpbWUgc2V0
IHRvIChhc2NpaSBmb3JtYXQpOiAke1RafSIgPj4gL3Zhci90bXAvaW5zdGFsbF9sb2cudHh0CgkK
CSMtLS0tLSBzZXQgb3ZlcmxheQoJCgkjIGNvbnZlcnQgdG8gYXNjaWkKCWlmIFsgIiRTSUdOIiA9
ICIrIiBdOyB0aGVuCgkgdGltZV9vZmZzZXQ9YGVjaG8gIiR7dGltZV9vZmZzZXR9IiB8IHNlZCAn
cy8rLyUyQi9nJ2AKCWVsc2UKCSB0aW1lX29mZnNldD1gZWNobyAiJHt0aW1lX29mZnNldH0iIHwg
c2VkICdzLy0vJTJEL2cnYAoJZmkKCQoJIyBvdmVybGF5IHRleHQKCW92ZXJsYXlfdGV4dD1gZWNo
byAiJHtjYW1lcmF9IC0gJHttb2RlbH0gLSAlYSAlYiAlZCAlWSAlSDolTTolUyAtIEdNVCR7dGlt
ZV9vZmZzZXR9IiB8IHNlZCAncy8gLyUyMC9nJ2AKCQoJIyBmb3Igbm93IGRpc2FibGUgdGhlIG92
ZXJsYXkKCXdnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9vdmVybGF5
dGV4dDE9JHtvdmVybGF5X3RleHR9CgkKCSMgY2xlYW4gdXAgZGV0cml0dXMKCXJtIHZiKgoJCgll
Y2hvICJoZWFkZXIgc2V0IHRvOiAke292ZXJsYXlfdGV4dH0iID4+IC92YXIvdG1wL2luc3RhbGxf
bG9nLnR4dAoJCgkjLS0tLS0gc2V0IGNvbG91ciBzZXR0aW5ncwoJCgkjIGNhbGwgQVBJIHRvIHNl
dCB0aGUgdGltZSAKCXdnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9i
cmlnaHRuZXNzPSR7YnJpZ2h0bmVzc30KCXdnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAu
MC4xL3ZiLmh0bT9jb250cmFzdD0ke2NvbnRyYXN0fQoJd2dldCBodHRwOi8vYWRtaW46JHtwYXNz
fUAxMjcuMC4wLjEvdmIuaHRtP3NoYXJwbmVzcz0ke3NoYXJwbmVzc30KCXdnZXQgaHR0cDovL2Fk
bWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9odWU9JHtodWV9Cgl3Z2V0IGh0dHA6Ly9hZG1p
bjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/c2F0dXJhdGlvbj0ke3NhdHVyYXRpb259CgkKCSMg
Y2xlYW4gdXAgZGV0cml0dXMKCXJtIHZiKgoJCQoJIyBzZXQgUkdCIGJhbGFuY2UKCS91c3Ivc2Jp
bi9zZXRfcmdiLnNoIDAgJHtyZWR9ICR7Z3JlZW59ICR7Ymx1ZX0KCgkjLS0tLS0gZ2VuZXJhdGUg
cmFuZG9tIG51bWJlciBiZXR3ZWVuIDAgYW5kIHRoZSBpbnRlcnZhbCB2YWx1ZQoJcm51bWJlcj1g
YXdrIC12IG1pbj0wIC12IG1heD0ke2Nyb25faW50fSAnQkVHSU57c3JhbmQoKTsgcHJpbnQgaW50
KG1pbityYW5kKCkqKG1heC1taW4rMSkpfSdgCgkKCSMgZGl2aWRlIDYwIG1pbiBieSB0aGUgaW50
ZXJ2YWwKCWRpdj1gYXdrIC12IGludGVydmFsPSR7Y3Jvbl9pbnR9ICdCRUdJTiB7cHJpbnQgNTkv
aW50ZXJ2YWx9J2AKCWludD1gZWNobyAkZGl2IHwgY3V0IC1kJy4nIC1mMWAKCQoJIyBnZW5lcmF0
ZSBsaXN0IG9mIHZhbHVlcyB0byBpdGVyYXRlIG92ZXIKCXZhbHVlcz1gYXdrIC12IG1heD0ke2lu
dH0gJ0JFR0lOeyBmb3IoaT0wO2k8PW1heDtpKyspIHByaW50IGl9J2AKCQoJZm9yIGkgaW4gJHt2
YWx1ZXN9OyBkbwoJIHByb2R1Y3Q9YGF3ayAtdiBpbnRlcnZhbD0ke2Nyb25faW50fSAtdiBzdGVw
PSR7aX0gJ0JFR0lOIHtwcmludCBpbnQoaW50ZXJ2YWwqc3RlcCl9J2AJCgkgc3VtPWBhd2sgLXYg
cHJvZHVjdD0ke3Byb2R1Y3R9IC12IG5yPSR7cm51bWJlcn0gJ0JFR0lOIHtwcmludCBpbnQocHJv
ZHVjdCtucil9J2AKCSAKCSBpZiBbICIke2l9IiAtZXEgIjAiIF07dGhlbgoJICBpbnRlcnZhbD1g
ZWNobyAke3N1bX1gCgkgZWxzZQoJICBpZiBbICIkc3VtIiAtbGUgIjU5IiBdO3RoZW4KCSAgIGlu
dGVydmFsPWBlY2hvICR7aW50ZXJ2YWx9LCR7c3VtfWAKCSAgZmkKCSBmaQoJZG9uZQoKCWVjaG8g
ImNyb250YWIgaW50ZXJ2YWxzIHNldCB0bzogJHtpbnRlcnZhbH0iID4+IC92YXIvdG1wL2luc3Rh
bGxfbG9nLnR4dAoKCSMtLS0tLSBzZXQgcm9vdCBjcm9uIGpvYnMKCQoJIyBzZXQgdGhlIG1haW4g
cGljdHVyZSB0YWtpbmcgcm91dGluZQoJZWNobyAiJHtpbnRlcnZhbH0gJHtjcm9uX3N0YXJ0fS0k
e2Nyb25fZW5kfSAqICogKiBzaCAvbW50L2NmZzEvc2NyaXB0cy9waGVub2NhbV91cGxvYWQuc2gi
ID4gL21udC9jZmcxL3NjaGVkdWxlL2FkbWluCgkJCgkjIHVwbG9hZCBpcCBhZGRyZXNzIGluZm8g
YXQgbWlkZGF5CgllY2hvICI1OSAxMSAqICogKiBzaCAvbW50L2NmZzEvc2NyaXB0cy9waGVub2Nh
bV9pcF90YWJsZS5zaCIgPj4gL21udC9jZmcxL3NjaGVkdWxlL2FkbWluCgkJCgkjIHJlYm9vdCBh
dCBtaWRuaWdodCBvbiByb290IGFjY291bnQKCWVjaG8gIjU5IDIzICogKiAqIHNoIC9tbnQvY2Zn
MS9zY3JpcHRzL3JlYm9vdF9jYW1lcmEuc2giID4gL21udC9jZmcxL3NjaGVkdWxlL3Jvb3QKCQoJ
IyBpbmZvCgllY2hvICJGaW5pc2hlZCBpbml0aWFsIHNldHVwIiA+PiAvdmFyL3RtcC9pbnN0YWxs
X2xvZy50eHQKCgkjLS0tLS0gZmluYWxpemUgdGhlIHNldHVwICsgcmVib290CgoJIyB1cGRhdGUg
dGhlIHN0YXRlIG9mIHRoZSB1cGRhdGUgcmVxdWlyZW1lbnQKCSMgaS5lLiBza2lwIGlmIGNhbGxl
ZCBtb3JlIHRoYW4gb25jZSwgdW5sZXNzCgkjIHRoaXMgZmlsZSBpcyBtYW51YWxseSBzZXQgdG8g
VFJVRSB3aGljaAoJIyB3b3VsZCByZXJ1biB0aGUgaW5zdGFsbCByb3V0aW5lIHVwb24gcmVib290
CgllY2hvICJGQUxTRSIgPiAvbW50L2NmZzEvdXBkYXRlLnR4dAoKCSMgcmVib290aW5nIGNhbWVy
YSB0byBtYWtlIHN1cmUgYWxsCgkjIHRoZSBzZXR0aW5ncyBzdGljawoJc2ggL21udC9jZmcxL3Nj
cmlwdHMvcmVib290X2NhbWVyYS5zaApmaQoKIyBjbGVhbiBleGl0CmV4aXQgMAoKAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZpbGVzL3BoZW5vY2FtX2lw
X3RhYmxlLnNoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzU1ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAw
MjUyMgAxNDcyNzA2NjA2MAAwMTYzNzcAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAdXN0YXIgIABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGtodWZr
ZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyEvYmluL3NoCgojLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0KIyAoYykgS29lbiBIdWZrZW5zIGZvciBCbHVlR3JlZW4gTGFicyAoQlYpCiMKIyBVbmF1
dGhvcml6ZWQgY2hhbmdlcyB0byB0aGlzIHNjcmlwdCBhcmUgY29uc2lkZXJlZCBhIGNvcHlyaWdo
dAojIHZpb2xhdGlvbiBhbmQgd2lsbCBiZSBwcm9zZWN1dGVkLgojCiMtLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBo
YXJkIGNvZGUgcGF0aCB3aGljaCBhcmUgbG9zdCBpbiBzb21lIGluc3RhbmNlcwojIHdoZW4gY2Fs
bGluZyB0aGUgc2NyaXB0IHRocm91Z2ggc3NoIApQQVRIPSIvdXNyL2xvY2FsL2JpbjovdXNyL2xv
Y2FsL3NiaW46L3Vzci9iaW46L3Vzci9zYmluOi9iaW46L3NiaW4iCgojIHNvbWUgZmVlZGJhY2sg
b24gdGhlIGFjdGlvbgplY2hvICJ1cGxvYWRpbmcgSVAgdGFibGUiCgojIGhvdyBtYW55IHNlcnZl
cnMgZG8gd2UgdXBsb2FkIHRvCm5yc2VydmVycz1gYXdrICdFTkQge3ByaW50IE5SfScgL21udC9j
ZmcxL3NlcnZlci50eHRgCm5yc2VydmVycz1gYXdrIC12IHZhcj0ke25yc2VydmVyc30gJ0JFR0lO
eyBuPTE7IHdoaWxlIChuIDw9IHZhciApIHsgcHJpbnQgbjsgbisrOyB9IH0nIHwgdHIgJ1xuJyAn
ICdgCgojIGdyYWIgdGhlIG5hbWUsIGRhdGUgYW5kIElQIG9mIHRoZSBjYW1lcmEKREFURVRJTUU9
YGRhdGVgCgojIGdyYWIgaW50ZXJuYWwgaXAgYWRkcmVzcwpJUD1gaWZjb25maWcgZXRoMCB8IGF3
ayAnL2luZXQgYWRkci97cHJpbnQgc3Vic3RyKCQyLDYpfSdgClNJVEVOQU1FPWBhd2sgJ05SPT0x
JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoKIyB1cGRhdGUgdGhlIElQIGFuZCB0aW1lIHZhcmlh
YmxlcwpjYXQgL21udC9jZmcxL3NjcmlwdHMvc2l0ZV9pcC5odG1sIHwgc2VkICJzfERBVEVUSU1F
fCREQVRFVElNRXxnIiB8IHNlZCAic3xTSVRFSVB8JElQfGciID4gL3Zhci90bXAvJHtTSVRFTkFN
RX1cX2lwLmh0bWwKCiMgcnVuIHRoZSB1cGxvYWQgc2NyaXB0IGZvciB0aGUgaXAgZGF0YQojIGFu
ZCBmb3IgYWxsIHNlcnZlcnMKZm9yIGkgaW4gJG5yc2VydmVycyA7CmRvCiBTRVJWRVI9YGF3ayAt
diBwPSRpICdOUj09cCcgL21udC9jZmcxL3NlcnZlci50eHRgIAogZnRwcHV0ICR7U0VSVkVSfSAt
dSAiYW5vbnltb3VzIiAtcCAiYW5vbnltb3VzIiBkYXRhLyR7U0lURU5BTUV9LyR7U0lURU5BTUV9
XF9pcC5odG1sIC92YXIvdG1wLyR7U0lURU5BTUV9XF9pcC5odG1sCmRvbmUKCiMgY2xlYW4gdXAK
cm0gL3Zhci90bXAvJHtTSVRFTkFNRX1cX2lwLmh0bWwKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMvcGhlbm9jYW1fdXBsb2Fk
LnNoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NzUAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDIwNzEz
ADE0NzQ3MTY2MjU0ADAxNjEyMAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAB1c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa2h1ZmtlbnMA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAjIS9iaW4vc2gKCiMtLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LQojIChjKSBLb2VuIEh1ZmtlbnMgZm9yIEJsdWVHcmVlbiBMYWJzIChCVikKIwojIFVuYXV0aG9y
aXplZCBjaGFuZ2VzIHRvIHRoaXMgc2NyaXB0IGFyZSBjb25zaWRlcmVkIGEgY29weXJpZ2h0CiMg
dmlvbGF0aW9uIGFuZCB3aWxsIGJlIHByb3NlY3V0ZWQuCiMKIy0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIGhhcmQg
Y29kZSBwYXRoIHdoaWNoIGFyZSBsb3N0IGluIHNvbWUgaW5zdGFuY2VzCiMgd2hlbiBjYWxsaW5n
IHRoZSBzY3JpcHQgdGhyb3VnaCBzc2ggClBBVEg9Ii91c3IvbG9jYWwvYmluOi91c3IvbG9jYWwv
c2JpbjovdXNyL2JpbjovdXNyL3NiaW46L2Jpbjovc2JpbiIKCiMgZXJyb3IgaGFuZGxpbmcKZXJy
b3JfZXhpdCgpewogIGVjaG8gIiIKICBlY2hvICIgRkFJTEVEIFRPIFVQTE9BRCBEQVRBIgogIGVj
aG8gIiIKfQoKIy0tLS0gZmVlZGJhY2sgb24gc3RhcnR1cCAtLS0KCmVjaG8gIiIKZWNobyAiU3Rh
cnRpbmcgaW1hZ2UgdXBsb2FkcyAuLi4gIgplY2hvICIiCgojLS0tLSBzdWJyb3V0aW5lcyAtLS0K
CmNhcHR1cmUoKSB7CgogaW1hZ2U9JDEKIG1ldGFmaWxlPSQyCiBkZWxheT0kMwogaXI9JDQKCiAj
IFNldCB0aGUgaW1hZ2UgdG8gbm9uIElSIGkuZS4gVklTCiAvdXNyL3NiaW4vc2V0X2lyLnNoICRp
ciA+L2Rldi9udWxsIDI+L2Rldi9udWxsCgogIyBhZGp1c3QgZXhwb3N1cmUKIHNsZWVwICRkZWxh
eQoKICMgZ3JhYiB0aGUgaW1hZ2UgZnJvbSB0aGUKIHdnZXQgaHR0cDovLzEyNy4wLjAuMS9pbWFn
ZS5qcGcgLU8gJHtpbWFnZX0gPi9kZXYvbnVsbCAyPi9kZXYvbnVsbAoKICMgZ3JhYiBkYXRlIGFu
ZCB0aW1lIGZvciBgLm1ldGFgIGZpbGVzCiBNRVRBREFURVRJTUU9YGRhdGUgLUlzZWNvbmRzYAoK
ICMgZ3JhYiB0aGUgZXhwb3N1cmUgdGltZSBhbmQgYXBwZW5kIHRvIG1ldGEtZGF0YQogZXhwb3N1
cmU9YC91c3Ivc2Jpbi9nZXRfZXhwIHwgY3V0IC1kICcgJyAtZjRgCgogIyBhZGp1c3QgbWV0YS1k
YXRhIGZpbGUKIGNhdCAvdmFyL3RtcC9tZXRhZGF0YS50eHQgPiAvdmFyL3RtcC8ke21ldGFmaWxl
fQogZWNobyAiZXhwb3N1cmU9JHtleHBvc3VyZX0iID4+IC92YXIvdG1wLyR7bWV0YWZpbGV9CiBl
Y2hvICJpcl9lbmFibGU9JGlyIiA+PiAvdmFyL3RtcC8ke21ldGFmaWxlfQogZWNobyAiZGF0ZXRp
bWVfb3JpZ2luYWw9XCIkTUVUQURBVEVUSU1FXCIiID4+IC92YXIvdG1wLyR7bWV0YWZpbGV9Cgp9
CgojIGVycm9yIGhhbmRsaW5nCmxvZ2luX3N1Y2Nlc3MoKXsKIHNlcnZpY2U9InNGVFAiCn0KCiMg
LS0tLS0tLS0tLS0tLS0gU0VUVElOR1MgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLQoKIyByZWFkIGluIGNvbmZpZ3VyYXRpb24gc2V0dGluZ3MKIyBncmFiIHNpdGVu
YW1lClNJVEVOQU1FPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoKIyBncmFi
IHRpbWUgb2Zmc2V0IC8gbG9jYWwgdGltZSB6b25lCiMgYW5kIGNvbnZlcnQgKy8tIHRvIGFzY2lp
CnRpbWVfb2Zmc2V0PWBhd2sgJ05SPT0yJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApTSUdOPWBl
Y2hvICR7dGltZV9vZmZzZXR9IHwgY3V0IC1jJzEnYAoKaWYgWyAiJFNJR04iID0gIisiIF07IHRo
ZW4KIHRpbWVfb2Zmc2V0PWBlY2hvICIke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvKy8lMkIvZydg
CmVsc2UKIHRpbWVfb2Zmc2V0PWBlY2hvICIke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvLS8lMkQv
ZydgCmZpCgojIHNldCBjYW1lcmEgbW9kZWwgbmFtZQptb2RlbD0iTmV0Q2FtIExpdmUyIgoKIyBo
b3cgbWFueSBzZXJ2ZXJzIGRvIHdlIHVwbG9hZCB0bwpucnNlcnZlcnM9YGF3ayAnRU5EIHtwcmlu
dCBOUn0nIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YApucnNlcnZlcnM9YGF3ayAtdiB2YXI9JHtucnNl
cnZlcnN9ICdCRUdJTnsgbj0xOyB3aGlsZSAobiA8PSB2YXIgKSB7IHByaW50IG47IG4rKzsgfSB9
JyB8IHRyICdcbicgJyAnYAoKIyBncmFiIHBhc3N3b3JkCnBhc3M9YGF3ayAnTlI9PTEnIC9tbnQv
Y2ZnMS8ucGFzc3dvcmRgCgojIE1vdmUgaW50byB0ZW1wb3JhcnkgZGlyZWN0b3J5CiMgd2hpY2gg
cmVzaWRlcyBpbiBSQU0sIG5vdCB0bwojIHdlYXIgb3V0IG90aGVyIHBlcm1hbmVudCBtZW1vcnkK
Y2QgL3Zhci90bXAKCiMgc2V0cyB0aGUgZGVsYXkgYmV0d2VlbiB0aGUKIyBSR0IgYW5kIElSIGlt
YWdlIGFjcXVpc2l0aW9ucwpERUxBWT0zMAoKIyBncmFiIGRhdGUgLSBrZWVwIGZpeGVkIGZvciBS
R0IgYW5kIElSIHVwbG9hZHMKREFURT1gZGF0ZSArIiVhICViICVkICVZICVIOiVNOiVTImAKCiMg
Z3JhcCBkYXRlIGFuZCB0aW1lIHN0cmluZyB0byBiZSBpbnNlcnRlZCBpbnRvIHRoZQojIGZ0cCBz
Y3JpcHRzIC0gdGhpcyBjb29yZGluYXRlcyB0aGUgdGltZSBzdGFtcHMKIyBiZXR3ZWVuIHRoZSBS
R0IgYW5kIElSIGltYWdlcyAob3RoZXJ3aXNlIHRoZXJlIGlzIGEKIyBzbGlnaHQgb2Zmc2V0IGR1
ZSB0byB0aGUgdGltZSBuZWVkZWQgdG8gYWRqdXN0IGV4cG9zdXJlCkRBVEVUSU1FU1RSSU5HPWBk
YXRlICsiJVlfJW1fJWRfJUglTSVTImAKCiMgZ3JhYiBtZXRhZGF0YSB1c2luZyB0aGUgbWV0YWRh
dGEgZnVuY3Rpb24KIyBncmFiIHRoZSBNQUMgYWRkcmVzcwptYWNfYWRkcj1gaWZjb25maWcgZXRo
MCB8IGdyZXAgJ0hXYWRkcicgfCBhd2sgJ3twcmludCAkNX0nIHwgc2VkICdzLzovL2cnYAoKIyBn
cmFiIGludGVybmFsIGlwIGFkZHJlc3MKaXBfYWRkcj1gaWZjb25maWcgZXRoMCB8IGF3ayAnL2lu
ZXQgYWRkci97cHJpbnQgc3Vic3RyKCQyLDYpfSdgCgojIGdyYWIgZXh0ZXJuYWwgaXAgYWRkcmVz
cyBpZiB0aGVyZSBpcyBhbiBleHRlcm5hbCBjb25uZWN0aW9uCiMgZmlyc3QgdGVzdCB0aGUgY29u
bmVjdGlvbiB0byB0aGUgZ29vZ2xlIG5hbWUgc2VydmVyCmNvbm5lY3Rpb249YHBpbmcgLXEgLWMg
MSA4LjguOC44ID4gL2Rldi9udWxsICYmIGVjaG8gb2sgfHwgZWNobyBlcnJvcmAKCiMgZ3JhYiB0
aW1lIHpvbmUKdHo9YGNhdCAvdmFyL1RaYAoKIyBnZXQgU0QgY2FyZCBwcmVzZW5jZQpTRENBUkQ9
YGRmIHwgZ3JlcCAibW1jIiB8IHdjIC1sYAoKIyBiYWNrdXAgdG8gU0QgY2FyZCB3aGVuIGluc2Vy
dGVkCiMgcnVucyBvbiBwaGVub2NhbSB1cGxvYWQgcmF0aGVyIHRoYW4gaW5zdGFsbAojIHRvIGFs
bG93IGhvdC1zd2FwcGluZyBvZiBjYXJkcwppZiBbICIkU0RDQVJEIiAtZXEgMSBdOyB0aGVuCiAK
ICMgY3JlYXRlIGJhY2t1cCBkaXJlY3RvcnkKIG1rZGlyIC1wIC9tbnQvbW1jL3BoZW5vY2FtX2Jh
Y2t1cC8KIApmaQoKIyAtLS0tLS0tLS0tLS0tLSBTRVQgRklYRUQgREFURSBUSU1FIEhFQURFUiAt
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIG92ZXJsYXkgdGV4dApvdmVybGF5X3RleHQ9YGVj
aG8gIiR7U0lURU5BTUV9IC0gJHttb2RlbH0gLSAke0RBVEV9IC0gR01UJHt0aW1lX29mZnNldH0i
IHwgc2VkICdzLyAvJTIwL2cnYAoJCiMgZm9yIG5vdyBkaXNhYmxlIHRoZSBvdmVybGF5CndnZXQg
aHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9vdmVybGF5dGV4dDE9JHtvdmVy
bGF5X3RleHR9ID4vZGV2L251bGwgMj4vZGV2L251bGwKCiMgY2xlYW4gdXAgZGV0cml0dXMKcm0g
dmIqCgojIC0tLS0tLS0tLS0tLS0tIFNFVCBGSVhFRCBNRVRBLURBVEEgLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLQoKIyBjcmVhdGUgYmFzZSBtZXRhLWRhdGEgZmlsZSBmcm9tIGNvbmZp
Z3VyYXRpb24gc2V0dGluZ3MKIyBhbmQgdGhlIGZpeGVkIHBhcmFtZXRlcnMKZWNobyAibW9kZWw9
TmV0Q2FtIExpdmUyIiA+IC92YXIvdG1wL21ldGFkYXRhLnR4dAoKIyBjb2xvdXIgYmFsYW5jZSBz
ZXR0aW5ncwpyZWQ9YGF3ayAnTlI9PTcnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCmdyZWVuPWBh
d2sgJ05SPT04JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApibHVlPWBhd2sgJ05SPT05JyAvbW50
L2NmZzEvc2V0dGluZ3MudHh0YCAKYnJpZ2h0bmVzcz1gYXdrICdOUj09MTAnIC9tbnQvY2ZnMS9z
ZXR0aW5ncy50eHRgCnNoYXJwbmVzcz1gYXdrICdOUj09MTEnIC9tbnQvY2ZnMS9zZXR0aW5ncy50
eHRgCmh1ZT1gYXdrICdOUj09MTInIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCmNvbnRyYXN0PWBh
d2sgJ05SPT0xMycgL21udC9jZmcxL3NldHRpbmdzLnR4dGAJIApzYXR1cmF0aW9uPWBhd2sgJ05S
PT0xNCcgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKYmxjPWBhd2sgJ05SPT0xNScgL21udC9jZmcx
L3NldHRpbmdzLnR4dGAKbmV0d29yaz1gYXdrICdOUj09MTYnIC9tbnQvY2ZnMS9zZXR0aW5ncy50
eHRgCgplY2hvICJuZXR3b3JrPSRuZXR3b3JrIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNo
byAiaXBfYWRkcj0kaXBfYWRkciIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gIm1hY19h
ZGRyPSRtYWNfYWRkciIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gInRpbWVfem9uZT0k
dHoiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJvdmVybGF5X3RleHQ9JG92ZXJsYXlf
dGV4dCIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CgplY2hvICJyZWQ9JHJlZCIgPj4gL3Zhci90
bXAvbWV0YWRhdGEudHh0CmVjaG8gImdyZWVuPSRncmVlbiIgPj4gL3Zhci90bXAvbWV0YWRhdGEu
dHh0CmVjaG8gImJsdWU9JGJsdWUiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJicmln
aHRuZXNzPSRicmlnaHRuZXNzIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAiY29udHJh
c3Q9JGNvbnRyYXN0IiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAiaHVlPSRodWUiID4+
IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJzaGFycG5lc3M9JHNoYXJwbmVzcyIgPj4gL3Zh
ci90bXAvbWV0YWRhdGEudHh0CmVjaG8gInNhdHVyYXRpb249JHNhdHVyYXRpb24iID4+IC92YXIv
dG1wL21ldGFkYXRhLnR4dAplY2hvICJiYWNrbGlnaHQ9JGJsYyIgPj4gL3Zhci90bXAvbWV0YWRh
dGEudHh0CgojIC0tLS0tLS0tLS0tLS0tIFVQTE9BRCBEQVRBIC0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgd2UgdXNlIHR3byBzdGF0ZXMgdG8gaW5kaWNhdGUgVklT
ICgwKSBhbmQgTklSICgxKSBzdGF0ZXMKIyBhbmQgdXNlIGEgZm9yIGxvb3AgdG8gY3ljbGUgdGhy
b3VnaCB0aGVzZSBzdGF0ZXMgYW5kCiMgdXBsb2FkIHRoZSBkYXRhCnN0YXRlcz0iMCAxIgoKZm9y
IHN0YXRlIGluICRzdGF0ZXM7CmRvCgogaWYgWyAiJHN0YXRlIiAtZXEgMCBdOyB0aGVuCgogICMg
Y3JlYXRlIFZJUyBmaWxlbmFtZXMKICBtZXRhZmlsZT1gZWNobyAke1NJVEVOQU1FfV8ke0RBVEVU
SU1FU1RSSU5HfS5tZXRhYAogIGltYWdlPWBlY2hvICR7U0lURU5BTUV9XyR7REFURVRJTUVTVFJJ
Tkd9LmpwZ2AKICBjYXB0dXJlICRpbWFnZSAkbWV0YWZpbGUgJERFTEFZIDAKCiBlbHNlCgogICMg
Y3JlYXRlIE5JUiBmaWxlbmFtZXMKICBtZXRhZmlsZT1gZWNobyAke1NJVEVOQU1FfV9JUl8ke0RB
VEVUSU1FU1RSSU5HfS5tZXRhYAogIGltYWdlPWBlY2hvICR7U0lURU5BTUV9X0lSXyR7REFURVRJ
TUVTVFJJTkd9LmpwZ2AKICBjYXB0dXJlICRpbWFnZSAkbWV0YWZpbGUgJERFTEFZIDEKIAogZmkK
CiAjIHJ1biB0aGUgdXBsb2FkIHNjcmlwdCBmb3IgdGhlIGlwIGRhdGEKICMgYW5kIGZvciBhbGwg
c2VydmVycwogZm9yIGkgaW4gJG5yc2VydmVyczsKIGRvCiAgU0VSVkVSPWBhd2sgLXYgcD0kaSAn
TlI9PXAnIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YAogIGVjaG8gInVwbG9hZGluZyB0bzogJHtTRVJW
RVJ9IgogIGVjaG8gIiIKICAKICAjIC0tLS0tLS0tLS0tLS0tIFZBTElEQVRFIFNFUlZJQ0UgLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KICAjIGNoZWNrIGlmIHNGVFAgaXMgcmVhY2hh
YmxlCgogICMgc2V0IHRoZSBkZWZhdWx0IHNlcnZpY2UKICBzZXJ2aWNlPSJGVFAiCgogIGlmIFsg
LWYgIi9tbnQvY2ZnMS9waGVub2NhbV9rZXkiIF07IHRoZW4KCiAgIGVjaG8gIkFuIHNGVFAga2V5
IHdhcyBmb3VuZCwgY2hlY2tpbmcgbG9naW4gY3JlZGVudGlhbHMuLi4iCgogICBlY2hvICJleGl0
IiA+IGJhdGNoZmlsZQogICBzZnRwIC1iIGJhdGNoZmlsZSAtaSAiL21udC9jZmcxL3BoZW5vY2Ft
X2tleSIgcGhlbm9zZnRwQCR7U0VSVkVSfSA+L2Rldi9udWxsIDI+L2Rldi9udWxsCgogICAjIGlm
IHN0YXR1cyBvdXRwdXQgbGFzdCBjb21tYW5kIHdhcwogICAjIDAgc2V0IHNlcnZpY2UgdG8gc0ZU
UAogICBpZiBbICQ/IC1lcSAwIF07IHRoZW4KICAgIGVjaG8gIlNVQ0NFUy4uLiB1c2luZyBzZWN1
cmUgc0ZUUCIKICAgIGVjaG8gIiIKICAgIHNlcnZpY2U9InNGVFAiCiAgIGVsc2UKICAgIGVjaG8g
IkZBSUxFRC4uLiBmYWxsaW5nIGJhY2sgdG8gRlRQISIKICAgIGVjaG8gIiIKICAgZmkKIAogICAj
IGNsZWFuIHVwCiAgIHJtIGJhdGNoZmlsZQogIGZpCiAgIyAtLS0tLS0tLS0tLS0tLSBWQUxJREFU
RSBTRVJWSUNFIEVORCAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKICAjIGlmIGtleSBm
aWxlIGV4aXN0cyB1c2UgU0ZUUAogIGlmIFsgIiR7c2VydmljZX0iICE9ICJGVFAiIF07IHRoZW4K
ICAgZWNobyAidXNpbmcgc0ZUUCIKICAKICAgZWNobyAiUFVUICR7aW1hZ2V9IGRhdGEvJHtTSVRF
TkFNRX0vJHtpbWFnZX0iID4gYmF0Y2hmaWxlCiAgIGVjaG8gIlBVVCAke21ldGFmaWxlfSBkYXRh
LyR7U0lURU5BTUV9LyR7bWV0YWZpbGV9IiA+PiBiYXRjaGZpbGUKICAKICAgIyB1cGxvYWQgdGhl
IGRhdGEKICAgZWNobyAiVXBsb2FkaW5nIChzdGF0ZTogJHtzdGF0ZX0pIgogICBlY2hvICIgLSBp
bWFnZSBmaWxlOiAke2ltYWdlfSIKICAgZWNobyAiIC0gbWV0YS1kYXRhIGZpbGU6ICR7bWV0YWZp
bGV9IgogICBzZnRwIC1iIGJhdGNoZmlsZSAtaSAiL21udC9jZmcxL3BoZW5vY2FtX2tleSIgcGhl
bm9zZnRwQCR7U0VSVkVSfSA+L2Rldi9udWxsIDI+L2Rldi9udWxsIHx8IGVycm9yX2V4aXQKICAg
CiAgICMgcmVtb3ZlIGJhdGNoIGZpbGUKICAgcm0gYmF0Y2hmaWxlCiAgIAogIGVsc2UKICAgZWNo
byAiVXNpbmcgRlRQIFtjaGVjayB5b3VyIGluc3RhbGwgYW5kIGtleSBjcmVkZW50aWFscyB0byB1
c2Ugc0ZUUF0iCiAgCiAgICMgdXBsb2FkIGltYWdlCiAgIGVjaG8gIlVwbG9hZGluZyAoc3RhdGU6
ICR7c3RhdGV9KSIKICAgZWNobyAiIC0gaW1hZ2UgZmlsZTogJHtpbWFnZX0iCiAgIGZ0cHB1dCAk
e1NFUlZFUn0gLS11c2VybmFtZSBhbm9ueW1vdXMgLS1wYXNzd29yZCBhbm9ueW1vdXMgIGRhdGEv
JHtTSVRFTkFNRX0vJHtpbWFnZX0gJHtpbWFnZX0gPi9kZXYvbnVsbCAyPi9kZXYvbnVsbCB8fCBl
cnJvcl9leGl0CgkKICAgZWNobyAiIC0gbWV0YS1kYXRhIGZpbGU6ICR7bWV0YWZpbGV9IgogICBm
dHBwdXQgJHtTRVJWRVJ9IC0tdXNlcm5hbWUgYW5vbnltb3VzIC0tcGFzc3dvcmQgYW5vbnltb3Vz
ICBkYXRhLyR7U0lURU5BTUV9LyR7bWV0YWZpbGV9ICR7bWV0YWZpbGV9ID4vZGV2L251bGwgMj4v
ZGV2L251bGwgfHwgZXJyb3JfZXhpdAoKICBmaQogZG9uZQoKICMgYmFja3VwIHRvIFNEIGNhcmQg
d2hlbiBpbnNlcnRlZAogaWYgWyAiJFNEQ0FSRCIgLWVxIDEgXTsgdGhlbiAKICBjcCAke2ltYWdl
fSAvbW50L21tYy9waGVub2NhbV9iYWNrdXAvJHtpbWFnZX0KICBjcCAke21ldGFmaWxlfSAvbW50
L21tYy9waGVub2NhbV9iYWNrdXAvJHttZXRhZmlsZX0KIGZpCgogIyBjbGVhbiB1cCBmaWxlcwog
cm0gKi5qcGcKIHJtICoubWV0YQoKZG9uZQoKIyBSZXNldCB0byBWSVMgYXMgZGVmYXVsdAovdXNy
L3NiaW4vc2V0X2lyLnNoIDAKCiMtLS0tLS0tLS0tLS0tLSBSRVNFVCBOT1JNQUwgSEVBREVSIC0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIG92ZXJsYXkgdGV4dApvdmVybGF5X3Rl
eHQ9YGVjaG8gIiR7U0lURU5BTUV9IC0gJHttb2RlbH0gLSAlYSAlYiAlZCAlWSAlSDolTTolUyAt
IEdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8gLyUyMC9nJ2AKCQojIGZvciBub3cgZGlzYWJs
ZSB0aGUgb3ZlcmxheQp3Z2V0IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/
b3ZlcmxheXRleHQxPSR7b3ZlcmxheV90ZXh0fSA+L2Rldi9udWxsIDI+L2Rldi9udWxsCgojIGNs
ZWFuIHVwIGRldHJpdHVzCnJtIHZiKgoKIy0tLS0tLS0gRkVFREJBQ0sgT04gQUNUSVZJVFkgLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCmlmIFsgISAtZiAiL3Zhci90bXAv
aW1hZ2VfbG9nLnR4dCIgXTsgdGhlbgogdG91Y2ggL3Zhci90bXAvaW1hZ2VfbG9nLnR4dAogY2ht
b2QgYStydyAvdmFyL3RtcC9pbWFnZV9sb2cudHh0CmZpCgplY2hvICJsYXN0IHVwbG9hZHMgYXQ6
IiA+PiAvdmFyL3RtcC9pbWFnZV9sb2cudHh0CmVjaG8gJERBVEUgPj4gL3Zhci90bXAvaW1hZ2Vf
bG9nLnR4dAp0YWlsIC92YXIvdG1wL2ltYWdlX2xvZy50eHQKCiMtLS0tLS0tIEZJTEUgUEVSTUlT
U0lPTlMgQU5EIENMRUFOVVAgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQpybSAtZiAv
dmFyL3RtcC9tZXRhZGF0YS50eHQKCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMvcGhlbm9jYW1fdmFsaWRhdGUuc2gAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAADAwMDA3NzUAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDAzMTYyADE0Njc0NTA0NDAzADAxNjQx
MwAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhciAgAGto
dWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAjIS9iaW4vc2gKCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIChjKSBLb2VuIEh1Zmtl
bnMgZm9yIEJsdWVHcmVlbiBMYWJzIChCVikKIwojIFVuYXV0aG9yaXplZCBjaGFuZ2VzIHRvIHRo
aXMgc2NyaXB0IGFyZSBjb25zaWRlcmVkIGEgY29weXJpZ2h0CiMgdmlvbGF0aW9uIGFuZCB3aWxs
IGJlIHByb3NlY3V0ZWQuCiMKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIGhhcmQgY29kZSBwYXRoIHdoaWNoIGFy
ZSBsb3N0IGluIHNvbWUgaW5zdGFuY2VzCiMgd2hlbiBjYWxsaW5nIHRoZSBzY3JpcHQgdGhyb3Vn
aCBzc2ggClBBVEg9Ii91c3IvbG9jYWwvYmluOi91c3IvbG9jYWwvc2JpbjovdXNyL2JpbjovdXNy
L3NiaW46L2Jpbjovc2JpbiIKCiMgLS0tLS0tLS0tLS0tLS0gU0VUVElOR1MgLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBNb3ZlIGludG8gdGVtcG9yYXJ5IGRp
cmVjdG9yeQojIHdoaWNoIHJlc2lkZXMgaW4gUkFNLCBub3QgdG8KIyB3ZWFyIG91dCBvdGhlciBw
ZXJtYW5lbnQgbWVtb3J5CmNkIC92YXIvdG1wCgojIGhvdyBtYW55IHNlcnZlcnMgZG8gd2UgdXBs
b2FkIHRvCm5yc2VydmVycz1gYXdrICdFTkQge3ByaW50IE5SfScgL21udC9jZmcxL3NlcnZlci50
eHRgCm5yc2VydmVycz1gYXdrIC12IHZhcj0ke25yc2VydmVyc30gJ0JFR0lOeyBuPTE7IHdoaWxl
IChuIDw9IHZhciApIHsgcHJpbnQgbjsgbisrOyB9IH0nIHwgdHIgJ1xuJyAnICdgCgojIC0tLS0t
LS0tLS0tLS0tIFZBTElEQVRFIExPR0lOIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tCgppZiBbICEgLWYgIi9tbnQvY2ZnMS9waGVub2NhbV9rZXkiIF07IHRoZW4KIGVjaG8g
Im5vIHNGVFAga2V5IGZvdW5kLCBub3RoaW5nIHRvIGJlIGRvbmUuLi4iCiBleGl0IDAKZmkKCiMg
cnVuIHRoZSB1cGxvYWQgc2NyaXB0IGZvciB0aGUgaXAgZGF0YQojIGFuZCBmb3IgYWxsIHNlcnZl
cnMKZm9yIGkgaW4gJG5yc2VydmVyczsKZG8KICBTRVJWRVI9YGF3ayAtdiBwPSRpICdOUj09cCcg
L21udC9jZmcxL3NlcnZlci50eHRgCiAKICBlY2hvICIiIAogIGVjaG8gIkNoZWNraW5nIHNlcnZl
cjogJHtTRVJWRVJ9IgogIGVjaG8gIiIKCiAgZWNobyAiZXhpdCIgPiBiYXRjaGZpbGUKICBzZnRw
IC1iIGJhdGNoZmlsZSAtaSAiL21udC9jZmcxL3BoZW5vY2FtX2tleSIgcGhlbm9zZnRwQCR7U0VS
VkVSfSA+L2Rldi9udWxsIDI+L2Rldi9udWxsCgogICMgaWYgc3RhdHVzIG91dHB1dCBsYXN0IGNv
bW1hbmQgd2FzCiAgIyAwIHNldCBzZXJ2aWNlIHRvIHNGVFAKICBpZiBbICQ/IC1lcSAwIF07IHRo
ZW4KICAgIGVjaG8gIlNVQ0NFUy4uLiBzZWN1cmUgc0ZUUCBsb2dpbiB3b3JrZWQiCiAgICBlY2hv
ICIiCiAgZWxzZQogICAgZWNobyAiRkFJTEVELi4uIHNlY3VyZSBzRlRQIGxvZ2luIGRpZCBub3Qg
d29yayIKICAgIGVjaG8gIltkYXRhIHVwbG9hZHMgd2lsbCBmYWxsIGJhY2sgdG8gaW5zZWN1cmUg
RlRQIG1vZGVdIgogICAgZWNobyAiIgogIGZpCiAgCiAgIyBjbGVhbnVwCiAgcm0gYmF0Y2hmaWxl
CmRvbmUKCmV4aXQgMAoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAGZpbGVzL3JlYm9vdF9jYW1lcmEuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAw
MDAwNjY0ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAwMjA0MQAxNDY1NzcwNzUwMQAwMTU1NDcAIDAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXN0YXIgIABraHVma2Vu
cwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAIyEvYmluL3NoCgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KIyAoYykgS29lbiBIdWZrZW5zIGZv
ciBCbHVlR3JlZW4gTGFicyAoQlYpCiMKIyBVbmF1dGhvcml6ZWQgY2hhbmdlcyB0byB0aGlzIHNj
cmlwdCBhcmUgY29uc2lkZXJlZCBhIGNvcHlyaWdodAojIHZpb2xhdGlvbiBhbmQgd2lsbCBiZSBw
cm9zZWN1dGVkLgojCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBoYXJkIGNvZGUgcGF0aCB3aGljaCBhcmUgbG9z
dCBpbiBzb21lIGluc3RhbmNlcwojIHdoZW4gY2FsbGluZyB0aGUgc2NyaXB0IHRocm91Z2ggc3No
IApQQVRIPSIvdXNyL2xvY2FsL2JpbjovdXNyL2xvY2FsL3NiaW46L3Vzci9iaW46L3Vzci9zYmlu
Oi9iaW46L3NiaW4iCgojIGdyYWIgcGFzc3dvcmQKcGFzcz1gYXdrICdOUj09MScgL21udC9jZmcx
Ly5wYXNzd29yZGAKCiMgbW92ZSBpbnRvIHRlbXBvcmFyeSBkaXJlY3RvcnkKY2QgL3Zhci90bXAK
CiMgc2xlZXAgMzAgc2Vjb25kcyBmb3IgbGFzdAojIGNvbW1hbmQgdG8gZmluaXNoIChpZiBhbnkg
c2hvdWxkIGJlIHJ1bm5pbmcpCnNsZWVwIDMwCgojIHRoZW4gcmVib290CndnZXQgaHR0cDovL2Fk
bWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9pcGNhbXJlc3RhcnRjbWQgJj4vZGV2L251bGwK
CiMgZG9uJ3QgZXhpdCBjbGVhbmx5IHdoZW4gdGhlIHJlYm9vdCBjb21tYW5kIGRvZXNuJ3Qgc3Rp
Y2sKIyBzaG91bGQgdHJpZ2dlciBhIHdhcm5pbmcgbWVzc2FnZQpzbGVlcCA2MAoKZWNobyAiIC0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
IgplY2hvICIiCmVjaG8gIiBSRUJPT1QgRkFJTEVEIC0gSU5TVEFMTCBNSUdIVCBOT1QgQkUgQ09N
UExFVEUhIgplY2hvICIiCmVjaG8gIj09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09IgoKZXhpdCAxCgAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAZmlsZXMvc2l0ZV9pcC5odG1sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA2
NjQAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDAwNTYwADE0NTM2NTUyNTAwADAxNDczMAAgMAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhciAgAGtodWZrZW5zAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAA8IURPQ1RZUEUgaHRtbCBQVUJMSUMgIi0vL1czQy8vRFREIEhUTUwgNC4wIFRyYW5z
aXRpb25hbC8vRU4iPgo8aHRtbD4KPGhlYWQ+CjxtZXRhIGh0dHAtZXF1aXY9IkNvbnRlbnQtVHlw
ZSIgY29udGVudD0idGV4dC9odG1sOyBjaGFyc2V0PWlzby04ODU5LTEiPgo8dGl0bGU+TmV0Q2Ft
U0MgSVAgQWRkcmVzczwvdGl0bGU+CjwvaGVhZD4KPGJvZHk+ClRpbWUgb2YgTGFzdCBJUCBVcGxv
YWQ6IERBVEVUSU1FPGJyPgpJUCBBZGRyZXNzOiBTSVRFSVAKJmJ1bGw7IDxhIGhyZWY9Imh0dHA6
Ly9TSVRFSVAvIj5WaWV3PC9hPgomYnVsbDsgPGEgaHJlZj0iaHR0cDovL1NJVEVJUC9hZG1pbi5j
Z2kiPkNvbmZpZ3VyZTwvYT4KPC9ib2R5Pgo8L2h0bWw+CgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
