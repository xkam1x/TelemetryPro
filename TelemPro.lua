-- Get ID of source
local function getTelemtryID(name)
 field = getFieldInfo(name)
 if field then
  return field.id
 end
 return -1
end

-- Function to convert the bytes into a string
local function bytesToString(bytesArray)
 tempString = ""
 for i = 1, 36 do
  if bytesArray[i] == '\0' or bytesArray[i] == nil then
   return tempString
  end
  if bytesArray[i] >= 0x20 and bytesArray[i] <= 0x7f then
   tempString = tempString .. string.char(bytesArray[i])
  end
 end
 return tempString
end

-- Function to get and store the messages from Ardupilot
local function getMessages()
 value = getValue(messagesID)
 if (value ~= nil) and (value ~= 0) and (value ~= messageLastChunk) then
  currentMessageChunks[currentMessageChunkPointer + 1] = bit32.band(bit32.rshift(value, 24), 0x7f)
  currentMessageChunks[currentMessageChunkPointer + 2] = bit32.band(bit32.rshift(value, 16), 0x7f)
  currentMessageChunks[currentMessageChunkPointer + 3] = bit32.band(bit32.rshift(value, 8), 0x7f)
  currentMessageChunks[currentMessageChunkPointer + 4] = bit32.band(value, 0x7f)
  currentMessageChunkPointer = currentMessageChunkPointer + 4
  if (currentMessageChunkPointer > 35) or (currentMessageChunks[currentMessageChunkPointer] == '\0') then
   currentMessageChunkPointer = -1
  end
  if bit32.band(value, 0x80) == 0x80 then
   messageSeverity = messageSeverity + 1
   currentMessageChunkPointer = -1
  end
  if bit32.band(value, 0x8000) == 0x8000 then
   messageSeverity = messageSeverity + 2
   currentMessageChunkPointer = -1
  end
  if bit32.band(value, 0x800000) == 0x800000 then
   messageSeverity = messageSeverity + 4
   currentMessageChunkPointer = -1
  end
  if currentMessageChunkPointer == -1 then
   currentMessageChunkPointer = 0
   if messageLatest == 7 then
    messageLatest = 1
   else
    messageLatest = messageLatest + 1
   end
   messages[messageLatest] = bytesToString(currentMessageChunks)
   messagesAvailable = messagesAvailable + 1
   messageSeverity = messageSeverity + 1
   for i = 1, 36 do
    currentMessageChunks[i] = nil
   end
  end
  messageLastChunk = value
 end
end

-- Function to get and store the Ardupilot Status
local function getApStatus()
 value = getValue(apStatID)
 if value ~= nil then
  currentFlightMode = bit32.band(value, 0x1f)
  -- Assume all flags are false
  simpleFlightModeFlag = false
  superSimpleFlightModeFlag = false
  isFlyingFlag = false
  isArmedFlag = false
  batteryFailSafeFlag = false
  ekfFailSafeFlag = false

  -- Set the flag true if needed
  if bit32.band(bit32.rshift(value, 5), 0x1) == 0x1 then
   simpleFlightModeFlag = true
  end

  if bit32.band(bit32.rshift(value, 6), 0x1) == 0x1 then
   superSimpleFlightModeFlag = true
  end

  if bit32.band(bit32.rshift(value, 7), 0x1) == 0x1 then
  isFlyingFlag = true
  end

  if bit32.band(bit32.rshift(value, 8), 0x1) == 0x1 then
  isArmedFlag = true
  end

  if bit32.band(bit32.rshift(value, 9), 0x1) == 0x1 then
  batteryFailSafeFlag = true
  end

  if bit32.band(bit32.rshift(value, 10), 0x1) == 0x1 then
  ekfFailSafeFlag = true
  end
 end
end

-- Function to get the GPS satellites, lock, hdop, vdop and altitude

