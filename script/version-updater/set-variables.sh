# Local variables, that should be different in every environment
 
app=""
extension=""
# tomcatManager variable in Tomcat 6 should not contain /text at the end - for example, "http://user:password@localhost:7070/manager"
tomcatManager=""
proxy=""
summaryTitle=""
 
# Local variables that are specific for live environments, where 2 or more servers in use
 
declare -A ehealthTomcatManagers
ehealthTomcatManagers[""]=""
ehealthTomcatManagers[""]=""
 
declare -A hisTomcatManagers
hisTomcatManagers[""]=""
hisTomcatManagers[""]=""
 
declare -A modules
modules["admin"]="ehealth"
modules["authentication"]="ehealth"
modules["authorization"]="ehealth"
modules["billing"]="ehealth"
modules["clinicial-portal"]="ehealth"
modules["diet"]="ehealth"
modules["docman"]="ehealth"
modules["integration"]="ehealth"
modules["integration-lt"]="ehealth"
modules["person"]="ehealth"
modules["prevention"]="ehealth"
modules["register"]="ehealth"
modules["report-engine"]="ehealth"
modules["schedule"]="ehealth"
modules["system"]="ehealth"
modules["treatment"]="ehealth"
modules["ui"]="ehealth"
modules["zk"]="ehealth"
modules["diagnostics"]="his"
modules["reception"]="his"
modules["treatment"]="his"
 
# General variables, that may stay the same in different environment, but if needed may be changed
 
extendedModules=""
lock=""
batchLock=""
log=""
rest=""
issues=""
jira=""
jiraAuth=""
warLocation=""
warLocationCom=""
batch=""
