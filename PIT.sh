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
  [-o <time offset from UTC>] 
  [-t <time zone>] 
  [-s <start time 0-23>]
  [-e <end time 0-23>]  
  [-m <interval minutes>]
  " 1>&2; exit 0;
 }

# grab arguments
while getopts ":hi:p:n:o:t:s:e:m:d:" option;
do
    case "${option}"
        in
        i) ip=${OPTARG} ;;
        p) pass=${OPTARG} ;;
        n) name=${OPTARG} ;;
        o) offset=${OPTARG} ;;
        t) tz=${OPTARG} ;;
        s) start=${OPTARG} ;;
        e) end=${OPTARG} ;;
        m) int=${OPTARG} ;;                
        h | *) usage; exit 0 ;;
    esac
done

echo ""
echo "===================================================================="
echo ""
echo " Running the installation script on the NetCam Live2 camera!"
echo ""
echo " (c) BlueGreen Labs 2024"
echo " -----------------------------------------------------------"
echo ""
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
 cd /var/tmp; cat | base64 -d | tar -x &&
 if [ ! -d '/mnt/cfg1/scripts' ]; then mkdir /mnt/cfg1/scripts; fi && 
 cp /var/tmp/files/* /mnt/cfg1/scripts &&
 rm -rf /var/tmp/files &&
 echo '#!/bin/sh' > /mnt/cfg1/userboot.sh &&
 echo 'sh /mnt/cfg1/scripts/phenocam_install.sh' >> /mnt/cfg1/userboot.sh &&
 echo '' &&
 echo ' Successfully uploaded install instructions!' &&
 echo '' &&
 echo ' --> Reboot the camera by cycling the power or wait 10 seconds! <-- ' &&
 echo '' &&
 echo '====================================================================' &&
 echo '' &&
 sh /mnt/cfg1/scripts/reboot_camera.sh ${pass}
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
MDAwMTc1MAAwMDAwMDAxMTA2MAAxNDU3NzUzMjc3MQAwMTYyNzUAIDAAAAAAAAAAAAAAAAAAAAAA
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
Y2FtX3VwbG9hZC5zaCIgPiAvbW50L2NmZzEvc2NoZWR1bGUvYWRtaW4KCQoJIyB1cG9uIHJlYm9v
dCBzZXQgdGltZSB6b25lCgllY2hvICJAcmVib290IHNsZWVwIDYwICYmIHNoIC9tbnQvY2ZnMS9z
Y3JpcHRzL3NldF90aW1lX3pvbmUuc2giID4gL21udC9jZmcxL3NjaGVkdWxlL3Jvb3QKCQoJIyB0
YWtlIHBpY3R1cmUgb24gcmVib290CgllY2hvICJAcmVib290IHNsZWVwIDEyMCAmJiBzaCAvbW50
L2NmZzEvc2NyaXB0cy9waGVub2NhbV91cGxvYWQuc2giID4+IC9tbnQvY2ZnMS9zY2hlZHVsZS9h
ZG1pbgoJCgkjIHVwbG9hZCBpcCBhZGRyZXNzIGluZm8KCWVjaG8gIjU5IDExICogKiAqIHNoIC9t
bnQvY2ZnMS9zY3JpcHRzL3BoZW5vY2FtX2lwX3RhYmxlLnNoIiA+PiAvbW50L2NmZzEvc2NoZWR1
bGUvYWRtaW4KCQkKCSMgcmVib290IGF0IG1pZG5pZ2h0CgllY2hvICI1OSAyMyAqICogKiByZWJv
b3QiID4+IC9tbnQvY2ZnMS9zY2hlZHVsZS9hZG1pbgoJCgkjIGluZm8KCWVjaG8gIkZpbmlzaGVk
IGluaXRpYWwgc2V0dXAiID4+IC92YXIvdG1wL2xvZy50eHQKCmZpCgojIHVwZGF0ZSB0aGUgc3Rh
dGUgb2YgdGhlIHVwZGF0ZSByZXF1aXJlbWVudAojIGkuZS4gc2tpcCBpZiBjYWxsZWQgbW9yZSB0
aGFuIG9uY2UsIHVubGVzcwojIHRoaXMgZmlsZSBpcyBtYW51YWxseSBzZXQgdG8gVFJVRSB3aGlj
aAojIHdvdWxkIHJlcnVuIHRoZSBpbnN0YWxsIHJvdXRpbmUgdXBvbiByZWJvb3QKZWNobyAiRkFM
U0UiID4gL21udC9jZmcxL3VwZGF0ZS50eHQKCmV4aXQgMAoKAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxlcy9waGVub2Nh
bV9pcF90YWJsZS5zaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMDAwMDc1NQAwMDAxNzUwADAwMDE3NTAAMDAw
MDAwMDIzNTQAMTQ1NjE3Njc2MjQAMDE2NDE0ACAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAHVzdGFyICAAa2h1ZmtlbnMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABr
aHVma2VucwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACMhL2Jpbi9zaAoKIy0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tCiMgKGMpIEtvZW4gSHVma2VucyBmb3IgQmx1ZUdyZWVuIExhYnMgKEJWKQojCiMg
VW5hdXRob3JpemVkIGNoYW5nZXMgdG8gdGhpcyBzY3JpcHQgYXJlIGNvbnNpZGVyZWQgYSBjb3B5
cmlnaHQKIyB2aW9sYXRpb24gYW5kIHdpbGwgYmUgcHJvc2VjdXRlZC4KIwojLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0K
CiMgc29tZSBmZWVkYmFjayBvbiB0aGUgYWN0aW9uCmVjaG8gInVwbG9hZGluZyBJUCB0YWJsZSIK
CiMgaG93IG1hbnkgc2VydmVycyBkbyB3ZSB1cGxvYWQgdG8KbnJzZXJ2ZXJzPWBhd2sgJ0VORCB7
cHJpbnQgTlJ9JyAvbW50L2NmZzEvc2VydmVyLnR4dGAKbnJzZXJ2ZXJzPWBhd2sgLXYgdmFyPSR7
bnJzZXJ2ZXJzfSAnQkVHSU57IG49MTsgd2hpbGUgKG4gPD0gdmFyICkgeyBwcmludCBuOyBuKys7
IH0gfScgfCB0ciAnXG4nICcgJ2AKCiMgZ3JhYiB0aGUgbmFtZSwgZGF0ZSBhbmQgSVAgb2YgdGhl
IGNhbWVyYQpEQVRFVElNRT1gZGF0ZWAKCiMgZ3JhYiBpbnRlcm5hbCBpcCBhZGRyZXNzCklQPWBp
ZmNvbmZpZyBldGgwIHwgYXdrICcvaW5ldCBhZGRyL3twcmludCBzdWJzdHIoJDIsNil9J2AKU0lU
RU5BTUU9YGF3ayAnTlI9PTEnIC9tbnQvY2ZnMS9zZXR0aW5ncy50eHRgCgojIHVwZGF0ZSB0aGUg
SVAgYW5kIHRpbWUgdmFyaWFibGVzCmNhdCAvbW50L2NmZzEvc2NyaXB0cy9zaXRlX2lwLmh0bWwg
fCBzZWQgInN8REFURVRJTUV8JERBVEVUSU1FfGciIHwgc2VkICJzfFNJVEVJUHwkSVB8ZyIgPiAv
dmFyL3RtcC8ke1NJVEVOQU1FfVxfaXAuaHRtbAoKIyBydW4gdGhlIHVwbG9hZCBzY3JpcHQgZm9y
IHRoZSBpcCBkYXRhCiMgYW5kIGZvciBhbGwgc2VydmVycwpmb3IgaSBpbiAkbnJzZXJ2ZXJzIDsK
ZG8KIFNFUlZFUj1gYXdrIC12IHA9JGkgJ05SPT1wJyAvbW50L2NmZzEvc2VydmVyLnR4dGAgCgkK
ICMgdXBsb2FkIGltYWdlCiBlY2hvICJ1cGxvYWRpbmcgTklSIGltYWdlICR7aW1hZ2V9IgogZnRw
cHV0ICR7U0VSVkVSfSAtdSAiYW5vbnltb3VzIiAtcCAiYW5vbnltb3VzIiBkYXRhLyR7U0lURU5B
TUV9LyR7U0lURU5BTUV9XF9pcC5odG1sIC92YXIvdG1wLyR7U0lURU5BTUV9XF9pcC5odG1sCgpk
b25lCgojIGNsZWFuIHVwCnJtIC92YXIvdG1wLyR7U0lURU5BTUV9XF9pcC5odG1sCgAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZpbGVzL3BoZW5vY2FtX3Vw
bG9hZC5zaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwMDAwNzc1ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAx
MjIwNwAxNDYwMTMwNDIwMgAwMTYwNjcAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKY2Fw
dHVyZSAoKSB7CgogaW1hZ2U9JDEKIG1ldGFmaWxlPSQyCiBkZWxheT0kMwogaXI9JDQKCiAjIFNl
dCB0aGUgaW1hZ2UgdG8gbm9uIElSIGkuZS4gVklTCiAvdXNyL3NiaW4vc2V0X2lyLnNoICRpcgoK
ICMgYWRqdXN0IGV4cG9zdXJlCiBzbGVlcCAkZGVsYXkKCiAjIGdyYWIgdGhlIGltYWdlIGZyb20g
dGhlCiB3Z2V0IGh0dHA6Ly8xMjcuMC4wLjEvaW1hZ2UuanBnIC1PICR7aW1hZ2V9CgogIyBncmFi
IGRhdGUgYW5kIHRpbWUgZm9yIGAubWV0YWAgZmlsZXMKIE1FVEFEQVRFVElNRT1gZGF0ZSAtSXNl
Y29uZHNgCgogIyBncmFiIHRoZSBleHBvc3VyZSB0aW1lIGFuZCBhcHBlbmQgdG8gbWV0YS1kYXRh
CiBleHBvc3VyZT1gL3Vzci9zYmluL2dldF9leHAgfCBjdXQgLWQgJyAnIC1mNGAKCiBjYXQgbWV0
YWRhdGEudHh0ID4+IC92YXIvdG1wLyR7bWV0YWZpbGV9CiBlY2hvICJleHBvc3VyZT0ke2V4cG9z
dXJlfSIgPj4gL3Zhci90bXAvJHttZXRhZmlsZX0KIGVjaG8gImlyX2VuYWJsZT0kaXIiID4+IC92
YXIvdG1wLyR7bWV0YWZpbGV9CiBlY2hvICJkYXRldGltZV9vcmlnaW5hbD1cIiRNRVRBREFURVRJ
TUVcIiIgPj4gL3Zhci90bXAvJHttZXRhZmlsZX0KCn0KCiMgLS0tLS0tLS0tLS0tLS0gU0VUVElO
R1MgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyByZWFkIGlu
IGNvbmZpZ3VyYXRpb24gc2V0dGluZ3MKIyBncmFiIHNpdGVuYW1lClNJVEVOQU1FPWBhd2sgJ05S
PT0xJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YAoKIyBncmFiIHRpbWUgb2Zmc2V0IC8gbG9jYWwg
dGltZSB6b25lCiMgYW5kIGNvbnZlcnQgKy8tIHRvIGFzY2lpCnRpbWVfb2Zmc2V0PWBhd2sgJ05S
PT0yJyAvbW50L2NmZzEvc2V0dGluZ3MudHh0YApTSUdOPWBlY2hvICR7dGltZV9vZmZzZXR9IHwg
Y3V0IC1jJzEnYAoKaWYgWyAiJFNJR04iID0gIisiIF07IHRoZW4KIHRpbWVfb2Zmc2V0PWBlY2hv
ICIke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvKy8lMkIvZydgCmVsc2UKIHRpbWVfb2Zmc2V0PWBl
Y2hvICIke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvLS8lMkQvZydgCmZpCgojIHNldCBjYW1lcmEg
bW9kZWwgbmFtZQptb2RlbD0iTmV0Q2FtIExpdmUyIgoKIyBob3cgbWFueSBzZXJ2ZXJzIGRvIHdl
IHVwbG9hZCB0bwpucnNlcnZlcnM9YGF3ayAnRU5EIHtwcmludCBOUn0nIC9tbnQvY2ZnMS9zZXJ2
ZXIudHh0YApucnNlcnZlcnM9YGF3ayAtdiB2YXI9JHtucnNlcnZlcnN9ICdCRUdJTnsgbj0xOyB3
aGlsZSAobiA8PSB2YXIgKSB7IHByaW50IG47IG4rKzsgfSB9JyB8IHRyICdcbicgJyAnYAoKIyBn
cmFiIHBhc3N3b3JkCnBhc3M9YGF3ayAnTlI9PTEnIC9tbnQvY2ZnMS8ucGFzc3dvcmRgCgojIE1v
dmUgaW50byB0ZW1wb3JhcnkgZGlyZWN0b3J5CiMgd2hpY2ggcmVzaWRlcyBpbiBSQU0sIG5vdCB0
bwojIHdlYXIgb3V0IG90aGVyIHBlcm1hbmVudCBtZW1vcnkKY2QgL3Zhci90bXAKCiMgc2V0cyB0
aGUgZGVsYXkgYmV0d2VlbiB0aGUKIyBSR0IgYW5kIElSIGltYWdlIGFjcXVpc2l0aW9ucwpERUxB
WT0zMAoKIyBncmFiIGRhdGUgLSBrZWVwIGZpeGVkIGZvciBSR0IgYW5kIElSIHVwbG9hZHMKREFU
RT1gZGF0ZSArIiVhICViICVkICVZICVIOiVNOiVTImAKCiMgZ3JhcCBkYXRlIGFuZCB0aW1lIHN0
cmluZyB0byBiZSBpbnNlcnRlZCBpbnRvIHRoZQojIGZ0cCBzY3JpcHRzIC0gdGhpcyBjb29yZGlu
YXRlcyB0aGUgdGltZSBzdGFtcHMKIyBiZXR3ZWVuIHRoZSBSR0IgYW5kIElSIGltYWdlcyAob3Ro
ZXJ3aXNlIHRoZXJlIGlzIGEKIyBzbGlnaHQgb2Zmc2V0IGR1ZSB0byB0aGUgdGltZSBuZWVkZWQg
dG8gYWRqdXN0IGV4cG9zdXJlCkRBVEVUSU1FU1RSSU5HPWBkYXRlICsiJVlfJW1fJWRfJUglTSVT
ImAKCiMgZ3JhYiBtZXRhZGF0YSB1c2luZyB0aGUgbWV0YWRhdGEgZnVuY3Rpb24KIyBncmFiIHRo
ZSBNQUMgYWRkcmVzcwptYWNfYWRkcj1gaWZjb25maWcgZXRoMCB8IGdyZXAgSFdhZGRyIHwgYXdr
ICd7cHJpbnQgJDV9JyB8IHNlZCAncy86Ly9nJ2AKCiMgZ3JhYiBpbnRlcm5hbCBpcCBhZGRyZXNz
CmlwX2FkZHI9YGlmY29uZmlnIGV0aDAgfCBhd2sgJy9pbmV0IGFkZHIve3ByaW50IHN1YnN0cigk
Miw2KX0nYAoKIyBncmFiIGV4dGVybmFsIGlwIGFkZHJlc3MgaWYgdGhlcmUgaXMgYW4gZXh0ZXJu
YWwgY29ubmVjdGlvbgojIGZpcnN0IHRlc3QgdGhlIGNvbm5lY3Rpb24gdG8gdGhlIGdvb2dsZSBu
YW1lIHNlcnZlcgpjb25uZWN0aW9uPWBwaW5nIC1xIC1jIDEgOC44LjguOCA+IC9kZXYvbnVsbCAm
JiBlY2hvIG9rIHx8IGVjaG8gZXJyb3JgCgojIGdyYWIgdGltZSB6b25lCnR6PWBjYXQgL3Zhci9U
WmAKCiMgZ3JhYiB0aGUgY29sb3VyIGJhbGFuY2Ugc2V0dGluZ3MhISEKCiMgY3JlYXRlIGJhc2Ug
bWV0YS1kYXRhIGZpbGUgZnJvbSBjb25maWd1cmF0aW9uIHNldHRpbmdzCiMgYW5kIHRoZSBmaXhl
ZCBwYXJhbWV0ZXJzCmVjaG8gIm1vZGVsPU5ldENhbSBMaXZlMiIgPiAvdmFyL3RtcC9tZXRhZGF0
YS50eHQKL21udC9jZmcxL3NjcmlwdHMvY2hscyA+PiAvdmFyL3RtcC9tZXRhZGF0YS50eHQKZWNo
byAiaXBfYWRkcj0kaXBfYWRkciIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gIm1hY19h
ZGRyPSRtYWNfYWRkciIgPj4gL3Zhci90bXAvbWV0YWRhdGEudHh0CmVjaG8gInRpbWVfem9uZT0k
dHoiID4+IC92YXIvdG1wL21ldGFkYXRhLnR4dAoKIyAtLS0tLS0tLS0tLS0tLSBTRVQgRklYRUQg
REFURSBUSU1FIEhFQURFUiAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCgojIG92ZXJsYXkgdGV4
dApvdmVybGF5X3RleHQ9YGVjaG8gIiR7U0lURU5BTUV9IC0gJHttb2RlbH0gLSAke0RBVEV9IC0g
R01UJHt0aW1lX29mZnNldH0iIHwgc2VkICdzLyAvJTIwL2cnYAoJCiMgZm9yIG5vdyBkaXNhYmxl
IHRoZSBvdmVybGF5CndnZXQgaHR0cDovL2FkbWluOiR7cGFzc31AMTI3LjAuMC4xL3ZiLmh0bT9v
dmVybGF5dGV4dDE9JHtvdmVybGF5X3RleHR9CgojIGNsZWFuIHVwIGRldHJpdHVzCnJtIHZiKgoK
IyAtLS0tLS0tLS0tLS0tLSBVUExPQUQgVklTIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0tLS0tCgojIGNyZWF0ZSBmaWxlbmFtZXMKbWV0YWZpbGU9YGVjaG8gJHtTSVRFTkFN
RX1fJHtEQVRFVElNRVNUUklOR30ubWV0YWAKaW1hZ2U9YGVjaG8gJHtTSVRFTkFNRX1fJHtEQVRF
VElNRVNUUklOR30uanBnYAoKY2FwdHVyZSAkaW1hZ2UgJG1ldGFmaWxlICRERUxBWSAwCgojIHJ1
biB0aGUgdXBsb2FkIHNjcmlwdCBmb3IgdGhlIGlwIGRhdGEKIyBhbmQgZm9yIGFsbCBzZXJ2ZXJz
CmZvciBpIGluICRucnNlcnZlcnM7CmRvCiBTRVJWRVI9YGF3ayAtdiBwPSRpICdOUj09cCcgL21u
dC9jZmcxL3NlcnZlci50eHRgCiAKIGVjaG8gInVwbG9hZGluZyB0bzogJHtTRVJWRVJ9IgoKICMg
dXBsb2FkIGltYWdlCiBlY2hvICJ1cGxvYWRpbmcgVklTIGltYWdlICR7aW1hZ2V9IgogZnRwcHV0
ICR7U0VSVkVSfSAtLXVzZXJuYW1lIGFub255bW91cyAtLXBhc3N3b3JkIGFub255bW91cyAgZGF0
YS8ke1NJVEVOQU1FfS8ke2ltYWdlfSAke2ltYWdlfQoJCiBlY2hvICJ1cGxvYWRpbmcgVklTIG1l
dGEtZGF0YSAke21ldGFmaWxlfSIKIGZ0cHB1dCAke1NFUlZFUn0gLS11c2VybmFtZSBhbm9ueW1v
dXMgLS1wYXNzd29yZCBhbm9ueW1vdXMgIGRhdGEvJHtTSVRFTkFNRX0vJHttZXRhZmlsZX0gJHtt
ZXRhZmlsZX0KCmRvbmUKCiMgY2xlYW4gdXAgZmlsZXMKcm0gKi5qcGcKcm0gKi5tZXRhCgojIC0t
LS0tLS0tLS0tLS0tIFVQTE9BRCBOSVIgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
LS0tLS0tLS0KCiMgY3JlYXRlIGZpbGVuYW1lcwptZXRhZmlsZT1gZWNobyAke1NJVEVOQU1FfV9J
Ul8ke0RBVEVUSU1FU1RSSU5HfS5tZXRhYAppbWFnZT1gZWNobyAke1NJVEVOQU1FfV9JUl8ke0RB
VEVUSU1FU1RSSU5HfS5qcGdgCgpjYXB0dXJlICRpbWFnZSAkbWV0YWZpbGUgJERFTEFZIDEKCiMg
cnVuIHRoZSB1cGxvYWQgc2NyaXB0IGZvciB0aGUgaXAgZGF0YQojIGFuZCBmb3IgYWxsIHNlcnZl
cnMKZm9yIGkgaW4gJG5yc2VydmVyczsKZG8KIFNFUlZFUj1gYXdrIC12IHA9JHtpfSAnTlI9PXAn
IC9tbnQvY2ZnMS9zZXJ2ZXIudHh0YAoKICMgdXBsb2FkIGltYWdlCiBlY2hvICJ1cGxvYWRpbmcg
TklSIGltYWdlICR7aW1hZ2V9IgogZnRwcHV0ICR7U0VSVkVSfSAtdSAiYW5vbnltb3VzIiAtcCAi
YW5vbnltb3VzIiAgZGF0YS8ke1NJVEVOQU1FfS8ke2ltYWdlfSAke2ltYWdlfQoJCiBlY2hvICJ1
cGxvYWRpbmcgTklSIG1ldGEtZGF0YSAke21ldGFmaWxlfSIKIGZ0cHB1dCAke1NFUlZFUn0gLXUg
ImFub255bW91cyIgLXAgImFub255bW91cyIgIGRhdGEvJHtTSVRFTkFNRX0vJHttZXRhZmlsZX0g
JHttZXRhZmlsZX0KCmRvbmUKCiMgY2xlYW4gdXAgZmlsZXMKcm0gKi5qcGcKcm0gKi5tZXRhCgoj
IFJlc2V0IHRvIFZJUwovdXNyL3NiaW4vc2V0X2lyLnNoIDAKCiMgLS0tLS0tLS0tLS0tLS0gU0VU
IE5PUk1BTCBIRUFERVIgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKIyBvdmVy
bGF5IHRleHQKb3ZlcmxheV90ZXh0PWBlY2hvICIke1NJVEVOQU1FfSAtICR7bW9kZWx9IC0gJWEg
JWIgJWQgJVkgJUg6JU06JVMgLSBHTVQke3RpbWVfb2Zmc2V0fSIgfCBzZWQgJ3MvIC8lMjAvZydg
CgkKIyBmb3Igbm93IGRpc2FibGUgdGhlIG92ZXJsYXkKd2dldCBodHRwOi8vYWRtaW46JHtwYXNz
fUAxMjcuMC4wLjEvdmIuaHRtP292ZXJsYXl0ZXh0MT0ke292ZXJsYXlfdGV4dH0KCiMgY2xlYW4g
dXAgZGV0cml0dXMKcm0gdmIqCgojLS0tLS0tLSBGRUVEQkFDSyBPTiBBQ1RJVklUWSAtLS0tLS0t
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KZWNobyAibGFzdCB1cGxvYWQgYXQ6IiA+
PiAvdmFyL3RtcC9sb2cudHh0CmVjaG8gZGF0ZSA+PiAvdmFyL3RtcC9sb2cudHh0CgoAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGZpbGVzL3JlYm9vdF9jYW1lcmEuc2gAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAwMDAwNjY0ADAwMDE3NTAAMDAwMTc1MAAwMDAwMDAwMDc0MwAxNDU3NzM0
NTAxNAAwMTU1NTQAIDAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQoKcGFzcz0kMQoKIyBzbGVl
cCAxNSBzZWNvbmRzIGFuZCB0cmlnZ2VyIHJlYm9vdApzbGVlcCAxMgoKIyBtb3ZlIGludG8gdGVt
cG9yYXJ5IGRpcmVjdG9yeQpjZCAvdmFyL3RtcAoKIyByZWJvb3QKd2dldCBodHRwOi8vYWRtaW46
JHtwYXNzfUAxMjcuMC4wLjEvdmIuaHRtP2lwY2FtcmVzdGFydGNtZCAmPi9kZXYvbnVsbAoKAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABmaWxlcy9zaXRlX2lwLmh0bWwAAAAAAAAAAAAAAAAA
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
