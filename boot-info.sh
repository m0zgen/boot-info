#!/bin/bash
# Author xck http://sys-admin.kz

HOSTNAME=`hostname`

AUTHOR=`figlet ${HOSTNAME}`

# get memory size
MEM=`awk '/MemTotal/ {printf( "%.2f\n", $2 / 1024 )}' /proc/meminfo`

# infonfig info
IFCONFIG=`ifconfig | grep "inet"`

RELEASE=`cat /etc/redhat-release`

# get # of cpus
CPUS=`grep -c processor /proc/cpuinfo`

# colorize
blue=`tput setaf 4`
red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`
purple="\e[38;5;198m"

# figure out how CPU count is determined
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

# Write the /root/myinfo.txt file
ifconfig='/sbin/ifconfig'
uniq='/usr/bin/uniq'
#echo -e "\n" >/root/myinfo.txt
echo -e "\n${blue}${AUTHOR}${reset}\n" > /root/myinfo.txt
echo "Computer name: " ${green}$HOSTNAME${reset} >> /root/myinfo.txt
echo "Release: " ${green}${RELEASE}${reset} >> /root/myinfo.txt
echo -e "\n${red}Info:${reset}" >> /root/myinfo.txt
echo ${CPUS}" CPU(s) detected "${CPUCNTMETHOD}" at Speed: ${SPEED} MHz with Cache: ${CACHE}" >>/root/myinfo.txt
echo ${MEM}"Mb of RAM" >>/root/myinfo.txt
for net in `$ifconfig | grep ^[a-z] | grep -v ^lo | awk '{ print $1}' | sed 's/.$//' | $uniq` ; do
   for (( i=0; $i<16; i=$i+1 )) ; do
      if [[ `$ifconfig | grep -c $net$i` != "0" ]] ; then
         $ifconfig $net$i | grep $net | awk '{ printf "%s %s %s", $1, "  MAC addr:", $5 }' >> /root/myinfo.txt
         $ifconfig $net$i | grep "inet addr" | awk '{ print "  IP " $2 }' >> /root/myinfo.txt
      fi
   done
done
#echo -e "\nIfocnfig info:\n${IFCONFIG}\n" >> /root/myinfo.txt
echo " " >>/root/myinfo.txt

# Make /root/myinfo.txt.net a duplicate of /root/myinfo.txt...
# cp -f  /etc/issue /etc/issue.net

cat /root/myinfo.txt > /etc/motd