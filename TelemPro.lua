-- Structure where all the d is stored

d = {}

-- Flight Mode names

flightModeName = {}

-- Global variables to temporarily store values

t_v = 0
t_v_1 = 0
t_v_2 = 0
t_s = nil

-- Get ID of source

local function get_telem_id(name)
 t_v = getFieldInfo(name)
 if t_v then
  return t_v.id
 end
 return -1
end

-- Function to convert the bytes into a string

local function bytes_to_string(bytes_array)
 t_s = ""
 for i = 1, 36 do
  if bytes_array[i] == '\0' or bytes_array[i] == nil then
   return t_s
  end
  if bytes_array[i] >= 0x20 and bytes_array[i] <= 0x7f then
   t_s = t_s .. string.char(bytes_array[i])
  end
 end
 return t_s
end

-- Function to get and store the messages from Ardupilot

local function get_messages()
 t_v = getValue(d.m_id)
 if t_v ~= nil and t_v ~= d.l_m_c and t_v ~= 0 then
  d.c_m_c[d.c_m_c_p + 1] = bit32.band(bit32.rshift(t_v, 24), 0x7f)
  d.c_m_c[d.c_m_c_p + 2] = bit32.band(bit32.rshift(t_v, 16), 0x7f)
  d.c_m_c[d.c_m_c_p + 3] = bit32.band(bit32.rshift(t_v, 8), 0x7f)
  d.c_m_c[d.c_m_c_p + 4] = bit32.band(t_v, 0x7f)
  d.c_m_c_p = d.c_m_c_p + 4
  if d.c_m_c_p >= 36 then
   d.c_m_c_f = true
  end
  if d.c_m_c[d.c_m_c_p] == '\0' then
   d.c_m_c_f = true
  end
  if bit32.band(t_v, 0x80) == 0x80 then
   d.m_s = d.m_s + 1
   d.c_m_c_f = true
  end
  if bit32.band(t_v, 0x8000) == 0x8000 then
   d.m_s = d.m_s + 2
   d.c_m_c_f = true
  end
  if bit32.band(t_v, 0x800000) == 0x800000 then
   d.m_s = d.m_s + 4
   d.c_m_c_f = true
  end
  if d.c_m_c_f == true then
   d.c_m_c_f = false
   d.c_m_c[d.c_m_c_p + 1] = nil
   if d.m_l == 7 then
    d.m_l = 1
   else
    d.m_l = d.m_l + 1
   end
   d.m[d.m_l] = bytes_to_string(d.c_m_c)
   d.m_a = d.m_a + 1
   d.c_m_c_p = 0
   d.m_s = d.m_s + 1
  end
  d.l_m_c = t_v
 end
end

-- Function to get and store the Ardupilot Status

local function get_ap_status()
 t_v = getValue(d.ap_s_id)
 if t_v ~= nil then
  d.f_m = bit32.band(t_v, 0x1f)
  d.s_s_s_f = bit32.band(bit32.rshift(t_v, 4), 0x6)
  d.i_f_f = bit32.band(bit32.rshift(t_v, 7), 0x1)
  d.i_a_f = bit32.band(bit32.rshift(t_v, 8), 0x1)
  d.b_fs_f = bit32.band(bit32.rshift(t_v, 9), 0x1)
  d.ekf_fs_f = bit32.band(bit32.rshift(t_v, 10), 0x1)
 end
end

-- Function to get the GPS satellites, lock, hdop, vdop and altitude

local function get_gps_status()
 t_v = getValue(d.gps_s_id)
 if t_v ~= nil then
  d.gps_sats = bit32.band(t_v, 0xf)

  d.gps_stat = bit32.band(bit32.rshift(t_v, 4), 0x3)

  t_v_1 = bit32.band(bit32.rshift(t_v, 6), 0x1ff)
  d.gps_hdop = bit32.band(bit32.rshift(t_v_1, 1), 0x7f)
  if bit32.band(t_v_1, 0x1) ~= 0x1 then
   d.gps_hdop = d.gps_hdop / 10
  end
  if bit32.band(t_v_1, 0x100) == 0x100 then
   d.gps_hdop = d.gps_hdop * -1
  end

  t_v_1 = bit32.band(bit32.rshift(t_v, 14), 0x1ff)
  d.gps_vdop = bit32.band(bit32.rshift(t_v_1, 1), 0x7f)
  if bit32.band(t_v_1, 0x1) ~= 0x1 then
   d.gps_vdop = d.gps_vdop / 10
  end
  if bit32.band(t_v_1, 0x100) == 0x100 then
   d.gps_vdop = d.gps_vdop * -1
  end

  t_v_1 = bit32.band(bit32.rshift(t_v, 22), 0x3ff)
  d.gps_alt = bit32.band(bit32.rshift(t_v_1, 2), 0x7f)
  t_v_2 = bit32.band(t_v_1, 0x3)
  if t_v_2 > 0 then
   d.gps_alt = d.gps_alt * math.pow(10, t_v_2)
  end
  d.gps_alt = d.gps_alt / 10
  if bit32.band(t_v_1, 0x200) == 0x200 then
  d.gps_alt = d.gps_alt * -1
  end
 end
