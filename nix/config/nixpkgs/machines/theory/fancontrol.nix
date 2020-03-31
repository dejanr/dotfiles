{}:

''
  INTERVAL=10
  DEVPATH=hwmon0=devices/pci0000:00/0000:00:1d.2/0000:3d:00.0 hwmon4=devices/platform/thinkpad_hwmon
  DEVNAME=hwmon0=nvme hwmon4=thinkpad
  FCTEMPS=hwmon4/pwm1=hwmon0/temp1_input
  FCFANS= hwmon4/pwm1=
  MINTEMP=hwmon4/pwm1=50
  MAXTEMP=hwmon4/pwm1=80
  MINSTART=hwmon4/pwm1=50
  MINSTOP=hwmon4/pwm1=10
  MINPWM=hwmon4/pwm1=10
  MAXPWM=hwmon4/pwm1=255
''
