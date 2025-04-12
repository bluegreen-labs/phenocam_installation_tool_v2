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
  [-f <fix a non-random interval> logical TRUE or FALSE]
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
while getopts "hi:p:n:o:s:e:m:f:d:uvrx" option;
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
        f) fix=${OPTARG} ;;
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

if [[ -z ${fix} || ${fix} == -* ]]; then
 echo " NOTE: fixed interval randomization not set, using the default (FALSE)"
 fix='FALSE'
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
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh ${fix}' >> /mnt/cfg1/userboot.sh &&
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
 echo ' Fixed (non random) interval: ${fix}' &&
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
 echo ' and send this key to phenocam@nau.edu (Phenocam US) to' &&
 echo ' or phenocam@uantwerpen.be (ICOS) to complete the install.' &&
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
MAAwMDAxNzUwADAwMDAwMDAzMTc1ADE0Nzc2NDMzNjU2ADAxNTc0MAAgMAAAAAAAAAAAAAAAAAAA
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
PT09PT09PT09PT09PT09PT09PT0iCiBleGl0IDEKCmVsc2UKICAKICMgY2xlYW4gZXhpdAogZXhp
dCAwCmZpCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZpbGVz
L3BoZW5vY2FtX2luc3RhbGwuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzc1ADAwMDE3NTAAMDAw
MTc1MAAwMDAwMDAxMzA0MgAxNDc3NjQyNjQwNwAwMTYzMDAAIDAAAAAAAAAAAAAAAAAAAAAAAAAA
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
cmFuZG9tIG51bWJlciBiZXR3ZWVuIDAgYW5kIHRoZSBpbnRlcnZhbCB2YWx1ZQoJCgkjIGdldCBv
bmx5IGFyZ3VtZW50IGZvciB0aGUgc2NyaXB0IGNvbmNlcm5pbmcKCSMgZml4aW5nIHRoZSBzY2hl
ZHVsZSwgY29udmVydCB0byBsb3dlciBjYXBzCglmaXg9YGVjaG8gJDEgfCBhd2sgJ3twcmludCB0
b2xvd2VyKCQwKX0nYAoJCQoJaWYgW1sgIiRmaXgiID09ICJ0cnVlIiBdXTsgdGhlbgoJIHJudW1i
ZXI9MAoJZWxzZQoJIHJudW1iZXI9YGF3ayAtdiBtaW49MCAtdiBtYXg9JHtjcm9uX2ludH0gJ0JF
R0lOe3NyYW5kKCk7IHByaW50IGludChtaW4rcmFuZCgpKihtYXgtbWluKzEpKX0nYAoJZmkKCQoJ
IyBkaXZpZGUgNjAgbWluIGJ5IHRoZSBpbnRlcnZhbAoJZGl2PWBhd2sgLXYgaW50ZXJ2YWw9JHtj
cm9uX2ludH0gJ0JFR0lOIHtwcmludCA1OS9pbnRlcnZhbH0nYAoJaW50PWBlY2hvICRkaXYgfCBj
dXQgLWQnLicgLWYxYAoJCgkjIGdlbmVyYXRlIGxpc3Qgb2YgdmFsdWVzIHRvIGl0ZXJhdGUgb3Zl
cgoJdmFsdWVzPWBhd2sgLXYgbWF4PSR7aW50fSAnQkVHSU57IGZvcihpPTA7aTw9bWF4O2krKykg
cHJpbnQgaX0nYAoJCglmb3IgaSBpbiAke3ZhbHVlc307IGRvCgkgcHJvZHVjdD1gYXdrIC12IGlu
dGVydmFsPSR7Y3Jvbl9pbnR9IC12IHN0ZXA9JHtpfSAnQkVHSU4ge3ByaW50IGludChpbnRlcnZh
bCpzdGVwKX0nYAkKCSBzdW09YGF3ayAtdiBwcm9kdWN0PSR7cHJvZHVjdH0gLXYgbnI9JHtybnVt
YmVyfSAnQkVHSU4ge3ByaW50IGludChwcm9kdWN0K25yKX0nYAoJIAoJIGlmIFsgIiR7aX0iIC1l
cSAiMCIgXTt0aGVuCgkgIGludGVydmFsPWBlY2hvICR7c3VtfWAKCSBlbHNlCgkgIGlmIFsgIiRz
dW0iIC1sZSAiNTkiIF07dGhlbgoJICAgaW50ZXJ2YWw9YGVjaG8gJHtpbnRlcnZhbH0sJHtzdW19
YAoJICBmaQoJIGZpCglkb25lCgoJZWNobyAiY3JvbnRhYiBpbnRlcnZhbHMgc2V0IHRvOiAke2lu
dGVydmFsfSIgPj4gL3Zhci90bXAvaW5zdGFsbF9sb2cudHh0CgoJIy0tLS0tIHNldCByb290IGNy
b24gam9icwoJCgkjIHNldCB0aGUgbWFpbiBwaWN0dXJlIHRha2luZyByb3V0aW5lCgllY2hvICIk
e2ludGVydmFsfSAke2Nyb25fc3RhcnR9LSR7Y3Jvbl9lbmR9ICogKiAqIHNoIC9tbnQvY2ZnMS9z
Y3JpcHRzL3BoZW5vY2FtX3VwbG9hZC5zaCIgPiAvbW50L2NmZzEvc2NoZWR1bGUvYWRtaW4KCQkK
CSMgdXBsb2FkIGlwIGFkZHJlc3MgaW5mbyBhdCBtaWRkYXkKCWVjaG8gIjU5IDExICogKiAqIHNo
IC9tbnQvY2ZnMS9zY3JpcHRzL3BoZW5vY2FtX2lwX3RhYmxlLnNoIiA+PiAvbW50L2NmZzEvc2No
ZWR1bGUvYWRtaW4KCQkKCSMgcmVib290IGF0IG1pZG5pZ2h0IG9uIHJvb3QgYWNjb3VudAoJZWNo
byAiNTkgMjMgKiAqICogc2ggL21udC9jZmcxL3NjcmlwdHMvcmVib290X2NhbWVyYS5zaCIgPiAv
bW50L2NmZzEvc2NoZWR1bGUvcm9vdAoJCgkjIGluZm8KCWVjaG8gIkZpbmlzaGVkIGluaXRpYWwg
c2V0dXAiID4+IC92YXIvdG1wL2luc3RhbGxfbG9nLnR4dAoKCSMtLS0tLSBmaW5hbGl6ZSB0aGUg
c2V0dXAgKyByZWJvb3QKCgkjIHVwZGF0ZSB0aGUgc3RhdGUgb2YgdGhlIHVwZGF0ZSByZXF1aXJl
bWVudAoJIyBpLmUuIHNraXAgaWYgY2FsbGVkIG1vcmUgdGhhbiBvbmNlLCB1bmxlc3MKCSMgdGhp
cyBmaWxlIGlzIG1hbnVhbGx5IHNldCB0byBUUlVFIHdoaWNoCgkjIHdvdWxkIHJlcnVuIHRoZSBp
bnN0YWxsIHJvdXRpbmUgdXBvbiByZWJvb3QKCWVjaG8gIkZBTFNFIiA+IC9tbnQvY2ZnMS91cGRh
dGUudHh0CgoJIyByZWJvb3RpbmcgY2FtZXJhIHRvIG1ha2Ugc3VyZSBhbGwKCSMgdGhlIHNldHRp
bmdzIHN0aWNrCglzaCAvbW50L2NmZzEvc2NyaXB0cy9yZWJvb3RfY2FtZXJhLnNoCmZpCgojIGNs
ZWFuIGV4aXQKZXhpdCAwCgoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMvcGhlbm9jYW1faXBf
dGFibGUuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NTUAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDAy
NTIyADE0NzI3MDY2MDYwADAxNjM3NwAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAB1c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa2h1Zmtl
bnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAjIS9iaW4vc2gKCiMtLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLQojIChjKSBLb2VuIEh1ZmtlbnMgZm9yIEJsdWVHcmVlbiBMYWJzIChCVikKIwojIFVuYXV0
aG9yaXplZCBjaGFuZ2VzIHRvIHRoaXMgc2NyaXB0IGFyZSBjb25zaWRlcmVkIGEgY29weXJpZ2h0
CiMgdmlvbGF0aW9uIGFuZCB3aWxsIGJlIHByb3NlY3V0ZWQuCiMKIy0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIGhh
cmQgY29kZSBwYXRoIHdoaWNoIGFyZSBsb3N0IGluIHNvbWUgaW5zdGFuY2VzCiMgd2hlbiBjYWxs
aW5nIHRoZSBzY3JpcHQgdGhyb3VnaCBzc2ggClBBVEg9Ii91c3IvbG9jYWwvYmluOi91c3IvbG9j
YWwvc2JpbjovdXNyL2JpbjovdXNyL3NiaW46L2Jpbjovc2JpbiIKCiMgc29tZSBmZWVkYmFjayBv
biB0aGUgYWN0aW9uCmVjaG8gInVwbG9hZGluZyBJUCB0YWJsZSIKCiMgaG93IG1hbnkgc2VydmVy
cyBkbyB3ZSB1cGxvYWQgdG8KbnJzZXJ2ZXJzPWBhd2sgJ0VORCB7cHJpbnQgTlJ9JyAvbW50L2Nm
ZzEvc2VydmVyLnR4dGAKbnJzZXJ2ZXJzPWBhd2sgLXYgdmFyPSR7bnJzZXJ2ZXJzfSAnQkVHSU57
IG49MTsgd2hpbGUgKG4gPD0gdmFyICkgeyBwcmludCBuOyBuKys7IH0gfScgfCB0ciAnXG4nICcg
J2AKCiMgZ3JhYiB0aGUgbmFtZSwgZGF0ZSBhbmQgSVAgb2YgdGhlIGNhbWVyYQpEQVRFVElNRT1g
ZGF0ZWAKCiMgZ3JhYiBpbnRlcm5hbCBpcCBhZGRyZXNzCklQPWBpZmNvbmZpZyBldGgwIHwgYXdr
ICcvaW5ldCBhZGRyL3twcmludCBzdWJzdHIoJDIsNil9J2AKU0lURU5BTUU9YGF3ayAnTlI9PTEn
IC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgojIHVwZGF0ZSB0aGUgSVAgYW5kIHRpbWUgdmFyaWFi
bGVzCmNhdCAvbW50L2NmZzEvc2NyaXB0cy9zaXRlX2lwLmh0bWwgfCBzZWQgInN8REFURVRJTUV8
JERBVEVUSU1FfGciIHwgc2VkICJzfFNJVEVJUHwkSVB8ZyIgPiAvdmFyL3RtcC8ke1NJVEVOQU1F
fVxfaXAuaHRtbAoKIyBydW4gdGhlIHVwbG9hZCBzY3JpcHQgZm9yIHRoZSBpcCBkYXRhCiMgYW5k
IGZvciBhbGwgc2VydmVycwpmb3IgaSBpbiAkbnJzZXJ2ZXJzIDsKZG8KIFNFUlZFUj1gYXdrIC12
IHA9JGkgJ05SPT1wJyAvbW50L2NmZzEvc2VydmVyLnR4dGAgCiBmdHBwdXQgJHtTRVJWRVJ9IC11
ICJhbm9ueW1vdXMiIC1wICJhbm9ueW1vdXMiIGRhdGEvJHtTSVRFTkFNRX0vJHtTSVRFTkFNRX1c
X2lwLmh0bWwgL3Zhci90bXAvJHtTSVRFTkFNRX1cX2lwLmh0bWwKZG9uZQoKIyBjbGVhbiB1cApy
bSAvdmFyL3RtcC8ke1NJVEVOQU1FfVxfaXAuaHRtbAoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxlcy9waGVub2NhbV91cGxvYWQu
c2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDc3NQAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMjA3MTMA
MTQ3NDcxNjYyNTQAMDE2MTIwACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAHVzdGFyICAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABraHVma2VucwAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMhL2Jpbi9zaAoKIy0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
CiMgKGMpIEtvZW4gSHVma2VucyBmb3IgQmx1ZUdyZWVuIExhYnMgKEJWKQojCiMgVW5hdXRob3Jp
emVkIGNoYW5nZXMgdG8gdGhpcyBzY3JpcHQgYXJlIGNvbnNpZGVyZWQgYSBjb3B5cmlnaHQKIyB2
aW9sYXRpb24gYW5kIHdpbGwgYmUgcHJvc2VjdXRlZC4KIwojLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgaGFyZCBj
b2RlIHBhdGggd2hpY2ggYXJlIGxvc3QgaW4gc29tZSBpbnN0YW5jZXMKIyB3aGVuIGNhbGxpbmcg
dGhlIHNjcmlwdCB0aHJvdWdoIHNzaCAKUEFUSD0iL3Vzci9sb2NhbC9iaW46L3Vzci9sb2NhbC9z
YmluOi91c3IvYmluOi91c3Ivc2JpbjovYmluOi9zYmluIgoKIyBlcnJvciBoYW5kbGluZwplcnJv
cl9leGl0KCl7CiAgZWNobyAiIgogIGVjaG8gIiBGQUlMRUQgVE8gVVBMT0FEIERBVEEiCiAgZWNo
byAiIgp9CgojLS0tLSBmZWVkYmFjayBvbiBzdGFydHVwIC0tLQoKZWNobyAiIgplY2hvICJTdGFy
dGluZyBpbWFnZSB1cGxvYWRzIC4uLiAiCmVjaG8gIiIKCiMtLS0tIHN1YnJvdXRpbmVzIC0tLQoK
Y2FwdHVyZSgpIHsKCiBpbWFnZT0kMQogbWV0YWZpbGU9JDIKIGRlbGF5PSQzCiBpcj0kNAoKICMg
U2V0IHRoZSBpbWFnZSB0byBub24gSVIgaS5lLiBWSVMKIC91c3Ivc2Jpbi9zZXRfaXIuc2ggJGly
ID4vZGV2L251bGwgMj4vZGV2L251bGwKCiAjIGFkanVzdCBleHBvc3VyZQogc2xlZXAgJGRlbGF5
CgogIyBncmFiIHRoZSBpbWFnZSBmcm9tIHRoZQogd2dldCBodHRwOi8vMTI3LjAuMC4xL2ltYWdl
LmpwZyAtTyAke2ltYWdlfSA+L2Rldi9udWxsIDI+L2Rldi9udWxsCgogIyBncmFiIGRhdGUgYW5k
IHRpbWUgZm9yIGAubWV0YWAgZmlsZXMKIE1FVEFEQVRFVElNRT1gZGF0ZSAtSXNlY29uZHNgCgog
IyBncmFiIHRoZSBleHBvc3VyZSB0aW1lIGFuZCBhcHBlbmQgdG8gbWV0YS1kYXRhCiBleHBvc3Vy
ZT1gL3Vzci9zYmluL2dldF9leHAgfCBjdXQgLWQgJyAnIC1mNGAKCiAjIGFkanVzdCBtZXRhLWRh
dGEgZmlsZQogY2F0IC92YXIvdG1wL21ldGFkYXRhLnR4dCA+IC92YXIvdG1wLyR7bWV0YWZpbGV9
CiBlY2hvICJleHBvc3VyZT0ke2V4cG9zdXJlfSIgPj4gL3Zhci90bXAvJHttZXRhZmlsZX0KIGVj
aG8gImlyX2VuYWJsZT0kaXIiID4+IC92YXIvdG1wLyR7bWV0YWZpbGV9CiBlY2hvICJkYXRldGlt
ZV9vcmlnaW5hbD1cIiRNRVRBREFURVRJTUVcIiIgPj4gL3Zhci90bXAvJHttZXRhZmlsZX0KCn0K
CiMgZXJyb3IgaGFuZGxpbmcKbG9naW5fc3VjY2Vzcygpewogc2VydmljZT0ic0ZUUCIKfQoKIyAt
LS0tLS0tLS0tLS0tLSBTRVRUSU5HUyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tCgojIHJlYWQgaW4gY29uZmlndXJhdGlvbiBzZXR0aW5ncwojIGdyYWIgc2l0ZW5h
bWUKU0lURU5BTUU9YGF3ayAnTlI9PTEnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgojIGdyYWIg
dGltZSBvZmZzZXQgLyBsb2NhbCB0aW1lIHpvbmUKIyBhbmQgY29udmVydCArLy0gdG8gYXNjaWkK
dGltZV9vZmZzZXQ9YGF3ayAnTlI9PTInIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgClNJR049YGVj
aG8gJHt0aW1lX29mZnNldH0gfCBjdXQgLWMnMSdgCgppZiBbICIkU0lHTiIgPSAiKyIgXTsgdGhl
bgogdGltZV9vZmZzZXQ9YGVjaG8gIiR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8rLyUyQi9nJ2AK
ZWxzZQogdGltZV9vZmZzZXQ9YGVjaG8gIiR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8tLyUyRC9n
J2AKZmkKCiMgc2V0IGNhbWVyYSBtb2RlbCBuYW1lCm1vZGVsPSJOZXRDYW0gTGl2ZTIiCgojIGhv
dyBtYW55IHNlcnZlcnMgZG8gd2UgdXBsb2FkIHRvCm5yc2VydmVycz1gYXdrICdFTkQge3ByaW50
IE5SfScgL21udC9jZmcxL3NlcnZlci50eHRgCm5yc2VydmVycz1gYXdrIC12IHZhcj0ke25yc2Vy
dmVyc30gJ0JFR0lOeyBuPTE7IHdoaWxlIChuIDw9IHZhciApIHsgcHJpbnQgbjsgbisrOyB9IH0n
IHwgdHIgJ1xuJyAnICdgCgojIGdyYWIgcGFzc3dvcmQKcGFzcz1gYXdrICdOUj09MScgL21udC9j
ZmcxLy5wYXNzd29yZGAKCiMgTW92ZSBpbnRvIHRlbXBvcmFyeSBkaXJlY3RvcnkKIyB3aGljaCBy
ZXNpZGVzIGluIFJBTSwgbm90IHRvCiMgd2VhciBvdXQgb3RoZXIgcGVybWFuZW50IG1lbW9yeQpj
ZCAvdmFyL3RtcAoKIyBzZXRzIHRoZSBkZWxheSBiZXR3ZWVuIHRoZQojIFJHQiBhbmQgSVIgaW1h
Z2UgYWNxdWlzaXRpb25zCkRFTEFZPTMwCgojIGdyYWIgZGF0ZSAtIGtlZXAgZml4ZWQgZm9yIFJH
QiBhbmQgSVIgdXBsb2FkcwpEQVRFPWBkYXRlICsiJWEgJWIgJWQgJVkgJUg6JU06JVMiYAoKIyBn
cmFwIGRhdGUgYW5kIHRpbWUgc3RyaW5nIHRvIGJlIGluc2VydGVkIGludG8gdGhlCiMgZnRwIHNj
cmlwdHMgLSB0aGlzIGNvb3JkaW5hdGVzIHRoZSB0aW1lIHN0YW1wcwojIGJldHdlZW4gdGhlIFJH
QiBhbmQgSVIgaW1hZ2VzIChvdGhlcndpc2UgdGhlcmUgaXMgYQojIHNsaWdodCBvZmZzZXQgZHVl
IHRvIHRoZSB0aW1lIG5lZWRlZCB0byBhZGp1c3QgZXhwb3N1cmUKREFURVRJTUVTVFJJTkc9YGRh
dGUgKyIlWV8lbV8lZF8lSCVNJVMiYAoKIyBncmFiIG1ldGFkYXRhIHVzaW5nIHRoZSBtZXRhZGF0
YSBmdW5jdGlvbgojIGdyYWIgdGhlIE1BQyBhZGRyZXNzCm1hY19hZGRyPWBpZmNvbmZpZyBldGgw
IHwgZ3JlcCAnSFdhZGRyJyB8IGF3ayAne3ByaW50ICQ1fScgfCBzZWQgJ3MvOi8vZydgCgojIGdy
YWIgaW50ZXJuYWwgaXAgYWRkcmVzcwppcF9hZGRyPWBpZmNvbmZpZyBldGgwIHwgYXdrICcvaW5l
dCBhZGRyL3twcmludCBzdWJzdHIoJDIsNil9J2AKCiMgZ3JhYiBleHRlcm5hbCBpcCBhZGRyZXNz
IGlmIHRoZXJlIGlzIGFuIGV4dGVybmFsIGNvbm5lY3Rpb24KIyBmaXJzdCB0ZXN0IHRoZSBjb25u
ZWN0aW9uIHRvIHRoZSBnb29nbGUgbmFtZSBzZXJ2ZXIKY29ubmVjdGlvbj1gcGluZyAtcSAtYyAx
IDguOC44LjggPiAvZGV2L251bGwgJiYgZWNobyBvayB8fCBlY2hvIGVycm9yYAoKIyBncmFiIHRp
bWUgem9uZQp0ej1gY2F0IC92YXIvVFpgCgojIGdldCBTRCBjYXJkIHByZXNlbmNlClNEQ0FSRD1g
ZGYgfCBncmVwICJtbWMiIHwgd2MgLWxgCgojIGJhY2t1cCB0byBTRCBjYXJkIHdoZW4gaW5zZXJ0
ZWQKIyBydW5zIG9uIHBoZW5vY2FtIHVwbG9hZCByYXRoZXIgdGhhbiBpbnN0YWxsCiMgdG8gYWxs
b3cgaG90LXN3YXBwaW5nIG9mIGNhcmRzCmlmIFsgIiRTRENBUkQiIC1lcSAxIF07IHRoZW4KIAog
IyBjcmVhdGUgYmFja3VwIGRpcmVjdG9yeQogbWtkaXIgLXAgL21udC9tbWMvcGhlbm9jYW1fYmFj
a3VwLwogCmZpCgojIC0tLS0tLS0tLS0tLS0tIFNFVCBGSVhFRCBEQVRFIFRJTUUgSEVBREVSIC0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgb3ZlcmxheSB0ZXh0Cm92ZXJsYXlfdGV4dD1gZWNo
byAiJHtTSVRFTkFNRX0gLSAke21vZGVsfSAtICR7REFURX0gLSBHTVQke3RpbWVfb2Zmc2V0fSIg
fCBzZWQgJ3MvIC8lMjAvZydgCgkKIyBmb3Igbm93IGRpc2FibGUgdGhlIG92ZXJsYXkKd2dldCBo
dHRwOi8vYWRtaW46JHtwYXNzfUAxMjcuMC4wLjEvdmIuaHRtP292ZXJsYXl0ZXh0MT0ke292ZXJs
YXlfdGV4dH0gPi9kZXYvbnVsbCAyPi9kZXYvbnVsbAoKIyBjbGVhbiB1cCBkZXRyaXR1cwpybSB2
YioKCiMgLS0tLS0tLS0tLS0tLS0gU0VUIEZJWEVEIE1FVEEtREFUQSAtLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tCgojIGNyZWF0ZSBiYXNlIG1ldGEtZGF0YSBmaWxlIGZyb20gY29uZmln
dXJhdGlvbiBzZXR0aW5ncwojIGFuZCB0aGUgZml4ZWQgcGFyYW1ldGVycwplY2hvICJtb2RlbD1O
ZXRDYW0gTGl2ZTIiID4gL3Zhci90bXAvbWV0YWRhdGEudHh0CgojIGNvbG91ciBiYWxhbmNlIHNl
dHRpbmdzCnJlZD1gYXdrICdOUj09NycgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKZ3JlZW49YGF3
ayAnTlI9PTgnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCmJsdWU9YGF3ayAnTlI9PTknIC9tbnQv
Y2ZnMS9zZXR0aW5ncy50eHRgIApicmlnaHRuZXNzPWBhd2sgJ05SPT0xMCcgL21udC9jZmcxL3Nl
dHRpbmdzLnR4dGAKc2hhcnBuZXNzPWBhd2sgJ05SPT0xMScgL21udC9jZmcxL3NldHRpbmdzLnR4
dGAKaHVlPWBhd2sgJ05SPT0xMicgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKY29udHJhc3Q9YGF3
ayAnTlI9PTEzJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAkgCnNhdHVyYXRpb249YGF3ayAnTlI9
PTE0JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApibGM9YGF3ayAnTlI9PTE1JyAvbW50L2NmZzEv
c2V0dGluZ3MudHh0YApuZXR3b3JrPWBhd2sgJ05SPT0xNicgL21udC9jZmcxL3NldHRpbmdzLnR4
dGAKCmVjaG8gIm5ldHdvcms9JG5ldHdvcmsiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hv
ICJpcF9hZGRyPSRpcF9hZGRyIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAibWFjX2Fk
ZHI9JG1hY19hZGRyIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAidGltZV96b25lPSR0
eiIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gIm92ZXJsYXlfdGV4dD0kb3ZlcmxheV90
ZXh0IiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKCmVjaG8gInJlZD0kcmVkIiA+PiAvdmFyL3Rt
cC9tZXRhZGF0YS50eHQKZWNobyAiZ3JlZW49JGdyZWVuIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50
eHQKZWNobyAiYmx1ZT0kYmx1ZSIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gImJyaWdo
dG5lc3M9JGJyaWdodG5lc3MiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJjb250cmFz
dD0kY29udHJhc3QiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJodWU9JGh1ZSIgPj4g
L3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gInNoYXJwbmVzcz0kc2hhcnBuZXNzIiA+PiAvdmFy
L3RtcC9tZXRhZGF0YS50eHQKZWNobyAic2F0dXJhdGlvbj0kc2F0dXJhdGlvbiIgPj4gL3Zhci90
bXAvbWV0YWRhdGEudHh0CmVjaG8gImJhY2tsaWdodD0kYmxjIiA+PiAvdmFyL3RtcC9tZXRhZGF0
YS50eHQKCiMgLS0tLS0tLS0tLS0tLS0gVVBMT0FEIERBVEEgLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLQoKIyB3ZSB1c2UgdHdvIHN0YXRlcyB0byBpbmRpY2F0ZSBWSVMg
KDApIGFuZCBOSVIgKDEpIHN0YXRlcwojIGFuZCB1c2UgYSBmb3IgbG9vcCB0byBjeWNsZSB0aHJv
dWdoIHRoZXNlIHN0YXRlcyBhbmQKIyB1cGxvYWQgdGhlIGRhdGEKc3RhdGVzPSIwIDEiCgpmb3Ig
c3RhdGUgaW4gJHN0YXRlczsKZG8KCiBpZiBbICIkc3RhdGUiIC1lcSAwIF07IHRoZW4KCiAgIyBj
cmVhdGUgVklTIGZpbGVuYW1lcwogIG1ldGFmaWxlPWBlY2hvICR7U0lURU5BTUV9XyR7REFURVRJ
TUVTVFJJTkd9Lm1ldGFgCiAgaW1hZ2U9YGVjaG8gJHtTSVRFTkFNRX1fJHtEQVRFVElNRVNUUklO
R30uanBnYAogIGNhcHR1cmUgJGltYWdlICRtZXRhZmlsZSAkREVMQVkgMAoKIGVsc2UKCiAgIyBj
cmVhdGUgTklSIGZpbGVuYW1lcwogIG1ldGFmaWxlPWBlY2hvICR7U0lURU5BTUV9X0lSXyR7REFU
RVRJTUVTVFJJTkd9Lm1ldGFgCiAgaW1hZ2U9YGVjaG8gJHtTSVRFTkFNRX1fSVJfJHtEQVRFVElN
RVNUUklOR30uanBnYAogIGNhcHR1cmUgJGltYWdlICRtZXRhZmlsZSAkREVMQVkgMQogCiBmaQoK
ICMgcnVuIHRoZSB1cGxvYWQgc2NyaXB0IGZvciB0aGUgaXAgZGF0YQogIyBhbmQgZm9yIGFsbCBz
ZXJ2ZXJzCiBmb3IgaSBpbiAkbnJzZXJ2ZXJzOwogZG8KICBTRVJWRVI9YGF3ayAtdiBwPSRpICdO
Uj09cCcgL21udC9jZmcxL3NlcnZlci50eHRgCiAgZWNobyAidXBsb2FkaW5nIHRvOiAke1NFUlZF
Un0iCiAgZWNobyAiIgogIAogICMgLS0tLS0tLS0tLS0tLS0gVkFMSURBVEUgU0VSVklDRSAtLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQogICMgY2hlY2sgaWYgc0ZUUCBpcyByZWFjaGFi
bGUKCiAgIyBzZXQgdGhlIGRlZmF1bHQgc2VydmljZQogIHNlcnZpY2U9IkZUUCIKCiAgaWYgWyAt
ZiAiL21udC9jZmcxL3BoZW5vY2FtX2tleSIgXTsgdGhlbgoKICAgZWNobyAiQW4gc0ZUUCBrZXkg
d2FzIGZvdW5kLCBjaGVja2luZyBsb2dpbiBjcmVkZW50aWFscy4uLiIKCiAgIGVjaG8gImV4aXQi
ID4gYmF0Y2hmaWxlCiAgIHNmdHAgLWIgYmF0Y2hmaWxlIC1pICIvbW50L2NmZzEvcGhlbm9jYW1f
a2V5IiBwaGVub3NmdHBAJHtTRVJWRVJ9ID4vZGV2L251bGwgMj4vZGV2L251bGwKCiAgICMgaWYg
c3RhdHVzIG91dHB1dCBsYXN0IGNvbW1hbmQgd2FzCiAgICMgMCBzZXQgc2VydmljZSB0byBzRlRQ
CiAgIGlmIFsgJD8gLWVxIDAgXTsgdGhlbgogICAgZWNobyAiU1VDQ0VTLi4uIHVzaW5nIHNlY3Vy
ZSBzRlRQIgogICAgZWNobyAiIgogICAgc2VydmljZT0ic0ZUUCIKICAgZWxzZQogICAgZWNobyAi
RkFJTEVELi4uIGZhbGxpbmcgYmFjayB0byBGVFAhIgogICAgZWNobyAiIgogICBmaQogCiAgICMg
Y2xlYW4gdXAKICAgcm0gYmF0Y2hmaWxlCiAgZmkKICAjIC0tLS0tLS0tLS0tLS0tIFZBTElEQVRF
IFNFUlZJQ0UgRU5EIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgogICMgaWYga2V5IGZp
bGUgZXhpc3RzIHVzZSBTRlRQCiAgaWYgWyAiJHtzZXJ2aWNlfSIgIT0gIkZUUCIgXTsgdGhlbgog
ICBlY2hvICJ1c2luZyBzRlRQIgogIAogICBlY2hvICJQVVQgJHtpbWFnZX0gZGF0YS8ke1NJVEVO
QU1FfS8ke2ltYWdlfSIgPiBiYXRjaGZpbGUKICAgZWNobyAiUFVUICR7bWV0YWZpbGV9IGRhdGEv
JHtTSVRFTkFNRX0vJHttZXRhZmlsZX0iID4+IGJhdGNoZmlsZQogIAogICAjIHVwbG9hZCB0aGUg
ZGF0YQogICBlY2hvICJVcGxvYWRpbmcgKHN0YXRlOiAke3N0YXRlfSkiCiAgIGVjaG8gIiAtIGlt
YWdlIGZpbGU6ICR7aW1hZ2V9IgogICBlY2hvICIgLSBtZXRhLWRhdGEgZmlsZTogJHttZXRhZmls
ZX0iCiAgIHNmdHAgLWIgYmF0Y2hmaWxlIC1pICIvbW50L2NmZzEvcGhlbm9jYW1fa2V5IiBwaGVu
b3NmdHBAJHtTRVJWRVJ9ID4vZGV2L251bGwgMj4vZGV2L251bGwgfHwgZXJyb3JfZXhpdAogICAK
ICAgIyByZW1vdmUgYmF0Y2ggZmlsZQogICBybSBiYXRjaGZpbGUKICAgCiAgZWxzZQogICBlY2hv
ICJVc2luZyBGVFAgW2NoZWNrIHlvdXIgaW5zdGFsbCBhbmQga2V5IGNyZWRlbnRpYWxzIHRvIHVz
ZSBzRlRQXSIKICAKICAgIyB1cGxvYWQgaW1hZ2UKICAgZWNobyAiVXBsb2FkaW5nIChzdGF0ZTog
JHtzdGF0ZX0pIgogICBlY2hvICIgLSBpbWFnZSBmaWxlOiAke2ltYWdlfSIKICAgZnRwcHV0ICR7
U0VSVkVSfSAtLXVzZXJuYW1lIGFub255bW91cyAtLXBhc3N3b3JkIGFub255bW91cyAgZGF0YS8k
e1NJVEVOQU1FfS8ke2ltYWdlfSAke2ltYWdlfSA+L2Rldi9udWxsIDI+L2Rldi9udWxsIHx8IGVy
cm9yX2V4aXQKCQogICBlY2hvICIgLSBtZXRhLWRhdGEgZmlsZTogJHttZXRhZmlsZX0iCiAgIGZ0
cHB1dCAke1NFUlZFUn0gLS11c2VybmFtZSBhbm9ueW1vdXMgLS1wYXNzd29yZCBhbm9ueW1vdXMg
IGRhdGEvJHtTSVRFTkFNRX0vJHttZXRhZmlsZX0gJHttZXRhZmlsZX0gPi9kZXYvbnVsbCAyPi9k
ZXYvbnVsbCB8fCBlcnJvcl9leGl0CgogIGZpCiBkb25lCgogIyBiYWNrdXAgdG8gU0QgY2FyZCB3
aGVuIGluc2VydGVkCiBpZiBbICIkU0RDQVJEIiAtZXEgMSBdOyB0aGVuIAogIGNwICR7aW1hZ2V9
IC9tbnQvbW1jL3BoZW5vY2FtX2JhY2t1cC8ke2ltYWdlfQogIGNwICR7bWV0YWZpbGV9IC9tbnQv
bW1jL3BoZW5vY2FtX2JhY2t1cC8ke21ldGFmaWxlfQogZmkKCiAjIGNsZWFuIHVwIGZpbGVzCiBy
bSAqLmpwZwogcm0gKi5tZXRhCgpkb25lCgojIFJlc2V0IHRvIFZJUyBhcyBkZWZhdWx0Ci91c3Iv
c2Jpbi9zZXRfaXIuc2ggMAoKIy0tLS0tLS0tLS0tLS0tIFJFU0VUIE5PUk1BTCBIRUFERVIgLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgb3ZlcmxheSB0ZXh0Cm92ZXJsYXlfdGV4
dD1gZWNobyAiJHtTSVRFTkFNRX0gLSAke21vZGVsfSAtICVhICViICVkICVZICVIOiVNOiVTIC0g
R01UJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLyAvJTIwL2cnYAoJCiMgZm9yIG5vdyBkaXNhYmxl
IHRoZSBvdmVybGF5CndnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9v
dmVybGF5dGV4dDE9JHtvdmVybGF5X3RleHR9ID4vZGV2L251bGwgMj4vZGV2L251bGwKCiMgY2xl
YW4gdXAgZGV0cml0dXMKcm0gdmIqCgojLS0tLS0tLSBGRUVEQkFDSyBPTiBBQ1RJVklUWSAtLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KaWYgWyAhIC1mICIvdmFyL3RtcC9p
bWFnZV9sb2cudHh0IiBdOyB0aGVuCiB0b3VjaCAvdmFyL3RtcC9pbWFnZV9sb2cudHh0CiBjaG1v
ZCBhK3J3IC92YXIvdG1wL2ltYWdlX2xvZy50eHQKZmkKCmVjaG8gImxhc3QgdXBsb2FkcyBhdDoi
ID4+IC92YXIvdG1wL2ltYWdlX2xvZy50eHQKZWNobyAkREFURSA+PiAvdmFyL3RtcC9pbWFnZV9s
b2cudHh0CnRhaWwgL3Zhci90bXAvaW1hZ2VfbG9nLnR4dAoKIy0tLS0tLS0gRklMRSBQRVJNSVNT
SU9OUyBBTkQgQ0xFQU5VUCAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCnJtIC1mIC92
YXIvdG1wL21ldGFkYXRhLnR4dAoKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAABmaWxlcy9waGVub2NhbV92YWxpZGF0ZS5zaAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAMDAwMDc3NQAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMDMxNjIAMTQ2NzQ1MDQ0MDMAMDE2NDEz
ACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHVzdGFyICAAa2h1
ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAACMhL2Jpbi9zaAoKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiMgKGMpIEtvZW4gSHVma2Vu
cyBmb3IgQmx1ZUdyZWVuIExhYnMgKEJWKQojCiMgVW5hdXRob3JpemVkIGNoYW5nZXMgdG8gdGhp
cyBzY3JpcHQgYXJlIGNvbnNpZGVyZWQgYSBjb3B5cmlnaHQKIyB2aW9sYXRpb24gYW5kIHdpbGwg
YmUgcHJvc2VjdXRlZC4KIwojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgaGFyZCBjb2RlIHBhdGggd2hpY2ggYXJl
IGxvc3QgaW4gc29tZSBpbnN0YW5jZXMKIyB3aGVuIGNhbGxpbmcgdGhlIHNjcmlwdCB0aHJvdWdo
IHNzaCAKUEFUSD0iL3Vzci9sb2NhbC9iaW46L3Vzci9sb2NhbC9zYmluOi91c3IvYmluOi91c3Iv
c2JpbjovYmluOi9zYmluIgoKIyAtLS0tLS0tLS0tLS0tLSBTRVRUSU5HUyAtLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIE1vdmUgaW50byB0ZW1wb3JhcnkgZGly
ZWN0b3J5CiMgd2hpY2ggcmVzaWRlcyBpbiBSQU0sIG5vdCB0bwojIHdlYXIgb3V0IG90aGVyIHBl
cm1hbmVudCBtZW1vcnkKY2QgL3Zhci90bXAKCiMgaG93IG1hbnkgc2VydmVycyBkbyB3ZSB1cGxv
YWQgdG8KbnJzZXJ2ZXJzPWBhd2sgJ0VORCB7cHJpbnQgTlJ9JyAvbW50L2NmZzEvc2VydmVyLnR4
dGAKbnJzZXJ2ZXJzPWBhd2sgLXYgdmFyPSR7bnJzZXJ2ZXJzfSAnQkVHSU57IG49MTsgd2hpbGUg
KG4gPD0gdmFyICkgeyBwcmludCBuOyBuKys7IH0gfScgfCB0ciAnXG4nICcgJ2AKCiMgLS0tLS0t
LS0tLS0tLS0gVkFMSURBVEUgTE9HSU4gLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0KCmlmIFsgISAtZiAiL21udC9jZmcxL3BoZW5vY2FtX2tleSIgXTsgdGhlbgogZWNobyAi
bm8gc0ZUUCBrZXkgZm91bmQsIG5vdGhpbmcgdG8gYmUgZG9uZS4uLiIKIGV4aXQgMApmaQoKIyBy
dW4gdGhlIHVwbG9hZCBzY3JpcHQgZm9yIHRoZSBpcCBkYXRhCiMgYW5kIGZvciBhbGwgc2VydmVy
cwpmb3IgaSBpbiAkbnJzZXJ2ZXJzOwpkbwogIFNFUlZFUj1gYXdrIC12IHA9JGkgJ05SPT1wJyAv
bW50L2NmZzEvc2VydmVyLnR4dGAKIAogIGVjaG8gIiIgCiAgZWNobyAiQ2hlY2tpbmcgc2VydmVy
OiAke1NFUlZFUn0iCiAgZWNobyAiIgoKICBlY2hvICJleGl0IiA+IGJhdGNoZmlsZQogIHNmdHAg
LWIgYmF0Y2hmaWxlIC1pICIvbW50L2NmZzEvcGhlbm9jYW1fa2V5IiBwaGVub3NmdHBAJHtTRVJW
RVJ9ID4vZGV2L251bGwgMj4vZGV2L251bGwKCiAgIyBpZiBzdGF0dXMgb3V0cHV0IGxhc3QgY29t
bWFuZCB3YXMKICAjIDAgc2V0IHNlcnZpY2UgdG8gc0ZUUAogIGlmIFsgJD8gLWVxIDAgXTsgdGhl
bgogICAgZWNobyAiU1VDQ0VTLi4uIHNlY3VyZSBzRlRQIGxvZ2luIHdvcmtlZCIKICAgIGVjaG8g
IiIKICBlbHNlCiAgICBlY2hvICJGQUlMRUQuLi4gc2VjdXJlIHNGVFAgbG9naW4gZGlkIG5vdCB3
b3JrIgogICAgZWNobyAiW2RhdGEgdXBsb2FkcyB3aWxsIGZhbGwgYmFjayB0byBpbnNlY3VyZSBG
VFAgbW9kZV0iCiAgICBlY2hvICIiCiAgZmkKICAKICAjIGNsZWFudXAKICBybSBiYXRjaGZpbGUK
ZG9uZQoKZXhpdCAwCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAZmlsZXMvcmVib290X2NhbWVyYS5zaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAw
MDA2NjQAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDAyMDQxADE0NjU3NzA3NTAxADAxNTU0NwAgMAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhciAgAGtodWZrZW5z
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAjIS9iaW4vc2gKCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIChjKSBLb2VuIEh1ZmtlbnMgZm9y
IEJsdWVHcmVlbiBMYWJzIChCVikKIwojIFVuYXV0aG9yaXplZCBjaGFuZ2VzIHRvIHRoaXMgc2Ny
aXB0IGFyZSBjb25zaWRlcmVkIGEgY29weXJpZ2h0CiMgdmlvbGF0aW9uIGFuZCB3aWxsIGJlIHBy
b3NlY3V0ZWQuCiMKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIGhhcmQgY29kZSBwYXRoIHdoaWNoIGFyZSBsb3N0
IGluIHNvbWUgaW5zdGFuY2VzCiMgd2hlbiBjYWxsaW5nIHRoZSBzY3JpcHQgdGhyb3VnaCBzc2gg
ClBBVEg9Ii91c3IvbG9jYWwvYmluOi91c3IvbG9jYWwvc2JpbjovdXNyL2JpbjovdXNyL3NiaW46
L2Jpbjovc2JpbiIKCiMgZ3JhYiBwYXNzd29yZApwYXNzPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEv
LnBhc3N3b3JkYAoKIyBtb3ZlIGludG8gdGVtcG9yYXJ5IGRpcmVjdG9yeQpjZCAvdmFyL3RtcAoK
IyBzbGVlcCAzMCBzZWNvbmRzIGZvciBsYXN0CiMgY29tbWFuZCB0byBmaW5pc2ggKGlmIGFueSBz
aG91bGQgYmUgcnVubmluZykKc2xlZXAgMzAKCiMgdGhlbiByZWJvb3QKd2dldCBodHRwOi8vYWRt
aW46JHtwYXNzfUAxMjcuMC4wLjEvdmIuaHRtP2lwY2FtcmVzdGFydGNtZCAmPi9kZXYvbnVsbAoK
IyBkb24ndCBleGl0IGNsZWFubHkgd2hlbiB0aGUgcmVib290IGNvbW1hbmQgZG9lc24ndCBzdGlj
awojIHNob3VsZCB0cmlnZ2VyIGEgd2FybmluZyBtZXNzYWdlCnNsZWVwIDYwCgplY2hvICIgLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0i
CmVjaG8gIiIKZWNobyAiIFJFQk9PVCBGQUlMRUQgLSBJTlNUQUxMIE1JR0hUIE5PVCBCRSBDT01Q
TEVURSEiCmVjaG8gIiIKZWNobyAiPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0iCgpleGl0IDEKAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAABmaWxlcy9zaXRlX2lwLmh0bWwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDY2
NAAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMDA1NjAAMTQ1MzY1NTI1MDAAMDE0NzMwACAwAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHVzdGFyICAAa2h1ZmtlbnMAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAADwhRE9DVFlQRSBodG1sIFBVQkxJQyAiLS8vVzNDLy9EVEQgSFRNTCA0LjAgVHJhbnNp
dGlvbmFsLy9FTiI+CjxodG1sPgo8aGVhZD4KPG1ldGEgaHR0cC1lcXVpdj0iQ29udGVudC1UeXBl
IiBjb250ZW50PSJ0ZXh0L2h0bWw7IGNoYXJzZXQ9aXNvLTg4NTktMSI+Cjx0aXRsZT5OZXRDYW1T
QyBJUCBBZGRyZXNzPC90aXRsZT4KPC9oZWFkPgo8Ym9keT4KVGltZSBvZiBMYXN0IElQIFVwbG9h
ZDogREFURVRJTUU8YnI+CklQIEFkZHJlc3M6IFNJVEVJUAomYnVsbDsgPGEgaHJlZj0iaHR0cDov
L1NJVEVJUC8iPlZpZXc8L2E+CiZidWxsOyA8YSBocmVmPSJodHRwOi8vU0lURUlQL2FkbWluLmNn
aSI+Q29uZmlndXJlPC9hPgo8L2JvZHk+CjwvaHRtbD4KAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
