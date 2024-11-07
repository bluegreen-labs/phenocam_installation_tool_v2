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
while getopts "hi:p:n:o:s:e:m:uvrx" option;
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
 echo ${pass} > /mnt/cfg1/.password &&
 if [ ! -f /mnt/cfg1/phenocam_key ]; then dropbearkey -t ecdsa -s 521 -f /mnt/cfg1/phenocam_key >/dev/null; fi &&
 cd /var/tmp; cat | base64 -d | tar -x &&
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi && 
 cp /var/tmp/files/* /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
 sh /mnt/cfg1/scripts/check_firmware.sh &&
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
 echo ' and send this key to phenocam@nau.edu to complete the install.' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 echo ' --> SUCCESSFUL UPLOAD OF THE INSTALLATION SCRIPT   <-- ' &&
 echo ' --> THE CAMERA WILL REBOOT TO COMPLETE THE INSTALL <--' &&
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
MAAwMDAxNzUwADAwMDAwMDAyMDMwADE0NjU3NjA1MTc1ADAxNTcyMAAgMAAAAAAAAAAAAAAAAAAA
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
LS0tLS0tLS0tLS0tCgojIGhhcmQgY29kZSBwYXRoIHdoaWNoIGFyZSBsb3N0IGluIHNvbWUgaW5z
dGFuY2VzCiMgd2hlbiBjYWxsaW5nIHRoZSBzY3JpcHQgdGhyb3VnaCBzc2ggClBBVEg9Ii91c3Iv
bG9jYWwvYmluOi91c3IvbG9jYWwvc2JpbjovdXNyL2JpbjovdXNyL3NiaW46L2Jpbjovc2JpbiIK
CiMgZ3JhYiBwYXNzd29yZApwYXNzPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvLnBhc3N3b3JkYAoK
IyBtb3ZlIGludG8gdGVtcG9yYXJ5IGRpcmVjdG9yeQpjZCAvdmFyL3RtcAoKIyBkdW1wIGRldmlj
ZSBpbmZvCndnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9EZXZpY2VJ
bmZvICY+L2Rldi9udWxsCgojIGV4dHJhY3QgZmlybXdhcmUgdmVyc2lvbgp2ZXJzaW9uPWBjYXQg
dmIuaHRtP0RldmljZUluZm8gfCBjdXQgLWQnLScgLWYzIHwgY3V0IC1kICcgJyAtZjEgfCB0ciAt
ZCAnQicgYAoKIyBjbGVhbiB1cCBkZXRyaXR1cwpybSB2YioKCmlmIFtbICR2ZXJzaW9uIC1sdCA5
MTA4IF1dOyB0aGVuCgogIyBlcnJvciBzdGF0ZW1lbnQgKyB0cmlnZ2VyaW5nCiAjIHRoZSBzc2gg
ZXJyb3Igc3VmZml4CiBlY2hvICIgV0FSTklORzogeW91ciBmaXJtd2FyZSB2ZXJzaW9uICR2ZXJz
aW9uIGlzIG5vdCBzdXBwb3J0ZWQsIgogZWNobyAiIHBsZWFzZSB1cGRhdGUgeW91ciBjYW1lcmEg
ZmlybXdhcmUgdG8gdmVyc2lvbiBCOTEwOCBvciBsYXRlci4iCiBleGl0IDEKCmVsc2UKIAogIyBj
bGVhbiBleGl0CiBleGl0IDAKZmkKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxl
cy9jaGxzAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDc3NQAwMDAxNzUwADAw
MDE3NTAAMDAwMDAwMDA3NDEAMTQ3MTMxMTQwMTAAMDEzMjUxACAwAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHVzdGFyICAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMhL2Jp
bi9zaAoKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tCiMgKGMpIEtvZW4gSHVma2VucyBmb3IgQmx1ZUdyZWVuIExhYnMg
KEJWKQojCiMgVW5hdXRob3JpemVkIGNoYW5nZXMgdG8gdGhpcyBzY3JpcHQgYXJlIGNvbnNpZGVy
ZWQgYSBjb3B5cmlnaHQKIyB2aW9sYXRpb24gYW5kIHdpbGwgYmUgcHJvc2VjdXRlZC4KIwojLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0KCm5yc2VydmVycz1gYXdrICdFTkQge3ByaW50IE5SfScgL21udC9jZmcxL3NlcnZl
ci50eHRgCmFsbD0iaWNvcyIKbWF0Y2g9YGdyZXAgLUUgJHthbGx9IC9tbnQvY2ZnMS9zZXJ2ZXIu
dHh0IHwgd2MgLWxgCgppZiBbICR7bnJzZXJ2ZXJzfSAtZXEgJHttYXRjaH0gXTsKdGhlbgogZWNo
byAibmV0d29yaz1pY29zIgpmaQoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMv
cGhlbm9jYW1faW5zdGFsbC5zaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NTUAMDAwMTc1MAAwMDAx
NzUwADAwMDAwMDEyNDYxADE0NzEzMTE0MDE3ADAxNjI2MAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB1c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAjIS9iaW4v
c2gKCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLQojIChjKSBLb2VuIEh1ZmtlbnMgZm9yIEJsdWVHcmVlbiBMYWJzIChC
VikKIwojIFVuYXV0aG9yaXplZCBjaGFuZ2VzIHRvIHRoaXMgc2NyaXB0IGFyZSBjb25zaWRlcmVk
IGEgY29weXJpZ2h0CiMgdmlvbGF0aW9uIGFuZCB3aWxsIGJlIHByb3NlY3V0ZWQuCiMKIy0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tCgojIGhhcmQgY29kZSBwYXRoIHdoaWNoIGFyZSBsb3N0IGluIHNvbWUgaW5zdGFuY2Vz
CiMgd2hlbiBjYWxsaW5nIHRoZSBzY3JpcHQgdGhyb3VnaCBzc2ggClBBVEg9Ii91c3IvbG9jYWwv
YmluOi91c3IvbG9jYWwvc2JpbjovdXNyL2JpbjovdXNyL3NiaW46L2Jpbjovc2JpbiIKCnNsZWVw
IDMwCmNkIC92YXIvdG1wCgojIHVwZGF0ZSBwZXJtaXNzaW9ucyBzY3JpcHRzCmNobW9kIGErcnd4
IC9tbnQvY2ZnMS9zY3JpcHRzLyoKCiMgZ2V0IHRvZGF5cyBkYXRlCnRvZGF5PWBkYXRlICsiJVkg
JW0gJWQgJUg6JU06JVMiYAoKIyBzZXQgY2FtZXJhIG1vZGVsIG5hbWUKbW9kZWw9Ik5ldENhbSBM
aXZlMiIKCiMgdXBsb2FkIC8gZG93bmxvYWQgc2VydmVyIC0gbG9jYXRpb24gZnJvbSB3aGljaCB0
byBncmFiIGFuZAojIGFuZCB3aGVyZSB0byBwdXQgY29uZmlnIGZpbGVzCmhvc3Q9J2ljb3MwMS51
YW50d2VycGVuLmJlJwoKIyBjcmVhdGUgZGVmYXVsdCBzZXJ2ZXIKaWYgWyAhIC1mICcvbW50L2Nm
ZzEvc2VydmVyLnR4dCcgXTsgdGhlbgogIGVjaG8gJHtob3N0fSA+IC9tbnQvY2ZnMS9zZXJ2ZXIu
dHh0CiAgZWNobyAidXNpbmcgZGVmYXVsdCBob3N0OiAke2hvc3R9IiA+PiAvdmFyL3RtcC9pbnN0
YWxsX2xvZy50eHQKICBjaG1vZCBhK3J3IC9tbnQvY2ZnMS9zZXJ2ZXIudHh0CmZpCgojIE9ubHkg
dXBkYXRlIHRoZSBzZXR0aW5ncyBpZiBleHBsaWNpdGx5CiMgaW5zdHJ1Y3RlZCB0byBkbyBzbywg
dGhpcyBmaWxlIHdpbGwgYmUKIyBzZXQgdG8gVFJVRSBieSB0aGUgUElULnNoIHNjcmlwdCwgd2hp
Y2gKIyB1cG9uIHJlYm9vdCB3aWxsIHRoZW4gYmUgcnVuLgoKaWYgWyBgY2F0IC9tbnQvY2ZnMS91
cGRhdGUudHh0YCA9ICJUUlVFIiBdOyB0aGVuIAoKCSMgc3RhcnQgbG9nZ2luZwoJZWNobyAiLS0t
LS0gJHt0b2RheX0gLS0tLS0iID4+IC92YXIvdG1wL2luc3RhbGxfbG9nLnR4dAoKCSMtLS0tLSBy
ZWFkIGluIHNldHRpbmdzCglpZiBbIC1mICcvbW50L2NmZzEvc2V0dGluZ3MudHh0JyBdOyB0aGVu
CgkgY2FtZXJhPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIHRpbWVfb2Zm
c2V0PWBhd2sgJ05SPT0yJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIGNyb25fc3RhcnQ9YGF3
ayAnTlI9PTQnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgY3Jvbl9lbmQ9YGF3ayAnTlI9PTUn
IC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgY3Jvbl9pbnQ9YGF3ayAnTlI9PTYnIC9tbnQvY2Zn
MS9zZXR0aW5ncy50eHRgCgkgCgkgIyBjb2xvdXIgYmFsYW5jZQogCSByZWQ9YGF3ayAnTlI9PTcn
IC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgZ3JlZW49YGF3ayAnTlI9PTgnIC9tbnQvY2ZnMS9z
ZXR0aW5ncy50eHRgCgkgYmx1ZT1gYXdrICdOUj09OScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAK
CSAKCSAjIHJlYWQgaW4gdGhlIGJyaWdodG5lc3Mvc2hhcnBuZXNzL2h1ZS9zYXR1cmF0aW9uIHZh
bHVlcwoJIGJyaWdodG5lc3M9YGF3ayAnTlI9PTEwJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJ
IHNoYXJwbmVzcz1gYXdrICdOUj09MTEnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgaHVlPWBh
d2sgJ05SPT0xMicgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBjb250cmFzdD1gYXdrICdOUj09
MTMnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCSAKCSBzYXR1cmF0aW9uPWBhd2sgJ05SPT0xNCcg
L21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBibGM9YGF3ayAnTlI9PTE1JyAvbW50L2NmZzEvc2V0
dGluZ3MudHh0YAoJZWxzZQoJIGVjaG8gIlNldHRpbmdzIGZpbGUgbWlzc2luZywgYWJvcnRpbmcg
aW5zdGFsbCByb3V0aW5lISIgPj4gL3Zhci90bXAvaW5zdGFsbF9sb2cudHh0CglmaQoJCiAgICAg
ICAgcGFzcz1gYXdrICdOUj09MScgL21udC9jZmcxLy5wYXNzd29yZGAKCgkjLS0tLS0gc2V0IHRp
bWUgem9uZSBvZmZzZXQgKGZyb20gR01UKQoJCgkjIHNldCBzaWduIHRpbWUgem9uZQoJU0lHTj1g
ZWNobyAke3RpbWVfb2Zmc2V0fSB8IGN1dCAtYycxJ2AKCgkjIG5vdGUgdGhlIHdlaXJkIGZsaXAg
aW4gdGhlIG5ldGNhbSBjYW1lcmFzCglpZiBbICIkU0lHTiIgPSAiKyIgXTsgdGhlbgoJIFRaPWBl
Y2hvICJHTVQke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvKy8lMkQvZydgCgllbHNlCgkgVFo9YGVj
aG8gIkdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8tLyUyQi9nJ2AKCWZpCgoJIyBjYWxsIEFQ
SSB0byBzZXQgdGhlIHRpbWUgCgl3Z2V0IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92
Yi5odG0/dGltZXpvbmU9JHtUWn0KCQoJIyBjbGVhbiB1cCBkZXRyaXR1cwoJcm0gdmIqCgkKCWVj
aG8gInRpbWUgc2V0IHRvIChhc2NpaSBmb3JtYXQpOiAke1RafSIgPj4gL3Zhci90bXAvaW5zdGFs
bF9sb2cudHh0CgkKCSMtLS0tLSBzZXQgb3ZlcmxheQoJCgkjIGNvbnZlcnQgdG8gYXNjaWkKCWlm
IFsgIiRTSUdOIiA9ICIrIiBdOyB0aGVuCgkgdGltZV9vZmZzZXQ9YGVjaG8gIiR7dGltZV9vZmZz
ZXR9IiB8IHNlZCAncy8rLyUyQi9nJ2AKCWVsc2UKCSB0aW1lX29mZnNldD1gZWNobyAiJHt0aW1l
X29mZnNldH0iIHwgc2VkICdzLy0vJTJEL2cnYAoJZmkKCQoJIyBvdmVybGF5IHRleHQKCW92ZXJs
YXlfdGV4dD1gZWNobyAiJHtjYW1lcmF9IC0gJHttb2RlbH0gLSAlYSAlYiAlZCAlWSAlSDolTTol
UyAtIEdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8gLyUyMC9nJ2AKCQoJIyBmb3Igbm93IGRp
c2FibGUgdGhlIG92ZXJsYXkKCXdnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3Zi
Lmh0bT9vdmVybGF5dGV4dDE9JHtvdmVybGF5X3RleHR9CgkKCSMgY2xlYW4gdXAgZGV0cml0dXMK
CXJtIHZiKgoJCgllY2hvICJoZWFkZXIgc2V0IHRvOiAke292ZXJsYXlfdGV4dH0iID4+IC92YXIv
dG1wL2luc3RhbGxfbG9nLnR4dAoJCgkjLS0tLS0gc2V0IGNvbG91ciBzZXR0aW5ncwoJCgkjIGNh
bGwgQVBJIHRvIHNldCB0aGUgdGltZSAKCXdnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAu
MC4xL3ZiLmh0bT9icmlnaHRuZXNzPSR7YnJpZ2h0bmVzc30KCXdnZXQgaHR0cDovL2FkbWluOiR7
cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9jb250cmFzdD0ke2NvbnRyYXN0fQoJd2dldCBodHRwOi8v
YWRtaW46JHtwYXNzfUAxMjcuMC4wLjEvdmIuaHRtP3NoYXJwbmVzcz0ke3NoYXJwbmVzc30KCXdn
ZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9odWU9JHtodWV9Cgl3Z2V0
IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/c2F0dXJhdGlvbj0ke3NhdHVy
YXRpb259CgkKCSMgY2xlYW4gdXAgZGV0cml0dXMKCXJtIHZiKgoJCQoJIyBzZXQgUkdCIGJhbGFu
Y2UKCS91c3Ivc2Jpbi9zZXRfcmdiLnNoIDAgJHtyZWR9ICR7Z3JlZW59ICR7Ymx1ZX0KCgkjLS0t
LS0gZ2VuZXJhdGUgcmFuZG9tIG51bWJlciBiZXR3ZWVuIDAgYW5kIHRoZSBpbnRlcnZhbCB2YWx1
ZQoJcm51bWJlcj1gYXdrIC12IG1pbj0wIC12IG1heD0ke2Nyb25faW50fSAnQkVHSU57c3JhbmQo
KTsgcHJpbnQgaW50KG1pbityYW5kKCkqKG1heC1taW4rMSkpfSdgCgkKCSMgZGl2aWRlIDYwIG1p
biBieSB0aGUgaW50ZXJ2YWwKCWRpdj1gYXdrIC12IGludGVydmFsPSR7Y3Jvbl9pbnR9ICdCRUdJ
TiB7cHJpbnQgNTkvaW50ZXJ2YWx9J2AKCWludD1gZWNobyAkZGl2IHwgY3V0IC1kJy4nIC1mMWAK
CQoJIyBnZW5lcmF0ZSBsaXN0IG9mIHZhbHVlcyB0byBpdGVyYXRlIG92ZXIKCXZhbHVlcz1gYXdr
IC12IG1heD0ke2ludH0gJ0JFR0lOeyBmb3IoaT0wO2k8PW1heDtpKyspIHByaW50IGl9J2AKCQoJ
Zm9yIGkgaW4gJHt2YWx1ZXN9OyBkbwoJIHByb2R1Y3Q9YGF3ayAtdiBpbnRlcnZhbD0ke2Nyb25f
aW50fSAtdiBzdGVwPSR7aX0gJ0JFR0lOIHtwcmludCBpbnQoaW50ZXJ2YWwqc3RlcCl9J2AJCgkg
c3VtPWBhd2sgLXYgcHJvZHVjdD0ke3Byb2R1Y3R9IC12IG5yPSR7cm51bWJlcn0gJ0JFR0lOIHtw
cmludCBpbnQocHJvZHVjdCtucil9J2AKCSAKCSBpZiBbICIke2l9IiAtZXEgIjAiIF07dGhlbgoJ
ICBpbnRlcnZhbD1gZWNobyAke3N1bX1gCgkgZWxzZQoJICBpZiBbICIkc3VtIiAtbGUgIjU5IiBd
O3RoZW4KCSAgIGludGVydmFsPWBlY2hvICR7aW50ZXJ2YWx9LCR7c3VtfWAKCSAgZmkKCSBmaQoJ
ZG9uZQoKCWVjaG8gImNyb250YWIgaW50ZXJ2YWxzIHNldCB0bzogJHtpbnRlcnZhbH0iID4+IC92
YXIvdG1wL2luc3RhbGxfbG9nLnR4dAoKCSMtLS0tLSBzZXQgcm9vdCBjcm9uIGpvYnMKCQoJIyBz
ZXQgdGhlIG1haW4gcGljdHVyZSB0YWtpbmcgcm91dGluZQoJZWNobyAiJHtpbnRlcnZhbH0gJHtj
cm9uX3N0YXJ0fS0ke2Nyb25fZW5kfSAqICogKiBzaCAvbW50L2NmZzEvc2NyaXB0cy9waGVub2Nh
bV91cGxvYWQuc2giID4gL21udC9jZmcxL3NjaGVkdWxlL2FkbWluCgkJCgkjIHVwbG9hZCBpcCBh
ZGRyZXNzIGluZm8gYXQgbWlkZGF5CgllY2hvICI1OSAxMSAqICogKiBzaCAvbW50L2NmZzEvc2Ny
aXB0cy9waGVub2NhbV9pcF90YWJsZS5zaCIgPj4gL21udC9jZmcxL3NjaGVkdWxlL2FkbWluCgkJ
CgkjIHJlYm9vdCBhdCBtaWRuaWdodCBvbiByb290IGFjY291bnQKCWVjaG8gIjU5IDIzICogKiAq
IHNoIC9tbnQvY2ZnMS9zY3JpcHRzL3JlYm9vdF9jYW1lcmEuc2giID4gL21udC9jZmcxL3NjaGVk
dWxlL3Jvb3QKCQoJIyBpbmZvCgllY2hvICJGaW5pc2hlZCBpbml0aWFsIHNldHVwIiA+PiAvdmFy
L3RtcC9pbnN0YWxsX2xvZy50eHQKCgkjLS0tLS0gZmluYWxpemUgdGhlIHNldHVwICsgcmVib290
CgoJIyB1cGRhdGUgdGhlIHN0YXRlIG9mIHRoZSB1cGRhdGUgcmVxdWlyZW1lbnQKCSMgaS5lLiBz
a2lwIGlmIGNhbGxlZCBtb3JlIHRoYW4gb25jZSwgdW5sZXNzCgkjIHRoaXMgZmlsZSBpcyBtYW51
YWxseSBzZXQgdG8gVFJVRSB3aGljaAoJIyB3b3VsZCByZXJ1biB0aGUgaW5zdGFsbCByb3V0aW5l
IHVwb24gcmVib290CgllY2hvICJGQUxTRSIgPiAvbW50L2NmZzEvdXBkYXRlLnR4dAoKCSMgcmVi
b290aW5nIGNhbWVyYSB0byBtYWtlIHN1cmUgYWxsCgkjIHRoZSBzZXR0aW5ncyBzdGljawoJc2gg
L21udC9jZmcxL3NjcmlwdHMvcmVib290X2NhbWVyYS5zaApmaQoKIyBjbGVhbiBleGl0CmV4aXQg
MAoKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMvcGhlbm9jYW1faXBf
dGFibGUuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NTUAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDAy
NjEyADE0NjU3NTc2NjMxADAxNjQxMwAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
IHA9JGkgJ05SPT1wJyAvbW50L2NmZzEvc2VydmVyLnR4dGAgCgkKICMgdXBsb2FkIGltYWdlCiBl
Y2hvICJ1cGxvYWRpbmcgTklSIGltYWdlICR7aW1hZ2V9IgogZnRwcHV0ICR7U0VSVkVSfSAtdSAi
YW5vbnltb3VzIiAtcCAiYW5vbnltb3VzIiBkYXRhLyR7U0lURU5BTUV9LyR7U0lURU5BTUV9XF9p
cC5odG1sIC92YXIvdG1wLyR7U0lURU5BTUV9XF9pcC5odG1sCgpkb25lCgojIGNsZWFuIHVwCnJt
IC92YXIvdG1wLyR7U0lURU5BTUV9XF9pcC5odG1sCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxlcy9waGVub2NhbV91cGxvYWQu
c2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDc3NQAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMjA2NDMA
MTQ2NzQyNDc0MTEAMDE2MTE0ACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
a3VwLwogCmZpCgojIC0tLS0tLS0tLS0tLS0tIFZBTElEQVRFIFNFUlZJQ0UgLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgY2hlY2sgaWYgc0ZUUCBpcyByZWFjaGFibGUsIGV2
ZW4gaWYgYSBrZXlzIHByb3ZpZGVkIGl0IG1pZ2h0IG5vdCBiZQojIHZhbGlkYXRlZCB5ZXQgLSBm
YWxsIGJhY2sgdG8gRlRQIGlmIHNGVFAgaXMgbm90IGF2YWlsYWJsZSAoeWV0KQoKIyBzZXQgdGhl
IGRlZmF1bHQgc2VydmljZQpzZXJ2aWNlPSJGVFAiCgppZiBbIC1mICIvbW50L2NmZzEvcGhlbm9j
YW1fa2V5IiBdOyB0aGVuCgogZWNobyAiQW4gc0ZUUCBrZXkgd2FzIGZvdW5kLCBjaGVja2luZyBs
b2dpbiBjcmVkZW50aWFscy4uLiIKCiBlY2hvICJleGl0IiA+IGJhdGNoZmlsZQogc2Z0cCAtYiBi
YXRjaGZpbGUgLWkgIi9tbnQvY2ZnMS9waGVub2NhbV9rZXkiIHBoZW5vc2Z0cEAke1NFUlZFUn0g
Pi9kZXYvbnVsbCAyPi9kZXYvbnVsbAoKICMgaWYgc3RhdHVzIG91dHB1dCBsYXN0IGNvbW1hbmQg
d2FzCiAjIDAgc2V0IHNlcnZpY2UgdG8gc0ZUUAogaWYgWyAkPyAtZXEgMCBdOyB0aGVuCiAgICBl
Y2hvICJTVUNDRVMuLi4gdXNpbmcgc2VjdXJlIHNGVFAiCiAgICBlY2hvICIiCiAgICBzZXJ2aWNl
PSJzRlRQIgogZWxzZQogICAgZWNobyAiRkFJTEVELi4uIGZhbGxpbmcgYmFjayB0byBGVFAhIgog
ICAgZWNobyAiIgogZmkKIAogIyBjbGVhbiB1cAogcm0gYmF0Y2hmaWxlCmZpCgojIC0tLS0tLS0t
LS0tLS0tIFNFVCBGSVhFRCBEQVRFIFRJTUUgSEVBREVSIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0KCiMgb3ZlcmxheSB0ZXh0Cm92ZXJsYXlfdGV4dD1gZWNobyAiJHtTSVRFTkFNRX0gLSAke21v
ZGVsfSAtICR7REFURX0gLSBHTVQke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvIC8lMjAvZydgCgkK
IyBmb3Igbm93IGRpc2FibGUgdGhlIG92ZXJsYXkKd2dldCBodHRwOi8vYWRtaW46JHtwYXNzfUAx
MjcuMC4wLjEvdmIuaHRtP292ZXJsYXl0ZXh0MT0ke292ZXJsYXlfdGV4dH0gPi9kZXYvbnVsbCAy
Pi9kZXYvbnVsbAoKIyBjbGVhbiB1cCBkZXRyaXR1cwpybSB2YioKCiMgLS0tLS0tLS0tLS0tLS0g
U0VUIEZJWEVEIE1FVEEtREFUQSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIGNy
ZWF0ZSBiYXNlIG1ldGEtZGF0YSBmaWxlIGZyb20gY29uZmlndXJhdGlvbiBzZXR0aW5ncwojIGFu
ZCB0aGUgZml4ZWQgcGFyYW1ldGVycwplY2hvICJtb2RlbD1OZXRDYW0gTGl2ZTIiID4gL3Zhci90
bXAvbWV0YWRhdGEudHh0Ci9tbnQvY2ZnMS9zY3JpcHRzL2NobHMgPj4gL3Zhci90bXAvbWV0YWRh
dGEudHh0CmVjaG8gImlwX2FkZHI9JGlwX2FkZHIiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dApl
Y2hvICJtYWNfYWRkcj0kbWFjX2FkZHIiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJ0
aW1lX3pvbmU9JHR6IiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAib3ZlcmxheV90ZXh0
PSRvdmVybGF5X3RleHQiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAoKIyBjb2xvdXIgYmFsYW5j
ZSBzZXR0aW5ncwpyZWQ9YGF3ayAnTlI9PTcnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCmdyZWVu
PWBhd2sgJ05SPT04JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApibHVlPWBhd2sgJ05SPT05JyAv
bW50L2NmZzEvc2V0dGluZ3MudHh0YCAKYnJpZ2h0bmVzcz1gYXdrICdOUj09MTAnIC9tbnQvY2Zn
MS9zZXR0aW5ncy50eHRgCnNoYXJwbmVzcz1gYXdrICdOUj09MTEnIC9tbnQvY2ZnMS9zZXR0aW5n
cy50eHRgCmh1ZT1gYXdrICdOUj09MTInIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCmNvbnRyYXN0
PWBhd2sgJ05SPT0xMycgL21udC9jZmcxL3NldHRpbmdzLnR4dGAJIApzYXR1cmF0aW9uPWBhd2sg
J05SPT0xNCcgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKYmxjPWBhd2sgJ05SPT0xNScgL21udC9j
ZmcxL3NldHRpbmdzLnR4dGAKCmVjaG8gInJlZD0kcmVkIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50
eHQKZWNobyAiZ3JlZW49JGdyZWVuIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAiYmx1
ZT0kYmx1ZSIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gImJyaWdodG5lc3M9JGJyaWdo
dG5lc3MiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJjb250cmFzdD0kY29udHJhc3Qi
ID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJodWU9JGh1ZSIgPj4gL3Zhci90bXAvbWV0
YWRhdGEudHh0CmVjaG8gInNoYXJwbmVzcz0kc2hhcnBuZXNzIiA+PiAvdmFyL3RtcC9tZXRhZGF0
YS50eHQKZWNobyAic2F0dXJhdGlvbj0kc2F0dXJhdGlvbiIgPj4gL3Zhci90bXAvbWV0YWRhdGEu
dHh0CmVjaG8gImJhY2tsaWdodD0kYmxjIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKCiMgLS0t
LS0tLS0tLS0tLS0gVVBMT0FEIERBVEEgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLQoKIyB3ZSB1c2UgdHdvIHN0YXRlcyB0byBpbmRpY2F0ZSBWSVMgKDApIGFuZCBOSVIg
KDEpIHN0YXRlcwojIGFuZCB1c2UgYSBmb3IgbG9vcCB0byBjeWNsZSB0aHJvdWdoIHRoZXNlIHN0
YXRlcyBhbmQKIyB1cGxvYWQgdGhlIGRhdGEKc3RhdGVzPSIwIDEiCgpmb3Igc3RhdGUgaW4gJHN0
YXRlczsKZG8KCiBpZiBbICIkc3RhdGUiIC1lcSAwIF07IHRoZW4KCiAgIyBjcmVhdGUgVklTIGZp
bGVuYW1lcwogIG1ldGFmaWxlPWBlY2hvICR7U0lURU5BTUV9XyR7REFURVRJTUVTVFJJTkd9Lm1l
dGFgCiAgaW1hZ2U9YGVjaG8gJHtTSVRFTkFNRX1fJHtEQVRFVElNRVNUUklOR30uanBnYAogIGNh
cHR1cmUgJGltYWdlICRtZXRhZmlsZSAkREVMQVkgMAoKIGVsc2UKCiAgIyBjcmVhdGUgTklSIGZp
bGVuYW1lcwogIG1ldGFmaWxlPWBlY2hvICR7U0lURU5BTUV9X0lSXyR7REFURVRJTUVTVFJJTkd9
Lm1ldGFgCiAgaW1hZ2U9YGVjaG8gJHtTSVRFTkFNRX1fSVJfJHtEQVRFVElNRVNUUklOR30uanBn
YAogIGNhcHR1cmUgJGltYWdlICRtZXRhZmlsZSAkREVMQVkgMQogCiBmaQoKICMgcnVuIHRoZSB1
cGxvYWQgc2NyaXB0IGZvciB0aGUgaXAgZGF0YQogIyBhbmQgZm9yIGFsbCBzZXJ2ZXJzCiBmb3Ig
aSBpbiAkbnJzZXJ2ZXJzOwogZG8KICBTRVJWRVI9YGF3ayAtdiBwPSRpICdOUj09cCcgL21udC9j
ZmcxL3NlcnZlci50eHRgCiAgZWNobyAidXBsb2FkaW5nIHRvOiAke1NFUlZFUn0iCiAgZWNobyAi
IgogCiAgIyBpZiBrZXkgZmlsZSBleGlzdHMgdXNlIFNGVFAKICBpZiBbICIke3NlcnZpY2V9IiAh
PSAiRlRQIiBdOyB0aGVuCiAgIGVjaG8gInVzaW5nIHNGVFAiCiAgCiAgIGVjaG8gIlBVVCAke2lt
YWdlfSBkYXRhLyR7U0lURU5BTUV9LyR7aW1hZ2V9IiA+IGJhdGNoZmlsZQogICBlY2hvICJQVVQg
JHttZXRhZmlsZX0gZGF0YS8ke1NJVEVOQU1FfS8ke21ldGFmaWxlfSIgPj4gYmF0Y2hmaWxlCiAg
CiAgICMgdXBsb2FkIHRoZSBkYXRhCiAgIGVjaG8gIlVwbG9hZGluZyAoc3RhdGU6ICR7c3RhdGV9
KSIKICAgZWNobyAiIC0gaW1hZ2UgZmlsZTogJHtpbWFnZX0iCiAgIGVjaG8gIiAtIG1ldGEtZGF0
YSBmaWxlOiAke21ldGFmaWxlfSIKICAgc2Z0cCAtYiBiYXRjaGZpbGUgLWkgIi9tbnQvY2ZnMS9w
aGVub2NhbV9rZXkiIHBoZW5vc2Z0cEAke1NFUlZFUn0gPi9kZXYvbnVsbCAyPi9kZXYvbnVsbCB8
fCBlcnJvcl9leGl0CiAgIAogICAjIHJlbW92ZSBiYXRjaCBmaWxlCiAgIHJtIGJhdGNoZmlsZQog
ICAKICBlbHNlCiAgIGVjaG8gIlVzaW5nIEZUUCBbY2hlY2sgeW91ciBpbnN0YWxsIGFuZCBrZXkg
Y3JlZGVudGlhbHMgdG8gdXNlIHNGVFBdIgogIAogICAjIHVwbG9hZCBpbWFnZQogICBlY2hvICJV
cGxvYWRpbmcgKHN0YXRlOiAke3N0YXRlfSkiCiAgIGVjaG8gIiAtIGltYWdlIGZpbGU6ICR7aW1h
Z2V9IgogICBmdHBwdXQgJHtTRVJWRVJ9IC0tdXNlcm5hbWUgYW5vbnltb3VzIC0tcGFzc3dvcmQg
YW5vbnltb3VzICBkYXRhLyR7U0lURU5BTUV9LyR7aW1hZ2V9ICR7aW1hZ2V9ID4vZGV2L251bGwg
Mj4vZGV2L251bGwgfHwgZXJyb3JfZXhpdAoJCiAgIGVjaG8gIiAtIG1ldGEtZGF0YSBmaWxlOiAk
e21ldGFmaWxlfSIKICAgZnRwcHV0ICR7U0VSVkVSfSAtLXVzZXJuYW1lIGFub255bW91cyAtLXBh
c3N3b3JkIGFub255bW91cyAgZGF0YS8ke1NJVEVOQU1FfS8ke21ldGFmaWxlfSAke21ldGFmaWxl
fSA+L2Rldi9udWxsIDI+L2Rldi9udWxsIHx8IGVycm9yX2V4aXQKCiAgZmkKIGRvbmUKCiAjIGJh
Y2t1cCB0byBTRCBjYXJkIHdoZW4gaW5zZXJ0ZWQKIGlmIFsgIiRTRENBUkQiIC1lcSAxIF07IHRo
ZW4gCiAgY3AgJHtpbWFnZX0gL21udC9tbWMvcGhlbm9jYW1fYmFja3VwLyR7aW1hZ2V9CiAgY3Ag
JHttZXRhZmlsZX0gL21udC9tbWMvcGhlbm9jYW1fYmFja3VwLyR7bWV0YWZpbGV9CiBmaQoKICMg
Y2xlYW4gdXAgZmlsZXMKIHJtICouanBnCiBybSAqLm1ldGEKCmRvbmUKCiMgUmVzZXQgdG8gVklT
IGFzIGRlZmF1bHQKL3Vzci9zYmluL3NldF9pci5zaCAwCgojLS0tLS0tLS0tLS0tLS0gUkVTRVQg
Tk9STUFMIEhFQURFUiAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBvdmVybGF5
IHRleHQKb3ZlcmxheV90ZXh0PWBlY2hvICIke1NJVEVOQU1FfSAtICR7bW9kZWx9IC0gJWEgJWIg
JWQgJVkgJUg6JU06JVMgLSBHTVQke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvIC8lMjAvZydgCgkK
IyBmb3Igbm93IGRpc2FibGUgdGhlIG92ZXJsYXkKd2dldCBodHRwOi8vYWRtaW46JHtwYXNzfUAx
MjcuMC4wLjEvdmIuaHRtP292ZXJsYXl0ZXh0MT0ke292ZXJsYXlfdGV4dH0gPi9kZXYvbnVsbCAy
Pi9kZXYvbnVsbAoKIyBjbGVhbiB1cCBkZXRyaXR1cwpybSB2YioKCiMtLS0tLS0tIEZFRURCQUNL
IE9OIEFDVElWSVRZIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQppZiBb
ICEgLWYgIi92YXIvdG1wL2ltYWdlX2xvZy50eHQiIF07IHRoZW4KIHRvdWNoIC92YXIvdG1wL2lt
YWdlX2xvZy50eHQKIGNobW9kIGErcncgL3Zhci90bXAvaW1hZ2VfbG9nLnR4dApmaQoKZWNobyAi
bGFzdCB1cGxvYWRzIGF0OiIgPj4gL3Zhci90bXAvaW1hZ2VfbG9nLnR4dAplY2hvICREQVRFID4+
IC92YXIvdG1wL2ltYWdlX2xvZy50eHQKdGFpbCAvdmFyL3RtcC9pbWFnZV9sb2cudHh0CgojLS0t
LS0tLSBGSUxFIFBFUk1JU1NJT05TIEFORCBDTEVBTlVQIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0Kcm0gLWYgL3Zhci90bXAvbWV0YWRhdGEudHh0CgoAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
