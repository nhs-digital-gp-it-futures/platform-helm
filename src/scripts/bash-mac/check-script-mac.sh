#!/usr/local/bin/bash

gnuPath="/usr/local/opt/gnu-getopt/bin"
#gnuPath="/usr/local"

errorMessage=$(declare -A test 2>&1)
if [[ "$errorMessage" != "" ]]; then 
  echo "Declare version issue detected"
  sleep 10
  exit 1
else
  if ! [ -d "$gnuPath" ]; then
    echo "Error: gnu-getopt is not installed at $gnuPath" >&2
    echo 'Install gnu-getopt via brew: brew install gnu-getopt'
    echo 'Ensure after installing you export the PATH variable:' 
    echo 'export PATH="$(brew --prefix gnu-getopt)/bin:$PATH"'
    echo 'and then restart your terminal to apply it'
    sleep 10
    exit 1
  else
    echo 'No Issues found'
  fi
fi


