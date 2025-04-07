#!/bin/bash

export TERMINUS_SITE=${TERMINUS_SITE:-"wpnext-test"}

terminus env:deploy "$TERMINUS_SITE".test
terminus env:deploy "$TERMINUS_SITE".live