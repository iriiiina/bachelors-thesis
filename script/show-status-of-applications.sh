#!/bin/bash
# Author: Irina Ivanova, 14.01.2016
# v1.0

. version-updater/functions.sh
. version-updater/set-variables.sh

curl -silent $tomcatManager/list | sort | grep ^/ | awk '{ gsub("running", "\033[32m&\033[0m");
                                                           gsub("stopped", "\033[31m&\033[0m");
                                                           gsub("\\:[0-9]+", "\033[34m&\033[0m");
                                                           gsub("^/.+:", "\033[36m&\033[0m");
                                                           gsub("[0-9]+.[0-9]+.[0-9]+.[0-9]+$", "\033[33m&\033[0m");
                                                           print }'

notificate;
