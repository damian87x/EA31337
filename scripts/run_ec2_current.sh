#!/usr/bin/env bash
set -e
read pattern args <<<$@
[ $# -eq 0 ] && { echo Usage: $0; exit 1; }
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
ROOT="$(git rev-parse --show-toplevel || echo $CWD)"
VERSION=${VERSION:-"Lite"}
SYMBOL=${SYMBOL:-"EURUSD"}
YEAR=${YEAR:-"2014"}
DEPOSIT=${DEPOSIT:-"2000"}
CURRENCY=${CURRENCY:-"USD"}
SPREAD=${SPREAD:-"10"}
DIGITS=${DIGITS:-"5"}
BT_SOURCE=${BT_SOURCE:-"DS"}
MT4_VER="4.0.0.971"
SET_DIR="$SYMBOL/default/$DEPOSIT$CURRENCY/$SPREAD-spread/$DIGITS-digits/$YEAR"
OPT_DIR="$SET_DIR/_optimization_results"
SET_FILE="$SET_DIR/*.set"
VM_DIR="_VM"
LOG_DIR="$ROOT/logs"

run_test() {
  local test_name=$1
  local rep_name="${test_name}--${SYMBOL}-${DEPOSIT}${CURRENCY}-${YEAR}year-${SPREAD}spread-${BT_SOURCE}-optimization-test"

  VM_NAME="$test_name" vagrant up --provider=aws --no-provision --destroy-on-error

  time \
  VM_NAME="$test_name" \
  RUN_TEST="-t -x -o -I TestModel=0 -E VerboseInfo=1 -f */\"$SET_DIR\"/*.set -e EA31337 -c $CURRENCY -p $SYMBOL -d $DEPOSIT -s $SPREAD -y $YEAR -M $MT4_VER -D $DIGITS -b $BT_SOURCE -i \"\$(find ~ -name \*${test_name}.rule*)\" -r \"$rep_name\" -O */\"$OPT_DIR\" $args " \
  vagrant provision
}

. "$ROOT"/conf/aws/load_env.local.inc.sh

[ ! -d "$LOG_DIR" ] && mkdir -vp "$LOG_DIR"

cd "$ROOT"/"$VM_DIR"

find "$ROOT/sets" -type f -name "*$pattern*.rule*" -print0 | while IFS= read -r -d '' rule_file; do
  test_name="$(basename "${rule_file%.*}")"

  echo "Starting ${test_name}..."

  run_test "$test_name" | tee "$LOG_DIR/${test_name:-$0}.log"

done