end

-- Function to get the battery voltage, current and consumption

local function get_batt()
 t_v = getValue(d.bat_id)
 if t_v ~= nil then
  d.bat_v = bit32.band(t_v, 0x1FF)
  d.bat_v = d.bat_v / 10

  t_v_1 = bit32.band(bit32.rshift(t_v, 9), 0xff)
  d.bat_cur = bit32.band(bit32.rshift(t_v_1, 1), 0x7f)
  if bit32.band(t_v_1, 0x1) ~= 0x1 then
   d.bat_cur = d.bat_cur / 10
  end
  if bit32.band(t_v_1, 0x100) == 0x100 then
   d.bat_cur = d.bat_cur * -1
  end

  d.bat_con = bit32.band(bit32.rshift(t_v, 17), 0x7fff)
 end
end

-- Function to get the home distance, bearing and altitude

local function get_home()
 t_v = getValue(d.hm_id)
 if t_v ~= nil then
  t_v_1 = bit32.band(t_v, 0x1fff)
  d.hm_dst = bit32.band(bit32.rshift(t_v_1, 2), 0x3ff)
  t_v_2 = bit32.band(t_v_1, 0x3)
  if t_v_2 > 0 then
   d.hm_dst = d.hm_dst * math.pow(10, t_v_2)
  end
  d.hm_dst = d.hm_dst / 10

  t_v_1 = bit32.band(bit32.rshift(t_v, 12), 0x1fff)
  d.hm_alt = bit32.band(bit32.rshift(t_v_1, 2), 0x3ff)
  t_v_2 = bit32.band(t_v_1, 0x3)
  if t_v_2 > 0 then
   d.hm_alt = d.hm_alt * math.pow(10, t_v_2)
  end
  d.hm_alt = d.hm_alt / 10
  if bit32.band(t_v_1, 0x1000) == 0x1000 then
   d.hm_alt = d.hm_alt * -1
  end

  t_v_1 = bit32.band(bit32.rshift(t_v, 25), 0x7f)
  d.hm_direc = t_v_1 * 3
 end
end

-- Function to get velocity and yaw

local function get_velandyaw()
 t_v = getValue(d.vy_id)
 if t_v ~= nil then
  t_v_1 = bit32.band(t_v, 0x1ff)
  d.v_v = bit32.band(bit32.rshift(t_v_1, 1), 0x7f)
  if bit32.band(t_v_1, 0x1) ~= 0x1 then
   d.v_v = d.v_v / 10
  end
  if bit32.band(t_v_1, 0x100) ~= 0x100 then
   d.v_v = d.v_v * -1
  end

  t_v_1 = bit32.band(bit32.rshift(t_v, 9), 0x1ff)
  d.h_v = bit32.band(bit32.rshift(t_v_1, 1), 0x7f)
  if bit32.band(t_v_1, 0x1) ~= 0x1 then
   d.h_v = d.h_v / 10
  end
  if bit32.band(t_v_1, 0x100) == 0x100 then
   d.h_v = d.h_v * -1
  end

  t_v_1 = bit32.band(bit32.rshift(t_v, 17), 0x7ff)
  d.yaw = (t_v_1 * 2) / 10

 end
end

-- function to get roll, pitch and range

--local function get_attiandrng()
-- t_v = getValue(d.att_r_id)
-- if t_v ~= nil then
--  t_v_1 = bit32.band(t_v, 0x7ff)
--  d.roll = (t_v_1 * 0.2) - 180

--  t_v_1 = bit32.band(bit32.rshift(t_v, 11), 0x3ff)
--  d.pitch = (t_v_1 * 0.2) - 90