local function getGpsStatus()
 value = getValue(gpsStatID)
 if value ~= nil then
  gpsSatellites = bit32.band(value, 0xf)

  gpsStatus = bit32.band(bit32.rshift(value, 4), 0x3)
  gpsHdop = bit32.band(bit32.rshift(value, 7), 0x7f)
  if bit32.band(value, 0x40) ~= 0x40 then
   gpsHdop = gpsHdop / 10
  end

  gpsVdop = bit32.band(bit32.rshift(value, 15), 0x7f)
  if bit32.band(value, 0x4000) ~= 0x4000 then
   gpsVdop = gpsVdop / 10
  end

  gpsAlt = bit32.band(bit32.rshift(value, 24), 0x7f)
  if bit32.band(value, 0x400000) ~= 0x400000 then
   gpsAlt = gpsAlt / 10
  end
  if bit32.band(value, 0x800000) == 0x800000 then
   gpsAlt = gpsAlt * 100
  end
  if bit32.band(value, 0x80000000) == 0x80000000 then
   gpsAlt = gpsAlt * -1
  end
 end
end

-- Function to get the battery voltage, current and consumption

local function getBattStatus()
 value = getValue(battID)
 if value ~= nil then
  batteryVoltage = bit32.band(value, 0x1ff) / 10

  batteryCurrent = bit32.band(bit32.rshift(value, 10), 0x7f)
  if bit32.band(value, 0x200) ~= 0x200 then
   batteryCurrent = batteryCurrent / 10
  end

  batteryMahUsed = bit32.band(bit32.rshift(value, 17), 0x7fff)
 end
end

-- Function to get the home distance, bearing and altitude

local function getHome()
 value = getValue(homeID)
 if value ~= nil then
  homeDistance = bit32.band(bit32.rshift(value, 2), 0x3ff)
  if bit32.band(value, 0x1) == 0x1 then
   homeDistance = homeDistance * 10
  end
  if bit32.band(value, 0x2) == 0x2 then
   homeDistance = homeDistance * 100
  end

  homeAltitude = bit32.band(bit32.rshift(value, 14), 0x3ff)
  if bit32.band(value, 0x1000) ~= 0x1000 then
   homeAltitude = homeAltitude / 10
  end
  if bit32.band(value, 0x2000) == 0x2000 then
   homeAltitude = homeAltitude * 100
  end
  if bit32.band(value, 0x1000000) == 0x1000000 then
   homeAltitude = homeAltitude * -1
  end

  homeBearing = bit32.band(bit32.rshift(value, 25), 0x7f) * 3
 end
end

-- Function to get velocity and yaw

local function getVelocityYaw()
 value = getValue(velocityYawID)
 if value ~= nil then
  verticalVelocity = bit32.band(bit32.rshift(value, 1), 0x7f)
  if bit32.band(value, 0x1) ~= 0x1 then
   verticalVelocity = verticalVelocity / 10
  end
  if bit32.band(value, 0x100) ~= 0x100 then
   verticalVelocity = verticalVelocity * -1
  end

  horizontalVelocity = bit32.band(bit32.rshift(value, 10), 0x7f)
  if bit32.band(value, 0x200) ~= 0x200 then
   horizontalVelocity = horizontalVelocity / 10
  end

  yaw = (bit32.band(bit32.rshift(value, 17), 0x7ff) * 2) / 10
 end
end

-- Function to get roll, pitch and range

local function getAttitudeRange()
 value = getValue(attitudeID)
 if value ~= nil then
  roll = (bit32.band(value, 0x7ff) * 0.2) - 180

  pitch = (bit32.band(bit32.rshift(value, 11), 0x7ff) * 0.2) - 90

  range = bit32.band(bit32.rshift(value, 22), 0x3ff)
  if bit32.band(value, 0x200000) == 0x200000 then
   range = range * 10
  end
 end
end

-- Function to get battery failsafe voltage, battery failsafe capacity and battery pack capacity

local function getParam()
 value = getValue(paramID)
 if value ~= nil then
  if bit32.band(bit32.rshift(value, 24), 0xff) == 0x2 then
   batteryFailsafeVoltage = bit32.band(value, 0xffffff) / 100
  end

  if bit32.band(bit32.rshift(value, 24), 0xff) == 0x3 then
   batteryFailsafeCapacity = bit32.band(value, 0xffffff)
  end

  if bit32.band(bit32.rshift(value, 24), 0xff) == 0x4 then
   batteryPackCapacity = bit32.band(value, 0xffffff)
  end
 end
end

-- Function to get rssi value and scale it linear 0 to 100

