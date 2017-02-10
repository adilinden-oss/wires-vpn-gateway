#!/bin/bash
#
# ---
#
# MIT License
# 
# Copyright (c) 2017 Adi Linden
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# 
# ---
#
# To use add to server config
#
# script-security 2
# client-connect scripts/up.sh
# client-disconnect scripts/down.sh
#
# OpenVPN passed the following variables:
#
#   common_name
#   trusted_ip
#   trusted_port
#   ifconfig_pool_remote_ip
#   remote_port_1
#   bytes_received
#   bytes_sent
#
# For testing we process the following commandline args
#
#   -t                              : enable testing mode
#   -a <ifconfig_pool_remote_ip>    : ip for testing
#   -c <common_name>                : cn for testing
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# Define where we look for client specific files
client_dir="up-down.d"

# How we have been called
script=$(basename "$0")

# Pipe iptables through sudo
iptables="sudo iptables"

function Main
{
    # Get command line args (used for testing only)
    parse_args $@

    # Make sure we have needed paramters
    [ -z "$common_name" ] && do_log "Error: common_name is missing"
    [ -z "$ifconfig_pool_remote_ip" ] && do_log "Error: ifconfig_pool_remote_ip is missing"

    # Define useful variables

    # Aliases
    cn="$common_name"

    # For iptables
    remip="${ifconfig_pool_remote_ip}/32"
    chain="OVPN:${common_name^^}"       # to upper
    comment="ovpn:${common_name}"

    do_log "common_name: $common_name, remip: $remip, chain: $chain, comment: $comment"

    # See what we are to do
    case $script in
        up.sh)
            do_script up
            do_log "connected: $cn"
            ;;
        down.sh)
            do_script down
            do_log "disconnected: $cn"
            ;;
    esac
}

##
## Special functions for client scripts
##

function iptables-purge
{
    local c=$1
    local t

    # Remove chain target from system table
    for t in FORWARD INPUT OUTPUT; do
        $iptables -L $t --line-numbers | grep "$c" | sort -r -n  | while read line; do
            num=$(echo "$line" | cut -f 1 -d " ")
            do_cmd "$iptables -D $t $num"
        done
    done

    # Remove actual chain
    if $iptables -L "$c" -n > /dev/null 2>&1 ; then
        do_cmd "$iptables -F $c"
        do_cmd "$iptables -X $c"
    fi
}

##
## Script functions
##

function parse_args
{
    local testaddr
    local testcn

    while [ $1 ]; do
        case $1 in
            -t)
                testmode="yes"
                ;;
            -a)
                testaddr="$2"
                shift
                ;;
            -c)
                testcn="$2"
                shift
                ;;
            *)
                # Proably not in test mode
                ;;
        esac
        shift
    done

    if [ "$testmode" = "yes" ]; then
        common_name="$testcn"
        ifconfig_pool_remote_ip="$testaddr"
        do_log "Using command line args"
    fi
}

function do_script
{
    local action=$1

    # Source client script
    if [ -f "${client_dir}/${common_name}" ]; then
        do_log "Sourcing ${client_dir}/${common_name}"
        source "${client_dir}/${common_name}"
    # Source default script 
    elif [ -f "${client_dir}/default" ]; then
        do_log "Sourcing ${client_dir}/default"
        source "${client_dir}/default"
    else
        do_log "No client config nor default config found"
    fi
}

function do_log
{
    local t="ovpn-$script"
    local p="daemon.info"

    if [ "$testmode" = "yes" ]; then
        echo "Test mode enabled - $1"
    else
        logger -p "$p" -t "$t" "$1"
    fi
}

function do_cmd
{
    local cmd=$1

    do_log "$cmd"
    eval "$cmd"
}

function up
{
    if [ "$action" = "up" ]; then
        do_cmd "$*"
    fi
}

function down
{
    if [ "$action" = "down" ]; then
        do_cmd "$*"
    fi
}

Main $@

# End
