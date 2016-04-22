#!/bin/bash

#
# CIS Debian 7 Hardening
#

#
# 9.3.13 Limit Access via SSH (Scored)
#

set -e # One error, it's over
set -u # One variable unset, it's over

PACKAGE='openssh-server'
FILE='/etc/ssh/sshd_config'

# This function will be called if the script status is on enabled / audit mode
audit () {
    OPTIONS="AllowUsers='$ALLOWED_USERS' AllowGroups='$ALLOWED_GROUPS' DenyUsers='$DENIED_USERS' DenyGroups='$DENIED_GROUPS'"
    is_pkg_installed $PACKAGE
    if [ $FNRET != 0 ]; then
        crit "$PACKAGE is not installed !"
    else
        ok "$PACKAGE is installed"
        for SSH_OPTION in $OPTIONS; do
            SSH_PARAM=$(echo $SSH_OPTION | cut -d= -f 1)
            SSH_VALUE=$(echo $SSH_OPTION | cut -d= -f 2)
            SSH_VALUE=$(sed "s/'//g" <<< $SSH_VALUE)
            PATTERN="^$SSH_PARAM[[:space:]]*$SSH_VALUE"
            does_pattern_exists_in_file $FILE "$PATTERN"
            if [ $FNRET = 0 ]; then
                ok "$PATTERN is present in $FILE"
            else
                crit "$PATTERN is not present in $FILE"
            fi
        done
    fi
}

# This function will be called if the script status is on enabled mode
apply () {
    is_pkg_installed $PACKAGE
    if [ $FNRET = 0 ]; then
        ok "$PACKAGE is installed"
    else
        crit "$PACKAGE is absent, installing it"
        apt_install $PACKAGE
    fi
    for SSH_OPTION in $OPTIONS; do
            SSH_PARAM=$(echo $SSH_OPTION | cut -d= -f 1)
            SSH_VALUE=$(echo $SSH_OPTION | cut -d= -f 2)
            SSH_VALUE=$(sed "s/'//g" <<< $SSH_VALUE)
            PATTERN="^$SSH_PARAM[[:space:]]*$SSH_VALUE"
            does_pattern_exists_in_file $FILE "$PATTERN"
            if [ $FNRET = 0 ]; then
                ok "$PATTERN is present in $FILE"
            else
                warn "$PATTERN not present in $FILE, adding it"
                does_pattern_exists_in_file $FILE "^$SSH_PARAM"
                if [ $FNRET != 0 ]; then
                    add_end_of_file $FILE "$SSH_PARAM $SSH_VALUE"
                else
                    info "Parameter $SSH_PARAM is present but with the wrong value, correcting"
                    replace_in_file $FILE "^$SSH_PARAM[[:space:]]*.*" "$SSH_PARAM $SSH_VALUE"
                fi
                /etc/init.d/ssh reload
            fi
    done
}

# This function will check config parameters required
check_config() {
    if [ -z $ALLOWED_USERS ]; then
        info "ALLOWED_USERS is not set, defaults to wildcard"
        ALLOWED_USERS="*"
    fi
    if [ -z $ALLOWED_GROUPS ]; then
        info "ALLOWED_GROUPS is not set, defaults to wildcard"
        ALLOWED_GROUPS="*"
    fi
    if [ -z $DENIED_USERS ]; then
        info "DENIED_USERS is not set, defaults to nobody"
        DENIED_USERS="nobody"
    fi
    if [ -z $DENIED_GROUPS ]; then
        info "DENIED_GROUPS is not set, defaults to nobody"
        DENIED_GROUPS="nobody"
    fi
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