local function getSignalStrength()
 value = getValue("RSSI")
 if value ~= nil then
  if value > 38 then
   signalStrength = math.floor(((math.log(value - 28, 10) - 1) / 0.8573324964) * 100)
  else
   signalStrength = 0
  end
 end
end

-- Function to get and parse GPS coordinates

local function getGps()
 table = getValue("GPS")
 if table ~= nil and (type(table) == "table") then
  if table["lat"] ~= nil then
   gpsLatitude = table["lat"]
  end

  if table["lon"] ~= nil then
   gpsLongitude = table["lon"]
  end
 end
end

-- Function to prepare data to be used later

local function calculateStuff()
 -- Battery remaining based on pack capacity and consumed
 if batteryPackCapacity > 0 then
  batteryRemaining = (1 - (batteryMahUsed / batteryPackCapacity)) * 100
  if batteryRemaining < 0 then
   batteryRemaining = 0
  else
   batteryRemaining = math.floor(batteryRemaining)
  end
 end
end

-- This function is responsible for all sounds

local function alertUser()
 -- Message Sevarity Alert
 if messageSeverity > 0 and messageSeverity <= 4 then
 playFile("/TP/MS" .. messageSeverity .. ".wav")
 end
 messageSeverity = -1

 -- Flight Mode ALert
 if lastFlightMode ~= currentFlightMode then
  playFile("/TP/FM" .. currentFlightMode .. ".wav")
  lastFlightMode = currentFlightMode
 end

 -- Armed and Disarmed ALert
 if lastArmedFlag ~= isArmedFlag then
  if isArmedFlag == true then
   playFile("/TP/A1.wav")
  else
   playFile("/TP/A0.wav")
  end
  lastArmedFlag = isArmedFlag
 end

 -- Takeoff and Land Alert
 if isArmedFlag == true then
  if lastFlyingFlag ~= isFlyingFlag then
    if isFlyingFlag == true then
     playFile("/TP/F1.wav")
    else
     playFile("/TP/F0.wav")
    end
  end
 end
 lastFlyingFlag = isFlyingFlag

 -- Continuous alert
 if batteryFailSafeFlag == true or ekfFailSafeFlag == true then
  if (getTime() - continuousAlertTimer) > 1000 then
   if batteryFailSafeFlag == true then
    playFile("/TP/BFS.wav")
   end
   if ekfFailSafeFlag == true then
    playFile("/TP/EKFFS.wav")
   end
   continuousAlertTimer = getTime()
  end
 end

 -- Battery alert
 if batteryRemaining < 30 and batteryFailSafeFlag == false then
  if (getTime() - batteryAlertTimer) > 1000 then
   if batteryRemaining < 30 then
    playFile("/TP/BL.wav")
   elseif batteryRemaining < 20 then
    playFile("/TP/BC.wav")
   end
   batteryAlertTimer = getTime()
  end
 end
end

local function initfunction()
 flightModeName = {}
 flightModeName[1] = "Stablise"
 flightModeName[2] = "Acro"
 flightModeName[3] = "Alt Hold"
 flightModeName[4] = "Auto"
 flightModeName[5] = "Guided"
 flightModeName[6] = "Loiter"
 flightModeName[7] = "RTL"
 flightModeName[8] = "Circle"
 flightModeName[10] = "Land"
 flightModeName[12] = "Drift"
 flightModeName[14] = "Sport"
 flightModeName[15] = "Flip"
 flightModeName[16] = "Auto-Tune"
 flightModeName[17] = "Pos Hold"
 flightModeName[18] = "Brake"
 flightModeName[19] = "Throw"
 flightModeName[20] = "ADSB"
 flightModeName[21] = "Guided No GPS"

 messagesID = getTelemtryID(5000)
 apStatID = getTelemtryID(5001)
 gpsStatID = getTelemtryID(5002)
 battID = getTelemtryID(5003)
 homeID = getTelemtryID(5004)
 velocityYawID = getTelemtryID(5005)
 attitudeID = getTelemtryID(5006)
 paramID = getTelemtryID(5007)

 firstLaunch = true
 currentScreen = 0

 messages = {}
 for i = 1, 7 do
  messages[i] = nil
 end
 currentMessageChunks = {}
 for i = 1, 36 do
  currentMessageChunks[i] = nil
 end
 currentMessageChunkPointer = 0
 messageSeverity = -1
 messageLatest = 0
 messagesAvailable = 0
 messageLastChunk = getValue(messagesID)

 currentFlightMode = 0
 simpleFlightModeFlag = false
 superSimpleFlightModeFlag = false
 isFlyingFlag = false
 isArmedFlag = false
 batteryFailSafeFlag = false
 ekfFailSafeFlag = false

 gpsSatellites = 0
 gpsStatus = 0
 gpsHdop = 100
 gpsVdop = 100
 gpsAlt = 0

 batteryVoltage = 0
 batteryCurrent = 0
 batteryMahUsed = 0

 homeDistance = 0
 homeAltitude = 0
 homeBearing = 0

 verticalVelocity = 0
 horizontalVelocity = 0
 yaw = 0

 roll = 0
 pitch = 0
 range = 0

 batteryFailsafeVoltage = 0
 batteryFailsafeCapacity = 0
 batteryPackCapacity = 0

 signalStrength = 0

 gpsLatitude = 0
 gpsLongitude = 0

 batteryRemaining = 100

 lastFlightMode = 0
 lastArmedFlag = false
 lastFlyingFlag = false
 continuousAlertTimer = 0
 batteryAlertTimer = 0
