#!/bin/bash

# Abort if any command fails.or any shell variables undefined.
set -eu

# Configuration.

# Suite names.
UPSTREAM_SUITE=global
UPSTREAM_TASK=forecast
DNSTREAM_SUITE=regional

DEBUG_MODE=true
ENSEMBLE_SIZE=2
DATA_DIR=$(mktemp -d)
JOB_HOST=localhost
BATCH_SYS=background  # or pbs (note lowercase, not "PBS")
JINJA2_OPTS="\
--set=ENSEMBLE_SIZE=$ENSEMBLE_SIZE \
--set=DATA_DIR=$DATA_DIR \
--set=JOB_HOST=$JOB_HOST \
--set=BATCH_SYS=$BATCH_SYS \
--set=UPSTREAM_SUITE=$UPSTREAM_SUITE \
--set=UPSTREAM_TASK=$UPSTREAM_TASK"

if $DEBUG_MODE; then
  DEBUG_OPT="--debug"
else
  DEBUG_OPT=""	
fi

SOURCE_DIR=$(dirname $0)/..

# Abort if either suite is already running.
ABORT=false
for SUITE in $UPSTREAM_SUITE $DNSTREAM_SUITE; do
  if cylc ping $SUITE > /dev/null 2>&1; then
    >&2 echo "ERROR: $SUITE is running already!"
    ABORT=true
  fi
done
$ABORT && >&2 echo "ABORTING!" && exit 1

# Clean up previous run.
rm -rf $HOME/cylc-run/{$UPSTREAM_SUITE,$DNSTREAM_SUITE}

# Register suites.
cylc register $UPSTREAM_SUITE $SOURCE_DIR/src/global
cylc register $DNSTREAM_SUITE $SOURCE_DIR/src/regional 

# Validate suites.
cylc validate $JINJA2_OPTS $UPSTREAM_SUITE
cylc validate $JINJA2_OPTS $DNSTREAM_SUITE

# Run upstream. Generates events and data availability messages.
cylc run $DEBUG_OPT $JINJA2_OPTS $UPSTREAM_SUITE
# Run downstream. Generate events and triggers off of upstream data
# availability messages.
cylc run $DEBUG_OPT $JINJA2_OPTS $DNSTREAM_SUITE

echo "..."
sleep 2
cylc scan
