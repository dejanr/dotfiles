{config, pkgs, ...}:
{
  services.throttled = {
    enable = true;
    extraConfig = ''
[GENERAL]
# Enable or disable the script execution
Enabled: True
# SYSFS path for checking if the system is running on AC power
Sysfs_Power_Path: /sys/class/power_supply/AC*/online

## Settings to apply while connected to Battery power
[BATTERY]
# Update the registers every this many seconds
Update_Rate_s: 30
# Max package power for time window #1
PL1_Tdp_W: 29
# Time window #1 duration
PL1_Duration_s: 28
# Max package power for time window #2
PL2_Tdp_W: 44
# Time window #2 duration
PL2_Duration_S: 0.002
# Max allowed temperature before throttling
Trip_Temp_C: 85
# Set cTDP to normal=0, down=1 or up=2 (EXPERIMENTAL)
cTDP: 0

## Settings to apply while connected to AC power
[AC]
# Update the registers every this many seconds
Update_Rate_s: 5
# Max package power for time window #1
PL1_Tdp_W: 44
# Time window #1 duration
PL1_Duration_s: 28
# Max package power for time window #2
PL2_Tdp_W: 44
# Time window #2 duration
PL2_Duration_S: 0.002
# Max allowed temperature before throttling
Trip_Temp_C: 97
# Set HWP energy performance hints to 'performance' on high load (EXPERIMENTAL)
HWP_Mode: true
# Set cTDP to normal=0, down=1 or up=2 (EXPERIMENTAL)
cTDP: 0

[UNDERVOLT.BATTERY]
# CPU core voltage offset (mV)
CORE: 0
# Integrated GPU voltage offset (mV)
GPU: 0
# CPU cache voltage offset (mV)
CACHE: 0
# System Agent voltage offset (mV)
UNCORE: 0
# Analog I/O voltage offset (mV)
ANALOGIO: 0

[UNDERVOLT.AC]
# CPU core voltage offset (mV)
CORE: 0
# Integrated GPU voltage offset (mV)
GPU: 0
# CPU cache voltage offset (mV)
CACHE: 0
# System Agent voltage offset (mV)
UNCORE: 0
# Analog I/O voltage offset (mV)
ANALOGIO: 0
    '';
  };
}
