#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 20.01.2016
# v6.0

. version-updater/set-variables.sh
. version-updater/functions.sh
. version-updater/functions-tomcat.sh
. version-updater/functions-local.sh

module=$1
version=$2

verifyVariables;
verifyLock;
verifyArguments $#;

if [[ $isAuthenticationRequired == "Y" ]]; then
  user=$3
  lock="UPDATING_$user-$module-$version.loc"
  isSilent $4;

  notificate;
  printCyan "Please insert password for JIRA account $user:";
  read -s password

  testJiraAuthentication;

elif [[ $isAuthenticationRequired == "N" ]]; then
  lock="UPDATING-$module-$version.loc"
  isSilent $3;
fi

touch $lock

setVariables;

if [[ $isLogDeletionRequired == "Y" ]] && [[ $silent == "N" ]]; then
  deleteLogs;
fi

if [[ $isTempFilesDeletionRequired == "Y" ]] && [[ $silent == "N" ]]; then
  deleteTempFiles;
fi

if [[ $isRestartRequired == "Y" ]]; then
  notificate;
  printCyan "Do you want to do the restart first? (Y, y, YES, yes)";
  read restart

  if [[ $restart == "Y" ]] || [[ $restart == "y" ]] || [[ $restart == "yes" ]] || [[ $restart == "YES" ]]; then
    restart;
  fi
fi

if [[ $isMultiServer == "Y" ]]; then
  echo -e "\n----------one module update: $module-$version----------" >> $log

  removeExistingFile;

  if [ $type != "" ]; then
    printGray "\n\t**********$module-$version**********";

    downloadFile;
  else
    removeLock;
    exit
  fi

  if [[ $type == "ehealth" ]]; then
    for index in ${!ehealthTomcatManagers[@]}
    do
      tomcatManager=${ehealthTomcatManagers[$index]}
      tomcatManagerName=$index

      printGray "\n\t*****UPDATE $module-$version$tomcatManagerName*****";

      getCurrentVersion;

      compareVersions;

      checkNumberOfDeploys;

      if [[ $silent == "N" ]]; then
        undeploy;
      fi

      deploy;

      checkIsRunning;
    done

  elif [[ $type == "his" ]]; then
    for index in ${!hisTomcatManagers[@]}
    do
      tomcatManager=${hisTomcatManagers[$index]}
      tomcatManagerName=$index

      printGray "\n\t*****UPDATE $module-$version$tomcatManagerName*****";

      getCurrentVersion;

      compareVersions;

      checkNumberOfDeploys;

      if [[ $silent == "N" ]]; then
        undeploy;
      fi

      deploy;

      checkIsRunning;
    done
  else
    printError "can't find Tomcat Managers for module type $type";
    log "ERROR: can't find Tomcat Managers for module type $type";
  fi

  if [ $type != "" ]; then
    if [[ $isJiraIssueUpdateRequired == "Y" ]] && [ ${#runErrors[*]} -eq 0 ]; then
      updateIssueSummary;
    fi

    removeDownloadedFile;

    printStatistics;
  fi
elif [[ $isMultiServer == "N" ]]; then
  printCyan "\n\t**********$war**********";

  getCurrentVersion;

  compareVersions;

  removeExistingFile;

  echo -e "\n----------one module update: $war----------" >> $log

  downloadFile;

  checkNumberOfDeploys;

  if [[ $silent == 'N' ]]; then
    undeploy;
  fi

  deploy;

  checkIsRunning;

  if [[ $isJiraIssueUpdateRequired == "Y" ]] && [[ ${#runErrors[*]} == 0 ]]; then
    updateIssueSummary;
  fi

  removeDownloadedFile;

  deployOtherVersion;
fi

removeLock;
