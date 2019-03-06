# Cross-trigging test suites for the Altair BOM test system.

## Files:

![files](etc/content.png?raw=true "files")

- `src/global/suite.rc` - global (upstream) suite definition
  - generates event messages and data availability messages
- `src/regional/suite.rc` - regional (downstream) suite definition
  - generates event messages and triggers off of data availability messages
- `bin/run-test.sh` - bash script that configures, registers, and runs the
  suites
  - ensures they are self-consistent (data location, upstream suite and task
    names etc.)
- `bin/handler.py` - event handler script to receive and process all events as
  specified in the suite definition.
  - this example just unpacks its command line arguments and prints them to
    stdout (this will appear in the *job activity log* of the associated task).
- `src/regional/lib/python/suite_state_x.py` - external trigger function for
  cross-suite triggering
  - this is a local copy of the built-in suite_state trigger function
  - any stdout will appear as stderr in the suite server log in debug mode (for
    good reasons; see explanatory comments in the script).

Notes:
- the two suites are almost identical in terms of structure and task names.
  That's not likely in real global/regional suites (although not impossible)
  but we can easily change details like this once the end-to-end test system is
  working.
- the two suites can be made much bigger by simply cranking up `ENSEMBLE_SIZE`
  in the run script (default size 2)
- event handler scripts are automatically available to the suite if stored
  in a suite `bin` directory (alongside the `suite.rc` file).
- external trigger functions are automatically available to the suite if stored
  in a suite `lib/python` directory (alongside the `suite.rc` file).
- event handler stdout appears in the "job activity log" of associated tasks
  - e.g. `cylc cat-log -f a global forecast_m1.20010101T0000Z`
-  external trigger function stdout appears in the suite server log, but only
   if the suite runs in debug mode.
   - e.g. `cylc cat-log regional`
- the run script cleans out old run directories and starts anew, but if
  things go wrong you may still need to find and kill any left-over Cylc
  processes manually. 
- don't set the initial cycle point up to "now" or in the future, or the
  date-time clock triggers will hold execution until their trigger times
  come up.
- one task in each suite is configured to abort with a message on the first try,
  then succeed on a second try.
- after modifying for the Kafka system (below) we can consider expanding the
  number of events reported (e.g. by contriving some failed job submissions,
  custom warning events, etc.)
- suite and task meta data (in the `[meta]` sections) is arbitrary - need to
  check what BOM needs here (e.g task "priority" ratings?)

## Instructions:

1. First run `bin/run-test.sh` to configure, register, and run the two
   inter-dependent suites using Cylc's built-in cross-suite triggering
   mechanism and background jobs (unlike the new Kafka-based solution this
   requires tight coupling: the regional suite has to know the global suite and
   task names and have direct access to its sqlite DB on disk).

1. Then modify to drive the new system - i.e. to use PBS and pump event
   messages and data availability messages into Kafka, and (regional case) to
   trigger off of data availability messages in Kafka.
   1. (both suites) replace the *list of handled events* and the event handler
      command line with the BOM event handler, and the command line form that
      it expects.
   1. (regional suite) replace the `suite_state_x` external trigger function
      declaration with that for the BOM Kafka consumer for cross-suite
      triggering.

## Global suite:

### Dependencies:
![global suite](etc/global.png?raw=true "global suite")

### Task runtime inheritance:
![global suite runtime](etc/global-runtime.png?raw=true "global suite runtime")

## Regional suite

### Dependencies:
![regional suite](etc/regional.png?raw=true "regional suite")

### Task runtime inheritance:
(Similar to global, above.)
