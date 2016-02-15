#!/bin/bash

###############################################################################################
### This is script for updating many modules at a time on Tomcat 8 server                   ###
### It doesn't require modifications and can be used out-of-the-box                         ###
### File can be downloaded from HG repo:                                                    ###
###    http://ehealth.webmedia.ee/scripts/version-updater/batch-update-versions-tomcat.sh   ###
###                                                                                         ###
### Author: Irina.Ivanova@nortal.com                                                        ###
### Last modified: 12.02.2016, v6.2                                                         ###
### Version-updater manual:                                                                 ###
###    https://confluence.nortal.com/display/support/Version-updater+Script+Manual          ###
###############################################################################################

# Import of global variables and functions
. version-updater/conf.sh
. version-updater/functions.sh
. version-updater/functions-tomcat.sh
. version-updater/functions-local.sh

verifyConfFile;
verifyLock;
verifyBatchArguments $#;

if [[ $isAuthenticationRequired == "Y" ]]; then
  user=$1
  lock="UPDATING_BATCH_MODULES_$user.loc"

  if [[ $2 == "p" ]]; then
    parallel="Y"

    notify;
    printInfo "Please insert password for JIRA account $user:";
    read -s password
  elif [[ $2 != "" ]]; then
    parallel="N"
    password=$2
  elif [[ $2 == "" ]]; then
    parallel="N"

    notify;
    printInfo "Please insert password for JIRA account $user:";
    read -s password
  fi
  
  testJiraAuthentication;
else
  lock="UPDATING_LATEST_BATCH_MODULES.loc"

  if [[ $1 == "p" ]]; then
    parallel="Y"
  else
    parallel="N"
  fi
fi

touch $lock

echo -e "\n"
printGray "*********************************************";
printGray "********************START********************";
printGray "*********************************************";

runBatchUpdate;

printStatistics;

removeLock;
