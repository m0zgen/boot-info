#!/bin/bash
# Author xck http://sys-admin.kz

# Sys env / paths / etc
# -------------------------------------------------------------------------------------------\
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
SCRIPT_PATH=$(cd `dirname "${BASH_SOURCE[0]}"` && pwd)
cd $SCRIPT_PATH

# Vars
HOSTNAME=`hostname`
SERVER_IP=`hostname -I`
EXTERNAL_IP=`curl -s ifconfig.co`
KERNEL=`uname -r`
ACTIVE_USERS=`w | cut -d ' ' -f1 | grep -v USER | xargs -n1`
TOTALMEM=`free -m | grep "Mem" | awk '{print "Total: " $2 " Free: " $4}'`
LAST_REBOOT=`who -b | awk '{print $3,$4,$5}'`
SERVER_UPTIME=`awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days, %d hour %d min\n",a,b,c)}' /proc/uptime`
MOOUNT_INFO=`mount|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|grep -v "loop"|sort -u -t' ' -k1,2`
DISK_USAGE=`df -PTh|egrep -iw "ext4|ext3|xfs|gfs|gfs2|btrfs"|grep -v "loop"|sort -k6n|awk '!seen[$1]++'`
# get # of cpus
CPUS=`grep -c processor /proc/cpuinfo`

if free | awk '/^Swap:/ {exit !$2}'; then
    TOTALSWAP=`free -m | awk '$1=="Swap:" {print $2}'`
    USAGESWAP=`free | awk '/Swap/{printf("%.2f%"), $3/$2*100}'`
else
    TOTALSWAP="TOTAL SWAP: swap does not exist"
    USAGESWAP="SWAP USAGE: swap not used"
fi

if [[ ! "$(command -v figlet)" ]]; then
    AUTHOR=`figlet ${HOSTNAME}`
else
    AUTHOR=${HOSTNAME}
fi

if [[ `/usr/bin/dmesg | grep -c "Using ACPI (MADT)"` == "1" ]]  ; then
   CPUCNTMETHOD="(via ACPI)"
else
   CPUCNTMETHOD="(via MP table)"
fi

# grep the proc speed from /proc/cpuinfo
if [[ `grep "^cpu MHz" /proc/cpuinfo | uniq | wc -l` == "1" ]] ; then
    SPEED=`grep "^cpu MHz" /proc/cpuinfo | uniq | awk -F : '{ print $2}' | awk -F . '{ print $1 }'`
else
    SPEED="Speed mismatch.  Speed list in /tmp/speedlist"
    grep "^cpu MHz" /proc/cpuinfo > /tmp/speedlist
fi

# grep the proc cache from /proc/cpuinfo
if [[ `grep "^cache size" /proc/cpuinfo | uniq | wc -l` == "1" ]] ; then
    CACHE=`grep "^cache size" /proc/cpuinfo | uniq | awk -F : '{ print $2 }'`
else
    CACHE="Cache mismatch.  Cache List in /tmp/cachelist"
    grep ^cache /proc/cpuinfo > /tmp/cachelist
fi

# colorize
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
purple="\e[38;5;198m"


# Checks supporting distros
checkDistro() {
    # Checking distro
    if [ -e /etc/centos-release ]; then
        DISTRO=`cat /etc/redhat-release | awk '{print $1,$4}'`
        RPM=1
    elif [ -e /etc/fedora-release ]; then
        DISTRO=`cat /etc/fedora-release | awk '{print ($1,$3~/^[0-9]/?$3:$4)}'`
        RPM=2
    elif [ -e /etc/os-release ]; then
        DISTRO=`lsb_release -d | awk -F"\t" '{print $2}'`
        RPM=0
        DEB=1
    else
        DISTRO="UNKNOWN"
        RPM=0
        DEB=0
    fi
}

getDate() {
    date '+%d-%m-%Y_%H-%M-%S'
}

service_active() {
    local n=$1
    if [[ $(systemctl list-units --type=service --state=active | grep $n.service | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

get_status() {
  local _STATUS=`systemctl is-active alertmanager.service`
  echo "alertmanager.service has status: $_STATUS"

}

checkDistro

# Write the /root/myinfo.txt file
echo -e "\n${blue}${AUTHOR}${reset}\n" > /root/myinfo.txt
echo "Computer name: " ${green}$HOSTNAME${reset} >> /root/myinfo.txt
echo "Distr: " ${green}${DISTRO}${reset} >> /root/myinfo.txt
echo -e "\n${red}Info:${reset}" >> /root/myinfo.txt
echo CPU: ${CPUS}" CPU(s) detected "${CPUCNTMETHOD}": ${SPEED}MHz with Cache: ${CACHE}" >> /root/myinfo.txt
echo Total mem: ${TOTALMEM}"Mb of RAM" >> /root/myinfo.txt
echo Swap: ${TOTALSWAP}"Mb" >> /root/myinfo.txt
echo Swap usage: ${USAGESWAP}"Mb of RAM" >> /root/myinfo.txt
echo Last reboot: ${LAST_REBOOT} >> /root/myinfo.txt
echo Uptime: ${SERVER_UPTIME} >> /root/myinfo.txt
echo Active users: ${ACTIVE_USERS} >> /root/myinfo.txt
echo IP: ${SERVER_IP} >> /root/myinfo.txt
echo External IP: ${EXTERNAL_IP} >> /root/myinfo.txt
echo 
echo " " >> /root/myinfo.txt

cat /root/myinfo.txt > /etc/motd