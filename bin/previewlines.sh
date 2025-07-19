#!/usr/bin/env bash
set -o errexit                  # exit if any pipeline fails
set -o nounset                  # set your variables first
set -o pipefail                 # if one component fails the pipeline fails
shopt -s lastpipe               # last component is exec'd in foreground
# set -o xtrace
main () {
    for i in previews/*/*.preview.png ; do
        echo "    - ${i}"
    done
}

###############################################################################
main "$@"
