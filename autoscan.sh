#!/bin/bash

# Enter directory and subnet before start
RUN_DIRECTORY=""
SCAN_SUBNET=""
VULN_PORTS="22,20,21,53,139,23,25,1723,7000"

DATE=`date +%F`
TIME=`date +%R`

echo "`date` - Start."
cd $RUN_DIRECTORY || exit 2
[ -d "scan-$DATE" ] || mkdir "scan-$DATE"
cd "scan-$DATE"
mkdir "$TIME"
cd "$TIME"
echo "`date` - Running nmap, please wait."
CUR_UP=`nmap --open -sn -n $SCAN_SUBNET -oG - -oX scan-$DATE-$TIME.xml | sed '1d ; s/.*\([0-9]\{3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/ ; $d'`
echo "`date` - Nmap process completed with exit code $?"
if [ `echo "$CUR_UP" | wc -l` -gt 0 ]
then
	REPORT="\nSCAN RESULTS FOR '${SCAN_SUBNET}'\n\nUp hosts:\n$CUR_UP\n"
else
	echo "`date` - All hosts are down."
	echo "ALL HOSTS ARE DOWN." > "./report-$DATE-$TIME.txt"
	cp "./report-$DATE-$TIME.txt" "../../report.txt"
	echo "`date` - Complete."
	exit 0
fi

if [ -e ../../scan-prev.xml ]
then
    echo "`date` - Compare with prev."
    UP=`ndiff ../../scan-prev.xml scan-$DATE-$TIME.xml | grep '+' | grep -E '[0-9]{3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}' | sed '1d; s/.*\([0-9]\{3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/'`
    DOWN=`ndiff ../../scan-prev.xml scan-$DATE-$TIME.xml | grep '-' | grep -E '[0-9]{3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}' | sed '1,2d ; s/.*\([0-9]\{3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\).*/\1/'`
    echo "`date` - Checking output"
    if [ `echo "$UP" | wc -l` -gt 0 ]
    then

    	echo "`date` - Some new up hosts from last scan was found."
    	REPORT="$REPORT\nUp from last scan:\n$UP\n\nDown from last scan:\n$DOWN\n"
    else
    	echo "`date` - No new up hosts since last scan."
    fi

else 
    echo "`date` - There is no previous scan (scan-prev.xml). Cannot diff now. Will do so next time." 
fi

echo "`date` - Checking up hosts for potentially vulnerable open ports."
VULNS=`nmap --open -A -p $VULN_PORTS $CUR_UP -n -oG - -oX vuln_ports_scan-$DATE-$TIME.xml`
if [ `echo "$VULNS" | wc -l` -gt 2 ]
then	
	VULNS=`echo -e "$VULNS" | grep '/open/' | sed -e 's/Host:\ /\nHost:\ /' -e 's/()//' -e 's/Ports:\ /\nPorts:\n/' -e 's/,\ /\n/' -e 's/\//\t/g' -e 's/open//' -e 's/[\t][\t]*/\t/g'` 
      	REPORT="$REPORT\nPotentially vulnerable:\n$VULNS\n"
else
      	echo "`date` - No potentially vulnerable ports found."
fi
echo -e "\n`date`\n$REPORT\n" > "./report-$DATE-$TIME.txt"
echo "`date` - Copy current report to report.txt"
cp "./report-$DATE-$TIME.txt" "../../report.txt"
cat "../../report.txt"
echo "`date` - Linking current scan to scan-prev.xml"
ln -sf "$RUN_DIRECTORY/scan-$DATE/$TIME/scan-$DATE-$TIME.xml" "../../scan-prev.xml"
echo -e "`date` - Complete.\n"
exit 0