end

local function defaultHeader()
 -- Page Header Flight Mode
 lcd.drawFilledRectangle(0, 0, 212, 8, FULL)
 if currentFlightMode > 0 then
  lcd.drawText(1, 0, flightModeName[currentFlightMode], INVERS)
 end

 -- Simple, Super Simple Flag
 if simpleFlightModeFlag == true then
  lcd.drawText(lcd.getLastPos(), 0, "+S", INVERS)
 end
 if superSimpleFlightModeFlag == true then
  lcd.drawText(lcd.getLastPos(), 0, "+SS", INVERS)
 end

 -- Armed Flag
 if isArmedFlag == true then
  lcd.drawText(lcd.getLastPos(), 0, "+A", INVERS)
 end

 -- RSSI
 lcd.drawText(172, 0, "RSSI:" .. signalStrength, INVERS)

 -- Battery
 lcd.drawText(128, 0, "Batt:" .. batteryRemaining, INVERS)
end


local function introScreen()
 lcd.clear()
 lcd.drawText(68, 9, "Welcome To", MIDSIZE)
 lcd.drawText(56, 25, "Telemetry Pro", MIDSIZE)
 lcd.drawText(71, 43, "Select Screen", BLINK)
 lcd.drawText(79, 57, "v2 By xkam1x", SMLSIZE)
 lcd.drawText(1, 5, "Overview", 0)
 lcd.drawText(1, 28, "GPS", 0)
 lcd.drawText(170, 5, "Battery", 0)
 lcd.drawText(164, 28, "Messages", 0)
 if firstLaunch == true then
  playFile("/TP/INTRO.wav")
  firstLaunch = false
 end
end

