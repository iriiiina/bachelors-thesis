#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 30.10.2015
# v5.0

. version-updater/set-variables.sh
. version-updater/functions-tomcat.sh
. version-updater/functions.sh
. version-updater/functions-local.sh

user=$1
silent='Y'
batchLock="UPDATING_LATEST_BATCH_MODULES_$user.loc"

verifyLock;
verifyBatchArguments $#;
touch $batchLock
notificate;
printInfo "Please insert password for JIRA account $user:";
read -s password

testJiraAuthentication;

printGray "\n\t\t*********************************************";
printGray "\t\t********************START********************";
printGray "\t\t*********************************************";

setBatchVariables;

printStatistics;

removeLock;