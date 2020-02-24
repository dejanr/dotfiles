{}:

''
INTERVAL=5
DEVPATH=hwmon2=devices/virtual/thermal/thermal_zone2 hwmon5=devices/platform/thinkpad_hwmon
DEVNAME=hwmon2=acpitz hwmon5=thinkpad
FCTEMPS=hwmon5/pwm1=hwmon2/temp1_input
FCFANS= hwmon5/pwm1=hwmon5/fan1_input
MINPWM=10
MINSTART=hwmon0/pwm2=60
MINSTOP=hwmon0/pwm2=50
MAXTEMP=hwmon0/pwm2=100
MAXPWM=250
''
