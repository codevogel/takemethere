#!/bin/bash

if [ ! -e $TMT_DATA_FILE ]; then
    echo "Creating data file at $TMT_DATA_FILE"
    touch $TMT_DATA_FILE
fi