--  t_v_1 = bit32.band(bit32.rshift(t_v, 21), 0x7ff)
--  d.range = bit32.band(bit32.rshift(t_v_1, 1), 0x3ff)
--  if bit32.band(t_v_1, 0x1) == 0x1 then
--   d.range = d.range * 10
--  end
--  d.range = d.range / 100
--  if bit32.band(t_v_1, 0x400) == 0x400 then
--   d.range = d.range * -1
--  end
-- end
--end

-- Function to get mav type, battery failsafe voltage, battery failsafe capacity and battery pack capacity

local function get_param()
 t_v = getValue(d.p_id)
 if t_v ~= nil then
  t_v_1 = bit32.band(bit32.rshift(t_v, 24), 0xff)
  if t_v_1 == 1 then
   d.mav_type = bit32.band(t_v, 0xffffff)
  end
  if t_v_1 == 2 then
   d.bat_fs_v = bit32.band(t_v, 0xffffff)
   d.bat_fs_v = d.bat_fs_v / 100
  end
  if t_v_1 == 3 then
   d.bat_fs_cap = bit32.band(t_v, 0xffffff)
  end
  if t_v_1 == 4 then
   d.bat_p_cap = bit32.band(t_v, 0xffffff)
  end
 end
end

-- Function to get rssi value and scale it linear 0 to 100

local function get_rssi()
 t_v = getValue("RSSI")
 if t_v ~= nil then
  if t_v > 38 then
   d.rssi = math.floor(((math.log(t_v - 28, 10) - 1) / 0.8573324964) * 100)
  else
   d.rssi = 0
  end
 end
end

-- Function to get and parse GPS coordinates

local function get_gps()
 t_v = getValue("GPS")
 if t_v ~= nil and (type(t_v) == "table") then
  t_v_1 = t_v["lat"]
  t_v_2 = t_v["lon"]
  if t_v_1 ~= nil then
   d.gps_lat = t_v_1
  end
  if t_v_2 ~= nil then
   d.gps_lon = t_v_2
  end
 end
end

-- Look at me I'm doing math stuff

local function do_math()
-- Battery remaining based on pack capacity and consumed
 if d.bat_p_cap > 0 then
  t_v = (1 - (d.bat_con / d.bat_p_cap)) * 100
  if t_v < 0 then
   d.bat_r = 0
  else
   d.bat_r = math.floor(t_v)
  end
 else
  d.bat_p_cap = 0
 end
end

-- This function is responsible for all sounds

local function alert_user()
-- Message Sevarity Alert
 if d.m_s > 0 and d.m_s <= 4 then
  t_s = "/TP/MS" .. d.m_s .. ".wav"
  playFile(t_s)
 end
 d.m_s = -1

-- Flight Mode ALert
 if d.l_f_m ~= d.f_m then
  t_s = "/TP/FM" .. d.f_m .. ".wav"
  playFile(t_s)
  d.l_f_m = d.f_m
 end

-- Armed and Disarmed ALert
 if d.i_a_f ~= d.l_a_s then
  t_s = "/TP/A" .. d.i_a_f .. ".wav"
  playFile(t_s)
 end
 d.l_a_s = d.i_a_f

-- Takeoff and Land Alert
 if d.i_a_f == 1 then
  if d.i_f_f ~= d.l_i_f_s then
   t_s = "/TP/F" .. d.i_f_f .. ".wav"
   playFile(t_s)
  end
 end
 d.l_i_f_s = d.i_f_f

-- Fail Safe alert
 if d.b_fs_f == 1 or d.ekf_fs_f == 1 then
  if (getTime() - d.fs_a_t) > 1000 then
   if d.b_fs_f == 1 then
    playFile("/TP/BFS.wav")
   end
   if d.ekf_fs_f == 1 then
    playFile("/TP/EKFFS.wav")
   end
   d.fs_a_t = getTime()
  end
 end

-- Battery level alert
 if d.bat_r < 31 and (getTime() - d.bat_a_t) > 1000 then
  if d.bat_r < 20 then
   playFile("/TP/BC.wav")
  else
   playFile("/TP/BL.wav")
  end
  if d.bat_a > 30 and d.bat_r == 30 then
   playFile("/TP/30R.wav")
   d.bat_a = 30
  end
  if d.bat_a > 20 and d.bat_r == 20 then
   playFile("/TP/20R.wav")
   d.bat_a = 20
  end
  if d.bat_a > 10 and d.bat_r == 10 then
   playFile("/TP/10R.wav")
   d.bat_a = 10
  end
  d.bat_a_t = getTime()
 end
end