local function overviewScreen()
 lcd.clear()

 -- Battery Icon
 lcd.drawLine(1, 10, 1, 62, SOLID, FORCE)
 lcd.drawLine(30, 10, 30, 62, SOLID, FORCE)
 lcd.drawLine(1, 10, 30, 10, SOLID, FORCE)
 lcd.drawLine(1, 62, 30, 62, SOLID, FORCE)
 lcd.drawLine(1, 62, 30, 62, SOLID, FORCE)
 lcd.drawFilledRectangle(12, 8, 7, 2, FULL)
 lcd.drawFilledRectangle(3, 12, 26, 49, FULL)
 lcd.drawFilledRectangle(3, 12, 26, (100 - batteryRemaining) * 0.49, FULL)

 -- Signal Strength
 lcd.drawLine(180, 20, 180, 62, SOLID, FORCE)
 lcd.drawFilledRectangle(177, 20, 7, 7, SOLID)
 lcd.drawLine(206, 62, 210, 62, SOLID, FORCE)
 lcd.drawLine(200, 62, 204, 62, SOLID, FORCE)
 lcd.drawLine(194, 62, 198, 62, SOLID, FORCE)
 lcd.drawLine(188, 62, 192, 62, SOLID, FORCE)
 lcd.drawLine(182, 62, 186, 62, SOLID, FORCE)
 if signalStrength > 83 then
  lcd.drawFilledRectangle(206, 16, 5, 46, FULL)
 end
 if signalStrength > 66 then
  lcd.drawFilledRectangle(200, 23, 5, 39, FULL)
 end
 if signalStrength > 50 then
  lcd.drawFilledRectangle(194, 33, 5, 29, FULL)
 end
 if signalStrength > 33 then
  lcd.drawFilledRectangle(188, 43, 5, 19, FULL)
 end
 if signalStrength > 17 then
  lcd.drawFilledRectangle(182, 53, 5, 9, FULL)
 end

 -- Flight Mode
 lcd.drawText((106 - ((string.len(flightModeName[currentFlightMode]) * 10) / 2)), 0, flightModeName[currentFlightMode], DBLSIZE)

 -- GPS summary
 if gpsStatus == 0 then
  lcd.drawText(90, 17, "No GPS", 0)
 end
 if gpsStatus == 1 then
  lcd.drawText(79, 17, "No GPS Lock", 0)
 end
 if gpsStatus == 2 then
  if gpsSatellites > 9 then
   lcd.drawText(55, 17, "2D GPS Lock. Sats: " .. gpsSatellites, 0)
  else
   lcd.drawText(58, 17, "2D GPS Lock. Sats: " .. gpsSatellites, 0)
  end
 end
 if gpsStatus == 3 then
  if gpsSatellites > 9 then
   lcd.drawText(55, 17, "3D GPS Lock. Sats: " .. gpsSatellites, 0)
  else
   lcd.drawText(58, 17, "3D GPS Lock. Sats: " .. gpsSatellites, 0)
  end
 end

 -- Home Altitude and Distance
 lcd.drawText(35, 26, "Alt: " .. homeAltitude .. "m", MIDSIZE)
 lcd.drawText(110, 26, "Dst: " .. homeDistance .. "m", MIDSIZE)

 -- Velocity Horizontal and Vertical
 lcd.drawText(35, 46, "VS: " .. verticalVelocity, MIDSIZE)
 value = lcd.getLastPos()
 lcd.drawText(value, 46, "m", SMLSIZE)
 lcd.drawText(value, 51, "s", SMLSIZE)
 lcd.drawText(110, 46, "HS: " .. horizontalVelocity, MIDSIZE)
 value = lcd.getLastPos()
 lcd.drawText(value, 46, "m", SMLSIZE)
 lcd.drawText(value, 51, "s", SMLSIZE)

 -- Simple, Super Simple Flag
 if simpleFlightModeFlag == true then
  lcd.drawText(190, 0, "S", DBLSIZE)
 end
 if superSimpleFlightModeFlag == true then
  lcd.drawText(179, 0, "SS", DBLSIZE)
 end

 -- Armed
 if isArmedFlag == true then
  lcd.drawText(201, 0, "A", DBLSIZE)
 end
end

