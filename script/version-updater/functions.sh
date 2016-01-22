#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 20.01.2016
# v6.0

NONE='\e[0m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
GRAY='\e[100m'

function printError() {
  echo -e "\n\t${RED}ERROR: $1${NONE}"
}

function printRed() {
  echo -e "${RED}$1${NONE}"
}

function printWarning() {
  echo -e "\t${YELLOW}WARNING: $1${NONE}"
}

function printOk() {
  echo -e "\t${GREEN}OK: $1${NONE}"
}

function printInfo() {
  echo -e "\n\t${CYAN}$1...${NONE}"
}

function printCyan() {
  echo -e "${CYAN}$1${NONE}"
}

function printGray() {
  echo -e "${GRAY}$1${NONE}"
}

function log() {
  now=$(date +"%d.%m.%Y %H:%M:%S")

  if [[ $isAuthenticationRequired == "Y" ]]; then
    echo -e "$now $user $1" >> $log
  elif [[ $isAuthenticationRequired == "N" ]]; then
    echo -e "$now $1" >> $log
  fi
}

function verifyLock() {
  if test -e "UPDATING_"*; then
    printError "somebody is updating, see .loc file for details";
    printRed "\n\n";
    notificate;
    exit
  fi
}

function verifyVariables() {

  checkErrorCount=0;

  if [ $isAuthenticationRequired != "N" ] && [ $isAuthenticationRequired != "Y" ] && [ $isAuthenticationRequired != "" ]; then
    printError "error in set variables.sh configurations: isAuthenticationRequired value can be only N, Y or NULL";
    checkErrorCount=1
  fi

  if [ $isJiraIssueUpdateRequired != "N" ] && [ $isJiraIssueUpdateRequired != "Y" ] && [ $isJiraIssueUpdateRequired != "" ]; then
    printError "error in set variables.sh configurations: isJiraIssueUpdateRequired value can be only N, Y or NULL";
    checkErrorCount=1
  fi

  if [ $isRestartRequired != "N" ] && [ $isRestartRequired != "Y" ] && [ $isRestartRequired != "" ]; then
    printError "error in set variables.sh configurations: isRestartRequired value can be only N, Y or NULL";
    checkErrorCount=1
  fi

  if [ $isLogDeletionRequired != "N" ] && [ $isLogDeletionRequired != "Y" ] && [ $isLogDeletionRequired != "" ]; then
    printError "error in set variables.sh configurations: isLogDeletionRequired value can be only N, Y or NULL";
    checkErrorCount=1
  fi

  if [ $isTempFilesDeletionRequired != "N" ] && [ $isTempFilesDeletionRequired != "Y" ] && [ $isTempFilesDeletionRequired != "" ]; then
    printError "error in set variables.sh configurations: isTempFilesDeletionRequired value can be only N, Y or NULL";
    checkErrorCount=1
  fi

  if [ $isMultiServer != "Y" ] && [ $isMultiServer != "N" ] && [ $isMultiServer != "" ]; then
    printError "error in set-variables.sh configurations: isMultiServer value can be only N, Y or NULL";
    checkErrorCount=1
  fi

  if [[ $isAuthenticationRequired == "N" ]] && [[ $isJiraIssueUpdateRequired == "Y" ]]; then
    printError "error in set-variables.sh configurations: isJiraIssueUpdateRequired can't be Y if isAuthenticationRequired is N";
    checkErrorCount=1
  fi

  if [[ $isJiraIssueUpdateRequired == "Y" ]] && ([[ $rest == "" ]] || [[ $issues == "" ]] || [[ $jira == "" ]] || [[ $jiraAuth == "" ]]); then
    printError "error in set-variables.sh configurations: rest, issues, jira or jiraAuth variables can't be NULL if isJiraIssueUpdateRequired is Y";
    checkErrorCount=1
  fi

  if [[ $isAuthenticationRequired == "Y" ]] && [[ $jiraAuth == "" ]]; then
    printError "error in set-variables.sh configurations: jiraAuth can't be NULL if isAuthenticationRequired is Y";
    checkErrorCount=1
  fi

  if [[ $isRestartRequired == "Y" ]] && [[ $tomcatBin == "" ]]; then
    printError "error in set-variables.sh configurations: tomcatBin can't be NULL if isRestartRequired is Y";
    checkErrorCount=1
  fi

  if [[ $isLogDeletionRequired == "Y" ]] && ([[ $appLogs == "" ]] || [[ $tomcatLogs == "" ]]); then
    printError "error in set-variables.sh configurations: appLogs or tomcatLogs can't be NULL if isLogDeletionRequired is Y";
    checkErrorCount=1
  fi

  if [[ $isTempFilesDeletionRequired == "Y" ]] && [[ $tempFiles == "" ]]; then
    printError "error in set-variables.sh configurations: tempFiles can't be NULL if isTempFilesDeletionRequired is Y";
    checkErrorCount=1
  fi

  if [ $checkErrorCount -gt 0 ]; then
    notificate;
    exit
  fi
}

