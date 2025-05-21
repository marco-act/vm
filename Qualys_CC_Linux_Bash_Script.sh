#!/bin/bash

# colored output
RED='\033[0;31m'
BYellow='\033[1;33m'
BGreen='\033[1;32m'
NC='\033[0m'

LOGFILE=qualys-scan-$(date +"%Y-%m-%d").log
echo "" > $LOGFILE

function scan() {
	nc -z -w 2 "64.39.$1.$2" 443 2>/dev/null && \
    echo -e "[SRV ${BGreen}+${NC}] Connectivity Successful - 64.39.$1.$2!" |
        tee -a $LOGFILE || \
    echo -e "[SRV ${RED}-${NC}] No Connectivity with Qualys range: 64.39.$1.$2!" >> $LOGFILE
	return
}

echo -e "[${BYellow}*${NC}] Checking connectivity on the Qualys range." |
    tee -a $LOGFILE
for i in {96..111};do 
	for j in {1..254};do
        scan $i $j &
	done
	wait
done

conn=$(grep -e 'No Connectivity' -c $LOGFILE)
if [ $conn -ne 0 ];then
    echo -e "[${RED}-${NC}] No Connectivity for $conn Ip's checked. See $LOGFILE for details."
fi

echo -e "[${BYellow}*${NC}] Scanning 64.39.96.0/20 range finished." |
    tee -a $LOGFILE

echo -e "[${BYellow}*${NC}] Validating Qualys Installation." |
    tee -a $LOGFILE

COUNT=0
if [ -d /usr/local/qualys/cloud-agent ];then
    echo -e "[FILE ${BGreen}+${NC}] /usr/local/qualys/cloud-agent ${BGreen}found${NC}." |
        tee -a $LOGFILE
else
    ((COUNT++))
    echo -e "[FILE ${RED}-${NC}] /usr/local/qualys/cloud-agent: ${RED}Installation not found${NC}!" >> $LOGFILE
fi

if [ -d /etc/qualys/cloud-agent/ ];then
    echo -e "[FILE ${BGreen}+${NC}] /etc/qualys/cloud-agent/: ${BGreen}found${NC}." |
        tee -a $LOGFILE
else
    ((COUNT++))
    echo -e "[FILE ${RED}-${NC}] /etc/qualys/cloud-agent/ ${RED}Installation not found${NC}!" >> $LOGFILE
fi

if [ ${COUNT} -eq 0 ];then
    echo -e "[File ${BGreen}+${NC}] ${BGreen}Found${NC} - File Structure." >> $LOGFILE
else
    echo -e "[File ${RED}-${NC}] Installation ${RED}Not Found${NC}!" | tee -a $LOGFILE
fi

echo -e "[${BYellow}*${NC}] Validating Qualys Installation finished." |
    tee -a $LOGFILE

echo -e "[${BYellow}*${NC}] Checking the Qualys Agent service" |
    tee -a $LOGFILE

sudo service qualys-cloud-agent status |
    grep -e 'running' 1>/dev/null && echo -e "[SVC ${BGreen}+${NC}] Qualys service is running." || \
        echo -e "[SVC ${RED}-${NC}] qualys service ${RED}not running${NC}!" | 
            tee -a $LOGFILE

sudo service qualys-cloud-agent status | tee -a $LOGFILE

#(sleep 2; echo 'JUNK') | openssl s_client -connect google.com:443 -tls1_2
#if [ $? -eq 0 ];then
#    echo -e "[TLS ${BGreen}+${NC}] TLS 1.2 check was ${BGreen}successful${NC}." |
#        tee -a $LOGFILE
#else
#    echo -e "[TLS ${RED}-${NC}] TLS 1.2 check ${RED}failed${NC}!" |
#        tee -a $LOGFILE
#fi

#(sleep 2; echo 'JUNK') | openssl s_client -connect google.com:443 -tls1_1 2>/dev/null 
#if [ $? -eq 0 ];then
#    echo -e "[TLS ${BGreen}+${NC}] TLS 1.1 check was ${BGreen}successful${NC}." |
#        tee -a $LOGFILE
#else
#    echo -e "[TLS ${RED}-${NC}] TLS 1.1 check ${RED}failed${NC}!" |
#        tee -a $LOGFILE
#fi 

curl -iL -sq https://qagpublic.qg1.apps.qualys.com/status | 
    grep -e '200 OK' 1>/dev/null && echo -e "[STATUS ${BGreen}+${NC}] got back ${BGreen}200${NC} response." |
        tee -a $LOGFILE || \
        echo -e "[STATUS ${RED}-${NC}] 200 response ${RED}failed${NC}!" |
            tee -a $LOGFILE

curl -iL -vvv https://qagpublic.qg1.apps.qualys.com/status 2>1 | tee -a $LOGFILE 