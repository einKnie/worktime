#!/usr/bin/env bash

# given a .locktime file, calculate unlocked time per unlock-lock pair.

input_path="$HOME/.locktimes"
output_path="$(dirname "$input_path")/timesheet"

# file formatting
ts_hdr="    LOGIN               LOGOUT              TIME DELTA"
#       Mon 22-02-04 08:59:47   22-02-04 18:30:43   [ 09:30:00 ]
ts_sep="--------------------------------------------------------"
ts_sum="                                    TOTAL  "

# login/logout times buffer
timestr=""
timestr_last=""
datestr=""
datestr_last=""
day=""
day_last=""
month=""
month_last=""

# daily work time calculation:
# I'm adding +8hours per day working. this is the easiest solution for now
# time per day = ((38*60)+30) minutes
#              = (((38*60)+30)*60) seconds / 5 = 27720 seconds = 462 minutes = 7.7 hours
# OR: 8h per day (to account for breaks) = 28800 seconds per day <-- better!
running_sec=0
target_sec=0
daily_sec=28800

show_help() {
    echo
    echo "$(basename "$0") - Timesheet generator"
    echo "Generate readable monthly timesheets from a given lockfile."
    echo "The resulting timesheets are stored to the lockfile's location."
    echo
    echo "usage:"
    echo "> $(basename "$0") [lockfile]"
    echo
    echo "default lockfile: $HOME/.locktimes"
    echo "expected lockfile syntax:"
    echo "  unlocking Mon 22-02-02 08:59:47"
    echo "  locking   Mon 22-02-02 17:00:03"
    echo "  unlocking Tue 22-02-03 08:55:13"
    echo "  locking   Tue 22-02-03 17:30:25"
    echo "  ..."
    echo
}

time_from_sec() {
    # return a string "HH:MM:SS" from a given amount of seconds
    local s=$1
    local hours=$((s / 60 / 60))
    local minutes=$(( (s / 60) - (hours * 60) ))
    local seconds=$(( s - (hours * 60 * 60) - (minutes * 60) ))

    # use abs value for min/sec in case of a negative value
    [ $minutes -lt 0 ] && minutes=$((minutes * -1))
    [ $seconds -lt 0 ] && seconds=$((seconds * -1))
    printf '%02d:%02d:%02d' $hours $minutes $seconds
}

timedelta() {
    # return seconds passed between two dates
    local date1="$(date --date "$1" +%s)"
    local date2="$(date --date "$2" +%s)"

    local seconds=$((date2 - date1))
    echo $seconds
}

# minimal parameter checking
if [ -n "$1" ]; then
    if [ -f "$1" ] ; then
        input_path="$1"
        output_path="$(dirname "$input_path")/timesheet"
    else
        echo "invalid input file" >&2
        show_help
        exit 1
    fi
fi

if [ -f "$output_path" ]; then
    mv "$output_path" "$output_path.bak"
    echo "moved existing file $output_path to $output_path.bak"
fi

# main loop
# parse lockfile line per line
while read -r line; do
    echo "line: $line"

    # skip comments
    [ "${line:0:1}" == "#" ] && continue;

    # parse line
    for part in $line; do
        case $part in
            unlocking)
                locked=0
                ;;
            locking)
                locked=1
                ;;
            *-*-*)
                datestr_last="$datestr"
                datestr="$part"
                ;;
            *:*:*)
                timestr_last="$timestr"
                timestr="$part"
                ;;
            [MTWFS]??)
                day="$part"
                ;;
            *)
                # we don't care about anything else
                ;;
        esac
    done

    # full set of unlock-lock has been found
    if [ $locked -eq 1 ] && [ -n "$datestr" ] && [ -n "$datestr_last" ]; then

        # rotate log on month change
        # do this first so we don't add today's time to last month's timesheet
        month="${datestr:3:2}"

        if [ -z "$month_last" ]; then
            month_last="$month"
        elif [ "$month_last" != "$month" ]; then
            # calculate total for last month and rotate file (timesheet_YYMM)
            ts_storage_path="${output_path}_${datestr:0:2}${month_last}"

            # calculate over/undertime
            total_time=$(time_from_sec $running_sec)
            abs_sec=$((running_sec - target_sec))
            abs_total="$(time_from_sec "$abs_sec")"

            printf '%s\n%s[ %s ] (%s)\n' $ts_sep "$ts_sum" $total_time $abs_total >> "$output_path"
            mv "$output_path" "${ts_storage_path}"
            echo "NEW_MONTH_DETECTED - old log stored at ${ts_storage_path}"

            # cleanup for next month
            running_sec=0
            target_sec=0
            month_last="$month"
        fi

        # calc time from last unlock
        echo "calculating time between $datestr_last $timestr_last and $datestr $timestr"

        if [ "$day" != "$day_last" ]; then
            # add daily worktime to counter (but only if new day)
            target_sec=$((target_sec + daily_sec))
            day_last="$day"
            echo "added day to worktime counter"
        fi

        delta_sec=$(timedelta "$datestr_last $timestr_last" "$datestr $timestr")
        delta_str="$(time_from_sec "$delta_sec")"
        running_sec=$((running_sec + delta_sec))

        echo "delta_sec: $delta_sec"
        echo "running_sec: $running_sec"
        echo "target_sec: $target_sec"

        # log to timesheet file
        [ -f "$output_path" ] || { echo "$ts_hdr" > "$output_path"; }
        printf '%s %s %s   %s %s   [ %s ]\n' $day $datestr_last $timestr_last $datestr $timestr $delta_str >> "$output_path"

        # and reset for next pair
        datestr=""
        datestr_last=""
        timestr=""
        timestr_last=""
    fi

done < "$input_path"

# show current timesheet (but ignore errors)
cat "$output_path" 2>/dev/null
