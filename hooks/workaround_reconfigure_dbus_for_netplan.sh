#!/bin/bash -x

# This is a workaround for LP#1942037
# The group of the file(/usr/lib/dbus-1.0/dbus-daemon-launch-helper)
# is incorrect
#   $ ls -lah /usr/lib/dbus-1.0/dbus-daemon-launch-helper
#   -rwsr-xr-- 1 root uuidd 66K Aug  9  2024 /usr/lib/dbus-1.0/dbus-daemon-launch-helper
# However, the database indicate the group of the file is correctly set
#   $ dpkg-statoverride --list /usr/lib/dbus-1.0/dbus-daemon-launch-helper
#   root messagebus 4754 /usr/lib/dbus-1.0/dbus-daemon-launch-helper
# So removing the database and reconfigure dbus is able to fix the issue
dpkg-statoverride --remove /usr/lib/dbus-1.0/dbus-daemon-launch-helper
dpkg-reconfigure dbus

rm -- "$0"
