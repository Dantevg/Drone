# Drone software in Lua
This is drone software for drone and controller, written in 100% Lua.

Device     | Language / flavor | Hardware
:----------|:------------------|:--------
Drone      | Lua / NodeMCU     | esp32 (see note #2)
Controller | Lua / Love2D      | Any android device

## Installation
So, you actually want to install this? Ok.

**NodeMCU**
1. Install the [firmware] (see note #1)
2. Upload the files in the [`/nodemcu`](/nodemcu) directory to the NodeMCU

**Controller**  
At this time, I haven't made any binaries for the controller yet.
But when I have, they can be found in the `/bin` folder. Just download and install it.

Connect everything up and power on.
The controller needs to be connected to the wifi network the NodeMCU creates. After that, the fun can begin!

## Notes
1. The [firmware] that I flashed my NodeMCU with includes the following modules:
   1. `adc`, `bit`, `file`, `gpio`, `i2c`, `net`, `node`, `pwm`, `tmr`, `uart`, `wifi`
2. Don't try to make this work on an esp8266.
   1. It has too little ram to support the reading of the LSM9DS1 sensor
   2. It is too slow to be able to set 4 PWM pins and communicate at the same time
    (you will be limited to around 2 updates per second)
3. This is for a school project, but I will keep updating it afterwards
4. I use tabs for indentation (as you should ;)
   so don't freak out when you see a 8-space indentation, that's just your browser
5. If you found anything here hepful or you have a question, please let me know (I would love to hear)

## License
This project is licensed under the MIT license. Use it for whatever you want!

**Other licenses:**  
[Love2d](https://love2d.org/wiki/License) (ZLIB)  
[Roboto font](https://github.com/google/roboto/blob/master/LICENSE) (Apache 2.0)  
[NodeMCU firmware](https://github.com/nodemcu/nodemcu-firmware/blob/master/LICENSE) (MIT)

[firmware]: nodemcu/firmware-adc-bit-file-gpio-i2c-net-node-pwm-tmr-uart-wifi.bin
