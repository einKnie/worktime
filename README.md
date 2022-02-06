# worktime tracker

track the time between unlocking and locking the screen.

## usage

Adapt the lockaction.sh script to your needs (i.e. configure the screenlocker of your choice) and then replace your current screenlocker with the lockaction.sh script.

This will track the date and time of every lock/unlock of the system in  `$HOME/.locktimes`.

### timesheet generation

The script `calc_worktimes.sh` may be used to create human-readable worksheets, including over/undertime tracking per month.

Simply call the script and it will generate timesheets per month from the data in `$HOME/.locktimes`. In case you store your locktimes in a different file, provide the file's path when calling calc_worktime.sh

```
calc_worktime.sh path/to/locktimes
```

The resulting timesheets are stored in the locktime file's path.

#### target time tracking

The script is set to 40hr weeks, or more specifically, 8hr days.
Every day the computer is unlocked a target of 8 hours is added to the total.  
Note that this means that only those days are counted where the computer has been unlocked and locked at least once.
The effective monthly target time thus results in `days spent working * 8 hours`.

