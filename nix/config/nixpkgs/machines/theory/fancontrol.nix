{}:

''
INTERVAL=10
DEVPATH=hwmon0=devices/pci0000:00/0000:00:1d.2/0000:3d:00.0 hwmon6=devices/platform/thinkpad_hwmon
DEVNAME=hwmon0=nvme hwmon6=thinkpad
FCTEMPS=hwmon6/pwm1=hwmon0/temp1_input
FCFANS= hwmon6/pwm1=
MINTEMP=hwmon6/pwm1=50
MAXTEMP=hwmon6/pwm1=80
MINSTART=hwmon6/pwm1=50
MINSTOP=hwmon6/pwm1=10
MINPWM=hwmon6/pwm1=10
MAXPWM=hwmon6/pwm1=255
''
