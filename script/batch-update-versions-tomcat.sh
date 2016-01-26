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

if [[ $isAuthenticationRequired == "Y" ]]; then
  user=$1
  lock="UPDATING_LATEST_BATCH_MODULES_$user.loc"

  if [[ $2 == "silent" ]]; then
    silent="Y"

    notificate;
    printInfo "Please insert password for JIRA account $user:";
    read -s password
  elif [[ $2 != "" ]]; then
    silent="N"
    password=$2
  elif [[ $2 == "" ]]; then
    silent="N"

    notificate;
    printInfo "Please insert password for JIRA account $user:";
    read -s password
  fi
  
  isSilent $silent;
  testJiraAuthentication;
else
  lock="UPDATING_LATEST_BATCH_MODULES.loc"

  if [[ $1 == "silent" ]]; then
    silent="Y"
  else
    silent="N"
  fi

  isSilent $silent;
fi

touch $lock

echo -e "\n"
printGray "*********************************************";
printGray "********************START********************";
printGray "*********************************************";

setBatchVariables;

printStatistics;

removeLock;
