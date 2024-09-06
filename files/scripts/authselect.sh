#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
set -oue pipefail

echo "Enabling faillock in PAM authentication profile"

authselect enable-feature with-faillock 1>/dev/null
