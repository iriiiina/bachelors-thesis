##!/bin/bash
# Author: Irina Ivanova, 30.10.2015
# v1.0

. version-updater/set-variables.sh

NONE='\e[0m'
GRAY='\e[100m'

function printTitle() {
  echo -e "${GRAY}$1${NONE}"
}

for index in ${!ehealthTomcatManagers[@]}
do
  printTitle "\n\n\t\t\t*********EHEALTH $index*********";

  curl -silent ${ehealthTomcatManagers[$index]}/list | sort | grep ^/ | awk '{ gsub("running", "\033[32m&\033[0m"); gsub("stopped", "\033[31m&\033[0m"); gsub("\\:[0-9]+", "\033[34m&\033[0m"); gsub("^/.+:", "\033[36m&\033[0m"); gsub("[0-9]+.[0-9]+.[0-9]+.[0-9]+$", "\033[33m&\033[0m"); print }'

done

for index in ${!hisTomcatManagers[@]}
do
  printTitle "\n\n\t\t\t*********HIS $index*********";

  curl -silent ${hisTomcatManagers[$index]}/list | sort | grep ^/ | awk '{ gsub("running", "\033[32m&\033[0m"); gsub("stopped", "\033[31m&\033[0m"); gsub("\\:[0-9]+", "\033[34m&\033[0m"); gsub("^/.+:", "\033[36m&\033[0m"); gsub("[0-9]+.[0-9]+.[0-9]+.[0-9]+$", "\033[33m&\033[0m"); print }'
done
