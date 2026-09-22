#!/bin/bash -x

# Cleanup generated files and directories to make rootfs back to clean status
rm -f /etc/passwd-                                  || echo "Failed to clean /etc/passwd-"
rm -f /etc/shadow-                                  || echo "Failed to clean /etc/shadow-"
rm -f /etc/gshadow-                                 || echo "Failed to clean /etc/gshadow-"
rm -f /etc/group-                                   || echo "Failed to clean /etc/group-"
rm -f /etc/default/grub.d/50-cloudimg-settings.cfg  || echo "Failed to clean cloudimg grub.cfg"
rm -rf /var/run/*                                   || echo "Failed to clean /var/run/*"

# To avoid creating incorrect /dev/null,
# if the base rootfs didn't have null node, redirect log to a memory file
redirect_target="/dev/null"
if [ ! -c "${redirect_target}" ]; then
    redirect_target="/tmp/ubuntu-image.cleanup.log"
fi

whitelisted_logs=(/var/log/btmp /var/log/wtmp /var/log/lastlog)
for log in $(find /var/log -type f)
do
    whitelisted=$(echo "${whitelisted_logs[@]}" | grep -o "${log}")
    if [ -z "${whitelisted}" ]; then
        # If logs are belong to someone, clean it. Otherwise, remove it.
        dpkg -S "${log}" > ${redirect_target} 2>&1 &&
            { : > "${log}"; echo "Cleand ${log}"; } ||
            { rm -f "${log}"; echo "Removed ${log}"; }
    else
        # Clean the content of white list logs
        : > "${log}"; echo "Cleaned ${log}"
    fi
done

whitelisted_dirs=(/var/log/journal)
for log_d in $(find /var/log/* -type d)
do
    whitelisted=$(echo "${whitelisted_dirs[@]}" | grep -o "${log_d}")
    if [ -z "${whitelisted}" ]; then
        # If directories are not belong to someone, remove it.
        dpkg -S "${log_d}" > ${redirect_target} 2>&1 || { rm -rf "${log_d}"; echo "Removed ${log_d}"; }
    fi
done

# Clean the tmp directory
rm -rf /tmp/*

rm -- "$0"
