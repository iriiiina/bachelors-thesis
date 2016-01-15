#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 21.08.2014
# v3.2

. version-updater/set-variables.sh
. version-updater/functions-tomcat.sh
. version-updater/functions.sh
. version-updater/functions-local.sh

# Environment specific variables
module=$1
version=$2
user=$3
lock="UPDATING_$user-$module-$version.loc"

verifyLock;
verifyArguments $#;
touch $lock
notificate;
printInfo "Please insert password for JIRA account $user:";
read -s password

testJiraAuthentication;

setVariables;

printInfo "\n\t**********$war**********";

getCurrentVersion;

compareVersions;

removeExistingFile;

echo -e "\n----------one module update: $war----------" >> $log

downloadFile;

checkNumberOfDeploys;

undeploy;

deploy;

checkIsRunning;

if [ ${#runErrors[*]} -eq 0 ]; then
  updateIssueSummary;
fi

removeDownloadedFile;

deployOtherVersion;

removeLock;
