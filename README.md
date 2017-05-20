Telemetry Pro!
=

This is a telemetry app/script that runs on FrSky Taranis X9D/X9D+ which uses ArduPilot Passthrough telemetry. More information here http://ardupilot.org/copter/docs/common-frsky-telemetry.html

Requirements:
-

1. Flight Controller capable of running ArduPilot firmware version 3.4 or above.
2. FrSky Taranis radio running OpenTX version 2.1.7 or above.
3. FrSky X-series receiver with smart-port capability.
4. Serial TTL to RS232 converter cable.

Prep-Flight Controller:
-

1.  Connect the flight controller to computer and navigate param list and set SERIAL4_PROTOCOL to 10 or FrSky Passthrough.
2. Connect the Telemetry Cable between Serial 4/5 port on pixhawk and smart port on your receiver. (Look at images if you wish to make your own!!)

Prep-Radio:
-

1. Mount the Taranis SD Card and navigate to '/SCRIPTS/TELEMETRY/'. If such folders are not present, create them.
2. Copy the file TelemPro.lua into '/SCRIPTS/TELEMETRY/'.
3. Copy the folder 'TP' to SD Card root.
4. Verify Receiver is paired and navigate to 'TELEMETRY' screen. MENU (single press) -> PAGE (Long Press).
5. Activate 'Delete all sensors',  verify 'Ignore instances' is checked and activate 'Discover new sensors'.
6. Power up and Arm the model.
7. Disarm the model and remove power.
8. At this point you should have sensors listed from 5000 to 5007, RSSI and GPS.
9. If there are no sensors detected, verify flight controller preparation is complete.
10. Navigate to Screen 1 and select Script then select TelemPro.
11. All done. Now you can run the script by holding 'PAGE' while on model home screen.

Samples:
-

![Alt text](https://github.com/xkam1x/TelemetryPro/blob/master/screenshot-1.png?raw=true)
![Alt text](https://github.com/xkam1x/TelemetryPro/blob/master/screenshot-2.png?raw=true)
![Alt text](https://github.com/xkam1x/TelemetryPro/blob/master/screenshot-3.png?raw=true)
![Alt text](https://github.com/xkam1x/TelemetryPro/blob/master/screenshot-4.png?raw=true)
![Alt text](https://github.com/xkam1x/TelemetryPro/blob/master/screenshot-5.png?raw=true)
