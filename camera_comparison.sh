#!/bin/bash

# demo wrapper script on how to
# subsitute parameters using sed
# and run the config script consistently

ip=$1
pass=$2
saturation=$3

# substitute the staturation value in the default script
# create a temporary script and use these settings
# while keeping the rest static (see below)
cat PIT.sh | sed "s/saturation=\"100\"/saturation=\"${saturation}\"/g" > PITtmp.sh

# fix the schedule (see -f)
sh PITtmp.sh -i $ip -p $pass -n testcam -o "\-1" -s 9 -e 22 -m 30 -d "phenocam" -f TRUE


