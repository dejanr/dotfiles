{} : ''
# Command to start the locker (should not fork)
locker="i3lock-fancy -p -g"

# Delay in seconds. Note that by default systemd-logind allows a maximum sleep
# delay of 5 seconds.
sleep_delay=1

# Run before starting the locker
pre_lock() {
    #mpc pause
    xset dpms 0 0 10
    return
}

# Run after the locker exits
post_lock() {
    xset -dpms
    return
}

pre_lock

# kill locker if we get killed
trap 'kill %%' TERM INT

if [[ -e /dev/fd/''${XSS_SLEEP_LOCK_FD:--1} ]]; then
    # lock fd is open, make sure the locker does not inherit a copy
    $locker {XSS_SLEEP_LOCK_FD}<&- &

    sleep $sleep_delay

    # now close our fd (only remaining copy) to indicate we're ready to sleep
    exec {XSS_SLEEP_LOCK_FD}<&-
else
    $locker &

    sleep $sleep_delay

    xset dpms force off
fi

wait # for locker to exit

post_lock
''
