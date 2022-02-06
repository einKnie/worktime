#!/usr/bin/env bash

# Use this script to track screenlock times

timesheet_path="$HOME/.locktimes"

echo "locking   $(date +"%a %F %T")" >> "$timesheet_path"

i3lock --nofork -u -t -c 000000 -e

echo "unlocking $(date +"%a %F %T")" >> "$timesheet_path"
