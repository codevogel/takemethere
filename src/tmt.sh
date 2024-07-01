#!/bin/bash

if [ -z $TMT_DATA_FILE ]; then
    TMT_DATA_FILE="/home/$(whoami)/.takemethere"
    echo "Warning: TMT_DATA_FILE not set, using default, which resolves to $TMT_DATA_FILE"
    echo "To suppress this warning, export TMT_DATA_FILE in your shell profile."
fi

if [ ! -e $TMT_DATA_FILE ]; then
    echo "Creating data file at $TMT_DATA_FILE"
    touch $TMT_DATA_FILE
fi
