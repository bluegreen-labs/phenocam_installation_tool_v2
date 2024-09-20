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
  [-k key based (sFTP) authentication if specified]
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
  if [ -f '/mnt/cfg1/phenocam_key' ]; then dropbearkey -t rsa -f /mnt/cfg1/phenocam_key -y; else exit 1; fi
 "

 echo " Retrieving the public key login credentials"
 echo ""
 
 # execute command
 ssh admin@${ip} ${command} > tmp.pub || error_key 2>/dev/null
 
 # strip out the public key
 # no header or footer
 grep "ssh-rsa" tmp.pub > phenocam_key.pub
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
while getopts "hi:p:n:o:s:e:m:kuvrx" option;
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
        k) key=TRUE ;;
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

if [ "${key}" ]; then
  # print the content of the path to the
  # key and assign to a variable
  echo " NOTE: Using secure SFTP and key based logins!"
  echo ""
  has_key="TRUE"
 else
  echo " NOTE: No key will be generated, defaulting to insecure FTP!"
  echo ""
  has_key="FALSE"
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
 if [[ ${has_key} && ! -f /mnt/cfg1/phenocam_key ]]; then dropbearkey -t ecdsa -s 521 -f /mnt/cfg1/phenocam_key >/dev/null; fi &&
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
 if [ -f /mnt/cfg1/phenocam_key ]; then echo ' ----------------------------------'; fi &&
 echo '' &&
 if [ -f /mnt/cfg1/phenocam_key ]; then echo ' A key (pair) exists or was generated, please run:'; fi &&
 if [ -f /mnt/cfg1/phenocam_key ]; then echo ' ./PIT.sh ${ip} -r'; fi &&
 if [ -f /mnt/cfg1/phenocam_key ]; then echo ' to display/retrieve the current login key'; fi &&
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
MDE3NTAAMDAwMDAwMDA3NDQAMTQ1NjIxNTA0NTcAMDEzMjc1ACAwAAAAAAAAAAAAAAAAAAAAAAAA
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
ci50eHRgCmFsbD0ibmF1IgptYXRjaD1gZ3JlcCAtRSAke2FsbH0gL21udC9jZmcxL3NlcnZlci50
eHQgfCB3YyAtbGAKCmlmIFsgJHtucnNlcnZlcnN9IC1lcSAke21hdGNofSBdOwp0aGVuCiBlY2hv
ICJuZXR3b3JrPXBoZW5vY2FtIgpmaQoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMv
cGhlbm9jYW1faW5zdGFsbC5zaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NTUAMDAwMTc1MAAwMDAx
NzUwADAwMDAwMDEyNDU1ADE0NjU3NTc2NjUxADAxNjMxMgAgMAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
byBncmFiIGFuZAojIGFuZCB3aGVyZSB0byBwdXQgY29uZmlnIGZpbGVzCmhvc3Q9J3BoZW5vY2Ft
Lm5hdS5lZHUnCgojIGNyZWF0ZSBkZWZhdWx0IHNlcnZlcgppZiBbICEgLWYgJy9tbnQvY2ZnMS9z
ZXJ2ZXIudHh0JyBdOyB0aGVuCiAgZWNobyAke2hvc3R9ID4gL21udC9jZmcxL3NlcnZlci50eHQK
ICBlY2hvICJ1c2luZyBkZWZhdWx0IGhvc3Q6ICR7aG9zdH0iID4+IC92YXIvdG1wL2luc3RhbGxf
bG9nLnR4dAogIGNobW9kIGErcncgL21udC9jZmcxL3NlcnZlci50eHQKZmkKCiMgT25seSB1cGRh
dGUgdGhlIHNldHRpbmdzIGlmIGV4cGxpY2l0bHkKIyBpbnN0cnVjdGVkIHRvIGRvIHNvLCB0aGlz
IGZpbGUgd2lsbCBiZQojIHNldCB0byBUUlVFIGJ5IHRoZSBQSVQuc2ggc2NyaXB0LCB3aGljaAoj
IHVwb24gcmVib290IHdpbGwgdGhlbiBiZSBydW4uCgppZiBbIGBjYXQgL21udC9jZmcxL3VwZGF0
ZS50eHRgID0gIlRSVUUiIF07IHRoZW4gCgoJIyBzdGFydCBsb2dnaW5nCgllY2hvICItLS0tLSAk
e3RvZGF5fSAtLS0tLSIgPj4gL3Zhci90bXAvaW5zdGFsbF9sb2cudHh0CgoJIy0tLS0tIHJlYWQg
aW4gc2V0dGluZ3MKCWlmIFsgLWYgJy9tbnQvY2ZnMS9zZXR0aW5ncy50eHQnIF07IHRoZW4KCSBj
YW1lcmE9YGF3ayAnTlI9PTEnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgdGltZV9vZmZzZXQ9
YGF3ayAnTlI9PTInIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgY3Jvbl9zdGFydD1gYXdrICdO
Uj09NCcgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBjcm9uX2VuZD1gYXdrICdOUj09NScgL21u
dC9jZmcxL3NldHRpbmdzLnR4dGAKCSBjcm9uX2ludD1gYXdrICdOUj09NicgL21udC9jZmcxL3Nl
dHRpbmdzLnR4dGAKCSAKCSAjIGNvbG91ciBiYWxhbmNlCiAJIHJlZD1gYXdrICdOUj09NycgL21u
dC9jZmcxL3NldHRpbmdzLnR4dGAKCSBncmVlbj1gYXdrICdOUj09OCcgL21udC9jZmcxL3NldHRp
bmdzLnR4dGAKCSBibHVlPWBhd2sgJ05SPT05JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIAoJ
ICMgcmVhZCBpbiB0aGUgYnJpZ2h0bmVzcy9zaGFycG5lc3MvaHVlL3NhdHVyYXRpb24gdmFsdWVz
CgkgYnJpZ2h0bmVzcz1gYXdrICdOUj09MTAnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgc2hh
cnBuZXNzPWBhd2sgJ05SPT0xMScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBodWU9YGF3ayAn
TlI9PTEyJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIGNvbnRyYXN0PWBhd2sgJ05SPT0xMycg
L21udC9jZmcxL3NldHRpbmdzLnR4dGAJIAoJIHNhdHVyYXRpb249YGF3ayAnTlI9PTE0JyAvbW50
L2NmZzEvc2V0dGluZ3MudHh0YAoJIGJsYz1gYXdrICdOUj09MTUnIC9tbnQvY2ZnMS9zZXR0aW5n
cy50eHRgCgllbHNlCgkgZWNobyAiU2V0dGluZ3MgZmlsZSBtaXNzaW5nLCBhYm9ydGluZyBpbnN0
YWxsIHJvdXRpbmUhIiA+PiAvdmFyL3RtcC9pbnN0YWxsX2xvZy50eHQKCWZpCgkKICAgICAgICBw
YXNzPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvLnBhc3N3b3JkYAoKCSMtLS0tLSBzZXQgdGltZSB6
b25lIG9mZnNldCAoZnJvbSBHTVQpCgkKCSMgc2V0IHNpZ24gdGltZSB6b25lCglTSUdOPWBlY2hv
ICR7dGltZV9vZmZzZXR9IHwgY3V0IC1jJzEnYAoKCSMgbm90ZSB0aGUgd2VpcmQgZmxpcCBpbiB0
aGUgbmV0Y2FtIGNhbWVyYXMKCWlmIFsgIiRTSUdOIiA9ICIrIiBdOyB0aGVuCgkgVFo9YGVjaG8g
IkdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8rLyUyRC9nJ2AKCWVsc2UKCSBUWj1gZWNobyAi
R01UJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLy0vJTJCL2cnYAoJZmkKCgkjIGNhbGwgQVBJIHRv
IHNldCB0aGUgdGltZSAKCXdnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0
bT90aW1lem9uZT0ke1RafQoJCgkjIGNsZWFuIHVwIGRldHJpdHVzCglybSB2YioKCQoJZWNobyAi
dGltZSBzZXQgdG8gKGFzY2lpIGZvcm1hdCk6ICR7VFp9IiA+PiAvdmFyL3RtcC9pbnN0YWxsX2xv
Zy50eHQKCQoJIy0tLS0tIHNldCBvdmVybGF5CgkKCSMgY29udmVydCB0byBhc2NpaQoJaWYgWyAi
JFNJR04iID0gIisiIF07IHRoZW4KCSB0aW1lX29mZnNldD1gZWNobyAiJHt0aW1lX29mZnNldH0i
IHwgc2VkICdzLysvJTJCL2cnYAoJZWxzZQoJIHRpbWVfb2Zmc2V0PWBlY2hvICIke3RpbWVfb2Zm
c2V0fSIgfCBzZWQgJ3MvLS8lMkQvZydgCglmaQoJCgkjIG92ZXJsYXkgdGV4dAoJb3ZlcmxheV90
ZXh0PWBlY2hvICIke2NhbWVyYX0gLSAke21vZGVsfSAtICVhICViICVkICVZICVIOiVNOiVTIC0g
R01UJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLyAvJTIwL2cnYAoJCgkjIGZvciBub3cgZGlzYWJs
ZSB0aGUgb3ZlcmxheQoJd2dldCBodHRwOi8vYWRtaW46JHtwYXNzfUAxMjcuMC4wLjEvdmIuaHRt
P292ZXJsYXl0ZXh0MT0ke292ZXJsYXlfdGV4dH0KCQoJIyBjbGVhbiB1cCBkZXRyaXR1cwoJcm0g
dmIqCgkKCWVjaG8gImhlYWRlciBzZXQgdG86ICR7b3ZlcmxheV90ZXh0fSIgPj4gL3Zhci90bXAv
aW5zdGFsbF9sb2cudHh0CgkKCSMtLS0tLSBzZXQgY29sb3VyIHNldHRpbmdzCgkKCSMgY2FsbCBB
UEkgdG8gc2V0IHRoZSB0aW1lIAoJd2dldCBodHRwOi8vYWRtaW46JHtwYXNzfUAxMjcuMC4wLjEv
dmIuaHRtP2JyaWdodG5lc3M9JHticmlnaHRuZXNzfQoJd2dldCBodHRwOi8vYWRtaW46JHtwYXNz
fUAxMjcuMC4wLjEvdmIuaHRtP2NvbnRyYXN0PSR7Y29udHJhc3R9Cgl3Z2V0IGh0dHA6Ly9hZG1p
bjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/c2hhcnBuZXNzPSR7c2hhcnBuZXNzfQoJd2dldCBo
dHRwOi8vYWRtaW46JHtwYXNzfUAxMjcuMC4wLjEvdmIuaHRtP2h1ZT0ke2h1ZX0KCXdnZXQgaHR0
cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9zYXR1cmF0aW9uPSR7c2F0dXJhdGlv
bn0KCQoJIyBjbGVhbiB1cCBkZXRyaXR1cwoJcm0gdmIqCgkJCgkjIHNldCBSR0IgYmFsYW5jZQoJ
L3Vzci9zYmluL3NldF9yZ2Iuc2ggMCAke3JlZH0gJHtncmVlbn0gJHtibHVlfQoKCSMtLS0tLSBn
ZW5lcmF0ZSByYW5kb20gbnVtYmVyIGJldHdlZW4gMCBhbmQgdGhlIGludGVydmFsIHZhbHVlCgly
bnVtYmVyPWBhd2sgLXYgbWluPTAgLXYgbWF4PSR7Y3Jvbl9pbnR9ICdCRUdJTntzcmFuZCgpOyBw
cmludCBpbnQobWluK3JhbmQoKSoobWF4LW1pbisxKSl9J2AKCQoJIyBkaXZpZGUgNjAgbWluIGJ5
IHRoZSBpbnRlcnZhbAoJZGl2PWBhd2sgLXYgaW50ZXJ2YWw9JHtjcm9uX2ludH0gJ0JFR0lOIHtw
cmludCA1OS9pbnRlcnZhbH0nYAoJaW50PWBlY2hvICRkaXYgfCBjdXQgLWQnLicgLWYxYAoJCgkj
IGdlbmVyYXRlIGxpc3Qgb2YgdmFsdWVzIHRvIGl0ZXJhdGUgb3ZlcgoJdmFsdWVzPWBhd2sgLXYg
bWF4PSR7aW50fSAnQkVHSU57IGZvcihpPTA7aTw9bWF4O2krKykgcHJpbnQgaX0nYAoJCglmb3Ig
aSBpbiAke3ZhbHVlc307IGRvCgkgcHJvZHVjdD1gYXdrIC12IGludGVydmFsPSR7Y3Jvbl9pbnR9
IC12IHN0ZXA9JHtpfSAnQkVHSU4ge3ByaW50IGludChpbnRlcnZhbCpzdGVwKX0nYAkKCSBzdW09
YGF3ayAtdiBwcm9kdWN0PSR7cHJvZHVjdH0gLXYgbnI9JHtybnVtYmVyfSAnQkVHSU4ge3ByaW50
IGludChwcm9kdWN0K25yKX0nYAoJIAoJIGlmIFsgIiR7aX0iIC1lcSAiMCIgXTt0aGVuCgkgIGlu
dGVydmFsPWBlY2hvICR7c3VtfWAKCSBlbHNlCgkgIGlmIFsgIiRzdW0iIC1sZSAiNTkiIF07dGhl
bgoJICAgaW50ZXJ2YWw9YGVjaG8gJHtpbnRlcnZhbH0sJHtzdW19YAoJICBmaQoJIGZpCglkb25l
CgoJZWNobyAiY3JvbnRhYiBpbnRlcnZhbHMgc2V0IHRvOiAke2ludGVydmFsfSIgPj4gL3Zhci90
bXAvaW5zdGFsbF9sb2cudHh0CgoJIy0tLS0tIHNldCByb290IGNyb24gam9icwoJCgkjIHNldCB0
aGUgbWFpbiBwaWN0dXJlIHRha2luZyByb3V0aW5lCgllY2hvICIke2ludGVydmFsfSAke2Nyb25f
c3RhcnR9LSR7Y3Jvbl9lbmR9ICogKiAqIHNoIC9tbnQvY2ZnMS9zY3JpcHRzL3BoZW5vY2FtX3Vw
bG9hZC5zaCIgPiAvbW50L2NmZzEvc2NoZWR1bGUvYWRtaW4KCQkKCSMgdXBsb2FkIGlwIGFkZHJl
c3MgaW5mbyBhdCBtaWRkYXkKCWVjaG8gIjU5IDExICogKiAqIHNoIC9tbnQvY2ZnMS9zY3JpcHRz
L3BoZW5vY2FtX2lwX3RhYmxlLnNoIiA+PiAvbW50L2NmZzEvc2NoZWR1bGUvYWRtaW4KCQkKCSMg
cmVib290IGF0IG1pZG5pZ2h0IG9uIHJvb3QgYWNjb3VudAoJZWNobyAiNTkgMjMgKiAqICogc2gg
L21udC9jZmcxL3NjcmlwdHMvcmVib290X2NhbWVyYS5zaCIgPiAvbW50L2NmZzEvc2NoZWR1bGUv
cm9vdAoJCgkjIGluZm8KCWVjaG8gIkZpbmlzaGVkIGluaXRpYWwgc2V0dXAiID4+IC92YXIvdG1w
L2luc3RhbGxfbG9nLnR4dAoKCSMtLS0tLSBmaW5hbGl6ZSB0aGUgc2V0dXAgKyByZWJvb3QKCgkj
IHVwZGF0ZSB0aGUgc3RhdGUgb2YgdGhlIHVwZGF0ZSByZXF1aXJlbWVudAoJIyBpLmUuIHNraXAg
aWYgY2FsbGVkIG1vcmUgdGhhbiBvbmNlLCB1bmxlc3MKCSMgdGhpcyBmaWxlIGlzIG1hbnVhbGx5
IHNldCB0byBUUlVFIHdoaWNoCgkjIHdvdWxkIHJlcnVuIHRoZSBpbnN0YWxsIHJvdXRpbmUgdXBv
biByZWJvb3QKCWVjaG8gIkZBTFNFIiA+IC9tbnQvY2ZnMS91cGRhdGUudHh0CgoJIyByZWJvb3Rp
bmcgY2FtZXJhIHRvIG1ha2Ugc3VyZSBhbGwKCSMgdGhlIHNldHRpbmdzIHN0aWNrCglzaCAvbW50
L2NmZzEvc2NyaXB0cy9yZWJvb3RfY2FtZXJhLnNoCmZpCgojIGNsZWFuIGV4aXQKZXhpdCAwCgoA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
AAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDc3NQAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMTcyMTAA
MTQ2NjAwNzMyMzcAMDE2MTA2ACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
CiMgLS0tLS0tLS0tLS0tLS0gU0VUVElOR1MgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLQoKIyByZWFkIGluIGNvbmZpZ3VyYXRpb24gc2V0dGluZ3MKIyBncmFiIHNp
dGVuYW1lClNJVEVOQU1FPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoKIyBn
cmFiIHRpbWUgb2Zmc2V0IC8gbG9jYWwgdGltZSB6b25lCiMgYW5kIGNvbnZlcnQgKy8tIHRvIGFz
Y2lpCnRpbWVfb2Zmc2V0PWBhd2sgJ05SPT0yJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApTSUdO
PWBlY2hvICR7dGltZV9vZmZzZXR9IHwgY3V0IC1jJzEnYAoKaWYgWyAiJFNJR04iID0gIisiIF07
IHRoZW4KIHRpbWVfb2Zmc2V0PWBlY2hvICIke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvKy8lMkIv
ZydgCmVsc2UKIHRpbWVfb2Zmc2V0PWBlY2hvICIke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvLS8l
MkQvZydgCmZpCgojIHNldCBjYW1lcmEgbW9kZWwgbmFtZQptb2RlbD0iTmV0Q2FtIExpdmUyIgoK
IyBob3cgbWFueSBzZXJ2ZXJzIGRvIHdlIHVwbG9hZCB0bwpucnNlcnZlcnM9YGF3ayAnRU5EIHtw
cmludCBOUn0nIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YApucnNlcnZlcnM9YGF3ayAtdiB2YXI9JHtu
cnNlcnZlcnN9ICdCRUdJTnsgbj0xOyB3aGlsZSAobiA8PSB2YXIgKSB7IHByaW50IG47IG4rKzsg
fSB9JyB8IHRyICdcbicgJyAnYAoKIyBncmFiIHBhc3N3b3JkCnBhc3M9YGF3ayAnTlI9PTEnIC9t
bnQvY2ZnMS8ucGFzc3dvcmRgCgojIE1vdmUgaW50byB0ZW1wb3JhcnkgZGlyZWN0b3J5CiMgd2hp
Y2ggcmVzaWRlcyBpbiBSQU0sIG5vdCB0bwojIHdlYXIgb3V0IG90aGVyIHBlcm1hbmVudCBtZW1v
cnkKY2QgL3Zhci90bXAKCiMgc2V0cyB0aGUgZGVsYXkgYmV0d2VlbiB0aGUKIyBSR0IgYW5kIElS
IGltYWdlIGFjcXVpc2l0aW9ucwpERUxBWT0zMAoKIyBncmFiIGRhdGUgLSBrZWVwIGZpeGVkIGZv
ciBSR0IgYW5kIElSIHVwbG9hZHMKREFURT1gZGF0ZSArIiVhICViICVkICVZICVIOiVNOiVTImAK
CiMgZ3JhcCBkYXRlIGFuZCB0aW1lIHN0cmluZyB0byBiZSBpbnNlcnRlZCBpbnRvIHRoZQojIGZ0
cCBzY3JpcHRzIC0gdGhpcyBjb29yZGluYXRlcyB0aGUgdGltZSBzdGFtcHMKIyBiZXR3ZWVuIHRo
ZSBSR0IgYW5kIElSIGltYWdlcyAob3RoZXJ3aXNlIHRoZXJlIGlzIGEKIyBzbGlnaHQgb2Zmc2V0
IGR1ZSB0byB0aGUgdGltZSBuZWVkZWQgdG8gYWRqdXN0IGV4cG9zdXJlCkRBVEVUSU1FU1RSSU5H
PWBkYXRlICsiJVlfJW1fJWRfJUglTSVTImAKCiMgZ3JhYiBtZXRhZGF0YSB1c2luZyB0aGUgbWV0
YWRhdGEgZnVuY3Rpb24KIyBncmFiIHRoZSBNQUMgYWRkcmVzcwptYWNfYWRkcj1gaWZjb25maWcg
ZXRoMCB8IGdyZXAgJ0hXYWRkcicgfCBhd2sgJ3twcmludCAkNX0nIHwgc2VkICdzLzovL2cnYAoK
IyBncmFiIGludGVybmFsIGlwIGFkZHJlc3MKaXBfYWRkcj1gaWZjb25maWcgZXRoMCB8IGF3ayAn
L2luZXQgYWRkci97cHJpbnQgc3Vic3RyKCQyLDYpfSdgCgojIGdyYWIgZXh0ZXJuYWwgaXAgYWRk
cmVzcyBpZiB0aGVyZSBpcyBhbiBleHRlcm5hbCBjb25uZWN0aW9uCiMgZmlyc3QgdGVzdCB0aGUg
Y29ubmVjdGlvbiB0byB0aGUgZ29vZ2xlIG5hbWUgc2VydmVyCmNvbm5lY3Rpb249YHBpbmcgLXEg
LWMgMSA4LjguOC44ID4gL2Rldi9udWxsICYmIGVjaG8gb2sgfHwgZWNobyBlcnJvcmAKCiMgZ3Jh
YiB0aW1lIHpvbmUKdHo9YGNhdCAvdmFyL1RaYAoKIyBnZXQgU0QgY2FyZCBwcmVzZW5jZQpTRENB
UkQ9YGRmIHwgZ3JlcCAibW1jIiB8IHdjIC1sYAoKIyBiYWNrdXAgdG8gU0QgY2FyZCB3aGVuIGlu
c2VydGVkCiMgcnVucyBvbiBwaGVub2NhbSB1cGxvYWQgcmF0aGVyIHRoYW4gaW5zdGFsbAojIHRv
IGFsbG93IGhvdC1zd2FwcGluZyBvZiBjYXJkcwppZiBbICIkU0RDQVJEIiAtZXEgMSBdOyB0aGVu
CiAKICMgY3JlYXRlIGJhY2t1cCBkaXJlY3RvcnkKIG1rZGlyIC1wIC9tbnQvbW1jL3BoZW5vY2Ft
X2JhY2t1cC8KIApmaQoKIyAtLS0tLS0tLS0tLS0tLSBTRVQgRklYRUQgREFURSBUSU1FIEhFQURF
UiAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIG92ZXJsYXkgdGV4dApvdmVybGF5X3RleHQ9
YGVjaG8gIiR7U0lURU5BTUV9IC0gJHttb2RlbH0gLSAke0RBVEV9IC0gR01UJHt0aW1lX29mZnNl
dH0iIHwgc2VkICdzLyAvJTIwL2cnYAoJCiMgZm9yIG5vdyBkaXNhYmxlIHRoZSBvdmVybGF5Cndn
ZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9vdmVybGF5dGV4dDE9JHtv
dmVybGF5X3RleHR9ID4vZGV2L251bGwgMj4vZGV2L251bGwKCiMgY2xlYW4gdXAgZGV0cml0dXMK
cm0gdmIqCgojIC0tLS0tLS0tLS0tLS0tIFNFVCBGSVhFRCBNRVRBLURBVEEgLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBjcmVhdGUgYmFzZSBtZXRhLWRhdGEgZmlsZSBmcm9tIGNv
bmZpZ3VyYXRpb24gc2V0dGluZ3MKIyBhbmQgdGhlIGZpeGVkIHBhcmFtZXRlcnMKZWNobyAibW9k
ZWw9TmV0Q2FtIExpdmUyIiA+IC92YXIvdG1wL21ldGFkYXRhLnR4dAovbW50L2NmZzEvc2NyaXB0
cy9jaGxzID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJpcF9hZGRyPSRpcF9hZGRyIiA+
PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAibWFjX2FkZHI9JG1hY19hZGRyIiA+PiAvdmFy
L3RtcC9tZXRhZGF0YS50eHQKZWNobyAidGltZV96b25lPSR0eiIgPj4gL3Zhci90bXAvbWV0YWRh
dGEudHh0CmVjaG8gIm92ZXJsYXlfdGV4dD0kb3ZlcmxheV90ZXh0IiA+PiAvdmFyL3RtcC9tZXRh
ZGF0YS50eHQKCiMgY29sb3VyIGJhbGFuY2Ugc2V0dGluZ3MKcmVkPWBhd2sgJ05SPT03JyAvbW50
L2NmZzEvc2V0dGluZ3MudHh0YApncmVlbj1gYXdrICdOUj09OCcgL21udC9jZmcxL3NldHRpbmdz
LnR4dGAKYmx1ZT1gYXdrICdOUj09OScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAgCmJyaWdodG5l
c3M9YGF3ayAnTlI9PTEwJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApzaGFycG5lc3M9YGF3ayAn
TlI9PTExJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApodWU9YGF3ayAnTlI9PTEyJyAvbW50L2Nm
ZzEvc2V0dGluZ3MudHh0YApjb250cmFzdD1gYXdrICdOUj09MTMnIC9tbnQvY2ZnMS9zZXR0aW5n
cy50eHRgCSAKc2F0dXJhdGlvbj1gYXdrICdOUj09MTQnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRg
CmJsYz1gYXdrICdOUj09MTUnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgplY2hvICJyZWQ9JHJl
ZCIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gImdyZWVuPSRncmVlbiIgPj4gL3Zhci90
bXAvbWV0YWRhdGEudHh0CmVjaG8gImJsdWU9JGJsdWUiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4
dAplY2hvICJicmlnaHRuZXNzPSRicmlnaHRuZXNzIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQK
ZWNobyAiY29udHJhc3Q9JGNvbnRyYXN0IiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAi
aHVlPSRodWUiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJzaGFycG5lc3M9JHNoYXJw
bmVzcyIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gInNhdHVyYXRpb249JHNhdHVyYXRp
b24iID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJiYWNrbGlnaHQ9JGJsYyIgPj4gL3Zh
ci90bXAvbWV0YWRhdGEudHh0CgojIC0tLS0tLS0tLS0tLS0tIFVQTE9BRCBEQVRBIC0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgd2UgdXNlIHR3byBzdGF0ZXMgdG8g
aW5kaWNhdGUgVklTICgwKSBhbmQgTklSICgxKSBzdGF0ZXMKIyBhbmQgdXNlIGEgZm9yIGxvb3Ag
dG8gY3ljbGUgdGhyb3VnaCB0aGVzZSBzdGF0ZXMgYW5kCiMgdXBsb2FkIHRoZSBkYXRhCnN0YXRl
cz0iMCAxIgoKZm9yIHN0YXRlIGluICRzdGF0ZXM7CmRvCgogaWYgWyAiJHN0YXRlIiAtZXEgMCBd
OyB0aGVuCgogICMgY3JlYXRlIFZJUyBmaWxlbmFtZXMKICBtZXRhZmlsZT1gZWNobyAke1NJVEVO
QU1FfV8ke0RBVEVUSU1FU1RSSU5HfS5tZXRhYAogIGltYWdlPWBlY2hvICR7U0lURU5BTUV9XyR7
REFURVRJTUVTVFJJTkd9LmpwZ2AKICBjYXB0dXJlICRpbWFnZSAkbWV0YWZpbGUgJERFTEFZIDAK
CiBlbHNlCgogICMgY3JlYXRlIE5JUiBmaWxlbmFtZXMKICBtZXRhZmlsZT1gZWNobyAke1NJVEVO
QU1FfV9JUl8ke0RBVEVUSU1FU1RSSU5HfS5tZXRhYAogIGltYWdlPWBlY2hvICR7U0lURU5BTUV9
X0lSXyR7REFURVRJTUVTVFJJTkd9LmpwZ2AKICBjYXB0dXJlICRpbWFnZSAkbWV0YWZpbGUgJERF
TEFZIDEKIAogZmkKCiAjIHJ1biB0aGUgdXBsb2FkIHNjcmlwdCBmb3IgdGhlIGlwIGRhdGEKICMg
YW5kIGZvciBhbGwgc2VydmVycwogZm9yIGkgaW4gJG5yc2VydmVyczsKIGRvCiAgU0VSVkVSPWBh
d2sgLXYgcD0kaSAnTlI9PXAnIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YAogCiAgZWNobyAidXBsb2Fk
aW5nIHRvOiAke1NFUlZFUn0iCiAKICAjIGlmIGtleSBmaWxlIGV4aXN0cyB1c2UgU0ZUUAogIGlm
IFsgLWYgIi9tbnQvY2ZnMS9waGVub2NhbV9rZXkiIF07IHRoZW4KICAgZWNobyAidXNpbmcgc0ZU
UCIKICAKICAgZWNobyAiUFVUICR7aW1hZ2V9IGRhdGEvJHtTSVRFTkFNRX0vJHtpbWFnZX0iID4g
YmF0Y2hmaWxlCiAgIGVjaG8gIlBVVCAke21ldGFmaWxlfSBkYXRhLyR7U0lURU5BTUV9LyR7bWV0
YWZpbGV9IiA+PiBiYXRjaGZpbGUKICAKICAgIyB1cGxvYWQgdGhlIGRhdGEKICAgZWNobyAiVXBs
b2FkaW5nIChzdGF0ZTogJHtzdGF0ZX0pIgogICBlY2hvICIgLSBpbWFnZSBmaWxlOiAke2ltYWdl
fSIKICAgZWNobyAiIC0gbWV0YS1kYXRhIGZpbGU6ICR7bWV0YWZpbGV9IgogICBzZnRwIC1iIGJh
dGNoZmlsZSAtaSAiL21udC9jZmcxL3BoZW5vY2FtX2tleSIgcGhlbm9zZnRwQCR7U0VSVkVSfSA+
L2Rldi9udWxsIDI+L2Rldi9udWxsIHx8IGVycm9yX2V4aXQKICAgCiAgICMgcmVtb3ZlIGJhdGNo
IGZpbGUKICAgcm0gYmF0Y2hmaWxlCiAgIAogIGVsc2UKICAgZWNobyAiVXNpbmcgRlRQIFtjaGVj
ayB5b3VyIGluc3RhbGwgdG8gdXNlIHNGVFBdIgogIAogICAjIHVwbG9hZCBpbWFnZQogICBlY2hv
ICJVcGxvYWRpbmcgKHN0YXRlOiAke3N0YXRlfSkiCiAgIGVjaG8gIiAtIGltYWdlIGZpbGU6ICR7
aW1hZ2V9IgogICBmdHBwdXQgJHtTRVJWRVJ9IC0tdXNlcm5hbWUgYW5vbnltb3VzIC0tcGFzc3dv
cmQgYW5vbnltb3VzICBkYXRhLyR7U0lURU5BTUV9LyR7aW1hZ2V9ICR7aW1hZ2V9ID4vZGV2L251
bGwgMj4vZGV2L251bGwgfHwgZXJyb3JfZXhpdAoJCiAgIGVjaG8gIiAtIG1ldGEtZGF0YSBmaWxl
OiAke21ldGFmaWxlfSIKICAgZnRwcHV0ICR7U0VSVkVSfSAtLXVzZXJuYW1lIGFub255bW91cyAt
LXBhc3N3b3JkIGFub255bW91cyAgZGF0YS8ke1NJVEVOQU1FfS8ke21ldGFmaWxlfSAke21ldGFm
aWxlfSA+L2Rldi9udWxsIDI+L2Rldi9udWxsIHx8IGVycm9yX2V4aXQKCiAgZmkKIGRvbmUKCiAj
IGJhY2t1cCB0byBTRCBjYXJkIHdoZW4gaW5zZXJ0ZWQKIGlmIFsgIiRTRENBUkQiIC1lcSAxIF07
IHRoZW4gCiAgY3AgJHtpbWFnZX0gL21udC9tbWMvcGhlbm9jYW1fYmFja3VwLyR7aW1hZ2V9CiAg
Y3AgJHttZXRhZmlsZX0gL21udC9tbWMvcGhlbm9jYW1fYmFja3VwLyR7bWV0YWZpbGV9CiBmaQoK
ICMgY2xlYW4gdXAgZmlsZXMKIHJtICouanBnCiBybSAqLm1ldGEKCmRvbmUKCiMgUmVzZXQgdG8g
VklTIGFzIGRlZmF1bHQKL3Vzci9zYmluL3NldF9pci5zaCAwCgojLS0tLS0tLS0tLS0tLS0gUkVT
RVQgTk9STUFMIEhFQURFUiAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBvdmVy
bGF5IHRleHQKb3ZlcmxheV90ZXh0PWBlY2hvICIke1NJVEVOQU1FfSAtICR7bW9kZWx9IC0gJWEg
JWIgJWQgJVkgJUg6JU06JVMgLSBHTVQke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvIC8lMjAvZydg
CgkKIyBmb3Igbm93IGRpc2FibGUgdGhlIG92ZXJsYXkKd2dldCBodHRwOi8vYWRtaW46JHtwYXNz
fUAxMjcuMC4wLjEvdmIuaHRtP292ZXJsYXl0ZXh0MT0ke292ZXJsYXlfdGV4dH0gPi9kZXYvbnVs
bCAyPi9kZXYvbnVsbAoKIyBjbGVhbiB1cCBkZXRyaXR1cwpybSB2YioKCiMtLS0tLS0tIEZFRURC
QUNLIE9OIEFDVElWSVRZIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQpp
ZiBbICEgLWYgIi92YXIvdG1wL2ltYWdlX2xvZy50eHQiIF07IHRoZW4KIHRvdWNoIC92YXIvdG1w
L2ltYWdlX2xvZy50eHQKIGNobW9kIGErcncgL3Zhci90bXAvaW1hZ2VfbG9nLnR4dApmaQoKZWNo
byAibGFzdCB1cGxvYWRzIGF0OiIgPj4gL3Zhci90bXAvaW1hZ2VfbG9nLnR4dAplY2hvICREQVRF
ID4+IC92YXIvdG1wL2ltYWdlX2xvZy50eHQKdGFpbCAvdmFyL3RtcC9pbWFnZV9sb2cudHh0Cgoj
LS0tLS0tLSBGSUxFIFBFUk1JU1NJT05TIEFORCBDTEVBTlVQIC0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0Kcm0gLWYgL3Zhci90bXAvbWV0YWRhdGEudHh0CgoAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAZmlsZXMvcGhlbm9jYW1fdmFsaWRhdGUuc2gAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAADAwMDA3NzUAMDAwMTc1MAAwMDAxNzUwADAwMDAwMDAyNjUzADE0NjczMjQzNjM3ADAxNjQy
NwAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
L3NiaW46L2Jpbjovc2JpbiIKCiMgZXJyb3IgaGFuZGxpbmcKZXJyb3JfZXhpdCgpewogIGVjaG8g
IiIKICBlY2hvICIgc0ZUUCBsb2dpbiBmYWlsZWQhIERpZCB5b3UgdXBsb2FkIHlvdXIgcHVibGlj
IGtleT8iCiAgZWNobyAiIgp9CgojIC0tLS0tLS0tLS0tLS0tIFNFVFRJTkdTIC0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgTW92ZSBpbnRvIHRlbXBvcmFyeSBk
aXJlY3RvcnkKIyB3aGljaCByZXNpZGVzIGluIFJBTSwgbm90IHRvCiMgd2VhciBvdXQgb3RoZXIg
cGVybWFuZW50IG1lbW9yeQpjZCAvdmFyL3RtcAoKIyBob3cgbWFueSBzZXJ2ZXJzIGRvIHdlIHVw
bG9hZCB0bwpucnNlcnZlcnM9YGF3ayAnRU5EIHtwcmludCBOUn0nIC9tbnQvY2ZnMS9zZXJ2ZXIu
dHh0YApucnNlcnZlcnM9YGF3ayAtdiB2YXI9JHtucnNlcnZlcnN9ICdCRUdJTnsgbj0xOyB3aGls
ZSAobiA8PSB2YXIgKSB7IHByaW50IG47IG4rKzsgfSB9JyB8IHRyICdcbicgJyAnYAoKIyAtLS0t
LS0tLS0tLS0tLSBWQUxJREFURSBMT0dJTiAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLQoKaWYgWyAhIC1mICIvbW50L2NmZzEvcGhlbm9jYW1fa2V5IiBdOyB0aGVuCiBlY2hv
ICJubyBzRlRQIGtleSBmb3VuZCwgbm90aGluZyB0byBiZSBkb25lLi4uIgogZXhpdCAwCmZpCgoK
IyBydW4gdGhlIHVwbG9hZCBzY3JpcHQgZm9yIHRoZSBpcCBkYXRhCiMgYW5kIGZvciBhbGwgc2Vy
dmVycwpmb3IgaSBpbiAkbnJzZXJ2ZXJzOwpkbwogIFNFUlZFUj1gYXdrIC12IHA9JGkgJ05SPT1w
JyAvbW50L2NmZzEvc2VydmVyLnR4dGAKIAogIGVjaG8gIiIgCiAgZWNobyAiQ2hlY2tpbmcgc2Vy
dmVyOiAke1NFUlZFUn0iCgogIGVjaG8gImV4aXQiID4gYmF0Y2hmaWxlCiAgc2Z0cCAtYiBiYXRj
aGZpbGUgLWkgIi9tbnQvY2ZnMS9waGVub2NhbV9rZXkiIHBoZW5vc2Z0cEAke1NFUlZFUn0gPi9k
ZXYvbnVsbCAyPi9kZXYvbnVsbCB8fCBlcnJvcl9leGl0CiAgCmRvbmUKCgAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAABmaWxlcy9yZWJvb3RfY2FtZXJhLnNoAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
MDAwMDY2NAAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMDIwNDEAMTQ2NTc3MDc1MDEAMDE1NTQ3ACAw
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHVzdGFyICAAa2h1Zmtl
bnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAACMhL2Jpbi9zaAoKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiMgKGMpIEtvZW4gSHVma2VucyBm
b3IgQmx1ZUdyZWVuIExhYnMgKEJWKQojCiMgVW5hdXRob3JpemVkIGNoYW5nZXMgdG8gdGhpcyBz
Y3JpcHQgYXJlIGNvbnNpZGVyZWQgYSBjb3B5cmlnaHQKIyB2aW9sYXRpb24gYW5kIHdpbGwgYmUg
cHJvc2VjdXRlZC4KIwojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgaGFyZCBjb2RlIHBhdGggd2hpY2ggYXJlIGxv
c3QgaW4gc29tZSBpbnN0YW5jZXMKIyB3aGVuIGNhbGxpbmcgdGhlIHNjcmlwdCB0aHJvdWdoIHNz
aCAKUEFUSD0iL3Vzci9sb2NhbC9iaW46L3Vzci9sb2NhbC9zYmluOi91c3IvYmluOi91c3Ivc2Jp
bjovYmluOi9zYmluIgoKIyBncmFiIHBhc3N3b3JkCnBhc3M9YGF3ayAnTlI9PTEnIC9tbnQvY2Zn
MS8ucGFzc3dvcmRgCgojIG1vdmUgaW50byB0ZW1wb3JhcnkgZGlyZWN0b3J5CmNkIC92YXIvdG1w
CgojIHNsZWVwIDMwIHNlY29uZHMgZm9yIGxhc3QKIyBjb21tYW5kIHRvIGZpbmlzaCAoaWYgYW55
IHNob3VsZCBiZSBydW5uaW5nKQpzbGVlcCAzMAoKIyB0aGVuIHJlYm9vdAp3Z2V0IGh0dHA6Ly9h
ZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/aXBjYW1yZXN0YXJ0Y21kICY+L2Rldi9udWxs
CgojIGRvbid0IGV4aXQgY2xlYW5seSB3aGVuIHRoZSByZWJvb3QgY29tbWFuZCBkb2Vzbid0IHN0
aWNrCiMgc2hvdWxkIHRyaWdnZXIgYSB3YXJuaW5nIG1lc3NhZ2UKc2xlZXAgNjAKCmVjaG8gIiAt
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LSIKZWNobyAiIgplY2hvICIgUkVCT09UIEZBSUxFRCAtIElOU1RBTEwgTUlHSFQgTk9UIEJFIENP
TVBMRVRFISIKZWNobyAiIgplY2hvICI9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIKCmV4aXQgMQoAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAGZpbGVzL3NpdGVfaXAuaHRtbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAw
NjY0ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAwMDU2MAAxNDUzNjU1MjUwMAAwMTQ3MzAAIDAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXN0YXIgIABraHVma2VucwAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAPCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBIVE1MIDQuMCBUcmFu
c2l0aW9uYWwvL0VOIj4KPGh0bWw+CjxoZWFkPgo8bWV0YSBodHRwLWVxdWl2PSJDb250ZW50LVR5
cGUiIGNvbnRlbnQ9InRleHQvaHRtbDsgY2hhcnNldD1pc28tODg1OS0xIj4KPHRpdGxlPk5ldENh
bVNDIElQIEFkZHJlc3M8L3RpdGxlPgo8L2hlYWQ+Cjxib2R5PgpUaW1lIG9mIExhc3QgSVAgVXBs
b2FkOiBEQVRFVElNRTxicj4KSVAgQWRkcmVzczogU0lURUlQCiZidWxsOyA8YSBocmVmPSJodHRw
Oi8vU0lURUlQLyI+VmlldzwvYT4KJmJ1bGw7IDxhIGhyZWY9Imh0dHA6Ly9TSVRFSVAvYWRtaW4u
Y2dpIj5Db25maWd1cmU8L2E+CjwvYm9keT4KPC9odG1sPgoAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
