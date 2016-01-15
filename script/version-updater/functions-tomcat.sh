#!/bin/bash
# Author: Irina.Ivanova@nortal.com, 30.10.2015
# v5.0

function getCurrentVersion() {
  printInfo "\n\tGetting current version of $moduleName$tomcatManagerName...";
  currentVersion=$(curl "$tomcatManager/list" | grep "^/$moduleName:" | grep -o --regexp='[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')

  if [[ "$currentVersion" = "" ]]; then
    printWarning "\tWARNING: can't find current version of $moduleName$tomcatManagerName";
  else
    printOk "\tOK: current version of $moduleName$tomcatManagerName is $currentVersion";
  fi
}

function checkNumberOfDeploys() {
  printInfo "\n\tChecking number of deploys of $moduleName$tomcatManagerName...";
  numberOfDeploys=$(curl "$tomcatManager/list" | grep "^/$moduleName:" | wc -l)

  if [[ $numberOfDeploys == 1 ]]; then
    printOk "\tOK: at the moment only 1 version of $moduleName$tomcatManagerName is deployed";
  elif [[ $numberOfDeploys == 0 ]]; then
    printWarning "\tWARNING: can't find any deployed version of $moduleName$tomcatManagerName";
  else
    printWarning "\tWARNING: there is more than 1 versions of $moduleName$tomcatManagerName is deployed";
  fi
}

function downloadBatchFile() {
  getCurrentVersion;

  compareVersions;

  printInfo "\n\tDownloading $war file...";

  wget $link

  if test -e "$war"; then
    printOk "\tOK: file $war is downloaded";
    log "OK: $war is downloaded";

    checkNumberOfDeploys;

    undeploy;

    deploy;

    removeDownloadedFile;

    checkIsRunning;

    if [[ $canUpdateJira -eq 0 ]]; then
      updateIssueSummary;
    fi

    printInfo "********************Update of $war is completed********************";

  else
    printError "\tERROR: can't download the $war file from $link";
    log "ERROR: $war is not downloaded from $link";
    downloadErrors+=($module-$version)
    printInfo "********************Update of $war is completed********************";
  fi
}

function downloadBatchFileLive() {

  printInfo "\n\tDownloading file $war...";

  wget $link

  if test -e "$war"; then
    printOk "\tOK: file $war is downloaded";
    log "OK: $war is downloaded";

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

      if [[ $canUpdateJira -eq 0 ]]; then
          updateIssueSummary;
      fi

      removeExistingFile;

      printInfo "********************Update of $module-$version is completed********************";

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

      removeExistingFile;

      printInfo "********************Update of $module-$version is completed********************";

    else
      printError "\tERROR: can't find Tomcat Managers for module type $type";
      log "ERROR: can't find Tomcat Managers for module type $type";
    fi

  else
    printError "\tERROR: can't download the $war file from $link";
    log "ERROR: $war is not downloaded from $link";
    downloadErrors+=("$module-$version")
    printInfo "********************Update of $mdodule-$version is completed********************";
  fi
}

function undeploy() {
  if [[ $numberOfDeploys == 1 ]]; then
    printInfo "\n\tUndeploying old version $moduleName-$currentVersion$tomcatManagerName...";

    undeploy=$(curl "$tomcatManager/undeploy?path=/$moduleName&version=$currentVersion")

    if echo "$undeploy" | grep -q "OK - Undeployed application at context path"; then
      printOk "\tOK: old version $moduleName-$currentVersion$tomcatManagerName is undeployed";
      log "OK: $moduleName-$currentVersion$tomcatManagerName is undeployed";
      isUndeployed=1
    else
      echo $undeploy
      printError "\tERROR: can't undeploy old version $moduleName-$currentVersion$tomcatManagerName";
      log "ERROR: old version $moduleName-$currentVersion$tomcatManagerName is not undeployed";
      isUndeployed=0
      undeployWarnings+=("$module-$currentVersion$tomcatManagerName")
    fi
  else
    undeployWarnings+=("$module$tomcatManagerName")
  fi
}

function deploy() {
  printInfo "\n\tDeploying new version $moduleName-$version$tomcatManagerName...";
  deploy=$(curl --upload-file "$war" "$tomcatManager/deploy?path=/$moduleName&version=$version&update=true")

  if echo "$deploy" | grep -q "OK - Deployed application at context path"; then
    printOk "\tOK: $moduleName-$version$tomcatManagerName is deployed";
    log "OK: $moduleName-$version$tomcatManagerName is deployed";
    successDeploys+=("$module-$version$tomcatManagerName")

  else
    echo $deploy
    printError "\tERROR: can't deploy $moduleName-$version$tomcatManagerName. See logs for details";
    log "ERROR: $moduleName-$version$tomcatManagerName is not deployed";
    deployErrors+=("$module-$version$tomcatManagerName")
  fi
}

function checkIsRunning() {
  printInfo "\n\tChecking whether $moduleName-$version$tomcatManagerName is running...";

  isRunning=$(curl "$tomcatManager/list")

  if echo "$isRunning" | grep -q "$moduleName:running" && echo "$isRunning" | grep -q "$moduleName##$version"; then
    printOk "\tOK: $moduleName-$version$tomcatManagerName is running";
    log "OK: $moduleName-$version$tomcatManagerName is running";
  else
    printError "\tERROR: $moduleName-$version$tomcatManagerName is not running";
    log "ERROR: $moduleName-$version$tomcatManagerName is not running";
    runErrors+=("$module-$version$tomcatManagerName")
    canUpdateJira=1
  fi
}

function deployOtherVersion() {
  if echo "$isRunning" | grep -q "$moduleName:running" && echo "$isRunning" | grep -q "$moduleName##$version"; then
    removeLock;
    exit
  else
    removeLock;

    printInfo "\n\nIf you want to deploy other version, please insert it's number.";
    printInfo "Number of last working version is $currentVersion";
    printInfo "Print n to exit from the script.";
 notificate;
    read answer

    if [[ $answer == "n" ]]; then
      exit
    else
      ./update-version-tomcat.sh $module $answer $user
    fi
  fi
}