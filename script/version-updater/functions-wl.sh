#!/bin/bash
# author: irina.ivanova@nortal.com, 28.08.2014
# v3.1

function getCurrentVersion() {
  printInfo "\n\tGetting current version of $moduleName...";

  currentVersion=$($wlst -loadProperties $WLenvironmentProperties $deployUndeployScript $moduleName "list" | grep "^$moduleName#" | grep -o --regexp='[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*')

  if [[ $currentVersion == "" ]]; then
    printWarning "\tWARNING: can't find current version of $moduleName";
  else
    printOk "\tOK: current version of $moduleName is $currentVersion";
  fi
}

function checkNumberOfDeploys() {
  printInfo "\n\tChecking number of deploys of $moduleName...";
  numberOfDeploys=$($wlst -loadProperties $WLenvironmentProperties $deployUndeployScript $moduleName "list" | grep "^$moduleName#" | wc -l)

  if [[ $numberOfDeploys == 1 ]]; then
    printOk "\tOK: at the moment only 1 version of $moduleName is deployed";
  elif [[ $numberOfDeploys == 0 ]]; then
    printWarning "\tWARNING: can't find any deployed version of $moduleName";
  else
    printWarning "\tWARNING: there is more than 1 versions of $moduleName are deployed, can't decide which one to undeploy";
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
    precompileBatch;
    printInfo "********************Update of $war is completed********************";

  else
    printError "\tERROR: can't download the $war file from $link";
	log "ERROR: $war is not downloaded from $link";
    downloadErrors+=($module-$version)
    printInfo "********************Update of $war is completed********************";
  fi
}

function precompile() {
  if [[ $module = "tyk" ]] || [[ $module = "itk" ]]; then
    printWarning "\n\tTYK or ITK module doesn't need to be precompiled";
  else
    export WL_HOME=/home/wls/bea/wlserver_12.1

    printInfo "\n\tPrecompiling $war...";
    java -Xmx512M -cp com.springsource.org.apache.taglibs.standard-1.1.2.v20110517.jar:$WL_HOME/server/lib/weblogic.jar weblogic.appc $war
    exitCode=$?

    if [ $exitCode -ne 0 ]; then
      printError "\tERROR: can't pecompile $war";
      log "ERROR: $war is not precompiled";
      rm $war
      removeLock;
      exit 1
    else
      printOk "\tOK: $war is precompiled";
      log "OK: $war is precompiled";
    fi
  fi
}

function precompileBatch() {
  if [[ $module = "tyk" ]] || [[ $module = "itk" ]]; then
    printWarning "\n\tTYK or ITK module doesn't need to be precompiled";
  else
    export WL_HOME=/home/wls/bea/wlserver_12.1

    printInfo "\n\tPrecompiling $war...";
    java -Xmx512M -cp com.springsource.org.apache.taglibs.standard-1.1.2.v20110517.jar:$WL_HOME/server/lib/weblogic.jar weblogic.appc $war
    exitCode=$?
  fi

  if [ $exitCode -ne 0 ]; then
    printError "\tERROR: can't precompile $war";
    log "ERROR: $war is not precompiled";
    exitCode=0
    precompileErrors+=($module-$version)
    rm $war
  else
    if [[ $module = "tyk" ]] || [[ $module = "itk" ]]; then
      echo ""
    else
      printOk "\tOK: $war is precompiled";
      log "OK: $war is precompiled";
    fi

    renameFile;
    undeploy;
    deploy;

  fi
}

function renameFile() {
  printInfo "\n\tRenaming downloaded file...";

  mv $war "$moduleName.war"
  printOk "\tOK: $war file is renamed to $moduleName.war";
}

function undeploy() {
  printInfo "\n\tUndeploying old version $moduleName-$currentVersion...";

  undeploy=$($wlst -loadProperties $WLenvironmentProperties $deployUndeployScript $moduleName "undeploy")

  if echo "$undeploy" | grep -q "OK: old version of"; then
    printOk "\tOK: old version $moduleName-$currentVersion is undeployed";
	log "OK: $moduleName-$currentVersion is undeployed";
  else
    printError $undeploy;
	log "ERROR: $moduleName-$currentVersion is not undeployed";
    undeployWarnings+=($module-$version)
  fi
}

function deploy() {
  printInfo "\n\tDeploying new version $moduleName-$version...";

  deploy=$($wlst -loadProperties $WLenvironmentProperties $deployUndeployScript $moduleName "deploy")

  if echo "$deploy" | grep -q "OK: new version of"; then
    printOk "\tOK: $moduleName-$version is deployed";
    log "OK: $moduleName-$version is deployed";
    successDeploys+=($module-$version)
    isRunning=true

    updateIssueSummary;
  else
    printError "$deploy";
    log "ERROR: $moduleName-$version is not deployed";
    deployErrors+=($module-$version)
    isRunning=false
  fi
}

function deployOtherVersion() {
  if [[ $isRunning == true ]]; then
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
      ./update-$app-version.sh $module $answer $user
    fi
  fi
}