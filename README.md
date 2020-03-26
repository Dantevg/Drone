# Drone software in Lua
This is drone software for drone and controller, written in 100% Lua.

Device     | Language / flavor | Hardware
:----------|:------------------|:--------
Drone      | Lua / [Whitecat]  | esp32 (see note #1)
Controller | Lua / [Love2D]    | Any android device

## Installation
So, you actually want to install this? Ok.

**ESP32**
1. Install the [Whitecat console](https://github.com/whitecatboard/whitecat-console)
2. Using the Whitecat console, erase the board and flash the latest firmware
3. Use the Whitecat console to upload the files in the [`/esp32`](/esp32) directory to the esp32

**Controller**  
At this time, I haven't made any binaries for the controller yet.
But when I have, they can be found in the `/bin` folder. Just download and install it.

Connect everything up and power on.
The controller needs to be connected to the wifi network the NodeMCU creates. After that, the fun can begin!

## Notes
1. Don't try to make this work on an esp8266.
   1. It has too little ram to support the reading of the LSM9DS1 sensor
   2. It is too slow to be able to set 4 PWM pins and communicate at the same time
    (you will be limited to around 2 updates per second)
2. This is for a school project, but I will keep updating it afterwards
3. I use tabs for indentation (as you should ;)
   so don't freak out when you see a 8-space indentation, that's just your browser
4. If you found anything here hepful or you have a question, please let me know (I would love to hear)

## License
This project is licensed under the MIT license. Use it for whatever you want!

**Other licenses:**  
[Love2d](https://love2d.org/wiki/License) (ZLIB)  
[Roboto font](https://github.com/google/roboto/blob/master/LICENSE) (Apache 2.0)  
[NodeMCU firmware](https://github.com/nodemcu/nodemcu-firmware/blob/master/LICENSE) (MIT) (no longer used)  
[Whitecat RTOS firmware](https://github.com/whitecatboard/Lua-RTOS-ESP32/blob/master/LICENSE) (BSD 3-clause)

[Whitecat]: https://github.com/whitecatboard
[Love2D]: https://love2d.org/
