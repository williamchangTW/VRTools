#!/bin/sh
################################################
# Information                                  #
################################################
# File name: pmbus.sh
# Author: William Chang
# Email: william80121@hotmail.com.tw

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
I2CGET="i2cget -f -y"
BUS="7"
VR_SLAVE_ADDRESS_1="0x5a"
VR_SLAVE_ADDRESS_2="0x5b"

cmdGetID()
{
    code="0xAD"
    cmd="$I2CGET $BUS $1 $code"
}

cmdGetRivision()
{
    code="0xAE"
    cmd="$I2CGEt $BUS $1 $code"
}

switchOptions()
{
    if [ "$2" == "gi" ]; then 
	    echo "Get Device ID"
        cmdGetID
    elif [ "$2" == "gr" ]; then
        echo "Get Device Revision"
        cmdGetRivision
    else 
	    echo "Your choise is invalid";
        Help 
    fi
}

Help()
{
    # Display all items
    echo "The script functions is here."
    echo "-----------------------------"
    echo "Syntax: scriptTemplate [-c|V]"
    echo "Options:"
    echo "gi    Get device ID. (Usage: {0xXX} g)"
    echo "gr    Get Device Revision."
    echo "e     Exit this script."
    echo "h     Print this Help."
}

################################################
# Main function                                #
################################################
main()
{
    # check slave address is valid
    while [ true ];
    do
        #read -t 5 -n 1
        if [ "$1" == VR_SLAVE_ADDRESS_1 ]; then
            echo "Get device from VR slavce address $VR_SLAVE_ADDRESS_1"
        elif [ "$1" == VR_SLAVE_ADDRESS_2 ]; then
            echo "Get device from VR slavce address $VR_SLAVE_ADDRESS_2"
        elif [ "$1" == "e" ]; then
            echo "exit..."
            exit 1
        else
	        echo "[ERROR] Cannot find VR Controller!"
            Help
        fi
    done
}

main "$@"