local function init_func()
 d.m_v = 1

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

 d.m_id = get_telem_id(5000)
 d.ap_s_id = get_telem_id(5001)
 d.gps_s_id = get_telem_id(5002)
 d.bat_id = get_telem_id(5003)
 d.hm_id = get_telem_id(5004)
 d.vy_id = get_telem_id(5005)
 --d.att_r_id = get_telem_id(5006)
 d.p_id = get_telem_id(5007)

 d.f_t = 1

 d.c_s = 0

 d.m = {}
 for i = 1, 7 do
  d.m[i] = nil
 end
 d.c_m_c = {}
 for i = 1, 35 do
  d.c_m_c[i] = nil
 end
 d.c_m_c_p = 0
 d.c_m_c_f = false
 d.l_m_c = 0
 d.m_s = -1
 d.m_l = 0
 d.m_a = 0

 d.f_m = 0
 d.s_s_s_f = 0
 d.i_f_f = 0
 d.i_a_f = 0
 d.b_fs_f = 0
 d.ekf_fs_f = 0

 d.gps_sats = 0
 d.gps_stat = 0
 d.gps_hdop = 100
 d.gps_vdop = 100
 d.gps_alt = 0

 d.bat_v = 0
 d.bat_cur = 0
 d.bat_con = 0

 d.hm_dst = 0
 d.hm_alt = 0
 d.hm_direc = 0

 d.v_v = 0
 d.h_v = 0
 d.yaw = 0

 --d.roll = 0
 --d.pitch = 0
 --d.range = 0

 d.mav_type = 0
 d.bat_fs_v = 0
 d.bat_fs_cap = 0
 d.bat_p_cap = 0

 d.rssi = 0

 d.gps_lat = 0
 d.gps_lon = 0

 d.bat_r = 0

 d.l_f_m = 0
 d.l_a_s = 0
 d.l_i_f_s = 0

 d.fs_a_t = 0
 d.bat_a = 100
 d.bat_a_t = 0
end

local function default_header()
-- Page Header Flight Mode
 lcd.drawFilledRectangle(0, 0, 212, 8, FULL)
 if d.f_m > 0 then
  lcd.drawText(1, 0, flightModeName[d.f_m], INVERS)
 end

-- Simple, Super Simple Flag
 if d.s_s_s_f == 2 then
  lcd.drawText(lcd.getLastPos(), 0, "+S", INVERS)
 end
 if d.s_s_s_f == 4 then
  lcd.drawText(lcd.getLastPos(), 0, "+SS", INVERS)
 end

-- Armed Flag
 if d.i_a_f == 1 then
  lcd.drawText(lcd.getLastPos(), 0, "+A", INVERS)
 end

-- RSSI
 lcd.drawText(172, 0, "RSSI:" .. d.rssi, INVERS)

-- Battery
 lcd.drawText(128, 0, "Batt:" .. d.bat_r, INVERS)
end

local function intro_screen()
 lcd.clear()
 lcd.drawText(68, 9, "Welcome To", MIDSIZE)
 lcd.drawText(56, 25, "Telemetry Pro", MIDSIZE)
 lcd.drawText(71, 43, "Select Screen", BLINK)
 lcd.drawText(79, 57, "v" .. d.m_v .. " By xkam1x", SMLSIZE)
 lcd.drawText(1, 5, "Overview", 0)
 lcd.drawText(1, 28, "GPS", 0)
 lcd.drawText(170, 5, "Battery", 0)
 lcd.drawText(164, 28, "Messages", 0)
 if d.f_t == 1 then
  playFile("/TP/INTRO.wav")
  d.f_t = 0
 end
end

local function overview_screen()
 lcd.clear()

-- Battery Icon
 lcd.drawLine(1, 10, 1, 62, SOLID, FORCE)
 lcd.drawLine(30, 10, 30, 62, SOLID, FORCE)
 lcd.drawLine(1, 10, 30, 10, SOLID, FORCE)
 lcd.drawLine(1, 62, 30, 62, SOLID, FORCE)
 lcd.drawLine(1, 62, 30, 62, SOLID, FORCE)
 lcd.drawFilledRectangle(12, 8, 7, 2, FULL)
 lcd.drawFilledRectangle(3, 12, 26, 49, FULL)
 t_v = (100 - d.bat_r) * 0.49
 lcd.drawFilledRectangle(3, 12, 26, t_v, FULL)

