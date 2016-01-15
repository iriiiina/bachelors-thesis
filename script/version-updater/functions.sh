#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 30.10.2015
# v5.0

NONE='\e[0m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
GRAY='\e[100m'

function printError() {
  echo -e "${RED}$1${NONE}"
}

function printWarning() {
  echo -e "${YELLOW}$1${NONE}"
}

function printOk() {
  echo -e "${GREEN}$1${NONE}"
}

function printInfo() {
  echo -e "${CYAN}$1${NONE}"
}

function printGray() {
  echo -e "${GRAY}$1${NONE}"
}

function log() {
  now=$(date +"%d.%m.%Y %H:%M:%S")

  echo -e "$now $user $1" >> $log
}

function verifyLock() {
  if test -e "UPDATING_"*; then
    printError "\n\tERROR: Somebody is updating, see .loc file for details";
    printError "\n\n";
    notificate;
    exit
  fi
}

function verifyArguments() {
  if [ $1 -ne 3 ]; then
    printError "\n\tUsage: $0 MODULE_NAME MODULE_VERSION JIRA_USERNAME";
    printError "\tExample: $0 admin 1.1.1.1 irina\n";
    notificate;
    exit
  fi
}

function verifyLiveArguments() {
  if [ $1 -lt 3 ] || [ $1 -gt 4 ]; then
    printError "\n\tUsage: $0 MODULE_NAME MODULE_VERSION JIRA_USERNAME [silent]";
    printError "\tExample: $0 admin 1.1.1.1 irina";
    printError "\tExample for silent update: $0 admin 1.1.1.1 irina silent\n";
    notificate;
    exit
  fi
}

function verifyBatchArguments() {
  if [[ $1 -gt 2 ]] || [[ $1 -lt 1 ]]; then
    printError "\n\tUsage: $0 JIRA_USERNAME";
    printError "\tExample: $0 irina\n";
    notificate;
    exit
  fi
}

function removeLock() {
  printInfo "\n\tRemoving lock file...";

  if test -e $lock; then
    rm $lock
    printOk "\tOK: lock file $lock is removed";
  fi

  if test -e $batchLock; then
    rm $batchLock
    printOk "\tOK: lock file $batchLock is removed";
  fi
  
  notificate;
}

function notificate() {
  printf '\a'
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

  printInfo "\n\tComparing version with deployed one...";

  if [[ $stage -gt $currentStage ]] || [[ $milestone -gt $currentMilestone ]] || [[ $submilestone -gt $currentSubmilestone ]]; then
    printWarning "\tWARNING: cycle of inserted version $version is grater than in deployed version $currentVersion$tomcatManagerName";
    versionWarnings+=("$module: old cycle $currentVersion is older than new cycle $version$tomcatManagerName")
  elif [[ $stage -lt $currentStage ]] || [[ $milestone -lt $currentMilestone ]] || [[ $submilestone -lt $currentSubmilestone ]]; then
    printWarning "\tWARNING: cycle of inserted version $version is lower than in deployed version $currentVersion$tomcatManagerName";
    versionWarnings+=("$module: old cycle $currentVersion is newer than new cycle $version$tomcatManagerName")
  elif [[ $versionNumber -lt $currentVersionNumber ]]; then
    printWarning "\tWARNING: inserted version $version is lower than deployed version $currentVersion$tomcatManagerName";
    versionWarnings+=("$module: old version $currentVersion is newer than new version $version$tomcatManagerName")
  else
    printOk "\tOK: inserted version $version is grater or equal to deployed version $currentVersion$tomcatManagerName";
  fi
}

function removeExistingFile() {
  if test -e "$war"; then
    printInfo "\tRemoving existing $war file...";

    rm $war

    if ! test -e "$war"; then
      printOk "\tOK: existing file is removed";
    else
      printError "\tERROR: can't remove existing file";
      exit
    fi
  fi
}

