#!/bin/bash

#
# CIS Debian 7 Hardening
#

#
# 2.10 Add nodev Option to /home (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

# Quick factoring as many script use the same logic
PARTITION="/home"
OPTION="nodev"

# This function will be called if the script status is on enabled / audit mode
audit () {
    info "Verifying that $PARTITION is a partition"
    FNRET=0
    is_a_partition "$PARTITION"
    if [ $FNRET -gt 0 ]; then
        crit "$PARTITION is not a partition"
        FNRET=2
    else
        ok "$PARTITION is a partition"
        has_mount_option $PARTITION $OPTION
        if [ $FNRET -gt 0 ]; then
            crit "$PARTITION have no option $OPTION in fstab !"
            FNRET=1
        else
            ok "$PARTITION have $OPTION in fstab"
            has_mounted_option $PARTITION $OPTION
            if [ $FNRET -gt 0 ]; then
                warn "$PARTITION is not mounted with $OPTION at runtime"
                FNRET=3 
            else
                ok "$PARTITION mounted with $OPTION"
            fi
        fi       
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    if [ $FNRET = 0 ]; then
        ok "$PARTITION is correctly set"
    elif [ $FNRET = 2 ]; then
        crit "$PARTITION is not a partition, correct this by yourself, I cannot help you here"
    elif [ $FNRET = 1 ]; then
        info "Adding $OPTION to fstab"
        add_option_to_fstab $PARTITION $OPTION
        info "Remounting $PARTITION from fstab"
        remount_partition $PARTITION
    elif [ $FNRET = 3 ]; then
        info "Remounting $PARTITION from fstab"
        remount_partition $PARTITION
    fi 
}

# This function will check config parameters required
check_config() {
    # No param for this script
    :
}

# Source Root Dir Parameter
if [ ! -r /etc/default/cis-hardening ]; then
    echo "There is no /etc/default/cis-hardening file, cannot source CIS_ROOT_DIR variable, aborting"
    exit 128
else
    . /etc/default/cis-hardening
    if [ -z ${CIS_ROOT_DIR:-} ]; then
        echo "No CIS_ROOT_DIR variable, aborting"
        exit 128
    fi
fi 

# Main function, will call the proper functions given the configuration (audit, enabled, disabled)
if [ -r $CIS_ROOT_DIR/lib/main.sh ]; then
    . $CIS_ROOT_DIR/lib/main.sh
else
    echo "Cannot find main.sh, have you correctly defined your root directory? Current value is $CIS_ROOT_DIR in /etc/default/cis-hardening"
    exit 128
fi