local function gpsScreen()
 lcd.clear()
 defaultHeader()

 -- GPS Status
 if gpsStatus == 0 then
  lcd.drawText(22, 11, "No GPS or No Telemetry", MIDSIZE + BLINK)
 end
 if gpsStatus == 1 then
  lcd.drawText(64, 11, "No GPS Lock", MIDSIZE)
 end
 if gpsStatus == 2 then
  lcd.drawText(65, 11, "2D GPS Lock", MIDSIZE)
  lcd.drawText(62, 30, "Sats: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, gpsSatellites, 0)
  lcd.drawText(107, 30, "HDOP: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, gpsHdop, 0)
 end
 if gpsStatus == 3 then
  lcd.drawText(65, 11, "3D GPS Lock", MIDSIZE)
  lcd.drawText(10, 30, "Sats: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, gpsSatellites, 0)
  lcd.drawText(55, 30, "HDOP: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, gpsHdop, 0)
  lcd.drawText(105, 30, "VDOP: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, gpsVdop, 0)
  lcd.drawText(155, 30, "Alt: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, gpsAlt, 0)
  lcd.drawText(lcd.getLastPos(), 30, "m", 0)
 end

 -- Latitude and Londitude
 lcd.drawText(29, 47, "Lat: " , 0)
 lcd.drawText(lcd.getLastPos(), 47, gpsLatitude, 0)
 lcd.drawText(109, 47, "Lon: " , 0)
 lcd.drawText(lcd.getLastPos(), 47, gpsLongitude, 0)
end

local function messagesScreen()
 lcd.clear()
 defaultHeader()

 if messagesAvailable == 0 then
  lcd.drawText(46, 25, "No Messages", DBLSIZE)
 else
  if messagesAvailable <= 7 then
   for i = 1, 7 do
    if messages[i] == nil then
     break
    end
    lcd.drawText(0, i * 8, messages[i])
   end
  else
   value = messageLatest
   for i = 1, 7 do
    lcd.drawText(0, 64 - (i * 8), messages[value])
    value = value - 1
    if value == 0 then
     value = 7
    end
   end
  end
 end
end

local function batteryScreen()
 lcd.clear()
 defaultHeader()

 -- Battery Icon
 lcd.drawLine(1, 10, 1, 62, SOLID, FORCE)
 lcd.drawLine(30, 10, 30, 62, SOLID, FORCE)
 lcd.drawLine(1, 10, 30, 10, SOLID, FORCE)
 lcd.drawLine(1, 62, 30, 62, SOLID, FORCE)
 lcd.drawLine(1, 62, 30, 62, SOLID, FORCE)
 lcd.drawFilledRectangle(12, 8, 7, 2, FULL)
 lcd.drawFilledRectangle(3, 12, 26, 49, FULL)
 lcd.drawFilledRectangle(3, 12, 26, ((100 - batteryRemaining) * 0.49), FULL)

 -- Battery Details
 lcd.drawText(35, 10, "Voltage: ", MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 10, batteryVoltage, MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 10, "v", MIDSIZE)
 lcd.drawText(35, 22, "Current: ", MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 22, batteryCurrent, MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 22, "A", MIDSIZE)
 lcd.drawText(35, 34, "Used: ", MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 34, batteryMahUsed, MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 34, "/", MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 34, batteryPackCapacity, MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 34, "mah", MIDSIZE)
 lcd.drawText(35, 56, "FS_V: ", 0)
 lcd.drawText(lcd.getLastPos(), 56, batteryFailsafeVoltage, 0)
 lcd.drawText(lcd.getLastPos(), 56, "v", 0)
 lcd.drawText(110, 56, "FS_C: ", 0)
 lcd.drawText(lcd.getLastPos(), 56, batteryFailsafeCapacity, 0)
 lcd.drawText(lcd.getLastPos(), 56, "mah", 0)
end

-- This function is run by taranis while telemetry screen is hidden
local function backgroundFunction()
 getMessages()
 getApStatus()
 getGpsStatus()
 getBattStatus()
 getHome()
 getVelocityYaw()
 getAttitudeRange()
 getParam()
 getSignalStrength()
 getGps()
 calculateStuff()
end

-- This function is run by taranis while telemetry screen is visible
local function runFunction(event)
 backgroundFunction()
 if currentScreen == 0 then
  introScreen()
 end

 if currentFlightMode > 0 then
  alertUser()
 end

 if currentScreen == 1 then
  if currentFlightMode == 0 then
   lcd.clear()
   lcd.drawText(46, 25, "No Telemetry!", DBLSIZE + BLINK)
  else
   overviewScreen()
  end
 end

 if currentScreen == 2 then
  gpsScreen()
 end

 if currentScreen == 3 then
  if currentFlightMode == 0 then
   lcd.clear()
   lcd.drawText(46, 25, "No Telemetry!", DBLSIZE + BLINK)
  else
   batteryScreen()
  end
 end

 if currentScreen == 4 then
  if currentFlightMode == 0 then
   lcd.clear()
   lcd.drawText(46, 25, "No Telemetry!", DBLSIZE + BLINK)
  else
   messagesScreen()
  end
 end

 if event ~= 0 then
  if event == 64 then
   killEvents(64)
   initfunction()
  end

  if event == 96 then
   -- MENU
   currentScreen = 1
  end

  if event == 99 then
   -- PAGE
   currentScreen = 2
  end

  if event == 100 then
   -- PLUS
   currentScreen = 3
  end

  if event == 101 then
   -- MINUS
   currentScreen = 4
  end
 end
end

return { run=runFunction, init=initfunction, background=backgroundFunction }
