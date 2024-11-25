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
L2NobHMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzc1ADAwMDE3NTAAMDAw
MTc1MAAwMDAwMDAwMDc0MQAxNDcyMTEwNDIxNwAwMTMyNjAAIDAAAAAAAAAAAAAAAAAAAAAAAAAA
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
LS0tLS0tLQoKbnJzZXJ2ZXJzPWBhd2sgJ0VORCB7cHJpbnQgTlJ9JyAvbW50L2NmZzEvc2VydmVy
LnR4dGAKYWxsPSJpY29zIgptYXRjaD1gZ3JlcCAtRSAke2FsbH0gL21udC9jZmcxL3NlcnZlci50
eHQgfCB3YyAtbGAKCmlmIFsgJHtucnNlcnZlcnN9IC1lcSAke21hdGNofSBdOwp0aGVuCiBlY2hv
ICJuZXR3b3JrPWljb3MiCmZpCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxlcy9w
aGVub2NhbV9pbnN0YWxsLnNoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDc3NQAwMDAxNzUwADAwMDE3
NTAAMDAwMDAwMTI0NjEAMTQ3MjExMDQyMTcAMDE2MjYyACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAHVzdGFyICAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMhL2Jpbi9z
aAoKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tCiMgKGMpIEtvZW4gSHVma2VucyBmb3IgQmx1ZUdyZWVuIExhYnMgKEJW
KQojCiMgVW5hdXRob3JpemVkIGNoYW5nZXMgdG8gdGhpcyBzY3JpcHQgYXJlIGNvbnNpZGVyZWQg
YSBjb3B5cmlnaHQKIyB2aW9sYXRpb24gYW5kIHdpbGwgYmUgcHJvc2VjdXRlZC4KIwojLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0KCiMgaGFyZCBjb2RlIHBhdGggd2hpY2ggYXJlIGxvc3QgaW4gc29tZSBpbnN0YW5jZXMK
IyB3aGVuIGNhbGxpbmcgdGhlIHNjcmlwdCB0aHJvdWdoIHNzaCAKUEFUSD0iL3Vzci9sb2NhbC9i
aW46L3Vzci9sb2NhbC9zYmluOi91c3IvYmluOi91c3Ivc2JpbjovYmluOi9zYmluIgoKc2xlZXAg
MzAKY2QgL3Zhci90bXAKCiMgdXBkYXRlIHBlcm1pc3Npb25zIHNjcmlwdHMKY2htb2QgYStyd3gg
L21udC9jZmcxL3NjcmlwdHMvKgoKIyBnZXQgdG9kYXlzIGRhdGUKdG9kYXk9YGRhdGUgKyIlWSAl
bSAlZCAlSDolTTolUyJgCgojIHNldCBjYW1lcmEgbW9kZWwgbmFtZQptb2RlbD0iTmV0Q2FtIExp
dmUyIgoKIyB1cGxvYWQgLyBkb3dubG9hZCBzZXJ2ZXIgLSBsb2NhdGlvbiBmcm9tIHdoaWNoIHRv
IGdyYWIgYW5kCiMgYW5kIHdoZXJlIHRvIHB1dCBjb25maWcgZmlsZXMKaG9zdD0naWNvczAxLnVh
bnR3ZXJwZW4uYmUnCgojIGNyZWF0ZSBkZWZhdWx0IHNlcnZlcgppZiBbICEgLWYgJy9tbnQvY2Zn
MS9zZXJ2ZXIudHh0JyBdOyB0aGVuCiAgZWNobyAke2hvc3R9ID4gL21udC9jZmcxL3NlcnZlci50
eHQKICBlY2hvICJ1c2luZyBkZWZhdWx0IGhvc3Q6ICR7aG9zdH0iID4+IC92YXIvdG1wL2luc3Rh
bGxfbG9nLnR4dAogIGNobW9kIGErcncgL21udC9jZmcxL3NlcnZlci50eHQKZmkKCiMgT25seSB1
cGRhdGUgdGhlIHNldHRpbmdzIGlmIGV4cGxpY2l0bHkKIyBpbnN0cnVjdGVkIHRvIGRvIHNvLCB0
aGlzIGZpbGUgd2lsbCBiZQojIHNldCB0byBUUlVFIGJ5IHRoZSBQSVQuc2ggc2NyaXB0LCB3aGlj
aAojIHVwb24gcmVib290IHdpbGwgdGhlbiBiZSBydW4uCgppZiBbIGBjYXQgL21udC9jZmcxL3Vw
ZGF0ZS50eHRgID0gIlRSVUUiIF07IHRoZW4gCgoJIyBzdGFydCBsb2dnaW5nCgllY2hvICItLS0t
LSAke3RvZGF5fSAtLS0tLSIgPj4gL3Zhci90bXAvaW5zdGFsbF9sb2cudHh0CgoJIy0tLS0tIHJl
YWQgaW4gc2V0dGluZ3MKCWlmIFsgLWYgJy9tbnQvY2ZnMS9zZXR0aW5ncy50eHQnIF07IHRoZW4K
CSBjYW1lcmE9YGF3ayAnTlI9PTEnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgdGltZV9vZmZz
ZXQ9YGF3ayAnTlI9PTInIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgY3Jvbl9zdGFydD1gYXdr
ICdOUj09NCcgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBjcm9uX2VuZD1gYXdrICdOUj09NScg
L21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBjcm9uX2ludD1gYXdrICdOUj09NicgL21udC9jZmcx
L3NldHRpbmdzLnR4dGAKCSAKCSAjIGNvbG91ciBiYWxhbmNlCiAJIHJlZD1gYXdrICdOUj09Nycg
L21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBncmVlbj1gYXdrICdOUj09OCcgL21udC9jZmcxL3Nl
dHRpbmdzLnR4dGAKCSBibHVlPWBhd2sgJ05SPT05JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJ
IAoJICMgcmVhZCBpbiB0aGUgYnJpZ2h0bmVzcy9zaGFycG5lc3MvaHVlL3NhdHVyYXRpb24gdmFs
dWVzCgkgYnJpZ2h0bmVzcz1gYXdrICdOUj09MTAnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkg
c2hhcnBuZXNzPWBhd2sgJ05SPT0xMScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCSBodWU9YGF3
ayAnTlI9PTEyJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIGNvbnRyYXN0PWBhd2sgJ05SPT0x
MycgL21udC9jZmcxL3NldHRpbmdzLnR4dGAJIAoJIHNhdHVyYXRpb249YGF3ayAnTlI9PTE0JyAv
bW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIGJsYz1gYXdrICdOUj09MTUnIC9tbnQvY2ZnMS9zZXR0
aW5ncy50eHRgCgllbHNlCgkgZWNobyAiU2V0dGluZ3MgZmlsZSBtaXNzaW5nLCBhYm9ydGluZyBp
bnN0YWxsIHJvdXRpbmUhIiA+PiAvdmFyL3RtcC9pbnN0YWxsX2xvZy50eHQKCWZpCgkKICAgICAg
ICBwYXNzPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvLnBhc3N3b3JkYAoKCSMtLS0tLSBzZXQgdGlt
ZSB6b25lIG9mZnNldCAoZnJvbSBHTVQpCgkKCSMgc2V0IHNpZ24gdGltZSB6b25lCglTSUdOPWBl
Y2hvICR7dGltZV9vZmZzZXR9IHwgY3V0IC1jJzEnYAoKCSMgbm90ZSB0aGUgd2VpcmQgZmxpcCBp
biB0aGUgbmV0Y2FtIGNhbWVyYXMKCWlmIFsgIiRTSUdOIiA9ICIrIiBdOyB0aGVuCgkgVFo9YGVj
aG8gIkdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8rLyUyRC9nJ2AKCWVsc2UKCSBUWj1gZWNo
byAiR01UJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLy0vJTJCL2cnYAoJZmkKCgkjIGNhbGwgQVBJ
IHRvIHNldCB0aGUgdGltZSAKCXdnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3Zi
Lmh0bT90aW1lem9uZT0ke1RafQoJCgkjIGNsZWFuIHVwIGRldHJpdHVzCglybSB2YioKCQoJZWNo
byAidGltZSBzZXQgdG8gKGFzY2lpIGZvcm1hdCk6ICR7VFp9IiA+PiAvdmFyL3RtcC9pbnN0YWxs
X2xvZy50eHQKCQoJIy0tLS0tIHNldCBvdmVybGF5CgkKCSMgY29udmVydCB0byBhc2NpaQoJaWYg
WyAiJFNJR04iID0gIisiIF07IHRoZW4KCSB0aW1lX29mZnNldD1gZWNobyAiJHt0aW1lX29mZnNl
dH0iIHwgc2VkICdzLysvJTJCL2cnYAoJZWxzZQoJIHRpbWVfb2Zmc2V0PWBlY2hvICIke3RpbWVf
b2Zmc2V0fSIgfCBzZWQgJ3MvLS8lMkQvZydgCglmaQoJCgkjIG92ZXJsYXkgdGV4dAoJb3Zlcmxh
eV90ZXh0PWBlY2hvICIke2NhbWVyYX0gLSAke21vZGVsfSAtICVhICViICVkICVZICVIOiVNOiVT
IC0gR01UJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLyAvJTIwL2cnYAoJCgkjIGZvciBub3cgZGlz
YWJsZSB0aGUgb3ZlcmxheQoJd2dldCBodHRwOi8vYWRtaW46JHtwYXNzfUAxMjcuMC4wLjEvdmIu
aHRtP292ZXJsYXl0ZXh0MT0ke292ZXJsYXlfdGV4dH0KCQoJIyBjbGVhbiB1cCBkZXRyaXR1cwoJ
cm0gdmIqCgkKCWVjaG8gImhlYWRlciBzZXQgdG86ICR7b3ZlcmxheV90ZXh0fSIgPj4gL3Zhci90
bXAvaW5zdGFsbF9sb2cudHh0CgkKCSMtLS0tLSBzZXQgY29sb3VyIHNldHRpbmdzCgkKCSMgY2Fs
bCBBUEkgdG8gc2V0IHRoZSB0aW1lIAoJd2dldCBodHRwOi8vYWRtaW46JHtwYXNzfUAxMjcuMC4w
LjEvdmIuaHRtP2JyaWdodG5lc3M9JHticmlnaHRuZXNzfQoJd2dldCBodHRwOi8vYWRtaW46JHtw
YXNzfUAxMjcuMC4wLjEvdmIuaHRtP2NvbnRyYXN0PSR7Y29udHJhc3R9Cgl3Z2V0IGh0dHA6Ly9h
ZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/c2hhcnBuZXNzPSR7c2hhcnBuZXNzfQoJd2dl
dCBodHRwOi8vYWRtaW46JHtwYXNzfUAxMjcuMC4wLjEvdmIuaHRtP2h1ZT0ke2h1ZX0KCXdnZXQg
aHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9zYXR1cmF0aW9uPSR7c2F0dXJh
dGlvbn0KCQoJIyBjbGVhbiB1cCBkZXRyaXR1cwoJcm0gdmIqCgkJCgkjIHNldCBSR0IgYmFsYW5j
ZQoJL3Vzci9zYmluL3NldF9yZ2Iuc2ggMCAke3JlZH0gJHtncmVlbn0gJHtibHVlfQoKCSMtLS0t
LSBnZW5lcmF0ZSByYW5kb20gbnVtYmVyIGJldHdlZW4gMCBhbmQgdGhlIGludGVydmFsIHZhbHVl
CglybnVtYmVyPWBhd2sgLXYgbWluPTAgLXYgbWF4PSR7Y3Jvbl9pbnR9ICdCRUdJTntzcmFuZCgp
OyBwcmludCBpbnQobWluK3JhbmQoKSoobWF4LW1pbisxKSl9J2AKCQoJIyBkaXZpZGUgNjAgbWlu
IGJ5IHRoZSBpbnRlcnZhbAoJZGl2PWBhd2sgLXYgaW50ZXJ2YWw9JHtjcm9uX2ludH0gJ0JFR0lO
IHtwcmludCA1OS9pbnRlcnZhbH0nYAoJaW50PWBlY2hvICRkaXYgfCBjdXQgLWQnLicgLWYxYAoJ
CgkjIGdlbmVyYXRlIGxpc3Qgb2YgdmFsdWVzIHRvIGl0ZXJhdGUgb3ZlcgoJdmFsdWVzPWBhd2sg
LXYgbWF4PSR7aW50fSAnQkVHSU57IGZvcihpPTA7aTw9bWF4O2krKykgcHJpbnQgaX0nYAoJCglm
b3IgaSBpbiAke3ZhbHVlc307IGRvCgkgcHJvZHVjdD1gYXdrIC12IGludGVydmFsPSR7Y3Jvbl9p
bnR9IC12IHN0ZXA9JHtpfSAnQkVHSU4ge3ByaW50IGludChpbnRlcnZhbCpzdGVwKX0nYAkKCSBz
dW09YGF3ayAtdiBwcm9kdWN0PSR7cHJvZHVjdH0gLXYgbnI9JHtybnVtYmVyfSAnQkVHSU4ge3By
aW50IGludChwcm9kdWN0K25yKX0nYAoJIAoJIGlmIFsgIiR7aX0iIC1lcSAiMCIgXTt0aGVuCgkg
IGludGVydmFsPWBlY2hvICR7c3VtfWAKCSBlbHNlCgkgIGlmIFsgIiRzdW0iIC1sZSAiNTkiIF07
dGhlbgoJICAgaW50ZXJ2YWw9YGVjaG8gJHtpbnRlcnZhbH0sJHtzdW19YAoJICBmaQoJIGZpCglk
b25lCgoJZWNobyAiY3JvbnRhYiBpbnRlcnZhbHMgc2V0IHRvOiAke2ludGVydmFsfSIgPj4gL3Zh
ci90bXAvaW5zdGFsbF9sb2cudHh0CgoJIy0tLS0tIHNldCByb290IGNyb24gam9icwoJCgkjIHNl
dCB0aGUgbWFpbiBwaWN0dXJlIHRha2luZyByb3V0aW5lCgllY2hvICIke2ludGVydmFsfSAke2Ny
b25fc3RhcnR9LSR7Y3Jvbl9lbmR9ICogKiAqIHNoIC9tbnQvY2ZnMS9zY3JpcHRzL3BoZW5vY2Ft
X3VwbG9hZC5zaCIgPiAvbW50L2NmZzEvc2NoZWR1bGUvYWRtaW4KCQkKCSMgdXBsb2FkIGlwIGFk
ZHJlc3MgaW5mbyBhdCBtaWRkYXkKCWVjaG8gIjU5IDExICogKiAqIHNoIC9tbnQvY2ZnMS9zY3Jp
cHRzL3BoZW5vY2FtX2lwX3RhYmxlLnNoIiA+PiAvbW50L2NmZzEvc2NoZWR1bGUvYWRtaW4KCQkK
CSMgcmVib290IGF0IG1pZG5pZ2h0IG9uIHJvb3QgYWNjb3VudAoJZWNobyAiNTkgMjMgKiAqICog
c2ggL21udC9jZmcxL3NjcmlwdHMvcmVib290X2NhbWVyYS5zaCIgPiAvbW50L2NmZzEvc2NoZWR1
bGUvcm9vdAoJCgkjIGluZm8KCWVjaG8gIkZpbmlzaGVkIGluaXRpYWwgc2V0dXAiID4+IC92YXIv
dG1wL2luc3RhbGxfbG9nLnR4dAoKCSMtLS0tLSBmaW5hbGl6ZSB0aGUgc2V0dXAgKyByZWJvb3QK
CgkjIHVwZGF0ZSB0aGUgc3RhdGUgb2YgdGhlIHVwZGF0ZSByZXF1aXJlbWVudAoJIyBpLmUuIHNr
aXAgaWYgY2FsbGVkIG1vcmUgdGhhbiBvbmNlLCB1bmxlc3MKCSMgdGhpcyBmaWxlIGlzIG1hbnVh
bGx5IHNldCB0byBUUlVFIHdoaWNoCgkjIHdvdWxkIHJlcnVuIHRoZSBpbnN0YWxsIHJvdXRpbmUg
dXBvbiByZWJvb3QKCWVjaG8gIkZBTFNFIiA+IC9tbnQvY2ZnMS91cGRhdGUudHh0CgoJIyByZWJv
b3RpbmcgY2FtZXJhIHRvIG1ha2Ugc3VyZSBhbGwKCSMgdGhlIHNldHRpbmdzIHN0aWNrCglzaCAv
bW50L2NmZzEvc2NyaXB0cy9yZWJvb3RfY2FtZXJhLnNoCmZpCgojIGNsZWFuIGV4aXQKZXhpdCAw
CgoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxlcy9waGVub2NhbV9pcF90
YWJsZS5zaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDc1NQAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMDI2
MTIAMTQ2NTc1NzY2MzEAMDE2NDEzACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAHVzdGFyICAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABraHVma2Vu
cwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMhL2Jpbi9zaAoKIy0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tCiMgKGMpIEtvZW4gSHVma2VucyBmb3IgQmx1ZUdyZWVuIExhYnMgKEJWKQojCiMgVW5hdXRo
b3JpemVkIGNoYW5nZXMgdG8gdGhpcyBzY3JpcHQgYXJlIGNvbnNpZGVyZWQgYSBjb3B5cmlnaHQK
IyB2aW9sYXRpb24gYW5kIHdpbGwgYmUgcHJvc2VjdXRlZC4KIwojLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgaGFy
ZCBjb2RlIHBhdGggd2hpY2ggYXJlIGxvc3QgaW4gc29tZSBpbnN0YW5jZXMKIyB3aGVuIGNhbGxp
bmcgdGhlIHNjcmlwdCB0aHJvdWdoIHNzaCAKUEFUSD0iL3Vzci9sb2NhbC9iaW46L3Vzci9sb2Nh
bC9zYmluOi91c3IvYmluOi91c3Ivc2JpbjovYmluOi9zYmluIgoKIyBzb21lIGZlZWRiYWNrIG9u
IHRoZSBhY3Rpb24KZWNobyAidXBsb2FkaW5nIElQIHRhYmxlIgoKIyBob3cgbWFueSBzZXJ2ZXJz
IGRvIHdlIHVwbG9hZCB0bwpucnNlcnZlcnM9YGF3ayAnRU5EIHtwcmludCBOUn0nIC9tbnQvY2Zn
MS9zZXJ2ZXIudHh0YApucnNlcnZlcnM9YGF3ayAtdiB2YXI9JHtucnNlcnZlcnN9ICdCRUdJTnsg
bj0xOyB3aGlsZSAobiA8PSB2YXIgKSB7IHByaW50IG47IG4rKzsgfSB9JyB8IHRyICdcbicgJyAn
YAoKIyBncmFiIHRoZSBuYW1lLCBkYXRlIGFuZCBJUCBvZiB0aGUgY2FtZXJhCkRBVEVUSU1FPWBk
YXRlYAoKIyBncmFiIGludGVybmFsIGlwIGFkZHJlc3MKSVA9YGlmY29uZmlnIGV0aDAgfCBhd2sg
Jy9pbmV0IGFkZHIve3ByaW50IHN1YnN0cigkMiw2KX0nYApTSVRFTkFNRT1gYXdrICdOUj09MScg
L21udC9jZmcxL3NldHRpbmdzLnR4dGAKCiMgdXBkYXRlIHRoZSBJUCBhbmQgdGltZSB2YXJpYWJs
ZXMKY2F0IC9tbnQvY2ZnMS9zY3JpcHRzL3NpdGVfaXAuaHRtbCB8IHNlZCAic3xEQVRFVElNRXwk
REFURVRJTUV8ZyIgfCBzZWQgInN8U0lURUlQfCRJUHxnIiA+IC92YXIvdG1wLyR7U0lURU5BTUV9
XF9pcC5odG1sCgojIHJ1biB0aGUgdXBsb2FkIHNjcmlwdCBmb3IgdGhlIGlwIGRhdGEKIyBhbmQg
Zm9yIGFsbCBzZXJ2ZXJzCmZvciBpIGluICRucnNlcnZlcnMgOwpkbwogU0VSVkVSPWBhd2sgLXYg
cD0kaSAnTlI9PXAnIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YCAKCQogIyB1cGxvYWQgaW1hZ2UKIGVj
aG8gInVwbG9hZGluZyBOSVIgaW1hZ2UgJHtpbWFnZX0iCiBmdHBwdXQgJHtTRVJWRVJ9IC11ICJh
bm9ueW1vdXMiIC1wICJhbm9ueW1vdXMiIGRhdGEvJHtTSVRFTkFNRX0vJHtTSVRFTkFNRX1cX2lw
Lmh0bWwgL3Zhci90bXAvJHtTSVRFTkFNRX1cX2lwLmh0bWwKCmRvbmUKCiMgY2xlYW4gdXAKcm0g
L3Zhci90bXAvJHtTSVRFTkFNRX1cX2lwLmh0bWwKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZpbGVzL3BoZW5vY2FtX3VwbG9hZC5z
aAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzc1ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAyMDY0MwAx
NDY3NDI0NzQxMQAwMTYxMTQAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAdXN0YXIgIABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGtodWZrZW5zAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyEvYmluL3NoCgojLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0K
IyAoYykgS29lbiBIdWZrZW5zIGZvciBCbHVlR3JlZW4gTGFicyAoQlYpCiMKIyBVbmF1dGhvcml6
ZWQgY2hhbmdlcyB0byB0aGlzIHNjcmlwdCBhcmUgY29uc2lkZXJlZCBhIGNvcHlyaWdodAojIHZp
b2xhdGlvbiBhbmQgd2lsbCBiZSBwcm9zZWN1dGVkLgojCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBoYXJkIGNv
ZGUgcGF0aCB3aGljaCBhcmUgbG9zdCBpbiBzb21lIGluc3RhbmNlcwojIHdoZW4gY2FsbGluZyB0
aGUgc2NyaXB0IHRocm91Z2ggc3NoIApQQVRIPSIvdXNyL2xvY2FsL2JpbjovdXNyL2xvY2FsL3Ni
aW46L3Vzci9iaW46L3Vzci9zYmluOi9iaW46L3NiaW4iCgojIGVycm9yIGhhbmRsaW5nCmVycm9y
X2V4aXQoKXsKICBlY2hvICIiCiAgZWNobyAiIEZBSUxFRCBUTyBVUExPQUQgREFUQSIKICBlY2hv
ICIiCn0KCiMtLS0tIGZlZWRiYWNrIG9uIHN0YXJ0dXAgLS0tCgplY2hvICIiCmVjaG8gIlN0YXJ0
aW5nIGltYWdlIHVwbG9hZHMgLi4uICIKZWNobyAiIgoKIy0tLS0gc3Vicm91dGluZXMgLS0tCgpj
YXB0dXJlKCkgewoKIGltYWdlPSQxCiBtZXRhZmlsZT0kMgogZGVsYXk9JDMKIGlyPSQ0CgogIyBT
ZXQgdGhlIGltYWdlIHRvIG5vbiBJUiBpLmUuIFZJUwogL3Vzci9zYmluL3NldF9pci5zaCAkaXIg
Pi9kZXYvbnVsbCAyPi9kZXYvbnVsbAoKICMgYWRqdXN0IGV4cG9zdXJlCiBzbGVlcCAkZGVsYXkK
CiAjIGdyYWIgdGhlIGltYWdlIGZyb20gdGhlCiB3Z2V0IGh0dHA6Ly8xMjcuMC4wLjEvaW1hZ2Uu
anBnIC1PICR7aW1hZ2V9ID4vZGV2L251bGwgMj4vZGV2L251bGwKCiAjIGdyYWIgZGF0ZSBhbmQg
dGltZSBmb3IgYC5tZXRhYCBmaWxlcwogTUVUQURBVEVUSU1FPWBkYXRlIC1Jc2Vjb25kc2AKCiAj
IGdyYWIgdGhlIGV4cG9zdXJlIHRpbWUgYW5kIGFwcGVuZCB0byBtZXRhLWRhdGEKIGV4cG9zdXJl
PWAvdXNyL3NiaW4vZ2V0X2V4cCB8IGN1dCAtZCAnICcgLWY0YAoKICMgYWRqdXN0IG1ldGEtZGF0
YSBmaWxlCiBjYXQgL3Zhci90bXAvbWV0YWRhdGEudHh0ID4gL3Zhci90bXAvJHttZXRhZmlsZX0K
IGVjaG8gImV4cG9zdXJlPSR7ZXhwb3N1cmV9IiA+PiAvdmFyL3RtcC8ke21ldGFmaWxlfQogZWNo
byAiaXJfZW5hYmxlPSRpciIgPj4gL3Zhci90bXAvJHttZXRhZmlsZX0KIGVjaG8gImRhdGV0aW1l
X29yaWdpbmFsPVwiJE1FVEFEQVRFVElNRVwiIiA+PiAvdmFyL3RtcC8ke21ldGFmaWxlfQoKfQoK
IyBlcnJvciBoYW5kbGluZwpsb2dpbl9zdWNjZXNzKCl7CiBzZXJ2aWNlPSJzRlRQIgp9CgojIC0t
LS0tLS0tLS0tLS0tIFNFVFRJTkdTIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0KCiMgcmVhZCBpbiBjb25maWd1cmF0aW9uIHNldHRpbmdzCiMgZ3JhYiBzaXRlbmFt
ZQpTSVRFTkFNRT1gYXdrICdOUj09MScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCiMgZ3JhYiB0
aW1lIG9mZnNldCAvIGxvY2FsIHRpbWUgem9uZQojIGFuZCBjb252ZXJ0ICsvLSB0byBhc2NpaQp0
aW1lX29mZnNldD1gYXdrICdOUj09MicgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKU0lHTj1gZWNo
byAke3RpbWVfb2Zmc2V0fSB8IGN1dCAtYycxJ2AKCmlmIFsgIiRTSUdOIiA9ICIrIiBdOyB0aGVu
CiB0aW1lX29mZnNldD1gZWNobyAiJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLysvJTJCL2cnYApl
bHNlCiB0aW1lX29mZnNldD1gZWNobyAiJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLy0vJTJEL2cn
YApmaQoKIyBzZXQgY2FtZXJhIG1vZGVsIG5hbWUKbW9kZWw9Ik5ldENhbSBMaXZlMiIKCiMgaG93
IG1hbnkgc2VydmVycyBkbyB3ZSB1cGxvYWQgdG8KbnJzZXJ2ZXJzPWBhd2sgJ0VORCB7cHJpbnQg
TlJ9JyAvbW50L2NmZzEvc2VydmVyLnR4dGAKbnJzZXJ2ZXJzPWBhd2sgLXYgdmFyPSR7bnJzZXJ2
ZXJzfSAnQkVHSU57IG49MTsgd2hpbGUgKG4gPD0gdmFyICkgeyBwcmludCBuOyBuKys7IH0gfScg
fCB0ciAnXG4nICcgJ2AKCiMgZ3JhYiBwYXNzd29yZApwYXNzPWBhd2sgJ05SPT0xJyAvbW50L2Nm
ZzEvLnBhc3N3b3JkYAoKIyBNb3ZlIGludG8gdGVtcG9yYXJ5IGRpcmVjdG9yeQojIHdoaWNoIHJl
c2lkZXMgaW4gUkFNLCBub3QgdG8KIyB3ZWFyIG91dCBvdGhlciBwZXJtYW5lbnQgbWVtb3J5CmNk
IC92YXIvdG1wCgojIHNldHMgdGhlIGRlbGF5IGJldHdlZW4gdGhlCiMgUkdCIGFuZCBJUiBpbWFn
ZSBhY3F1aXNpdGlvbnMKREVMQVk9MzAKCiMgZ3JhYiBkYXRlIC0ga2VlcCBmaXhlZCBmb3IgUkdC
IGFuZCBJUiB1cGxvYWRzCkRBVEU9YGRhdGUgKyIlYSAlYiAlZCAlWSAlSDolTTolUyJgCgojIGdy
YXAgZGF0ZSBhbmQgdGltZSBzdHJpbmcgdG8gYmUgaW5zZXJ0ZWQgaW50byB0aGUKIyBmdHAgc2Ny
aXB0cyAtIHRoaXMgY29vcmRpbmF0ZXMgdGhlIHRpbWUgc3RhbXBzCiMgYmV0d2VlbiB0aGUgUkdC
IGFuZCBJUiBpbWFnZXMgKG90aGVyd2lzZSB0aGVyZSBpcyBhCiMgc2xpZ2h0IG9mZnNldCBkdWUg
dG8gdGhlIHRpbWUgbmVlZGVkIHRvIGFkanVzdCBleHBvc3VyZQpEQVRFVElNRVNUUklORz1gZGF0
ZSArIiVZXyVtXyVkXyVIJU0lUyJgCgojIGdyYWIgbWV0YWRhdGEgdXNpbmcgdGhlIG1ldGFkYXRh
IGZ1bmN0aW9uCiMgZ3JhYiB0aGUgTUFDIGFkZHJlc3MKbWFjX2FkZHI9YGlmY29uZmlnIGV0aDAg
fCBncmVwICdIV2FkZHInIHwgYXdrICd7cHJpbnQgJDV9JyB8IHNlZCAncy86Ly9nJ2AKCiMgZ3Jh
YiBpbnRlcm5hbCBpcCBhZGRyZXNzCmlwX2FkZHI9YGlmY29uZmlnIGV0aDAgfCBhd2sgJy9pbmV0
IGFkZHIve3ByaW50IHN1YnN0cigkMiw2KX0nYAoKIyBncmFiIGV4dGVybmFsIGlwIGFkZHJlc3Mg
aWYgdGhlcmUgaXMgYW4gZXh0ZXJuYWwgY29ubmVjdGlvbgojIGZpcnN0IHRlc3QgdGhlIGNvbm5l
Y3Rpb24gdG8gdGhlIGdvb2dsZSBuYW1lIHNlcnZlcgpjb25uZWN0aW9uPWBwaW5nIC1xIC1jIDEg
OC44LjguOCA+IC9kZXYvbnVsbCAmJiBlY2hvIG9rIHx8IGVjaG8gZXJyb3JgCgojIGdyYWIgdGlt
ZSB6b25lCnR6PWBjYXQgL3Zhci9UWmAKCiMgZ2V0IFNEIGNhcmQgcHJlc2VuY2UKU0RDQVJEPWBk
ZiB8IGdyZXAgIm1tYyIgfCB3YyAtbGAKCiMgYmFja3VwIHRvIFNEIGNhcmQgd2hlbiBpbnNlcnRl
ZAojIHJ1bnMgb24gcGhlbm9jYW0gdXBsb2FkIHJhdGhlciB0aGFuIGluc3RhbGwKIyB0byBhbGxv
dyBob3Qtc3dhcHBpbmcgb2YgY2FyZHMKaWYgWyAiJFNEQ0FSRCIgLWVxIDEgXTsgdGhlbgogCiAj
IGNyZWF0ZSBiYWNrdXAgZGlyZWN0b3J5CiBta2RpciAtcCAvbW50L21tYy9waGVub2NhbV9iYWNr
dXAvCiAKZmkKCiMgLS0tLS0tLS0tLS0tLS0gVkFMSURBVEUgU0VSVklDRSAtLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBjaGVjayBpZiBzRlRQIGlzIHJlYWNoYWJsZSwgZXZl
biBpZiBhIGtleXMgcHJvdmlkZWQgaXQgbWlnaHQgbm90IGJlCiMgdmFsaWRhdGVkIHlldCAtIGZh
bGwgYmFjayB0byBGVFAgaWYgc0ZUUCBpcyBub3QgYXZhaWxhYmxlICh5ZXQpCgojIHNldCB0aGUg
ZGVmYXVsdCBzZXJ2aWNlCnNlcnZpY2U9IkZUUCIKCmlmIFsgLWYgIi9tbnQvY2ZnMS9waGVub2Nh
bV9rZXkiIF07IHRoZW4KCiBlY2hvICJBbiBzRlRQIGtleSB3YXMgZm91bmQsIGNoZWNraW5nIGxv
Z2luIGNyZWRlbnRpYWxzLi4uIgoKIGVjaG8gImV4aXQiID4gYmF0Y2hmaWxlCiBzZnRwIC1iIGJh
dGNoZmlsZSAtaSAiL21udC9jZmcxL3BoZW5vY2FtX2tleSIgcGhlbm9zZnRwQCR7U0VSVkVSfSA+
L2Rldi9udWxsIDI+L2Rldi9udWxsCgogIyBpZiBzdGF0dXMgb3V0cHV0IGxhc3QgY29tbWFuZCB3
YXMKICMgMCBzZXQgc2VydmljZSB0byBzRlRQCiBpZiBbICQ/IC1lcSAwIF07IHRoZW4KICAgIGVj
aG8gIlNVQ0NFUy4uLiB1c2luZyBzZWN1cmUgc0ZUUCIKICAgIGVjaG8gIiIKICAgIHNlcnZpY2U9
InNGVFAiCiBlbHNlCiAgICBlY2hvICJGQUlMRUQuLi4gZmFsbGluZyBiYWNrIHRvIEZUUCEiCiAg
ICBlY2hvICIiCiBmaQogCiAjIGNsZWFuIHVwCiBybSBiYXRjaGZpbGUKZmkKCiMgLS0tLS0tLS0t
LS0tLS0gU0VUIEZJWEVEIERBVEUgVElNRSBIRUFERVIgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LQoKIyBvdmVybGF5IHRleHQKb3ZlcmxheV90ZXh0PWBlY2hvICIke1NJVEVOQU1FfSAtICR7bW9k
ZWx9IC0gJHtEQVRFfSAtIEdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8gLyUyMC9nJ2AKCQoj
IGZvciBub3cgZGlzYWJsZSB0aGUgb3ZlcmxheQp3Z2V0IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEy
Ny4wLjAuMS92Yi5odG0/b3ZlcmxheXRleHQxPSR7b3ZlcmxheV90ZXh0fSA+L2Rldi9udWxsIDI+
L2Rldi9udWxsCgojIGNsZWFuIHVwIGRldHJpdHVzCnJtIHZiKgoKIyAtLS0tLS0tLS0tLS0tLSBT
RVQgRklYRUQgTUVUQS1EQVRBIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgY3Jl
YXRlIGJhc2UgbWV0YS1kYXRhIGZpbGUgZnJvbSBjb25maWd1cmF0aW9uIHNldHRpbmdzCiMgYW5k
IHRoZSBmaXhlZCBwYXJhbWV0ZXJzCmVjaG8gIm1vZGVsPU5ldENhbSBMaXZlMiIgPiAvdmFyL3Rt
cC9tZXRhZGF0YS50eHQKL21udC9jZmcxL3NjcmlwdHMvY2hscyA+PiAvdmFyL3RtcC9tZXRhZGF0
YS50eHQKZWNobyAiaXBfYWRkcj0kaXBfYWRkciIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVj
aG8gIm1hY19hZGRyPSRtYWNfYWRkciIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gInRp
bWVfem9uZT0kdHoiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJvdmVybGF5X3RleHQ9
JG92ZXJsYXlfdGV4dCIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CgojIGNvbG91ciBiYWxhbmNl
IHNldHRpbmdzCnJlZD1gYXdrICdOUj09NycgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKZ3JlZW49
YGF3ayAnTlI9PTgnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCmJsdWU9YGF3ayAnTlI9PTknIC9t
bnQvY2ZnMS9zZXR0aW5ncy50eHRgIApicmlnaHRuZXNzPWBhd2sgJ05SPT0xMCcgL21udC9jZmcx
L3NldHRpbmdzLnR4dGAKc2hhcnBuZXNzPWBhd2sgJ05SPT0xMScgL21udC9jZmcxL3NldHRpbmdz
LnR4dGAKaHVlPWBhd2sgJ05SPT0xMicgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKY29udHJhc3Q9
YGF3ayAnTlI9PTEzJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAkgCnNhdHVyYXRpb249YGF3ayAn
TlI9PTE0JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApibGM9YGF3ayAnTlI9PTE1JyAvbW50L2Nm
ZzEvc2V0dGluZ3MudHh0YAoKZWNobyAicmVkPSRyZWQiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4
dAplY2hvICJncmVlbj0kZ3JlZW4iID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJibHVl
PSRibHVlIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNobyAiYnJpZ2h0bmVzcz0kYnJpZ2h0
bmVzcyIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gImNvbnRyYXN0PSRjb250cmFzdCIg
Pj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gImh1ZT0kaHVlIiA+PiAvdmFyL3RtcC9tZXRh
ZGF0YS50eHQKZWNobyAic2hhcnBuZXNzPSRzaGFycG5lc3MiID4+IC92YXIvdG1wL21ldGFkYXRh
LnR4dAplY2hvICJzYXR1cmF0aW9uPSRzYXR1cmF0aW9uIiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50
eHQKZWNobyAiYmFja2xpZ2h0PSRibGMiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAoKIyAtLS0t
LS0tLS0tLS0tLSBVUExPQUQgREFUQSAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tCgojIHdlIHVzZSB0d28gc3RhdGVzIHRvIGluZGljYXRlIFZJUyAoMCkgYW5kIE5JUiAo
MSkgc3RhdGVzCiMgYW5kIHVzZSBhIGZvciBsb29wIHRvIGN5Y2xlIHRocm91Z2ggdGhlc2Ugc3Rh
dGVzIGFuZAojIHVwbG9hZCB0aGUgZGF0YQpzdGF0ZXM9IjAgMSIKCmZvciBzdGF0ZSBpbiAkc3Rh
dGVzOwpkbwoKIGlmIFsgIiRzdGF0ZSIgLWVxIDAgXTsgdGhlbgoKICAjIGNyZWF0ZSBWSVMgZmls
ZW5hbWVzCiAgbWV0YWZpbGU9YGVjaG8gJHtTSVRFTkFNRX1fJHtEQVRFVElNRVNUUklOR30ubWV0
YWAKICBpbWFnZT1gZWNobyAke1NJVEVOQU1FfV8ke0RBVEVUSU1FU1RSSU5HfS5qcGdgCiAgY2Fw
dHVyZSAkaW1hZ2UgJG1ldGFmaWxlICRERUxBWSAwCgogZWxzZQoKICAjIGNyZWF0ZSBOSVIgZmls
ZW5hbWVzCiAgbWV0YWZpbGU9YGVjaG8gJHtTSVRFTkFNRX1fSVJfJHtEQVRFVElNRVNUUklOR30u
bWV0YWAKICBpbWFnZT1gZWNobyAke1NJVEVOQU1FfV9JUl8ke0RBVEVUSU1FU1RSSU5HfS5qcGdg
CiAgY2FwdHVyZSAkaW1hZ2UgJG1ldGFmaWxlICRERUxBWSAxCiAKIGZpCgogIyBydW4gdGhlIHVw
bG9hZCBzY3JpcHQgZm9yIHRoZSBpcCBkYXRhCiAjIGFuZCBmb3IgYWxsIHNlcnZlcnMKIGZvciBp
IGluICRucnNlcnZlcnM7CiBkbwogIFNFUlZFUj1gYXdrIC12IHA9JGkgJ05SPT1wJyAvbW50L2Nm
ZzEvc2VydmVyLnR4dGAKICBlY2hvICJ1cGxvYWRpbmcgdG86ICR7U0VSVkVSfSIKICBlY2hvICIi
CiAKICAjIGlmIGtleSBmaWxlIGV4aXN0cyB1c2UgU0ZUUAogIGlmIFsgIiR7c2VydmljZX0iICE9
ICJGVFAiIF07IHRoZW4KICAgZWNobyAidXNpbmcgc0ZUUCIKICAKICAgZWNobyAiUFVUICR7aW1h
Z2V9IGRhdGEvJHtTSVRFTkFNRX0vJHtpbWFnZX0iID4gYmF0Y2hmaWxlCiAgIGVjaG8gIlBVVCAk
e21ldGFmaWxlfSBkYXRhLyR7U0lURU5BTUV9LyR7bWV0YWZpbGV9IiA+PiBiYXRjaGZpbGUKICAK
ICAgIyB1cGxvYWQgdGhlIGRhdGEKICAgZWNobyAiVXBsb2FkaW5nIChzdGF0ZTogJHtzdGF0ZX0p
IgogICBlY2hvICIgLSBpbWFnZSBmaWxlOiAke2ltYWdlfSIKICAgZWNobyAiIC0gbWV0YS1kYXRh
IGZpbGU6ICR7bWV0YWZpbGV9IgogICBzZnRwIC1iIGJhdGNoZmlsZSAtaSAiL21udC9jZmcxL3Bo
ZW5vY2FtX2tleSIgcGhlbm9zZnRwQCR7U0VSVkVSfSA+L2Rldi9udWxsIDI+L2Rldi9udWxsIHx8
IGVycm9yX2V4aXQKICAgCiAgICMgcmVtb3ZlIGJhdGNoIGZpbGUKICAgcm0gYmF0Y2hmaWxlCiAg
IAogIGVsc2UKICAgZWNobyAiVXNpbmcgRlRQIFtjaGVjayB5b3VyIGluc3RhbGwgYW5kIGtleSBj
cmVkZW50aWFscyB0byB1c2Ugc0ZUUF0iCiAgCiAgICMgdXBsb2FkIGltYWdlCiAgIGVjaG8gIlVw
bG9hZGluZyAoc3RhdGU6ICR7c3RhdGV9KSIKICAgZWNobyAiIC0gaW1hZ2UgZmlsZTogJHtpbWFn
ZX0iCiAgIGZ0cHB1dCAke1NFUlZFUn0gLS11c2VybmFtZSBhbm9ueW1vdXMgLS1wYXNzd29yZCBh
bm9ueW1vdXMgIGRhdGEvJHtTSVRFTkFNRX0vJHtpbWFnZX0gJHtpbWFnZX0gPi9kZXYvbnVsbCAy
Pi9kZXYvbnVsbCB8fCBlcnJvcl9leGl0CgkKICAgZWNobyAiIC0gbWV0YS1kYXRhIGZpbGU6ICR7
bWV0YWZpbGV9IgogICBmdHBwdXQgJHtTRVJWRVJ9IC0tdXNlcm5hbWUgYW5vbnltb3VzIC0tcGFz
c3dvcmQgYW5vbnltb3VzICBkYXRhLyR7U0lURU5BTUV9LyR7bWV0YWZpbGV9ICR7bWV0YWZpbGV9
ID4vZGV2L251bGwgMj4vZGV2L251bGwgfHwgZXJyb3JfZXhpdAoKICBmaQogZG9uZQoKICMgYmFj
a3VwIHRvIFNEIGNhcmQgd2hlbiBpbnNlcnRlZAogaWYgWyAiJFNEQ0FSRCIgLWVxIDEgXTsgdGhl
biAKICBjcCAke2ltYWdlfSAvbW50L21tYy9waGVub2NhbV9iYWNrdXAvJHtpbWFnZX0KICBjcCAk
e21ldGFmaWxlfSAvbW50L21tYy9waGVub2NhbV9iYWNrdXAvJHttZXRhZmlsZX0KIGZpCgogIyBj
bGVhbiB1cCBmaWxlcwogcm0gKi5qcGcKIHJtICoubWV0YQoKZG9uZQoKIyBSZXNldCB0byBWSVMg
YXMgZGVmYXVsdAovdXNyL3NiaW4vc2V0X2lyLnNoIDAKCiMtLS0tLS0tLS0tLS0tLSBSRVNFVCBO
T1JNQUwgSEVBREVSIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIG92ZXJsYXkg
dGV4dApvdmVybGF5X3RleHQ9YGVjaG8gIiR7U0lURU5BTUV9IC0gJHttb2RlbH0gLSAlYSAlYiAl
ZCAlWSAlSDolTTolUyAtIEdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8gLyUyMC9nJ2AKCQoj
IGZvciBub3cgZGlzYWJsZSB0aGUgb3ZlcmxheQp3Z2V0IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEy
Ny4wLjAuMS92Yi5odG0/b3ZlcmxheXRleHQxPSR7b3ZlcmxheV90ZXh0fSA+L2Rldi9udWxsIDI+
L2Rldi9udWxsCgojIGNsZWFuIHVwIGRldHJpdHVzCnJtIHZiKgoKIy0tLS0tLS0gRkVFREJBQ0sg
T04gQUNUSVZJVFkgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCmlmIFsg
ISAtZiAiL3Zhci90bXAvaW1hZ2VfbG9nLnR4dCIgXTsgdGhlbgogdG91Y2ggL3Zhci90bXAvaW1h
Z2VfbG9nLnR4dAogY2htb2QgYStydyAvdmFyL3RtcC9pbWFnZV9sb2cudHh0CmZpCgplY2hvICJs
YXN0IHVwbG9hZHMgYXQ6IiA+PiAvdmFyL3RtcC9pbWFnZV9sb2cudHh0CmVjaG8gJERBVEUgPj4g
L3Zhci90bXAvaW1hZ2VfbG9nLnR4dAp0YWlsIC92YXIvdG1wL2ltYWdlX2xvZy50eHQKCiMtLS0t
LS0tIEZJTEUgUEVSTUlTU0lPTlMgQU5EIENMRUFOVVAgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLQpybSAtZiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKCgAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAGZpbGVzL3BoZW5vY2FtX3ZhbGlkYXRlLnNoAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAwMDAwNzc1ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAwMzE2MgAxNDY3NDUwNDQwMwAwMTY0MTMA
IDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXN0YXIgIABraHVm
a2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAIyEvYmluL3NoCgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KIyAoYykgS29lbiBIdWZrZW5z
IGZvciBCbHVlR3JlZW4gTGFicyAoQlYpCiMKIyBVbmF1dGhvcml6ZWQgY2hhbmdlcyB0byB0aGlz
IHNjcmlwdCBhcmUgY29uc2lkZXJlZCBhIGNvcHlyaWdodAojIHZpb2xhdGlvbiBhbmQgd2lsbCBi
ZSBwcm9zZWN1dGVkLgojCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBoYXJkIGNvZGUgcGF0aCB3aGljaCBhcmUg
bG9zdCBpbiBzb21lIGluc3RhbmNlcwojIHdoZW4gY2FsbGluZyB0aGUgc2NyaXB0IHRocm91Z2gg
c3NoIApQQVRIPSIvdXNyL2xvY2FsL2JpbjovdXNyL2xvY2FsL3NiaW46L3Vzci9iaW46L3Vzci9z
YmluOi9iaW46L3NiaW4iCgojIC0tLS0tLS0tLS0tLS0tIFNFVFRJTkdTIC0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgTW92ZSBpbnRvIHRlbXBvcmFyeSBkaXJl
Y3RvcnkKIyB3aGljaCByZXNpZGVzIGluIFJBTSwgbm90IHRvCiMgd2VhciBvdXQgb3RoZXIgcGVy
bWFuZW50IG1lbW9yeQpjZCAvdmFyL3RtcAoKIyBob3cgbWFueSBzZXJ2ZXJzIGRvIHdlIHVwbG9h
ZCB0bwpucnNlcnZlcnM9YGF3ayAnRU5EIHtwcmludCBOUn0nIC9tbnQvY2ZnMS9zZXJ2ZXIudHh0
YApucnNlcnZlcnM9YGF3ayAtdiB2YXI9JHtucnNlcnZlcnN9ICdCRUdJTnsgbj0xOyB3aGlsZSAo
biA8PSB2YXIgKSB7IHByaW50IG47IG4rKzsgfSB9JyB8IHRyICdcbicgJyAnYAoKIyAtLS0tLS0t
LS0tLS0tLSBWQUxJREFURSBMT0dJTiAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLQoKaWYgWyAhIC1mICIvbW50L2NmZzEvcGhlbm9jYW1fa2V5IiBdOyB0aGVuCiBlY2hvICJu
byBzRlRQIGtleSBmb3VuZCwgbm90aGluZyB0byBiZSBkb25lLi4uIgogZXhpdCAwCmZpCgojIHJ1
biB0aGUgdXBsb2FkIHNjcmlwdCBmb3IgdGhlIGlwIGRhdGEKIyBhbmQgZm9yIGFsbCBzZXJ2ZXJz
CmZvciBpIGluICRucnNlcnZlcnM7CmRvCiAgU0VSVkVSPWBhd2sgLXYgcD0kaSAnTlI9PXAnIC9t
bnQvY2ZnMS9zZXJ2ZXIudHh0YAogCiAgZWNobyAiIiAKICBlY2hvICJDaGVja2luZyBzZXJ2ZXI6
ICR7U0VSVkVSfSIKICBlY2hvICIiCgogIGVjaG8gImV4aXQiID4gYmF0Y2hmaWxlCiAgc2Z0cCAt
YiBiYXRjaGZpbGUgLWkgIi9tbnQvY2ZnMS9waGVub2NhbV9rZXkiIHBoZW5vc2Z0cEAke1NFUlZF
Un0gPi9kZXYvbnVsbCAyPi9kZXYvbnVsbAoKICAjIGlmIHN0YXR1cyBvdXRwdXQgbGFzdCBjb21t
YW5kIHdhcwogICMgMCBzZXQgc2VydmljZSB0byBzRlRQCiAgaWYgWyAkPyAtZXEgMCBdOyB0aGVu
CiAgICBlY2hvICJTVUNDRVMuLi4gc2VjdXJlIHNGVFAgbG9naW4gd29ya2VkIgogICAgZWNobyAi
IgogIGVsc2UKICAgIGVjaG8gIkZBSUxFRC4uLiBzZWN1cmUgc0ZUUCBsb2dpbiBkaWQgbm90IHdv
cmsiCiAgICBlY2hvICJbZGF0YSB1cGxvYWRzIHdpbGwgZmFsbCBiYWNrIHRvIGluc2VjdXJlIEZU
UCBtb2RlXSIKICAgIGVjaG8gIiIKICBmaQogIAogICMgY2xlYW51cAogIHJtIGJhdGNoZmlsZQpk
b25lCgpleGl0IDAKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAABmaWxlcy9yZWJvb3RfY2FtZXJhLnNoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAw
MDY2NAAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMDIwNDEAMTQ2NTc3MDc1MDEAMDE1NTQ3ACAwAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHVzdGFyICAAa2h1ZmtlbnMA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAACMhL2Jpbi9zaAoKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCiMgKGMpIEtvZW4gSHVma2VucyBmb3Ig
Qmx1ZUdyZWVuIExhYnMgKEJWKQojCiMgVW5hdXRob3JpemVkIGNoYW5nZXMgdG8gdGhpcyBzY3Jp
cHQgYXJlIGNvbnNpZGVyZWQgYSBjb3B5cmlnaHQKIyB2aW9sYXRpb24gYW5kIHdpbGwgYmUgcHJv
c2VjdXRlZC4KIwojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgaGFyZCBjb2RlIHBhdGggd2hpY2ggYXJlIGxvc3Qg
aW4gc29tZSBpbnN0YW5jZXMKIyB3aGVuIGNhbGxpbmcgdGhlIHNjcmlwdCB0aHJvdWdoIHNzaCAK
UEFUSD0iL3Vzci9sb2NhbC9iaW46L3Vzci9sb2NhbC9zYmluOi91c3IvYmluOi91c3Ivc2Jpbjov
YmluOi9zYmluIgoKIyBncmFiIHBhc3N3b3JkCnBhc3M9YGF3ayAnTlI9PTEnIC9tbnQvY2ZnMS8u
cGFzc3dvcmRgCgojIG1vdmUgaW50byB0ZW1wb3JhcnkgZGlyZWN0b3J5CmNkIC92YXIvdG1wCgoj
IHNsZWVwIDMwIHNlY29uZHMgZm9yIGxhc3QKIyBjb21tYW5kIHRvIGZpbmlzaCAoaWYgYW55IHNo
b3VsZCBiZSBydW5uaW5nKQpzbGVlcCAzMAoKIyB0aGVuIHJlYm9vdAp3Z2V0IGh0dHA6Ly9hZG1p
bjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/aXBjYW1yZXN0YXJ0Y21kICY+L2Rldi9udWxsCgoj
IGRvbid0IGV4aXQgY2xlYW5seSB3aGVuIHRoZSByZWJvb3QgY29tbWFuZCBkb2Vzbid0IHN0aWNr
CiMgc2hvdWxkIHRyaWdnZXIgYSB3YXJuaW5nIG1lc3NhZ2UKc2xlZXAgNjAKCmVjaG8gIiAtLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSIK
ZWNobyAiIgplY2hvICIgUkVCT09UIEZBSUxFRCAtIElOU1RBTEwgTUlHSFQgTk9UIEJFIENPTVBM
RVRFISIKZWNobyAiIgplY2hvICI9PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09
PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIKCmV4aXQgMQoAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAGZpbGVzL3NpdGVfaXAuaHRtbAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNjY0
ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAwMDU2MAAxNDUzNjU1MjUwMAAwMTQ3MzAAIDAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXN0YXIgIABraHVma2VucwAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAPCFET0NUWVBFIGh0bWwgUFVCTElDICItLy9XM0MvL0RURCBIVE1MIDQuMCBUcmFuc2l0
aW9uYWwvL0VOIj4KPGh0bWw+CjxoZWFkPgo8bWV0YSBodHRwLWVxdWl2PSJDb250ZW50LVR5cGUi
IGNvbnRlbnQ9InRleHQvaHRtbDsgY2hhcnNldD1pc28tODg1OS0xIj4KPHRpdGxlPk5ldENhbVND
IElQIEFkZHJlc3M8L3RpdGxlPgo8L2hlYWQ+Cjxib2R5PgpUaW1lIG9mIExhc3QgSVAgVXBsb2Fk
OiBEQVRFVElNRTxicj4KSVAgQWRkcmVzczogU0lURUlQCiZidWxsOyA8YSBocmVmPSJodHRwOi8v
U0lURUlQLyI+VmlldzwvYT4KJmJ1bGw7IDxhIGhyZWY9Imh0dHA6Ly9TSVRFSVAvYWRtaW4uY2dp
Ij5Db25maWd1cmU8L2E+CjwvYm9keT4KPC9odG1sPgoAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
