#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 02.03.2015
# v0.1

NONE='\033[00m'
RED='\033[01;31m'
GREEN='\033[01;32m'
CYAN='\033[01;36m'

file="batch-modules.txt"

# NB! order in the modules array is important - it defines in which order modules will be propagated
# Right order can be found in version tracker: http://ehealthtest.webmedia.int:7070/versiontracker/
modules=(
	'authentication'
	'authorization'
	'system'
	'person'
	'admin'
	'integration'
	'integration-lt'
	'docman'
	'billing'
	'diet'
	'reception'
	'schedule'
	'treatment'
	'diagnostics'
	'register'
	'ui'
	'clinician-portal'
	)

host="https://ehllt.nortal.com"
env="kjl-test"


function printError() {
  echo -e "${RED}ERROR: $1${NONE}"
}

function printRed() {
  echo -e "${RED}$1${NONE}"
}

function printOk() {
  echo -e "${GREEN}OK: $1${NONE}"
}

function printInfo() {
  echo -e "${CYAN}$1...${NONE}"
}

function emptyFile() {
  printInfo "Removing old content from $file";
  echo "" > $file
  printOk "old content from $file is removed";
}

function findVersion() {
  for module in ${modules[@]}; do
    printInfo "Finding version of $module";
    if [[ $module == "clinician-portal" ]]; then
      url="$host/$env/sysInfo"
      version=$(curl -k $url | grep -A 3 '<td class="info">module.version</td>' | grep -o --regexp='[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')
    elif [[ $module == "ui" ]]; then
      url="$host/$env-$module/sysInfo.json"
      version=$(curl -k $url | grep -o --regexp='[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')
    else
      url="$host/$env-$module/sysInfo"
      version=$(curl -k $url | grep -A 3 '<td class="info">module.version</td>' | grep -o --regexp='[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')
    fi

  addLine;
  done
}

function addLine() {
  if [[ $version == "" ]]; then
      printError "can't find version for $module: $url";
      errors+=($module)
    else
      printOk "version for $module is found: $version";
      echo "$module $version" >> $file
    fi
}

function removeBlankLine() {
  sed -i '1d' ./$file
}

function printErrors() {
  if [[ ${#errors[*]} -gt 0 ]]; then
    echo -e "\n\n"
    printRed "CAN'T FIND VERSIONS FOR ${#errors[*]} MODULES";
    for item in ${errors[*]}
    do
      echo -e "\t\t\t${RED}$item${NONE}"
    done
  else
    echo -e "\n\n"
    printOk "versions for all modules are found and saved in $file\n\n";
  fi
}

emptyFile;
findVersion;
removeBlankLine;
printErrors;
