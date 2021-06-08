#!/bin/bash
#
# Copyright 2019 Northern.tech AS
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

set -e

mkdir -p /work
cd /work



# Raspberry Pi 3 B/B+
/usr/local/bin/build-uboot-rpi.sh rpi_3_32b_defconfig raspberrypi3
cp /work/uboot-mender/integration-binaries/*.tar* /output


chown -R --reference /output /output/*
