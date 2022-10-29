#!/bin/sh
################################################
# Information                                  #
################################################
# File name: raa228926.sh
# Author: William Chang
# Email: william80121@hotmail.com.tw

################################################
# Notification                                 #
################################################
# * communication protocol based on PMBus
# * DMA command codes are keyword to flash FW

################################################
# Flash process                                #
################################################
# 1. Unbind driver 
# 2. Disable packet capture
# 3. Determine number of NVM slots available
# 4. Verify device and file version
# 5. Read and parse one line from HEX file to device
# 6. Verify programming success

################################################
# Command Code                                 #
################################################
# Command Name | Code
# IC_DEVICE_ID: 0xAD
# MFR_ID: 0x99
# MFR_MODEL: 0x9A
# MFR_DATE: 0x9B
# IC_DEVICE_REV: 0xAE
# DMAFIX: 0xC5
# DMASEQ: 0xC6
# DMAADDR: 0xC7

################################################
# Others                                       #
################################################
# if retun none-zero then exit immediately
set -e 
# Variable
# VR controller I2C bus
BUS=7
# VR controller slave address
VR_SLAVE_ADDRESS_1='0x5a'
VR_SLAVE_ADDRESS_2='0x5b'
# BMC IP
IP="192.168.123.123"
LOGOUT=/tmp/RAA228926_VR_FW_Update.log
#BMCDATA=/tmp/liteon-psu
#PSU_IMG=/tmp/PSU_image.bin
#HEXDUMP_TOOL=/usr/local/bin/hexconvert
#GPIO_TOOL=/usr/local/bin/gpiotool

################################################
# Offload driver                               #
################################################
unbindDriver()
{

}

checkVersion()
{
	echo -e "\n*****Current Version*****"
	ret=`$IPMICMD 0x08 0xD5`
    DELAY 0.1
	echo $ret
}

reboot()
{
    echo -e "\n*****Reboot PSU*****"
	$IPMICMD 0x0 0xD2 0x03
    DELAY 3
}

transferData()
{
	echo "Transfer $PSU_IMG from bin file format to BMC hex data..."
	rm -rf $BMCDATA
	$HEXDUMP_TOOL -c 32 -ps "$PSU_IMG"  > $BMCDATA
	BLOCK_SIZE=32

	LAST_LINE=`tail -n 1 $BMCDATA`
	CHECK_COUNT=`expr $BLOCK_SIZE \* 2`
	while [ ${#LAST_LINE} -lt $CHECK_COUNT ] ; do
		STR="`tail -n 1 $BMCDATA`ff"
		sed -i '$d' $BMCDATA
		echo "$STR" >> $BMCDATA
		LAST_LINE=`tail -n 1 $BMCDATA`
	done
	DELAY 1
}

writeData()
{
	TRANS_DATA

	RAW=`awk 'END {print NR}' $BMCDATA`
	echo -e " Start to Write $RAW piece of data..."

	LOOP=1
	while read LINE
	do               
		STR_DATA="`echo $LINE | sed 's/.\{2\}/0x& /g'`"
	 	$IPMICMD 0x0 0xD4 $STR_DATA
		echo "LOOP = $LOOP"
		echo "$IPMICMD 0x0 0xD4 $STR_DATA"
		if [ "$LOOP" -eq "1" ];then DELAY 2;
		elif [ "$LOOP" -eq "2" ];then DELAY 2;
		else DELAY 0.1;
		fi
		LOOP=`expr $LOOP + 1`
	done < $BMCDATA
	rm -f $BMCDATA
}

checkData()
{
    echo -e "\n*****Check response is 0x${1}*****"

	#echo "$IPMICMD 0x01 0xD2"
    ret=`$IPMICMD 0x01 0xD2`
	if [ "$ret" != " $1" ] 
	then 
		echo "STATUS $ret		[ERROR]"
		exit
	else
		echo "STATUS $ret"
	fi
	DELAY 0.36
}

delay()
{
	echo -e "delay $1 seconds ..."
	sleep $1
}

DO()
{
#	echo " $1"
	$1 > /dev/null 2>&1
	if [ "$?" != "0" ]; then echo " [ERROR] $1, Command FAIL!"; exit; fi
}

disableRecieveData()
{
    echo "Stop sensor scanning of all PSU sensors..."
    $GPIO_TOOL  --set-gpios-dir-output 98
    $GPIO_TOOL  --set-gpios-dir-output 101
    sleep 1
    $GPIO_TOOL  --set-data-low 98
    $GPIO_TOOL  --set-data-low 101
    sleep 1
}

enableRecieveData()
{
    echo "Start sensor scanning of all PSU sensors..."
    $GPIO_TOOL  --set-data-high 98
    $GPIO_TOOL  --set-data-high 101
    sleep 1
    $GPIO_TOOL  --set-gpios-dir-input 98
    $GPIO_TOOL  --set-gpios-dir-input 101
    sleep 1
}

updateFW()
{
	echo "[Start to Update Liteon PSU FW]"
	CHECK_VER
	STOP_PSU_SCANNING
	WR_ISP_KEY
	BOOT_PSU_OS
	CHECK_DATA 40
	RESTART
	CHECK_DATA 40
	WR_DATA
	CHECK_DATA 41
	REBOOT_PSU
	START_PSU_SCANNING
	CHECK_VER
}

Help()
{
    # Display all items
    echo "The script functions is here."
    echo "-----------------------------"
    echo "Syntax: scriptTemplate [-c|V]"
    echo "Options:"
    echo "g    Get device ID."
    echo "usage: g {0xXX} to get device ID from specify slave address."
    echo "u    Unbind VR controller driver"
    echo "f    Flash VR controller."
    echo "usage: f {0xXX} to flash VR controller with specify slave address"
    echo "h    Print this Help."
    
}

################################################
# Main function                                #
################################################
if [ "$2" == VR_SLAVE_ADDRESS_1 ]; then
    echo "Get device from VR slavce address $VR_SLAVE_ADDRESS_1"

elif [ "$2" == VR_SLAVE_ADDRESS_2 ]; then
    echo "Get device from VR slavce address $VR_SLAVE_ADDRESS_2"

else
	echo "[ERROR] Cannot find PSU_SLAVE!"
fi
# Check PSU FW image is existed
if [ -e "$1" ]; then 
	echo " Input PSU FW Image: $1"
	PSU_IMG="$1"
else 
	echo " [ERROR] Cannot find PSU FW Image: $1!";
	exit 
fi

echo "`date`"
IPMICMD="/usr/local/bin/ipmitool -I lanplus -H "$IP" -U admin -P admin raw 0x6 0x52 0xf "$PSU_SLAVE""
FW_UPDATE
echo "`date`"
#----------End----------
