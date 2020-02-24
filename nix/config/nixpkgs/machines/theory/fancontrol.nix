{}:

''
INTERVAL=5
DEVPATH=hwmon2=devices/virtual/thermal/thermal_zone2 hwmon5=devices/platform/thinkpad_hwmon
DEVNAME=hwmon2=acpitz hwmon5=thinkpad
FCTEMPS=hwmon5/pwm1=hwmon2/temp1_input
FCFANS= hwmon5/pwm1=hwmon5/fan1_input
MINTEMP=hwmon5/pwm1=20
MAXTEMP=hwmon5/pwm1=60
MINSTART=hwmon5/pwm1=150
MINSTOP=hwmon5/pwm1=0
''