-- Signal Strength
 lcd.drawLine(180, 20, 180, 62, SOLID, FORCE)
 lcd.drawFilledRectangle(177, 20, 7, 7, SOLID)
 lcd.drawLine(206, 62, 210, 62, SOLID, FORCE)
 lcd.drawLine(200, 62, 204, 62, SOLID, FORCE)
 lcd.drawLine(194, 62, 198, 62, SOLID, FORCE)
 lcd.drawLine(188, 62, 192, 62, SOLID, FORCE)
 lcd.drawLine(182, 62, 186, 62, SOLID, FORCE)
 if d.rssi > 83 then
  lcd.drawFilledRectangle(206, 16, 5, 46, FULL)
 end
 if d.rssi > 66 then
  lcd.drawFilledRectangle(200, 23, 5, 39, FULL)
 end
 if d.rssi > 50 then
  lcd.drawFilledRectangle(194, 33, 5, 29, FULL)
 end
 if d.rssi > 33 then
  lcd.drawFilledRectangle(188, 43, 5, 19, FULL)
 end
 if d.rssi > 17 then
  lcd.drawFilledRectangle(182, 53, 5, 9, FULL)
 end

-- Flight Mode
 t_v = 106 - ((string.len(flightModeName[d.f_m]) * 10) / 2)
 lcd.drawText(t_v, 0, flightModeName[d.f_m], DBLSIZE)

-- GPS summary
 if d.gps_stat == 0 then
  lcd.drawText(90, 17, "No GPS", 0)
 end
 if d.gps_stat == 1 then
  lcd.drawText(79, 17, "No GPS Lock", 0)
 end
 if d.gps_stat == 2 then
  if d.gps_sats > 9 then
   lcd.drawText(55, 17, "2D GPS Lock. Sats: " .. d.gps_sats, 0)
  else
   lcd.drawText(58, 17, "2D GPS Lock. Sats: " .. d.gps_sats, 0)
  end
 end
 if d.gps_stat == 3 then
  if d.gps_sats > 9 then
   lcd.drawText(55, 17, "3D GPS Lock. Sats: " .. d.gps_sats, 0)
  else
   lcd.drawText(58, 17, "3D GPS Lock. Sats: " .. d.gps_sats, 0)
  end
 end

-- Home Altitude and Distance
 lcd.drawText(35, 26, "Alt: " .. d.hm_alt .. "m", MIDSIZE)
 lcd.drawText(110, 26, "Dst: " .. d.hm_dst .. "m", MIDSIZE)

-- Velocity Horizontal and Vertical
 lcd.drawText(35, 46, "VS: " .. d.v_v, MIDSIZE)
 t_v = lcd.getLastPos()
 lcd.drawText(t_v, 46, "m", SMLSIZE)
 lcd.drawText(t_v, 51, "s", SMLSIZE)
 lcd.drawText(110, 46, "HS: " .. d.h_v, MIDSIZE)
 t_v = lcd.getLastPos()
 lcd.drawText(t_v, 46, "m", SMLSIZE)
 lcd.drawText(t_v, 51, "s", SMLSIZE)

-- Simple, Super Simple Flag
 if d.s_s_s_f == 2 then
  lcd.drawText(190, 0, "S", DBLSIZE)
 end
 if d.s_s_s_f == 4 then
  lcd.drawText(179, 0, "SS", DBLSIZE)
 end

-- Armed
 if d.i_a_f == 1 then
  lcd.drawText(201, 0, "A", DBLSIZE)
 end
end

local function gps_screen()
 lcd.clear()
 default_header()

