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
# IC_DEVICE_REV: 0xAE
# MFR_ID: 0x99
# MFR_MODEL: 0x9A
# MFR_DATE: 0x9B
# DMAFIX: 0xC5
# DMASEQ: 0xC6
# DMAADDR: 0xC7
IP=""
I2CGET="i2cget -f -y"
BUS="7"
VR_SLAVE_ADDRESS_1="0x5a"
VR_SLAVE_ADDRESS_2="0x5b"

cmdGetID()
{
    # Default read I2C block
    code="0xad"
    cmd="$I2CGET $BUS $1 $code s"
    echo $cmd
    reverseLSB "$cmd"
}

cmdGetRivision()
{
    # Default read I2C block
    code="0xae"
    cmd="$I2CGET $BUS $1 $code s"
    echo $cmd
    reverseLSB "$cmd"
}

switchOptions()
{
    echo $2
    if [ $2 == "i" ]; then 
	    echo "Get Device ID"
        cmdGetID "$@"
    elif [ $2 == "r" ]; then
        echo "Get Device Revision"
        cmdGetRivision "$@"
    else 
	    echo "Your choise is invalid"
        Help
        exit 1
    fi
}

reverseLSB()
{
    echo "reverseLSB"
    cmd="whoami"
    response=`$cmd`
    echo "$response"
    for ((i=${#response}-1; i>=0; i--))
    do
        reverseResult="$reverseResult${response:i:1}"
    done
    echo "$reverseResult"
}

Help()
{
    # Display all items
    echo "-----------------------------"
    echo "The script functions is here."
    echo "-----------------------------"
    echo "Syntax: scriptTemplate [-c|V]"
    echo "Options:"
    echo "i    Get device ID. (Usage: {0xXX} i)"
    echo "r    Get Device Revision."
    echo "u    Unbind Driver. (Usage: {0xXX} u)"
    echo "h     Print this Help."
}

################################################
# Main function                                #
################################################
main()
{
    # check slave address is valid
    if [ $1 == $VR_SLAVE_ADDRESS_1 ]; then
        echo "Get device from VR slavce address $VR_SLAVE_ADDRESS_1"
        switchOptions "$@"
    elif [ $1 == $VR_SLAVE_ADDRESS_2 ]; then
        echo "Get device from VR slavce address $VR_SLAVE_ADDRESS_2"
        switchOptions "$@"
    else
        echo "[ERROR] Cannot find VR Controller!"
        Help
        exit 1
    fi
}

main "$@"