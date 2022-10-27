#!/bin/sh
# author: William Chang
# email: william80121@hotmail.com.tw
# Notification:
# * communication protocol based on PMBus
# * DMA command codes are keyword to flash FW
# Process of flash VR controller 
# 1. Disable packet capture
# 2. Determine number of NVM slots available 
# ccommand code define:
# Command Name | Code
# IC_DEVICE_ID: 0xAD
# MFR_ID: 0x99
# MFR_MODEL: 0x9A
# MFR_DATE: 0x9B
# IC_DEVICE_REV: 0xAE
# DMAFIX: 0xC5
# DMASEQ: 0xC6
# DMAADDR: 0xC7
# if retun none-zero then exit immediately
set -e 
# Variable
# VR controller I2C bus
BUS=7
# VR controller slave address
SLAVE_ADDRESS_1='0x5a'
SLAVE_ADDRESS_2='0x5b'
# BMC IP
IP="192.168.123.123"
LOGOUT=/tmp/RAA228926_VR_FW_Update.log
#BMCDATA=/tmp/liteon-psu
#PSU_IMG=/tmp/PSU_image.bin
#HEXDUMP_TOOL=/usr/local/bin/hexconvert
#GPIO_TOOL=/usr/local/bin/gpiotool

CHECK_VER(){
	echo -e "\n*****Current Version*****"
	ret=`$IPMICMD 0x08 0xD5`
    DELAY 0.1
	echo $ret
}

WR_ISP_KEY(){
	echo -e "\n*****Write ISP Key*****"
	$IPMICMD 0x0 0xD1 0x49 0x6E 0x76 0x74
	DELAY 0.15
}

BOOT_PSU_OS(){
	echo -e "\n*****Boot PSU ISP OS*****"
	$IPMICMD 0x0 0xD2 0x02
	DELAY 2.5
}

RESTART(){
	echo -e "\n*****Restart PSU ISP OS*****"
	$IPMICMD 0x0 0xD2 0x01
    DELAY 4.6
}

REBOOT_PSU(){
    echo -e "\n*****Reboot PSU*****"
	$IPMICMD 0x0 0xD2 0x03
    DELAY 3
}

TRANS_DATA(){
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

WR_DATA(){
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

CHECK_DATA(){
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

DELAY(){
	echo -e "delay $1 seconds ..."
	sleep $1
}

DO(){
#	echo " $1"
	$1 > /dev/null 2>&1
	if [ "$?" != "0" ]; then echo " [ERROR] $1, Command FAIL!"; exit; fi
}

STOP_PSU_SCANNING(){
    echo "Stop sensor scanning of all PSU sensors..."
    $GPIO_TOOL  --set-gpios-dir-output 98
    $GPIO_TOOL  --set-gpios-dir-output 101
    sleep 1
    $GPIO_TOOL  --set-data-low 98
    $GPIO_TOOL  --set-data-low 101
    sleep 1
}

START_PSU_SCANNING(){
    echo "Start sensor scanning of all PSU sensors..."
    $GPIO_TOOL  --set-data-high 98
    $GPIO_TOOL  --set-data-high 101
    sleep 1
    $GPIO_TOOL  --set-gpios-dir-input 98
    $GPIO_TOOL  --set-gpios-dir-input 101
    sleep 1
}

FW_UPDATE(){
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

#----------Main---------
#Check PSU Slave Address
if [ "$2" == "1" ]; then
	PSU_SLAVE="0xB0"
	echo " PSU Slave Address = $PSU_SLAVE"
elif [ "$2" == "2" ]; then
    PSU_SLAVE="0xB2"
	echo " PSU Slave Address = $PSU_SLAVE"
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
