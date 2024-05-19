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

# subroutines
error_handler(){
  echo ""
  echo " NOTE: If no confirmation of a successful upload is provided,"
  echo " check all script parameters!"
  echo ""
  echo "===================================================================="
  exit 1
}

# define usage
usage() { 
 echo "
 Usage: $0
  [-i <camera ip address>]
  [-p <camera password>]
  [-n <camera name>]
  [-o <time offset from UTC/GMT>]
  [-s <start time 0-23>]
  [-e <end time 0-23>]  
  [-m <interval minutes>]
  [-k <sftp private key>]
  " 1>&2; exit 0;
 }

# grab arguments
while getopts ":hi:p:n:o:t:s:e:m:k:d:" option;
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
        k) key=${OPTARG} ;;
        h | *) usage; exit 0 ;;
    esac
done

echo ""
echo "===================================================================="
echo ""
echo " Running the installation script on the NetCam Live2 camera!"
echo ""
echo " (c) BlueGreen Labs (BV) 2024"
echo " -----------------------------------------------------------"
echo ""

# Default to GMT time zone
tz="GMT"

if [ -f "${key}" ]; then
 # print the content of the path to the
 # key and assign to a variable
 private_key=`cat ${key}`
 echo " Private key provided, using secure SFTP!"
 echo ""
 has_key="TRUE"
else
 echo " No private key provided, defaulting to insecure FTP!"
 echo ""
 has_key="FALSE"
fi

# message on confirming the password
echo " Uploading installation files, please approve this transaction by"
echo " by confirming the password!"
echo ""

