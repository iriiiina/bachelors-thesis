#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 21.01.2016
# v6.0

. version-updater/set-variables.sh
. version-updater/functions.sh
. version-updater/functions-tomcat.sh
. version-updater/functions-local.sh

verifyVariables;
verifyLock;
verifyBatchArguments $#;

silent='Y'

if [[ $isAuthenticationRequired == "Y" ]]; then
  user=$1
  lock="UPDATING_LATEST_BATCH_MODULES_$user.loc"

  notificate;
  printInfo "Please insert password for JIRA account $user:";
  read -s password

  testJiraAuthentication;

else
  lock="UPDATING_LATEST_BATCH_MODULES.loc"
fi

touch $lock

printGray "\n\t\t*********************************************";
printGray "\t\t********************START********************";
printGray "\t\t*********************************************";

setBatchVariables;

printStatistics;

removeLock;
