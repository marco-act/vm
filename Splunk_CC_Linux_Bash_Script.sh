#!/bin/bash

RED='\033[0;31m'
BYellow='\033[1;33m'
BGreen='\033[1;32m'
NC='\033[0m'

INFO="[${BYellow}*${NC}]"
WARNING="[${RED}WARNING${NC}]"
SUCC="[${BGreen}+${NC}]"

LOGFILE="splunk-scan-$(date +%Y-%m-%d).log"
echo "" > ${LOGFILE}

#confirm UF configs
config_dirs=$(ls -1 /opt/splunkforwarder/etc/apps 2>/dev/null)
if [ ${?} -eq 2 ];then
    echo -e "${WARNING} splunkforwarder directories not found!!" | 
        tee -a ${LOGFILE}
#    exit
fi

SPLUNKDIR="/opt/splunkforwarder/etc/apps"
dir_count=12
count=0

# check dirs
echo -e "${INFO} testing for required directories"

if [ -d "${SPLUNKDIR}/000_accenture_is" ];then
    ((count++))
    echo -e "${INFO} 000_accenture_is directory ${BGreen}found${NC}."
fi

if [ -d "${SPLUNKDIR}/000_accenture_prod_outputs" ];then
    ((count++))
    echo -e "${INFO} 000_accenture_prod_outputs found."
fi

if [ -d "${SPLUNKDIR}/000_installer_monitor" ];then
    ((count++))
    echo -e "${INFO} 000_installer_monitor found."
fi 

if [ -d "${SPLUNKDIR}/introspection_generator_addon" ];then
    ((count++))
    echo -e "${INFO} introspection_generator_addon ${BGreen}found${NC}."
fi 

if [ -d "${SPLUNKDIR}/journald_input" ];then
    ((count++))
    echo -e "${INFO} journald_input ${BGreen}found${NC}."
fi

if [ -d "${SPLUNKDIR}/learned" ];then
    ((count++))
    echo -e "${INFO} learned ${BGreen}found${NC}."
fi

if [ -d "${SPLUNKDIR}/linux_app_bundle" ];then
    ((count++))
    echo -e "${INFO} linux_app_bundle ${BGreen}found${NC}."
fi 

if [ -d "${SPLUNKDIR}/search" ];then
    ((count++))
    echo -e "${INFO} search ${BGreen}found${NC}."
fi

if [ -d "${SPLUNKDIR}/splunk_httpinput" ];then
    ((count++))
    echo -e "${INFO} splunk_httpinput ${BGreen}found${NC}."
fi 

if [ -d "${SPLUNKDIR}/splunk_internal_metrics" ];then
    ((count++))
    echo -e "${INFO} splunk_internal_metrics ${BGreen}found${NC}."
fi 

if [ -d "${SPLUNKDIR}/Splunk_TA_nix" ];then
    ((count++))
    echo -e "${INFO} Splunk_TA_nix ${BGreen}found${NC}."
fi

if [ -d "${SPLUNKDIR}/SplunkUniversalForwarder" ];then
    ((count++))
    echo -e "${INFO} SplunkUniversalForwarder" ${BGreen}found${NC}.""
fi

# make sure all dirs are found
if [ $count -eq 12 ];then
    echo -e "${SUCC} all directories ${BGreen}found${NC}." | 
        tee -a ${LOGFILE}
else
    echo -e "${WARNING} only ${RED}${count}${NC} directories found of the required 12!" | 
        tee -a ${LOGFILE}
fi

# check perms ownership
ls -lah /opt/splunkforwarder/bin | awk '{
    if ( $3 == "splunk" )
        print "[\033[1;32m+\033[0m] user " $3  " is owner of " $9
    else
        print "[\033[0;31mWARNING\033[0m] user " $3 " is owner of " $9 " \033[0;31mnot splunk\033[0m!" 
    }' | tee -a ${LOGFILE}

# check for bash scripts
bin_count=0
bin_check=$(ls -1 /opt/splunkforwarder/etc/apps/000_accenture_linux_is/bin)
if [ ${?} -eq 2 ];then
    echo -e "${WARNING} utility bin directory ${RED}not found${NC}!" |
        tee -a ${LOGFILE}
#    exit
fi

BINDIR="/opt/splunkforwarder/etc/apps/000_accenture_linux_is/bin"
if [ -f "${BINDIR}/add_meta.sh" ];then
    ((bin_count++))
    echo -e "${INFO} add_meta.sh ${BGreen}found${NC}."
fi

if [ -f "${BINDIR}/get_env_details.sh" ];then
    ((bin_count++))
    echo -e "${INFO} get_env_details.sh ${BGreen}found${NC}."
fi

if [ -f "${BINDIR}/restart_helper.sh" ];then
    ((bin_count++))
    echo -e "${INFO} restart_helper.sh ${BGreen}found${NC}."
fi

if [ $bin_count -eq 3 ];then
    echo -e "${SUCC} ${BGreen}${bin_count}${NC} out of 3 scripts found." |
        tee -a ${LOGFILE}
else
    echo -e "${WARNING} ${RED}${bin_count}${NC} out of 3 scripts found." |
        tee -a ${LOGFILE}
fi

# check inputs.conf for uuid and guid
uuid_count=$(grep -e'uuid' "/opt/splunkforwarder/etc/system/local/inputs.conf" -c)
guid_count=$(grep -e'guid' "/opt/splunkforwarder/etc/system/local/inputs.conf" -c)
if [ ${uuid_count} -eq 1 ];then
    echo -e "${SUCC} uuid found in inputs.conf." |
        tee -a ${LOGFILE}
else
    echo -e "${WARNING} ${RED}${uuid_count}${NC} uuid found in inputs.conf." |
        tee -a ${LOGFILE}
fi

if [ ${guid_count} -eq 1 ];then
    echo -e "${SUCC} guid found in inputs.conf." |
        tee -a $LOGFILE
else 
    echo -e "${WARNING} ${RED}${guid_count}${NC} guids found in inputs.conf." |
        tee -a ${LOGFILE}
fi

# checking splunk service
sudo service splunkforwarder status | 
    tee -a ${LOGFILE}

while read -r ip;do
    addr=$(echo -n $ip | tr -d '\r\n')
    timeout 1s /bin/bash -c "echo EOF > /dev/tcp/$addr/9997" && \
        echo -e "${SUCC} connection to $addr available" | tee -a ${LOGFILE} || \
            echo -e "${WARNING} connection to $addr ${RED}failed${NC}!" | tee -a ${LOGFILE} &
done < splunk-ips.txt
wait

echo -e "${INFO} checking if hostname found in list of servers."

while read -r hosts;do
    h=$(echo -n $hosts | tr -d '\r\n')
    if [ "$(hostname)" = "$h" ];then
        echo -e "${SUCC} $h found in list." |
            tee -a ${LOGFILE}
        echo -e "${INFO} script finished!" |
            tee -a ${LOGFILE}
 	exit 
    fi
done < hostnames.txt 

echo -e "${WARNING} $host was not found in the list of hosts!" |
    tee -a ${LOGFILE} 
echo -e "${INFO} script finished!" |
    tee -a ${LOGFILE}