command="
 echo TRUE > /mnt/cfg1/update.txt &&
 echo ${name} > /mnt/cfg1/settings.txt &&
 echo ${offset} >> /mnt/cfg1/settings.txt &&
 echo ${tz} >> /mnt/cfg1/settings.txt &&
 echo ${start} >> /mnt/cfg1/settings.txt &&
 echo ${end} >> /mnt/cfg1/settings.txt &&
 echo ${int} >> /mnt/cfg1/settings.txt &&
 echo '225' >> /mnt/cfg1/settings.txt &&
 echo '125' >> /mnt/cfg1/settings.txt &&
 echo '205' >> /mnt/cfg1/settings.txt &&
 echo ${pass} > /mnt/cfg1/.password &&
 rm -rf /mnt/cfg1/.key &&
 if [ ${has_key} = "TRUE" ]; then echo '${private_key}' > /mnt/cfg1/.key; fi && 
 cd /var/tmp; cat | base64 -d | tar -x &&
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi && 
 cp /var/tmp/files/* /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
 echo '#!/bin/sh' > /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh' >> /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_upload.sh' >> /mnt/cfg1/userboot.sh &&
 echo '' &&
 echo ' Successfully uploaded install instructions!' &&
 echo '' &&
 echo 'Using the following settings:' &&
 echo 'Sitename: ${name}' &&
 echo 'GMT timezone offset: ${offset}' &&
 echo 'Upload start: ${start}' &&
 echo 'Upload end: ${end}' &&
 echo 'Upload interval: ${int}' &&
 echo 'FTP mode:' &&
 echo '' &&
 echo ' --> Reboot the camera by cycling the power or wait 10 seconds! <-- ' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 sh /mnt/cfg1/scripts/reboot_camera.sh
"

# install command
BINLINE=$(awk '/^__BINARY__/ { print NR + 1; exit 0; }' $0)
tail -n +${BINLINE} $0 | ssh admin@${ip} ${command} || error_handler 2>/dev/null

# remove last lines from history
# containing the password
history -d -1--2

# exit
exit 0

__BINARY__
ZmlsZXMvY2hscwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NzUAMDAwMTc1
MAAwMDAxNzUwADAwMDAwMDAwNzQ0ADE0NTYyMTUwNDU3ADAxMzI3NQAgMAAAAAAAAAAAAAAAAAAA
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
LS0tLS0tLS0tLS0tCgpucnNlcnZlcnM9YGF3ayAnRU5EIHtwcmludCBOUn0nIC9tbnQvY2ZnMS9z
ZXJ2ZXIudHh0YAphbGw9Im5hdSIKbWF0Y2g9YGdyZXAgLUUgJHthbGx9IC9tbnQvY2ZnMS9zZXJ2
ZXIudHh0IHwgd2MgLWxgCgppZiBbICR7bnJzZXJ2ZXJzfSAtZXEgJHttYXRjaH0gXTsKdGhlbgog
ZWNobyAibmV0d29yaz1waGVub2NhbSIKZmkKAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZp
bGVzL3BoZW5vY2FtX2luc3RhbGwuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzU1ADAwMDE3NTAA
MDAwMTc1MAAwMDAwMDAxMDc2MQAxNDYwNTUzMDEzNwAwMTYyNjYAIDAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAdXN0YXIgIABraHVma2VucwAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyEv
YmluL3NoCgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0KIyAoYykgS29lbiBIdWZrZW5zIGZvciBCbHVlR3JlZW4gTGFi
cyAoQlYpCiMKIyBVbmF1dGhvcml6ZWQgY2hhbmdlcyB0byB0aGlzIHNjcmlwdCBhcmUgY29uc2lk
ZXJlZCBhIGNvcHlyaWdodAojIHZpb2xhdGlvbiBhbmQgd2lsbCBiZSBwcm9zZWN1dGVkLiBJZiB5
b3UgY2FtZSB0aGlzIGZhciB0aGluawojIHR3aWNlIGFib3V0IHdoYXQgeW91IGFyZSBhYm91dCB0
byBkby4gQXMgdGhpcyBtZWFucyB0aGF0IHlvdQojIHJldmVyc2UgZW5naW5lZXJlZCBwcm90ZWN0
aW9uIHRocm91Z2ggb2JmdXNjYXRpb24KIyB3aGljaCB3b3VsZCBjb25zdGl0dXRlIGEgZmlyc3Qg
Y29weXJpZ2h0IG9mZmVuc2UuCiMKIy0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgpzbGVlcCAzMApjZCAvdmFyL3RtcAoK
IyB1cGRhdGUgcGVybWlzc2lvbnMgc2NyaXB0cwpjaG1vZCBhK3J3eCAvbW50L2NmZzEvc2NyaXB0
cy8qCgojIGdldCB0b2RheXMgZGF0ZQp0b2RheT1gZGF0ZSArIiVZICVtICVkICVIOiVNOiVTImAK
CiMgc2V0IGNhbWVyYSBtb2RlbCBuYW1lCm1vZGVsPSJOZXRDYW0gTGl2ZTIiCgojIHVwbG9hZCAv
IGRvd25sb2FkIHNlcnZlciAtIGxvY2F0aW9uIGZyb20gd2hpY2ggdG8gZ3JhYiBhbmQKIyBhbmQg
d2hlcmUgdG8gcHV0IGNvbmZpZyBmaWxlcwpob3N0PSdwaGVub2NhbS5uYXUuZWR1JwoKIyBjcmVh
dGUgZGVmYXVsdCBzZXJ2ZXIKaWYgWyAhIC1mICcvbW50L2NmZzEvc2VydmVyLnR4dCcgXTsgdGhl
bgogIGVjaG8gJHtob3N0fSA+IC9tbnQvY2ZnMS9zZXJ2ZXIudHh0CiAgZWNobyAidXNpbmcgZGVm
YXVsdCBob3N0OiAke2hvc3R9IiA+PiAvdmFyL3RtcC9sb2cudHh0CiAgY2htb2QgYStydyAvbW50
L2NmZzEvc2VydmVyLnR4dApmaQoKIyBPbmx5IHVwZGF0ZSB0aGUgc2V0dGluZ3MgaWYgZXhwbGlj
aXRseQojIGluc3RydWN0ZWQgdG8gZG8gc28sIHRoaXMgZmlsZSB3aWxsIGJlCiMgc2V0IHRvIFRS
VUUgYnkgdGhlIFBJVC5zaCBzY3JpcHQsIHdoaWNoCiMgdXBvbiByZWJvb3Qgd2lsbCB0aGVuIGJl
IHJ1bi4KCmlmIFsgYGNhdCAvbW50L2NmZzEvdXBkYXRlLnR4dGAgPSAiVFJVRSIgXTsgdGhlbiAK
CgkjIHN0YXJ0IGxvZ2dpbmcKCWVjaG8gIi0tLS0tICR7dG9kYXl9IC0tLS0tIiA+IC92YXIvdG1w
L2xvZy50eHQKCgkjLS0tLS0gcmVhZCBpbiBzZXR0aW5ncwoJaWYgWyAtZiAnL21udC9jZmcxL3Nl
dHRpbmdzLnR4dCcgXTsgdGhlbgoJIGNhbWVyYT1gYXdrICdOUj09MScgL21udC9jZmcxL3NldHRp
bmdzLnR4dGAKCSB0aW1lX29mZnNldD1gYXdrICdOUj09MicgL21udC9jZmcxL3NldHRpbmdzLnR4
dGAKCSBjcm9uX3N0YXJ0PWBhd2sgJ05SPT00JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIGNy
b25fZW5kPWBhd2sgJ05SPT01JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoJIGNyb25faW50PWBh
d2sgJ05SPT02JyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAogCSByZWQ9YGF3ayAnTlI9PTcnIC9t
bnQvY2ZnMS9zZXR0aW5ncy50eHRgCgkgZ3JlZW49YGF3ayAnTlI9PTgnIC9tbnQvY2ZnMS9zZXR0
aW5ncy50eHRgCgkgYmx1ZT1gYXdrICdOUj09OScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAgCgll
bHNlCgkgZWNobyAiU2V0dGluZ3MgZmlsZSBtaXNzaW5nLCBhYm9ydGluZyBpbnN0YWxsIHJvdXRp
bmUhIiA+PiAvdmFyL3RtcC9sb2cudHh0CglmaQoJCiAgICAgICAgcGFzcz1gYXdrICdOUj09MScg
L21udC9jZmcxLy5wYXNzd29yZGAKCgkjLS0tLS0gc2V0IHRpbWUgem9uZSBvZmZzZXQgKGZyb20g
R01UKQoJCgkjIHNldCBzaWduIHRpbWUgem9uZQoJU0lHTj1gZWNobyAke3RpbWVfb2Zmc2V0fSB8
IGN1dCAtYycxJ2AKCgkjIG5vdGUgdGhlIHdlaXJkIGZsaXAgaW4gdGhlIG5ldGNhbSBjYW1lcmFz
CglpZiBbICIkU0lHTiIgPSAiKyIgXTsgdGhlbgoJIFRaPWBlY2hvICJHTVQke3RpbWVfb2Zmc2V0
fSIgfCBzZWQgJ3MvKy8lMkQvZydgCgllbHNlCgkgVFo9YGVjaG8gIkdNVCR7dGltZV9vZmZzZXR9
IiB8IHNlZCAncy8tLyUyQi9nJ2AKCWZpCgoJIyBjYWxsIEFQSSB0byBzZXQgdGhlIHRpbWUgCgl3
Z2V0IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/dGltZXpvbmU9JHtUWn0K
CQoJIyBjbGVhbiB1cCBkZXRyaXR1cwoJcm0gdmIqCgkKCWVjaG8gInRpbWUgc2V0IHRvIChhc2Np
aSBmb3JtYXQpOiAke1RafSIgPj4gL3Zhci90bXAvbG9nLnR4dAoJCgkjLS0tLS0gc2V0IG92ZXJs
YXkKCQoJIyBjb252ZXJ0IHRvIGFzY2lpCglpZiBbICIkU0lHTiIgPSAiKyIgXTsgdGhlbgoJIHRp
bWVfb2Zmc2V0PWBlY2hvICIke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvKy8lMkIvZydgCgllbHNl
CgkgdGltZV9vZmZzZXQ9YGVjaG8gIiR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8tLyUyRC9nJ2AK
CWZpCgkKCSMgb3ZlcmxheSB0ZXh0CglvdmVybGF5X3RleHQ9YGVjaG8gIiR7Y2FtZXJhfSAtICR7
bW9kZWx9IC0gJWEgJWIgJWQgJVkgJUg6JU06JVMgLSBHTVQke3RpbWVfb2Zmc2V0fSIgfCBzZWQg
J3MvIC8lMjAvZydgCgkKCSMgZm9yIG5vdyBkaXNhYmxlIHRoZSBvdmVybGF5Cgl3Z2V0IGh0dHA6
Ly9hZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5odG0/b3ZlcmxheXRleHQxPSR7b3ZlcmxheV90
ZXh0fQoJCgkjIGNsZWFuIHVwIGRldHJpdHVzCglybSB2YioKCQoJZWNobyAiaGVhZGVyIHNldCB0
bzogJHtvdmVybGF5X3RleHR9IiA+PiAvdmFyL3RtcC9sb2cudHh0CgkKCSMtLS0tLSBzZXQgY29s
b3VyIHNldHRpbmdzCgkvdXNyL3NiaW4vc2V0X3JnYi5zaCAwICR7cmVkfSAke2dyZWVufSAke2Js
dWV9CgoJIy0tLS0tIGdlbmVyYXRlIHJhbmRvbSBudW1iZXIgYmV0d2VlbiAwIGFuZCB0aGUgaW50
ZXJ2YWwgdmFsdWUKCXJudW1iZXI9YGF3ayAtdiBtaW49MCAtdiBtYXg9JHtjcm9uX2ludH0gJ0JF
R0lOe3NyYW5kKCk7IHByaW50IGludChtaW4rcmFuZCgpKihtYXgtbWluKzEpKX0nYAoJCgkjIGRp
dmlkZSA2MCBtaW4gYnkgdGhlIGludGVydmFsCglkaXY9YGF3ayAtdiBpbnRlcnZhbD0ke2Nyb25f
aW50fSAnQkVHSU4ge3ByaW50IDU5L2ludGVydmFsfSdgCglpbnQ9YGVjaG8gJGRpdiB8IGN1dCAt
ZCcuJyAtZjFgCgkKCSMgZ2VuZXJhdGUgbGlzdCBvZiB2YWx1ZXMgdG8gaXRlcmF0ZSBvdmVyCgl2
YWx1ZXM9YGF3ayAtdiBtYXg9JHtpbnR9ICdCRUdJTnsgZm9yKGk9MDtpPD1tYXg7aSsrKSBwcmlu
dCBpfSdgCgkKCWZvciBpIGluICR7dmFsdWVzfTsgZG8KCSBwcm9kdWN0PWBhd2sgLXYgaW50ZXJ2
YWw9JHtjcm9uX2ludH0gLXYgc3RlcD0ke2l9ICdCRUdJTiB7cHJpbnQgaW50KGludGVydmFsKnN0
ZXApfSdgCQoJIHN1bT1gYXdrIC12IHByb2R1Y3Q9JHtwcm9kdWN0fSAtdiBucj0ke3JudW1iZXJ9
ICdCRUdJTiB7cHJpbnQgaW50KHByb2R1Y3QrbnIpfSdgCgkgCgkgaWYgWyAiJHtpfSIgLWVxICIw
IiBdO3RoZW4KCSAgaW50ZXJ2YWw9YGVjaG8gJHtzdW19YAoJIGVsc2UKCSAgaWYgWyAiJHN1bSIg
LWxlICI1OSIgXTt0aGVuCgkgICBpbnRlcnZhbD1gZWNobyAke2ludGVydmFsfSwke3N1bX1gCgkg
IGZpCgkgZmkKCWRvbmUKCgllY2hvICJjcm9udGFiIGludGVydmFscyBzZXQgdG86ICR7aW50ZXJ2
YWx9IiA+PiAvdmFyL3RtcC9sb2cudHh0CgoJIy0tLS0tIHNldCByb290IGNyb24gam9icwoJCgkj
IHNldCB0aGUgbWFpbiBwaWN0dXJlIHRha2luZyByb3V0aW5lCgllY2hvICIke2ludGVydmFsfSAk
e2Nyb25fc3RhcnR9LSR7Y3Jvbl9lbmR9ICogKiAqIHNoIC9tbnQvY2ZnMS9zY3JpcHRzL3BoZW5v
Y2FtX3VwbG9hZC5zaCIgPiAvbW50L2NmZzEvc2NoZWR1bGUvYWRtaW4KCQkKCSMgdXBsb2FkIGlw
IGFkZHJlc3MgaW5mbwoJZWNobyAiNTkgMTEgKiAqICogc2ggL21udC9jZmcxL3NjcmlwdHMvcGhl
bm9jYW1faXBfdGFibGUuc2giID4+IC9tbnQvY2ZnMS9zY2hlZHVsZS9hZG1pbgoJCQoJIyByZWJv
b3QgYXQgbWlkbmlnaHQKCWVjaG8gIjU5IDIzICogKiAqIHNoIC9tbnQvY2ZnMS9zY3JpcHRzL3Jl
Ym9vdF9jYW1lcmEuc2giID4+IC9tbnQvY2ZnMS9zY2hlZHVsZS9hZG1pbgoJCgkjIGluZm8KCWVj
aG8gIkZpbmlzaGVkIGluaXRpYWwgc2V0dXAiID4+IC92YXIvdG1wL2xvZy50eHQKCgkjLS0tLS0g
ZmluYWxpemUgdGhlIHNldHVwICsgcmVib290CgoJIyB1cGRhdGUgdGhlIHN0YXRlIG9mIHRoZSB1
cGRhdGUgcmVxdWlyZW1lbnQKCSMgaS5lLiBza2lwIGlmIGNhbGxlZCBtb3JlIHRoYW4gb25jZSwg
dW5sZXNzCgkjIHRoaXMgZmlsZSBpcyBtYW51YWxseSBzZXQgdG8gVFJVRSB3aGljaAoJIyB3b3Vs
ZCByZXJ1biB0aGUgaW5zdGFsbCByb3V0aW5lIHVwb24gcmVib290CgllY2hvICJGQUxTRSIgPiAv
bW50L2NmZzEvdXBkYXRlLnR4dAoKCSMgcmVib290aW5nIGNhbWVyYSB0byBtYWtlIHN1cmUgYWxs
CgkjIHRoZSBzZXR0aW5ncyBzdGljawoJc2ggL21udC9jZmcxL3NjcmlwdHMvcmVib290X2NhbWVy
YS5zaApmaQoKIyBjbGVhbiBleGl0CmV4aXQgMAoKAAAAAAAAAAAAAAAAAAAAZmlsZXMvcGhlbm9j
YW1faXBfdGFibGUuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwMDA3NTUAMDAwMTc1MAAwMDAxNzUwADAw
MDAwMDAyMzU0ADE0NTYxNzY3NjI0ADAxNjQxNAAgMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAB1c3RhciAgAGtodWZrZW5zAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
a2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAjIS9iaW4vc2gKCiMt
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLQojIChjKSBLb2VuIEh1ZmtlbnMgZm9yIEJsdWVHcmVlbiBMYWJzIChCVikKIwoj
IFVuYXV0aG9yaXplZCBjaGFuZ2VzIHRvIHRoaXMgc2NyaXB0IGFyZSBjb25zaWRlcmVkIGEgY29w
eXJpZ2h0CiMgdmlvbGF0aW9uIGFuZCB3aWxsIGJlIHByb3NlY3V0ZWQuCiMKIy0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
CgojIHNvbWUgZmVlZGJhY2sgb24gdGhlIGFjdGlvbgplY2hvICJ1cGxvYWRpbmcgSVAgdGFibGUi
CgojIGhvdyBtYW55IHNlcnZlcnMgZG8gd2UgdXBsb2FkIHRvCm5yc2VydmVycz1gYXdrICdFTkQg
e3ByaW50IE5SfScgL21udC9jZmcxL3NlcnZlci50eHRgCm5yc2VydmVycz1gYXdrIC12IHZhcj0k
e25yc2VydmVyc30gJ0JFR0lOeyBuPTE7IHdoaWxlIChuIDw9IHZhciApIHsgcHJpbnQgbjsgbisr
OyB9IH0nIHwgdHIgJ1xuJyAnICdgCgojIGdyYWIgdGhlIG5hbWUsIGRhdGUgYW5kIElQIG9mIHRo
ZSBjYW1lcmEKREFURVRJTUU9YGRhdGVgCgojIGdyYWIgaW50ZXJuYWwgaXAgYWRkcmVzcwpJUD1g
aWZjb25maWcgZXRoMCB8IGF3ayAnL2luZXQgYWRkci97cHJpbnQgc3Vic3RyKCQyLDYpfSdgClNJ
VEVOQU1FPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoKIyB1cGRhdGUgdGhl
IElQIGFuZCB0aW1lIHZhcmlhYmxlcwpjYXQgL21udC9jZmcxL3NjcmlwdHMvc2l0ZV9pcC5odG1s
IHwgc2VkICJzfERBVEVUSU1FfCREQVRFVElNRXxnIiB8IHNlZCAic3xTSVRFSVB8JElQfGciID4g
L3Zhci90bXAvJHtTSVRFTkFNRX1cX2lwLmh0bWwKCiMgcnVuIHRoZSB1cGxvYWQgc2NyaXB0IGZv
ciB0aGUgaXAgZGF0YQojIGFuZCBmb3IgYWxsIHNlcnZlcnMKZm9yIGkgaW4gJG5yc2VydmVycyA7
CmRvCiBTRVJWRVI9YGF3ayAtdiBwPSRpICdOUj09cCcgL21udC9jZmcxL3NlcnZlci50eHRgIAoJ
CiAjIHVwbG9hZCBpbWFnZQogZWNobyAidXBsb2FkaW5nIE5JUiBpbWFnZSAke2ltYWdlfSIKIGZ0
cHB1dCAke1NFUlZFUn0gLXUgImFub255bW91cyIgLXAgImFub255bW91cyIgZGF0YS8ke1NJVEVO
QU1FfS8ke1NJVEVOQU1FfVxfaXAuaHRtbCAvdmFyL3RtcC8ke1NJVEVOQU1FfVxfaXAuaHRtbAoK
ZG9uZQoKIyBjbGVhbiB1cApybSAvdmFyL3RtcC8ke1NJVEVOQU1FfVxfaXAuaHRtbAoAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxlcy9waGVub2NhbV91
cGxvYWQuc2gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDc3NQAwMDAxNzUwADAwMDE3NTAAMDAwMDAw
MTMzMjcAMTQ2MjIzMjY1MTEAMDE2MTA1ACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAHVzdGFyICAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABraHVm
a2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMhL2Jpbi9zaAoKIy0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tCiMgKGMpIEtvZW4gSHVma2VucyBmb3IgQmx1ZUdyZWVuIExhYnMgKEJWKQojCiMgVW5h
dXRob3JpemVkIGNoYW5nZXMgdG8gdGhpcyBzY3JpcHQgYXJlIGNvbnNpZGVyZWQgYSBjb3B5cmln
aHQKIyB2aW9sYXRpb24gYW5kIHdpbGwgYmUgcHJvc2VjdXRlZC4KIwojLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCmNh
cHR1cmUgKCkgewoKIGltYWdlPSQxCiBtZXRhZmlsZT0kMgogZGVsYXk9JDMKIGlyPSQ0CgogIyBT
ZXQgdGhlIGltYWdlIHRvIG5vbiBJUiBpLmUuIFZJUwogL3Vzci9zYmluL3NldF9pci5zaCAkaXIK
CiAjIGFkanVzdCBleHBvc3VyZQogc2xlZXAgJGRlbGF5CgogIyBncmFiIHRoZSBpbWFnZSBmcm9t
IHRoZQogd2dldCBodHRwOi8vMTI3LjAuMC4xL2ltYWdlLmpwZyAtTyAke2ltYWdlfQoKICMgZ3Jh
YiBkYXRlIGFuZCB0aW1lIGZvciBgLm1ldGFgIGZpbGVzCiBNRVRBREFURVRJTUU9YGRhdGUgLUlz
ZWNvbmRzYAoKICMgZ3JhYiB0aGUgZXhwb3N1cmUgdGltZSBhbmQgYXBwZW5kIHRvIG1ldGEtZGF0
YQogZXhwb3N1cmU9YC91c3Ivc2Jpbi9nZXRfZXhwIHwgY3V0IC1kICcgJyAtZjRgCgogY2F0IG1l
dGFkYXRhLnR4dCA+PiAvdmFyL3RtcC8ke21ldGFmaWxlfQogZWNobyAiZXhwb3N1cmU9JHtleHBv
c3VyZX0iID4+IC92YXIvdG1wLyR7bWV0YWZpbGV9CiBlY2hvICJpcl9lbmFibGU9JGlyIiA+PiAv
dmFyL3RtcC8ke21ldGFmaWxlfQogZWNobyAiZGF0ZXRpbWVfb3JpZ2luYWw9XCIkTUVUQURBVEVU
SU1FXCIiID4+IC92YXIvdG1wLyR7bWV0YWZpbGV9Cgp9CgojIC0tLS0tLS0tLS0tLS0tIFNFVFRJ
TkdTIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KCiMgcmVhZCBp
biBjb25maWd1cmF0aW9uIHNldHRpbmdzCiMgZ3JhYiBzaXRlbmFtZQpTSVRFTkFNRT1gYXdrICdO
Uj09MScgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKCiMgZ3JhYiB0aW1lIG9mZnNldCAvIGxvY2Fs
IHRpbWUgem9uZQojIGFuZCBjb252ZXJ0ICsvLSB0byBhc2NpaQp0aW1lX29mZnNldD1gYXdrICdO
Uj09MicgL21udC9jZmcxL3NldHRpbmdzLnR4dGAKU0lHTj1gZWNobyAke3RpbWVfb2Zmc2V0fSB8
IGN1dCAtYycxJ2AKCmlmIFsgIiRTSUdOIiA9ICIrIiBdOyB0aGVuCiB0aW1lX29mZnNldD1gZWNo
byAiJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLysvJTJCL2cnYAplbHNlCiB0aW1lX29mZnNldD1g
ZWNobyAiJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLy0vJTJEL2cnYApmaQoKIyBzZXQgY2FtZXJh
IG1vZGVsIG5hbWUKbW9kZWw9Ik5ldENhbSBMaXZlMiIKCiMgaG93IG1hbnkgc2VydmVycyBkbyB3
ZSB1cGxvYWQgdG8KbnJzZXJ2ZXJzPWBhd2sgJ0VORCB7cHJpbnQgTlJ9JyAvbW50L2NmZzEvc2Vy
dmVyLnR4dGAKbnJzZXJ2ZXJzPWBhd2sgLXYgdmFyPSR7bnJzZXJ2ZXJzfSAnQkVHSU57IG49MTsg
d2hpbGUgKG4gPD0gdmFyICkgeyBwcmludCBuOyBuKys7IH0gfScgfCB0ciAnXG4nICcgJ2AKCiMg
Z3JhYiBwYXNzd29yZApwYXNzPWBhd2sgJ05SPT0xJyAvbW50L2NmZzEvLnBhc3N3b3JkYAoKIyBN
b3ZlIGludG8gdGVtcG9yYXJ5IGRpcmVjdG9yeQojIHdoaWNoIHJlc2lkZXMgaW4gUkFNLCBub3Qg
dG8KIyB3ZWFyIG91dCBvdGhlciBwZXJtYW5lbnQgbWVtb3J5CmNkIC92YXIvdG1wCgojIHNldHMg
dGhlIGRlbGF5IGJldHdlZW4gdGhlCiMgUkdCIGFuZCBJUiBpbWFnZSBhY3F1aXNpdGlvbnMKREVM
QVk9MzAKCiMgZ3JhYiBkYXRlIC0ga2VlcCBmaXhlZCBmb3IgUkdCIGFuZCBJUiB1cGxvYWRzCkRB
VEU9YGRhdGUgKyIlYSAlYiAlZCAlWSAlSDolTTolUyJgCgojIGdyYXAgZGF0ZSBhbmQgdGltZSBz
dHJpbmcgdG8gYmUgaW5zZXJ0ZWQgaW50byB0aGUKIyBmdHAgc2NyaXB0cyAtIHRoaXMgY29vcmRp
bmF0ZXMgdGhlIHRpbWUgc3RhbXBzCiMgYmV0d2VlbiB0aGUgUkdCIGFuZCBJUiBpbWFnZXMgKG90
aGVyd2lzZSB0aGVyZSBpcyBhCiMgc2xpZ2h0IG9mZnNldCBkdWUgdG8gdGhlIHRpbWUgbmVlZGVk
IHRvIGFkanVzdCBleHBvc3VyZQpEQVRFVElNRVNUUklORz1gZGF0ZSArIiVZXyVtXyVkXyVIJU0l
UyJgCgojIGdyYWIgbWV0YWRhdGEgdXNpbmcgdGhlIG1ldGFkYXRhIGZ1bmN0aW9uCiMgZ3JhYiB0
aGUgTUFDIGFkZHJlc3MKbWFjX2FkZHI9YGlmY29uZmlnIGV0aDAgfCBncmVwIEhXYWRkciB8IGF3
ayAne3ByaW50ICQ1fScgfCBzZWQgJ3MvOi8vZydgCgojIGdyYWIgaW50ZXJuYWwgaXAgYWRkcmVz
cwppcF9hZGRyPWBpZmNvbmZpZyBldGgwIHwgYXdrICcvaW5ldCBhZGRyL3twcmludCBzdWJzdHIo
JDIsNil9J2AKCiMgZ3JhYiBleHRlcm5hbCBpcCBhZGRyZXNzIGlmIHRoZXJlIGlzIGFuIGV4dGVy
bmFsIGNvbm5lY3Rpb24KIyBmaXJzdCB0ZXN0IHRoZSBjb25uZWN0aW9uIHRvIHRoZSBnb29nbGUg
bmFtZSBzZXJ2ZXIKY29ubmVjdGlvbj1gcGluZyAtcSAtYyAxIDguOC44LjggPiAvZGV2L251bGwg
JiYgZWNobyBvayB8fCBlY2hvIGVycm9yYAoKIyBncmFiIHRpbWUgem9uZQp0ej1gY2F0IC92YXIv
VFpgCgojIGdldCBTRCBjYXJkIHByZXNlbmNlClNEQ0FSRD1gZGYgfCBncmVwICJtbWMiIHwgd2Mg
LWxgCgojIGJhY2t1cCB0byBTRCBjYXJkIHdoZW4gaW5zZXJ0ZWQKIyBydW5zIG9uIHBoZW5vY2Ft
IHVwbG9hZCByYXRoZXIgdGhhbiBpbnN0YWxsCiMgdG8gYWxsb3cgaG90LXN3YXBwaW5nIG9mIGNh
cmRzCmlmIFsgIiRTRENBUkQiIC1lcSAxIF07IHRoZW4KIAogIyBjcmVhdGUgYmFja3VwIGRpcmVj
dG9yeQogbWtkaXIgLXAgL21udC9tbWMvcGhlbm9jYW1fYmFja3VwLwogCmZpCgojIGNyZWF0ZSBi
YXNlIG1ldGEtZGF0YSBmaWxlIGZyb20gY29uZmlndXJhdGlvbiBzZXR0aW5ncwojIGFuZCB0aGUg
Zml4ZWQgcGFyYW1ldGVycwplY2hvICJtb2RlbD1OZXRDYW0gTGl2ZTIiID4gL3Zhci90bXAvbWV0
YWRhdGEudHh0Ci9tbnQvY2ZnMS9zY3JpcHRzL2NobHMgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0
CmVjaG8gImlwX2FkZHI9JGlwX2FkZHIiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJt
YWNfYWRkcj0kbWFjX2FkZHIiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAplY2hvICJ0aW1lX3pv
bmU9JHR6IiA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKCiMgLS0tLS0tLS0tLS0tLS0gU0VUIEZJ
WEVEIERBVEUgVElNRSBIRUFERVIgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBvdmVybGF5
IHRleHQKb3ZlcmxheV90ZXh0PWBlY2hvICIke1NJVEVOQU1FfSAtICR7bW9kZWx9IC0gJHtEQVRF
fSAtIEdNVCR7dGltZV9vZmZzZXR9IiB8IHNlZCAncy8gLyUyMC9nJ2AKCQojIGZvciBub3cgZGlz
YWJsZSB0aGUgb3ZlcmxheQp3Z2V0IGh0dHA6Ly9hZG1pbjoke3Bhc3N9QDEyNy4wLjAuMS92Yi5o
dG0/b3ZlcmxheXRleHQxPSR7b3ZlcmxheV90ZXh0fQoKIyBjbGVhbiB1cCBkZXRyaXR1cwpybSB2
YioKCiMgLS0tLS0tLS0tLS0tLS0gVVBMT0FEIERBVEEgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLQoKIyB3ZSB1c2UgdHdvIHN0YXRlcyB0byBpbmRpY2F0ZSBWSVMgKDAp
IGFuZCBOSVIgKDEpIHN0YXRlcwojIGFuZCB1c2UgYSBmb3IgbG9vcCB0byBjeWNsZSB0aHJvdWdo
IHRoZXNlIHN0YXRlcyBhbmQKIyB1cGxvYWQgdGhlIGRhdGEKc3RhdGVzPSIwIDEiCgpmb3Igc3Rh
dGUgaW4gJHN0YXRlczsKZG8KCiBpZiBbICIkc3RhdGUiIC1lcSAwIF07IHRoZW4KCiAgIyBjcmVh
dGUgVklTIGZpbGVuYW1lcwogIG1ldGFmaWxlPWBlY2hvICR7U0lURU5BTUV9XyR7REFURVRJTUVT
VFJJTkd9Lm1ldGFgCiAgaW1hZ2U9YGVjaG8gJHtTSVRFTkFNRX1fJHtEQVRFVElNRVNUUklOR30u
anBnYAogIGNhcHR1cmUgJGltYWdlICRtZXRhZmlsZSAkREVMQVkgMAoKIGVsc2UKCiAgIyBjcmVh
dGUgTklSIGZpbGVuYW1lcwogIG1ldGFmaWxlPWBlY2hvICR7U0lURU5BTUV9X0lSXyR7REFURVRJ
TUVTVFJJTkd9Lm1ldGFgCiAgaW1hZ2U9YGVjaG8gJHtTSVRFTkFNRX1fSVJfJHtEQVRFVElNRVNU
UklOR30uanBnYAogIGNhcHR1cmUgJGltYWdlICRtZXRhZmlsZSAkREVMQVkgMQogCiBmaQoKICMg
cnVuIHRoZSB1cGxvYWQgc2NyaXB0IGZvciB0aGUgaXAgZGF0YQogIyBhbmQgZm9yIGFsbCBzZXJ2
ZXJzCiBmb3IgaSBpbiAkbnJzZXJ2ZXJzOwogZG8KICBTRVJWRVI9YGF3ayAtdiBwPSRpICdOUj09
cCcgL21udC9jZmcxL3NlcnZlci50eHRgCiAKICBlY2hvICJ1cGxvYWRpbmcgdG86ICR7U0VSVkVS
fSIKIAogICMgaWYga2V5IGZpbGUgZXhpc3RzIHVzZSBTRlRQCiAgaWYgWyAtZiAiL21udC9jZmcx
Ly5rZXkiIF07IHRoZW4KICAgZWNobyAidXNpbmcgU0ZUUCIKICAKICAgZWNobyAicHV0ICR7aW1h
Z2V9IGRhdGEvJHtTSVRFTkFNRX0vJHtpbWFnZX0iID4gYmF0Y2hmaWxlCiAgIGVjaG8gInB1dCAk
e21ldGFmaWxlfSBkYXRhLyR7U0lURU5BTUV9LyR7bWV0YWZpbGV9IiA+PiBiYXRjaGZpbGUKICAK
ICAgIyB1cGxvYWQgdGhlIGRhdGEKICAgc2Z0cCAtYiBiYXRjaGZpbGUgLWkgIi9tbnQvY2ZnMS8u
a2V5IiAke1NJVEVOQU1FfUAke1NFUlZFUn0KICAgCiAgICMgcmVtb3ZlIGJhdGNoIGZpbGUKICAg
cm0gYmF0Y2hmaWxlCiAgIAogIGVsc2UKICAgZWNobyAiZGVmYXVsdGluZyB0byBGVFAsIGNoZWNr
IHlvdXIga2V5IgogIAogICAjIHVwbG9hZCBpbWFnZQogICBlY2hvICJ1cGxvYWRpbmcgaW1hZ2Ug
JHtpbWFnZX0gKHN0YXRlOiAke3N0YXRlfSkiCiAgIGZ0cHB1dCAke1NFUlZFUn0gLS11c2VybmFt
ZSBhbm9ueW1vdXMgLS1wYXNzd29yZCBhbm9ueW1vdXMgIGRhdGEvJHtTSVRFTkFNRX0vJHtpbWFn
ZX0gJHtpbWFnZX0KCQogICBlY2hvICJ1cGxvYWRpbmcgbWV0YS1kYXRhICR7bWV0YWZpbGV9IChz
dGF0ZTogJHtzdGF0ZX0pIgogICBmdHBwdXQgJHtTRVJWRVJ9IC0tdXNlcm5hbWUgYW5vbnltb3Vz
IC0tcGFzc3dvcmQgYW5vbnltb3VzICBkYXRhLyR7U0lURU5BTUV9LyR7bWV0YWZpbGV9ICR7bWV0
YWZpbGV9CgogIGZpCiBkb25lCgogIyBiYWNrdXAgdG8gU0QgY2FyZCB3aGVuIGluc2VydGVkCiBp
ZiBbICIkU0RDQVJEIiAtZXEgMSBdOyB0aGVuIAogIGNwICR7aW1hZ2V9IC9tbnQvbW1jL3BoZW5v
Y2FtX2JhY2t1cC8ke2ltYWdlfQogIGNwICR7bWV0YWZpbGV9IC9tbnQvbW1jL3BoZW5vY2FtX2Jh
Y2t1cC8ke21ldGFmaWxlfQogZmkKCiAjIGNsZWFuIHVwIGZpbGVzCiBybSAqLmpwZwogcm0gKi5t
ZXRhCgpkb25lCgojIFJlc2V0IHRvIFZJUyBhcyBkZWZhdWx0Ci91c3Ivc2Jpbi9zZXRfaXIuc2gg
MAoKIy0tLS0tLS0tLS0tLS0tIFJFU0VUIE5PUk1BTCBIRUFERVIgLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0KCiMgb3ZlcmxheSB0ZXh0Cm92ZXJsYXlfdGV4dD1gZWNobyAiJHtTSVRF
TkFNRX0gLSAke21vZGVsfSAtICVhICViICVkICVZICVIOiVNOiVTIC0gR01UJHt0aW1lX29mZnNl
dH0iIHwgc2VkICdzLyAvJTIwL2cnYAoJCiMgZm9yIG5vdyBkaXNhYmxlIHRoZSBvdmVybGF5Cndn
ZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9vdmVybGF5dGV4dDE9JHtv
dmVybGF5X3RleHR9CgojIGNsZWFuIHVwIGRldHJpdHVzCnJtIHZiKgoKIy0tLS0tLS0gRkVFREJB
Q0sgT04gQUNUSVZJVFkgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCmVj
aG8gImxhc3QgdXBsb2FkIGF0OiIgPj4gL3Zhci90bXAvbG9nLnR4dAplY2hvICREQVRFID4+IC92
YXIvdG1wL2xvZy50eHQKCgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZpbGVzL3JlYm9vdF9jYW1lcmEuc2gAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAwMDAwNjY0ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAwMDc3NwAxNDYwNTUy
MzAzNAAwMTU1NTMAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
dXN0YXIgIABraHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGtodWZrZW5zAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIyEvYmluL3NoCgojLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KIyAoYykg
S29lbiBIdWZrZW5zIGZvciBCbHVlR3JlZW4gTGFicyAoQlYpCiMKIyBVbmF1dGhvcml6ZWQgY2hh
bmdlcyB0byB0aGlzIHNjcmlwdCBhcmUgY29uc2lkZXJlZCBhIGNvcHlyaWdodAojIHZpb2xhdGlv
biBhbmQgd2lsbCBiZSBwcm9zZWN1dGVkLgojCiMtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBncmFiIHBhc3N3b3Jk
CnBhc3M9YGF3ayAnTlI9PTEnIC9tbnQvY2ZnMS8ucGFzc3dvcmRgCgojIHNsZWVwIDE1IHNlY29u
ZHMKc2xlZXAgMTUKCiMgbW92ZSBpbnRvIHRlbXBvcmFyeSBkaXJlY3RvcnkKY2QgL3Zhci90bXAK
CiMgcmVib290CndnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9pcGNh
bXJlc3RhcnRjbWQgJj4vZGV2L251bGwKCgBmaWxlcy9zaXRlX2lwLmh0bWwAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAMDAwMDY2NAAwMDAxNzUwADAwMDE3NTAAMDAwMDAwMDA1NjAAMTQ1MzY1NTI1
MDAAMDE0NzMwACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHVz
dGFyICAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABraHVma2VucwAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADwhRE9DVFlQRSBodG1sIFBVQkxJQyAiLS8vVzNDLy9E
VEQgSFRNTCA0LjAgVHJhbnNpdGlvbmFsLy9FTiI+CjxodG1sPgo8aGVhZD4KPG1ldGEgaHR0cC1l
cXVpdj0iQ29udGVudC1UeXBlIiBjb250ZW50PSJ0ZXh0L2h0bWw7IGNoYXJzZXQ9aXNvLTg4NTkt
MSI+Cjx0aXRsZT5OZXRDYW1TQyBJUCBBZGRyZXNzPC90aXRsZT4KPC9oZWFkPgo8Ym9keT4KVGlt
ZSBvZiBMYXN0IElQIFVwbG9hZDogREFURVRJTUU8YnI+CklQIEFkZHJlc3M6IFNJVEVJUAomYnVs
bDsgPGEgaHJlZj0iaHR0cDovL1NJVEVJUC8iPlZpZXc8L2E+CiZidWxsOyA8YSBocmVmPSJodHRw
Oi8vU0lURUlQL2FkbWluLmNnaSI+Q29uZmlndXJlPC9hPgo8L2JvZHk+CjwvaHRtbD4KAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAA=
