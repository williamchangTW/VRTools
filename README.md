# VRTools
contributors: <`williamchangTW`>
Implement a tool for VR operation.

***
## Overview
NA

***
## Target
- [ ] Trying to update RAA228926 firmware via PMBus(I2C).
    - [ ] Refer to PMBus spec documentation, and makes sure all command has right response.
    - [ ] Refer to RAA228926 datasheet, and make sure all command has right output.
        - [ ] Trying to write data via DMA register(Refer to RAA228926 programming guide).
- [x] Automation test needs to convert a string with 16 characters to a string with 16 bytes in hexadecimal.
    - [x] seperate string to 16 character
    - [x] convert to hexadecimal character
    - [x] concate all characters back to string

***
## Files
- `raa228926.sh`: This tool content the method to update the firmware in the VR controller(raa228926).
- `strTohex.sh`: Convert string to hexadecimal representation.

***
### Reference
- [PMbus(v1.3) specific documentation](https://pmbus.org/specification-archives/)
- [RAA228228 Datasheet](https://www.renesas.com/us/en/products/power-power-management/computing-power-vrmimvp/digital-multiphase-dcdc-switching-controllers/raa228228-digital-double-output-20-phase-pwm-controller-adaptive-voltage-scaling-bus-avsbus#overview)