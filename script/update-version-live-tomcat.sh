#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 30.10.2015
# v5.0

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
verifyLiveArguments $#;
touch $lock
notificate;
isSilent $4;
printInfo "Please insert password for JIRA account $user:";
read -s password

testJiraAuthentication;

setVariables;

echo -e "\n----------one module update: $module-$version----------" >> $log

removeExistingFile;

if [[ $type != "" ]]; then
  printGray "\n\t**********$module-$version**********";

  downloadFile;
else
  removeLock;
  exit
fi

if [[ $type = "ehealth" ]]; then
  for index in ${!ehealthTomcatManagers[@]}
  do

    tomcatManager=${ehealthTomcatManagers[$index]}
    tomcatManagerName=$index

    printGray "\n\t*****UPDATE $module-$version$tomcatManagerName*****";

    getCurrentVersion;

    compareVersions;

    checkNumberOfDeploys;

    if [ $silent == 'N' ]; then
      undeploy;
    fi

    deploy;

    checkIsRunning;
  done

elif [[ $type = "his" ]]; then
  for index in ${!hisTomcatManagers[@]}
  do
    tomcatManager=${hisTomcatManagers[$index]}
    tomcatManagerName=$index

    printGray "\n\t*****UPDATE $module-$version$tomcatManagerName*****";

    getCurrentVersion;

    compareVersions;

    checkNumberOfDeploys;

    if [ $silent == 'N' ]; then
      undeploy;
    fi

    deploy;

    checkIsRunning;
  done

else
  printError "\tERROR: can't find Tomcat Managers for module type $type";
  log "ERROR: can't find Tomcat Managers for module type $type";
fi

if [[ $type != "" ]]; then
  if [ ${#runErrors[*]} -eq 0 ]; then
    updateIssueSummary;
  fi

  removeDownloadedFile;

  printStatistics;
fi

removeLock;