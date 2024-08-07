#!/bin/bash

#--------------------------------------------------------------------
# (c) Koen Hufkens for BlueGreen Labs (BV)
#--------------------------------------------------------------------

#---- global login banner ----

echo ""
echo "===================================================================="
echo ""
echo " Phenocam Installation Tool password tool for NetCam Live2 cameras"
echo ""
echo " (c) BlueGreen Labs (BV) 2024 - https://bluegreenlabs.org"
echo ""
echo " -----------------------------------------------------------"
echo ""

#---- subroutines ----

# error handling purging routine
error_pass(){
  echo ""
  echo " WARNING: Failed to update the password!"
  echo ""
  echo "===================================================================="
  exit 0
}

# define usage
usage() { 
 echo "
 
 This scripts allows you to quickly change
 the default password on the StarDot NetCam Live2
 
 Usage: $0
  [-i <camera ip address>]
  [-h calls this menu if specified]
  " 1>&2
  
  exit 0
 }
 
 #---- parse arguments (and/or execute subroutine calls) ----

# grab arguments
while getopts "h:i:" option;
do
    case "${option}"
        in
        i) ip=${OPTARG} ;;
        h | *) usage; exit 0 ;;
    esac
done

echo " Changing the password"
echo ""
 
# check if IP is provided
if [ -z ${ip} ]; then
  echo " No IP address provided"
  error_upload
fi
 
# create command
command="
  passwd admin
 "
 
# execute command
ssh admin@${ip} ${command} || error_pass 2>/dev/null
 
echo " -----------------------------------------------------------"
echo ""
echo " Done, successfully changed the password"
echo ""
echo "===================================================================="
exit 0