function verifyArguments() {
  if [[ $isAuthenticationRequired == "Y" ]]; then
    if [ $1 -lt 3 ] || [ $1 -gt 4 ]; then
      printRed "\nUsage: $0 MODULE_NAME MODULE_VERSION JIRA_USERNAME [silent]";
      printRed "Example: $0 admin 1.1.1.1 irina";
      printRed "Example for silent update: $0 admin 1.1.1.1 irina silent\n";
      notificate;
      exit
    fi
  elif [[ $isAuthenticationRequired == "N" ]]; then
    if [ $1 -lt 2 ] || [ $1 -gt 3 ]; then
      printRed "\nUsage: $0 MODULE_NAME MODULE_VERSION [silent]";
      printRed "Example: $0 admin 1.1.1.1";
      printRed "Example for silent update: $0 admin 1.1.1.1 silent\n";
      notificate;
      exit
    fi
  fi
}

function verifyBatchArguments() {
  if [[ $isAuthenticationRequired == "Y" ]]; then
    if [[ $1 -gt 2 ]] || [[ $1 -lt 1 ]]; then
      printRed "\nUsage: $0 JIRA_USERNAME";
      printRed "Example: $0 irina\n";
      notificate;
      exit
    fi
  elif [[ $isAuthenticationRequired == "N" ]]; then
    if [[ $1 -gt 1 ]]; then
      printRed "\nUsage: $0";
      printRed "Example: $0\n";
      notificate;
      exit
    fi
  fi
}

function removeLock() {
  printInfo "Removing lock file";

  if test -e $lock; then
    rm $lock
    printOk "lock file $lock is removed";
  fi
  
  notificate;
}

function notificate() {
  printf '\a'
}

function isSilent() {
  if [[ $1 == "silent" ]]; then
    silent="Y"
    printWarning "update ${RED}is ${YELLOW}silent!${NONE}\n";
    log "INFO: update is silent";
  else
    silent="N"
    printWarning "update is ${RED}not ${YELLOW}silent!${NONE}\n";
    log "INFO: update is not silent";
  fi
}

function deleteLogs() {
  printInfo "Deleting old logs";
  find $appLogs -mtime +7 -exec rm {} \;
  log "OK: application logs $appLogs are deleted";
  find $tomcatLogs -mtime +7 -exec rm {} \;
  log "OK: Tomcat logs $tomcatLogs are deleted";
  printOk "logs older than 7 days are deleted";
}

