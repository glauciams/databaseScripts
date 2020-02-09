#!/bin/bash
#************************************************************************************
# File: Monitor database - Monthly
# Purpose: Send an e-mail with enviroment information.
# Author: Glaucia Melo - glauciamelo@gmail.com
#************************************************************************************
# Enviroment variables


# Declare script variables
export host_name=`uname -n`
export databaseid="PRODUCAO EAGLE"
#
export Vcompany="LOG-IN LOGISTICA INTERMODAL"
export Vdata=`date +"%d/%m/%y - %H:%M"`

# Start report monitor script

# Clear old files
> /tmp/monitordatabase.log

touch /tmp/monitordatabase.log
#
touch /tmp/databasestart.txt
touch /tmp/databaseuse.txt
touch /tmp/databasesga.txt
touch /tmp/databasetbs.txt
touch /tmp/databaseinvalid.txt
touch /tmp/databaseblockcontention.txt
touch /tmp/databasecreatedobj.txt
touch /tmp/databasejobstatus.txt
touch /tmp/databaseconstraintstatus.txt
touch /tmp/databasedefaultprofile.txt
touch /tmp/databasetbssystem.txt
touch /tmp/databasetbsio.txt
touch /tmp/databasebufferpool.txt
touch /tmp/databaselogbuffer.txt
touch /tmp/databaseshared.txt
touch /tmp/databasesharedspace.txt
touch /tmp/databaselatch.txt
#
echo "####################### MONITOR REPORT #######################" >> /tmp/monitordatabase.log
echo " COMPANY NAME: " $Vcompany >> /tmp/monitordatabase.log
echo " EXTRACTED IN:"  $Vdata >> /tmp/monitordatabase.log
echo " HOST:" $host_name >> /tmp/monitordatabase.log
echo " DATABASE:" $databaseid >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log



echo " ------------ SERVER INFO ------------ " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
export Vup=`uptime | awk -F "up" '{ print $2 }' | cut -d, -f1`
export Vload=`uptime | awk -F "load average:" '{ print $2 }' | cut -d, -f3`
echo " The server has been up for: " $Vup >> /tmp/monitordatabase.log
echo " The server's load average for the last 15 min is: " $Vload >> /tmp/monitordatabase.log
echo "       (normal is until 10.0)" >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
export Vfilesystem=`df -H | grep -vE '^Filesystem|tmpfs|cdrom|mnt' | awk '{ print $6 " -> " $5 }'| grep -vE 'dev|usr|var|boot|home'`
echo " The filesystem ocupation today is: " >> /tmp/monitordatabase.log
echo $Vfilesystem >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
#
echo " ------------ DATABASE INFO ------------ " >> /tmp/monitordatabase.log
echo " -- DATABASE START INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databasestart.txt   >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE SPACE USE INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databaseuse.txt     >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE SGA INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databasesga.txt     >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE TABLESPACE INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databasetbs.txt     >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE INVALID OBJECTS INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databaseinvalid.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
#
echo " -- DATABASE BLOCK CONTENTION INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databaseblockcontention.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE CREATED OBJECTS (LAST 24H) INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databasecreatedobj.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE JOBS STATUS INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databasejobstatus.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE DISABLED CONSTRAINTS STATUS INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databaseconstraintstatus.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE DEFAULT PROFILE USERS INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databasedefaultprofile.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE USERS SYSTEM TABLESPACE INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databasetbssystem.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE TABLESPACE I/O INFORMATION (READ/WRITE > 5000) -- " >> /tmp/monitordatabase.log
cat /tmp/databasetbsio.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE BUFFER POOL HIT RATIO -- " >> /tmp/monitordatabase.log
cat /tmp/databasebufferpool.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE LOG_BUFFER AND REDO LOG INFORMATION SET -- " >> /tmp/monitordatabase.log
cat /tmp/databaselogbuffer.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE SHARED POOL OBJ (EXEC > 100) INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databaseshared.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE FAILED SPACE SHARED POOL OBJ INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databasesharedspace.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " -- DATABASE LATCH STATISTICS INFORMATION -- " >> /tmp/monitordatabase.log
cat /tmp/databaselatch.txt >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo " " >> /tmp/monitordatabase.log
echo "####################### END MONITOR DATABASE REPORT #######################" >> /tmp/monitordatabase.log


