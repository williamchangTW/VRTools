#!/bin/sh
################################################
# Information                                  #
################################################
# File name: strTOhex.sh
# Author: William Chang
# Email: william80121@hotmail.com.tw
# example string that reply from IPMI command
# -> 01 00 00 01 00 00 0a fe 09 0a 10 00 15 11 ab 43
IPMITOOL="ipmitool raw"
IPMIReturn="01 00 00 01 00 00 0a fe 09 0a 10 00 15 43 c3 30"

echo ${#IPMIReturn}

# seperate every character in string 
for ((i=0; i<=${#IPMIReturn}; i+=3))
do
    #echo $i
    echo "0x${IPMIReturn:i:2}"
    IPMIResult="$IPMIResult 0x${IPMIReturn:i:2}"
done

echo "$IPMIResult"
