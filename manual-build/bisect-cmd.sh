#!/usr/bin/env bash

cd ..
./build-and-render.sh out.png
cmp out.png reference.png
