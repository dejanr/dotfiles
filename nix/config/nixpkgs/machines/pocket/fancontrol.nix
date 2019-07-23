{}:

''
INTERVAL=10
DEVPATH=hwmon0=devices/platform/nct6775.656 hwmon1=devices/pci0000:00/0000:00:18.3
DEVNAME=hwmon0=nct6793 hwmon1=k10temp
FCTEMPS=hwmon0/pwm2=hwmon1/temp1_input
FCFANS= hwmon0/pwm2=hwmon0/fan2_input
MINTEMP=hwmon0/pwm2=50
MINPWM=50
MINSTART=hwmon0/pwm2=80
MINSTOP=hwmon0/pwm2=50
MAXTEMP=hwmon0/pwm2=80
MAXPWM=240
''