-- GPS Status
 if d.gps_stat == 0 then
  lcd.drawText(22, 11, "No GPS or No Telemetry", MIDSIZE + BLINK)
 end
 if d.gps_stat == 1 then
  lcd.drawText(64, 11, "No GPS Lock", MIDSIZE)
 end
 if d.gps_stat == 2 then
  lcd.drawText(65, 11, "2D GPS Lock", MIDSIZE)
  lcd.drawText(62, 30, "Sats: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, d.gps_sats, 0)
  lcd.drawText(107, 30, "HDOP: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, d.gps_hdop, 0)
 end
 if d.gps_stat == 3 then
  lcd.drawText(65, 11, "3D GPS Lock", MIDSIZE)
  lcd.drawText(10, 30, "Sats: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, d.gps_sats, 0)
  lcd.drawText(55, 30, "HDOP: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, d.gps_hdop, 0)
  lcd.drawText(105, 30, "VDOP: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, d.gps_vdop, 0)
  lcd.drawText(155, 30, "Alt: ", 0)
  lcd.drawText(lcd.getLastPos(), 30, d.gps_alt, 0)
  lcd.drawText(lcd.getLastPos(), 30, "m", 0)
 end

-- Latitude and Londitude
 lcd.drawText(29, 47, "Lat: " , 0)
 lcd.drawText(lcd.getLastPos(), 47, d.gps_lat, 0)
 lcd.drawText(109, 47, "Lon: " , 0)
 lcd.drawText(lcd.getLastPos(), 47, d.gps_lon, 0)
end

local function messages_screen()
 lcd.clear()
 default_header()

-- Messages
 if d.m_a == 0 then
  lcd.drawText(46, 25, "No Messages", DBLSIZE)
 else
  if d.m_a <= 7 then
   for i = 1, 7 do
    if d.m[i] == nil then
     break
    end
    lcd.drawText(0, i * 8, d.m[i])
   end
  else
   t_v = d.m_l
    for i = 1, 7 do
     lcd.drawText(0, 64 - (i * 8), d.m[t_v])
     t_v = t_v - 1
     if t_v == 0 then
      t_v = 7
    end
   end
  end
 end
end

local function battery_screen()
 lcd.clear()
 default_header()

-- Battery Icon
 lcd.drawLine(1, 10, 1, 62, SOLID, FORCE)
 lcd.drawLine(30, 10, 30, 62, SOLID, FORCE)
 lcd.drawLine(1, 10, 30, 10, SOLID, FORCE)
 lcd.drawLine(1, 62, 30, 62, SOLID, FORCE)
 lcd.drawLine(1, 62, 30, 62, SOLID, FORCE)
 lcd.drawFilledRectangle(12, 8, 7, 2, FULL)
 lcd.drawFilledRectangle(3, 12, 26, 49, FULL)
 t_v = (100 - d.bat_r) * 0.49
 lcd.drawFilledRectangle(3, 12, 26, t_v, FULL)

-- Battery Details
 lcd.drawText(35, 10, "Voltage: ", MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 10, d.bat_v, MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 10, "v", MIDSIZE)
 lcd.drawText(35, 22, "Current: ", MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 22, d.bat_cur, MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 22, "A", MIDSIZE)
 lcd.drawText(35, 34, "Used: ", MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 34, d.bat_con, MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 34, "/", MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 34, d.bat_p_cap, MIDSIZE)
 lcd.drawText(lcd.getLastPos(), 34, "mah", MIDSIZE)
 lcd.drawText(35, 56, "FS_V: ", 0)
 lcd.drawText(lcd.getLastPos(), 56, d.bat_fs_v, 0)
 lcd.drawText(lcd.getLastPos(), 56, "v", 0)
 lcd.drawText(110, 56, "FS_C: ", 0)
 lcd.drawText(lcd.getLastPos(), 56, d.bat_fs_cap, 0)
 lcd.drawText(lcd.getLastPos(), 56, "mah", 0)
end

-- This function is run by taranis while telemetry screen is hidden

local function background_func()
 get_messages()
 get_ap_status()
 get_gps_status()
 get_batt()
 get_home()
 get_velandyaw()
 --get_attiandrng()
 get_param()
 get_rssi()
 get_gps()
 do_math()
end

-- This function is run by taranis while telemetry screen is visible

local function run_func(event)
 background_func()
 if d.c_s == 0 then
  intro_screen()
 end
 if d.f_m > 0 then
  alert_user()
 end

 if d.c_s == 1 then
  if d.f_m == 0 then
   lcd.clear()
   lcd.drawText(46, 25, "No Telemetry!", DBLSIZE + BLINK)
  else
   overview_screen()
  end
 end

 if d.c_s == 2 then
   gps_screen()
 end

 if d.c_s == 3 then
  if d.f_m == 0 then
   lcd.clear()
   lcd.drawText(46, 25, "No Telemetry!", DBLSIZE + BLINK)
  else
   battery_screen()
  end
 end

 if d.c_s == 4 then
  if d.f_m == 0 then
   lcd.clear()
   lcd.drawText(46, 25, "No Telemetry!", DBLSIZE + BLINK)
  else
   messages_screen()
  end
 end

 if event ~= 0 then
  if event == 64 then
   killEvents(64)
   init_func()
  end
  if event == 96 then
   -- MENU
   d.c_s = 1
  end
  if event == 99 then
   -- PAGE
   d.c_s = 2
  end
  if event == 100 then
   -- PLUS
   d.c_s = 3
  end
  if event == 101 then
   -- MINUS
   d.c_s = 4
  end
 end
end

return { run=run_func, init=init_func, background=background_func }
