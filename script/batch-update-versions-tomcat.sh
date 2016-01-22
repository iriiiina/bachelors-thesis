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

silent='N'

if [[ $isAuthenticationRequired == "Y" ]]; then
  user=$1
  lock="UPDATING_LATEST_BATCH_MODULES_$user.loc"
  
  if [[ "$2" == "" ]]; then
    notificate;
    printInfo "Please insert password for JIRA account $user:";
    read -s password
  else
    password=$2
  fi

  testJiraAuthentication;
else
  lock="UPDATING_LATEST_BATCH_MODULES.loc"
fi

touch $lock

echo -e "\n"
printGray "*********************************************";
printGray "********************START********************";
printGray "*********************************************";

setBatchVariables;

printStatistics;

removeLock;