function downloadFile() {
  printInfo "\n\tDownloading $war file...";
  wget $link

  if test -e $war; then
    printOk "\tOK: file $war is downloaded";
    log "OK: $war is downloaded";
  else
    printError "\tERROR: can't download the $war file from $link";
    log "ERROR: $war is not downloaded from $link";
    removeLock;
    exit
  fi
}

function removeDownloadedFile() {
  printInfo "\n\tRemoving downloaded file...";
  rm $war

  if ! test -e "$war"; then
    printOk "\tOK: downloaded file is removed";
  else
    printError "\tERROR: can't remove file $war";
  fi
}

function testJiraAuthentication() {
  printInfo "\n\tTesting JIRA authentication...";

  authenticate=$(curl -D- -u $user:$password -H "Content-Type: application/json" $jiraAuth $proxy)

  if echo "$authenticate" | grep -q "AUTHENTICATED_FAILED"; then
    printError "\tJIRA ERROR: authentication failed: 401 unauthorized. Probably username or password is incorrect";
    removeLock;
    exit;
  elif echo "$authenticate" | grep -q "AUTHENTICATION_DENIED"; then
    printError "\tJIRA ERROR: authentication denied: 403 forbidden. Probably password was inserted incorrectly 3 times and now you should relogin yourself in browser with captcha control";
    removeLock;
    exit;
  elif echo "$authenticate" | grep -q "302 Found"; then
    printOk "\tOK: login into JIRA succeeded";
  else
    printError "$authenticate";
    removeLock;
    exit;
  fi
}

function findIssue() {
  printInfo "\n\tFinding JIRA issue key in jira-issues.txt...";

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
    printError "\tERROR: can't find JIRA issue key for $module in jira-issues.txt";
  else
    printOk "\tOK: JIRA issue key for $moduleName is found: $issue";
  fi
}

function clearJiraRest() {
  printInfo "\n\tDeleting generated REST content...";

  echo -n "" > $rest

  printOk "\tOK: generated REST content is deleted";
}

function generateJiraRest() {
  printInfo "\n\tGenerating REST content...";

  echo -n "" > $rest

  echo "{
             \"fields\": {
               \"summary\": \"$summary\"
             }
           }" >> $rest

  printOk "\tOK: REST content is generated";
}

function updateIssueSummary() {
  printInfo "\n\tUpdating JIRA issue summary...";

  findIssue;

  if [[ $issue = "" ]]; then
    jiraErrors+=($module-$version)
    log "ERROR: JIRA issue is not found";
  else

    generateJiraRest;

    update=$(curl -D- -u $user:$password -X PUT --data @$rest -H "Content-Type: application/json" $jira/$issue $proxy)

    if echo "$update" | grep -q "No Content"; then
      printOk "\tOK: JIRA issue $issue summary is updated to $summary";
      log "OK: JIRA issue $issue summary is updated to $summary";
    else
      printError "$update";
      jiraErrors+=($module-$version)
      log "JIRA ERROR: issue $issue summary is not updated";
    fi

    clearJiraRest;

  fi
}

function findType() {

  printInfo "\n\tFinding type of module $module...";

  for index in ${!modules[@]}
  do
    if [[ $module = $index ]]; then
      type=${modules[$index]}
      printOk "\tOK: type of module $module is $type";
      break
    else
      type=""
    fi
  done

  if [[ $type = "" ]]; then
    typeErrors+=("$module-$version$tomcatManagerName")
    printError "\tERROR: can't figure out is $module is eHealth or HIS";
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
  printGray "\n\n\t\t**************************************************";
  printGray "\t\t********************STATISTICS********************";

  printTypeErrors;
  printDownloadErrors;
  printPrecompileErrors;
  printUndeployWarnings;
  printDeployErrors;
  printRunErrors;
  printJiraErrors;
  printVersionWarnings;
  printDeployedModules;

  printGray "\t\t**************************************************";
  echo -e "\n\n"
}