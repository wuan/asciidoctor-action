#!/bin/bash
# Exit on error.
set -e
# Allow ** globs, ignore empty globs
shopt -s extglob globstar nullglob

EX_USAGE=64 # Usage error exit code from /usr/include/sysexits.h

OUTPUT_FORMAT=
ASCIIDOCTOR_ARGS=

while getopts "f:a:" arg; do
  case "${arg}" in
    f)
      OUTPUT_FORMAT=${OPTARG}
      ;;
    a)
      ASCIIDOCTOR_ARGS=${OPTARG}
      ;;
    :)
      printf "Expected -${OPTARG} to have a value\n" >&2
      exit $EX_USAGE
      ;;
    *)
      printf "Unexpected arg ${OPTARG}\n" >&2
      exit $EX_USAGE
      ;;
  esac
done
shift $((OPTIND-1))

read -r INPUT_FILES <<<$*

ASCIIDOCTOR=asciidoctor
if [[ "pdf" = $OUTPUT_FORMAT ]]; then
  ASCIIDOCTOR=asciidoctor-pdf
fi

if [[ -z $INPUT_FILES ]]; then
  printf "No input files specified\n" >&2
  exit $EX_USAGE
fi

# TEST env variable indicates we should be in testing mode (below).
if [[ -z $TEST ]]; then
  for file in $(ls $INPUT_FILES); do
    set +x
    $ASCIIDOCTOR -r asciidoctor-diagram $ASCIIDOCTOR_ARGS $INPUT_FILES
  done
else
  printf "" > entrypoint-test-output
  for file in $(ls $INPUT_FILES); do
    set +x
    echo "$ASCIIDOCTOR -r asciidoctor-diagram $ASCIIDOCTOR_ARGS $file" >> entrypoint-test-output
  done

  commands=$(cat entrypoint-test-output)
  if [[ $commands = "${TEST}" ]]; then
    echo "Commands equal test expectations."
    exit 0
  else                                                                             
    printf "Ran unexpected commands:\n" >&2
    diff entrypoint-test-output <(echo "${TEST}") >&2
    exit 1
  fi

fi