function deleteTempFiles() {
  printInfo "Deleting temporary files from $tempFiles/*$moduleName*";
  rm -rf $tempFiles/*$moduleName*
  log "OK: temporary files $tempFiles are deleted";
  printOk "temporary files $tempFiles/*$moduleName* are deleted";
}

function compareVersions() {
  currentStage=$(echo $currentVersion | grep -o --regexp='^[0-9]*')
  stage=$(echo $version | grep -o --regexp='^[0-9]*')

  currentMilestone=$(echo $currentVersion | grep -o --regexp='^[0-9]*\.[0-9]*' | grep -o --regexp='[0-9]*$')
  milestone=$(echo $version | grep -o --regexp='^[0-9]*\.[0-9]*' | grep -o --regexp='[0-9]*$')

  currentSubmilestone=$(echo $currentVersion | grep -o --regexp='\.[0-9]*\.[0-9]*' | grep -o --regexp='[0-9]*$')
  submilestone=$(echo $version | grep -o --regexp='\.[0-9]*\.[0-9]*' | grep -o --regexp='[0-9]*$')

  currentVersionNumber=$(echo $currentVersion | grep -o --regexp='[0-9]*$')
  versionNumber=$(echo $version | grep -o --regexp='[0-9]*$')

  printInfo "Comparing version with deployed one";

  if [[ $stage -gt $currentStage ]] || [[ $milestone -gt $currentMilestone ]] || [[ $submilestone -gt $currentSubmilestone ]]; then
    printWarning "cycle of inserted version $version is grater than in deployed version $currentVersion$tomcatManagerName";
    versionWarnings+=("$module: old cycle $currentVersion is older than new cycle $version$tomcatManagerName")
  elif [[ $stage -lt $currentStage ]] || [[ $milestone -lt $currentMilestone ]] || [[ $submilestone -lt $currentSubmilestone ]]; then
    printWarning "cycle of inserted version $version is lower than in deployed version $currentVersion$tomcatManagerName";
    versionWarnings+=("$module: old cycle $currentVersion is newer than new cycle $version$tomcatManagerName")
  elif [[ $versionNumber -lt $currentVersionNumber ]]; then
    printWarning "inserted version $version is lower than deployed version $currentVersion$tomcatManagerName";
    versionWarnings+=("$module: old version $currentVersion is newer than new version $version$tomcatManagerName")
  else
    printOk "inserted version $version is grater or equal to deployed version $currentVersion$tomcatManagerName";
  fi
}

function removeExistingFile() {
  if test -e "$war"; then
    printInfo "Removing existing $war file";

    rm $war

    if ! test -e "$war"; then
      printOk "existing file is removed";
    else
      printError "can't remove existing file";
      exit
    fi
  fi
}

function downloadFile() {
  printInfo "Downloading $war file";
  wget $link

  if test -e $war; then
    printOk "file $war is downloaded";
    log "OK: $war is downloaded";
  else
    printError "can't download the $war file from $link";
    log "ERROR: $war is not downloaded from $link";
    removeLock;
    exit
  fi
}

function removeDownloadedFile() {
  printInfo "Removing downloaded file";
  rm $war

  if ! test -e "$war"; then
    printOk "downloaded file is removed";
  else
    printError "can't remove file $war";
  fi
}

function testJiraAuthentication() {
  printInfo "Testing JIRA authentication";

  authenticate=$(curl -D- -u $user:$password -H "Content-Type: application/json" $jiraAuth $proxy)

  if echo "$authenticate" | grep -q "AUTHENTICATED_FAILED"; then
    printError "authentication failed: 401 unauthorized. Probably username or password is incorrect";
    removeLock;
    exit;
  elif echo "$authenticate" | grep -q "AUTHENTICATION_DENIED"; then
    printError "authentication denied: 403 forbidden. Probably password was inserted incorrectly 3 times and now you should relogin yourself in browser with captcha control";
    removeLock;
    exit;
  elif echo "$authenticate" | grep -q "302 Found"; then
    printOk "login into JIRA succeeded";
  else
    printRed "$authenticate";
    removeLock;
    exit;
  fi
}

function findIssue() {
  printInfo "Finding JIRA issue key in jira-issues.txt";

  while read -r key; do

    issueModule=$( echo "$key" | cut -d ":" -f1 )
    issueKey=$( echo "$key" | cut -d ":" -f2 )

    if [ $issueModule = $module ]; then
      issue=$issueKey
    return
    else
      issue=""
    fi

  done < $issues

  if [[ $issue == "" ]]; then
    printError "can't find JIRA issue key for $module in jira-issues.txt";
  else
    printOk "JIRA issue key for $moduleName is found: $issue";
  fi
}

function clearJiraRest() {
  printInfo "Deleting generated REST content";

  echo -n "" > $rest

  printOk "generated REST content is deleted";
}

function generateJiraRest() {
  printInfo "Generating REST content";

  echo -n "" > $rest

  echo "{
             \"fields\": {
               \"summary\": \"$summary\"
             }
           }" >> $rest

  printOk "REST content is generated";
}

function updateIssueSummary() {
  printInfo "Updating JIRA issue summary";

  findIssue;

  if [[ $issue = "" ]]; then
    jiraErrors+=($module-$version)
    log "ERROR: JIRA issue is not found";
  else

    generateJiraRest;

    update=$(curl -D- -u $user:$password -X PUT --data @$rest -H "Content-Type: application/json" $jira/$issue $proxy)

    if echo "$update" | grep -q "No Content"; then
      printOk "JIRA issue $issue summary is updated to $summary";
      log "OK: JIRA issue $issue summary is updated to $summary";
    else
      printRed "$update";
      jiraErrors+=($module-$version)
      log "JIRA ERROR: issue $issue summary is not updated";
    fi

    clearJiraRest;

  fi
}

function findType() {

  printInfo "Finding type of module $module";

  for index in ${!modules[@]}
  do
    if [[ $module = $index ]]; then
      type=${modules[$index]}
      printOk "type of module $module is $type";
      break
    else
      type=""
    fi
  done

  if [[ $type = "" ]]; then
    typeErrors+=("$module-$version$tomcatManagerName")
    printError "can't figure out is $module is eHealth or HIS";
    log "ERROR: can't figure out is $module is eHealth or HIS";
  fi
}

function printTypeErrors() {
  if [ ${#typeErrors[*]} -gt 0 ]; then
    echo -e "\t\tTYPE ERRORS: ${RED}${#typeErrors[*]}${NONE}"
    for item in ${typeErrors[*]}
    do
      echo -e "\t\t\t${RED}$item${NONE}"
    done
  else
    echo -e "\t\tTYPE ERRORS: ${#typeErrors[*]}"
  fi
}

function printDownloadErrors() {
  if [ ${#downloadErrors[*]} -gt 0 ]; then
    echo -e "\t\tDOWNLOAD ERRORS: ${RED}${#downloadErrors[*]}${NONE}"
    for item in ${downloadErrors[*]}
    do
      echo -e "\t\t\t${RED}$item${NONE}"
    done
  else
    echo -e "\t\tDOWNLOAD ERRORS: ${#downloadErrors[*]}"
  fi
}

function printPrecompileErrors() {
  if [ ${#precompileErrors[*]} -gt 0 ]; then
    echo -e "\t\tPRECOMPILE ERRORS: ${RED}${#precompileErrors[*]}${NONE}"
    for item in ${precompileErrors[*]}
    do
      echo -e "\t\t\t${RED}$item${NONE}"
    done
  else
    echo -e "\t\tPRECOMPILE ERRORS: ${#precompileErrors[*]}"
  fi
}

function printUndeployWarnings() {
  if [ ${#undeployWarnings[*]} -gt 0 ]; then
    echo -e "\t\tUNDEPLOY WARNINGS: ${YELLOW}${#undeployWarnings[*]}${NONE}"
    for item in ${undeployWarnings[*]}
    do
      echo -e "\t\t\t${YELLOW}$item${NONE}"
    done
  else
    echo -e "\t\tUNDEPLOY WARNINGS: ${#undeployWarnings[*]}"
  fi
}

function printDeployErrors() {
  if [ ${#deployErrors[*]} -gt 0 ]; then
    echo -e "\t\tDEPLOY ERRORS: ${RED}${#deployErrors[*]}${NONE}"
    for item in ${deployErrors[*]}
    do
      echo -e "\t\t\t${RED}$item${NONE}"
    done
  else
    echo -e "\t\tDEPLOY ERRORS: ${#deployErrors[*]}"
  fi
}

function printRunErrors() {
  if [ ${#runErrors[*]} -gt 0 ]; then
    echo -e "\t\tRUN ERRORS: ${RED}${#runErrors[*]}${NONE}"
    for item in ${runErrors[*]}
    do
      echo -e "\t\t\t${RED}$item${NONE}"
    done
  else
    echo -e "\t\tRUN ERRORS: ${#runErrors[*]}"
  fi
}

function printJiraErrors() {
  if [ ${#jiraErrors[*]} -gt 0 ]; then
    echo -e "\t\tJIRA ERRORS: ${RED}${#jiraErrors[*]}${NONE}"
    for item in ${jiraErrors[*]}
    do
      echo -e "\t\t\t${RED}$item${NONE}"
    done
  else
    echo -e "\t\tJIRA ERRORS: ${#jiraErrors[*]}"
  fi
}

function printVersionWarnings() {

  if [ ${#versionWarnings[*]} -gt 0 ]; then
    echo -e "\t\tVERSION WARNINGS: ${YELLOW}${#versionWarnings[*]}${NONE}"
    for ((i = 0; i < ${#versionWarnings[@]}; i++)); do
      echo -e "\t\t\t${YELLOW}${versionWarnings[$i]}${NONE}"
    done
  else
    echo -e "\t\tVERSION WARNINGS: ${#versionWarnings[*]}"
  fi
}

function printDeployedModules() {
  if [ ${#successDeploys[*]} -gt 0 ]; then
    echo -e "\n\n\t\tDEPLOYED MODULES: ${GREEN}${#successDeploys[*]}${NONE}"
    for item in ${successDeploys[*]}
    do
      echo -e "\t\t\t${GREEN}$item${NONE}"
    done
  else
    echo -e "\n\t\tDEPLOYED MODULES: ${#successDeploys[*]}"
  fi
}

function printStatistics() {
  echo -e "\n\n"
  printGray "**************************************************";
  printGray "********************STATISTICS********************";

  printTypeErrors;
  printDownloadErrors;
  printPrecompileErrors;
  printUndeployWarnings;
  printDeployErrors;
  printRunErrors;
  printJiraErrors;
  printVersionWarnings;
  printDeployedModules;

  printGray "**************************************************";
  echo -e "\n\n"
}
