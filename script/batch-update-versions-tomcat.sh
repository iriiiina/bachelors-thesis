#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 03.11.2015
# v5.0

. version-updater/set-variables.sh
. version-updater/functions-tomcat.sh
. version-updater/functions.sh
. version-updater/functions-local.sh

user=$1
silent='N'
batchLock="UPDATING_LATEST_BATCH_MODULES_$user.loc"

verifyLock;
verifyBatchArguments $#;
touch $batchLock
notificate;

if [[ "$2" == "" ]]; then
  printInfo "Please insert password for JIRA account $user:";
  read -s password
  testJiraAuthentication;
else
  password=$2
  testJiraAuthentication;
fi

printGray "\n\t\t*********************************************";
printGray "\t\t********************START********************";
printGray "\t\t*********************************************";

setBatchVariables;

printStatistics;

removeLock;