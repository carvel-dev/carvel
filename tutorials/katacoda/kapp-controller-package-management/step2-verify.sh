#!/bin/bash

kapp ls | tail -n 1 | grep Succeeded && echo "done"

