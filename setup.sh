#!/bin/bash
# Author: Calvin GLuck <W7KYG@qruqsp.org>
# FIXME: Add more introduction comments here

# NOTE: env can be used to execute a binary regardless of path
# EXAMPLE: #!/usr/bin/env php 

# FIXME: Update this script for all supported and desired supported platforms
# Jesse: https://github.com/QRUQSP/qruqsp/blob/master/docs/dev-install-jessie.md
# Mac: https://github.com/QRUQSP/qruqsp/blob/master/docs/dev-install-mac.md
# Ubuntu: https://github.com/QRUQSP/qruqsp/blob/master/docs/dev-install-ubuntu.md
# Windows 10 Subsystem for Linux
# Windows 8
# Windows 7
# Android $4 Bit Web Server 

echoAndLog () {
    timestamp=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${timestamp} ${@}" | tee -a /ciniki/logs/qruqsp_setup.txt
}

checkFiles () {
    for reqFile in ${@}
    do
        if [ -f $reqFile ]
        then
            echoAndLog "OK: File exists: ${reqFile}"
            printf "    "
            ls -l ${reqFile}
        else
            echoAndLog "FAIL: File should be present but is missing: ${reqFile}"
            exit 1
        fi
    done
} # END checkFiles

if [ -d /ciniki/logs ]
then
    echoAndLog echo "OK: /ciniki/logs folder exists"
else
    mkdir -p /ciniki/logs
fi

echoAndLog "------------------------------------------------------"
echoAndLog "| START $0"
echoAndLog "------------------------------------------------------"

# Arguments to control actions of script
# -p - Do everything except load database and setup station, this will be done when pi is started by user
PREPARE_ONLY=0

#
# Check for arguments
#
# -p - Prepare SD image, do not setup QRUQSP
#
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"

    case $key in
        -p)
        PREPARE_ONLY=1
        shift
        ;;
    *)
        shift
        ;;
    esac
done

# Check if we are root.
ID=`id -u`
if [ `id -u` -ne 0 ]
then
    echoAndLog "FAIL: We are not running as root."
    exit 1
else
    echoAndLog "OK: We are running as root."
fi

# What platform am I on
if [ -f /bin/uname ]
then
  OS=`/bin/uname -s`
  REV=`/bin/uname -r`
  ARCH=`/bin/uname -m`
  PLAT=`/bin/uname -p`
  NAME=`/bin/uname -n`
else
  OS=`/usr/bin/uname -s`
  REV=`/usr/bin/uname -r`
  ARCH=`/usr/bin/uname -m`
  PLAT=`/usr/bin/uname -p`
  NAME=`/usr/bin/uname -n`
fi

if [ $OS == "Linux" ]
then
    LOCAL_PATH=/usr/bin:/usr/sbin:/sbin:/bin:/usr/local/bin:/usr/local/sbin
    LOCAL_MANPATH=/usr/local/man:/usr/man
    case $REV in
      4.9.70-v7+)
        echoAndLog "OS=${OS} REV=${REV} ARCH=${ARCH} PLAT=${PLAT} NAME=${NAME}"
        echoAndLog "OK: $OS kernel revision $REV is known to work and good results are expected."
      ;;
      4.14.*)
        echoAndLog "OS=${OS} REV=${REV} ARCH=${ARCH} PLAT=${PLAT} NAME=${NAME}"
        echoAndLog "OK: $OS kernel revision $REV is known to work and good results are expected."
      ;;
      *)
        echoAndLog "OS=${OS} REV=${REV} ARCH=${ARCH} PLAT=${PLAT} NAME=${NAME}"
        echoAndLog "WARNING: $OS kernel revision $REV is NOT KNOWN to work. Please let us know how it works."
        LOCAL_PATH=/usr/bin:/usr/sbin:/sbin:/bin:/usr/local/bin:/usr/local/sbin
        LOCAL_MANPATH=/usr/local/man:/usr/man
      ;;
    esac
fi

if [ $OS == "Darwin" ]
then
    LOCAL_PATH=/usr/bin:/usr/sbin:/var/root/bin/powerpc-apple-darwin:/var/root/bin:/bin:/usr/local/sbin:/sbin
    LOCAL_MANPATH=/sw/share/man:/sw/man:/var/root/man:/usr/local/share/man:/usr/share/man:/usr/man:/usr/share/man
    case $REV in
      5.*|6.*|7.*|8.*|9.*|10.*|11.*|12.*|13.*|14.*|15.*|16.*)
        # Fink env variable settings:
        # . /sw/bin/init.sh
        echoAndLog "OS=${OS} REV=${REV} ARCH=${ARCH} PLAT=${PLAT} NAME=${NAME}"
        echoAndLog "OK: $OS kernel revision $REV is known to work and good results are expected."
      ;;
      *)
        echoAndLog "OS=${OS} REV=${REV} ARCH=${ARCH} PLAT=${PLAT} NAME=${NAME}"
        echoAndLog "WARNING: $OS kernel revision $REV is NOT KNOWN to work. Please let us know how it works."
      ;;
  esac
fi

# If they exist, then add other paths that should be common to all platforms but don't add them to the path if they do not exist.
for ADDPATH in /usr/local/git /usr/local /opt/local /usr/pkg ~/$OS/$REV /opt/local/lib/mysql56/bin /opt/local/apache2/bin
do
  if [ -d $ADDPATH/bin ]
  then
    LOCAL_PATH=${LOCAL_PATH}:${ADDPATH}/bin
  fi
  if [ -d $ADDPATH/man ]
  then
    LOCAL_MANPATH=${LOCAL_MANPATH}:${ADDPATH}/man
  fi
  if [ -d $ADDPATH/share/man ]
  then
    LOCAL_MANPATH=${LOCAL_MANPATH}:${ADDPATH}/share/man
  fi
  if [ -d $ADDPATH/sbin ]
  then
    LOCAL_PATH=${LOCAL_PATH}:${ADDPATH}/sbin
  fi
done

echoAndLog "Now we will ask some questions to be used for setup later in the script..."
# echo "Please enter database_host [localhost]: "
# read database_host
database_host="127.0.0.1"

# echo "Please enter database_username [qruqsp]: "
# read database_username
database_username="admin"

# echo "Please enter database_name [qruqsp]: "
# read database_name
database_name="qruqsp"

# Only capture user information if run by user, ignore when prepare SD card
if [[ ${PREPARE_ONLY} -eq 0 ]]; then

    echo "Please enter admin_email: "
    read admin_email
    echoAndLog "admin_email=${admin_email}"

    echo "Please enter callsign"
    read callsign
    echoAndLog "callsign=${callsign}"

    echo "Please enter your preferred password for ${callsign}"
    read -s qruqsp_password

    echo
    echo "Please enter your preferred password for ${callsign} AGAIN"
    read -s again_qruqsp_password 
    echo

    if [ "${qruqsp_password}X" == "${again_qruqsp_password}X" ]
    then
        echoAndLog "OK: Passwords match"
    else
        echoAndLog "FATAL: Passwords do not match please run again ${0}"
        exit 1
    fi
fi

# echo "Please enter admin_username: [callsign]"
# read admin_username
# We prefer admin_username normally be LOWERCASE of callsign
admin_username=`echo ${callsign}|awk '{print tolower ($1)}'`
echoAndLog "admin_username=${admin_username}"

# echo "Please enter admin_password: "
# read admin_password
# FIXME: Create the random password or read it from my.cnf
# For now we will use MAC addresses from the eth0 and wlan0 interfaces which is a total of 34 characters including the colons
macs=`ifconfig -a | awk '/ether / {
    gsub (":", "", $2)
    printf ("%s", $2)
}'`

# Then add the CPU serial number
admin_password=`/usr/bin/awk '/Serial/ {print $3 MACS}' MACS=${macs} /proc/cpuinfo`
echoAndLog "admin_password=${admin_password}"

# echo "Please enter master_name which is master tenant name: ["
# read master_name
# We prefer master_name normally be UPPERCASE of callsign because it looks better in the UI in all uppercase
master_name=`echo ${callsign}|awk '{print toupper ($1)}'`
echoAndLog "master_name=${master_name}"

# This server_name is the part of the URL that is the hostname or IP address or however you get to it with DNS
# For our testing on locahost this has always been set to qruqsp.local and we put an entry in /etc/hosts
# echo "Please enter server_name: "
#read server_name
# The BEST OPTION is to use IP address from ifconfig so that it is easy to fix after DHCP gives a different IP address
# We will use the first inet (IPv4 address) that is not 127.0.0.1 in case they have more than one ethernet interface 
server_name=`ifconfig|awk '/inet / {if ($2 !~ "127.0.0.1") {print $2} }'|head -1`
echoAndLog "server_name=${server_name}"

# JUST_CHECK=1 will prevent rpi-update from actually updating anything and it will just get a list of commits contained in rpi-update since you last updated
JUST_CHECK=1
FIRMWARE=`rpi-update`
if [ $? -eq 2 ]
then
    echoAndLog "* WARNING: firmware is not up to date. rpi-update returned the following updates are recommended:"
    echoAndLog "${FIRMWARE}"
    echoAndLog "Press enter to update the firmware and reboot. Otherwise press any key followed by enter to skip firware update."
    read yes
    if [ "${yes}X" == "X" ]
    then
        JUST_CHECK=0
        rpi-update
        echoAndLog "Press enter to reboot. Then re-run ${0} to continue setup."
        read reboot
        reboot
    else
        echoAndLog "* WARNING: Skipping firmware update. This is not recommended but we will continue anyway and see what happens"
    fi
else
    echoAndLog "OK: The firmware is up to date"
fi

echoAndLog "Checking if ssh is active and running..."
/bin/systemctl status ssh
sshActive=`/bin/systemctl status ssh | /usr/bin/awk '/Active/ {print $2}'`
if [ "X$sshActive" == "Xactive" ] 
then
    echoAndLog "OK: ssh is active"
else
    echoAndLog "WARN: ssh is not active. It looks like ssh is ${sshActive}"
    echoAndLog "* Attempting to enable ssh..."
    /bin/systemctl enable ssh | tee -a /ciniki/logs/qruqsp_setup.txt
fi

echoAndLog "Checking if git is installed..."
gitInstalled=`which git | wc -l`
if [[ ${gitInstalled} -eq 1 ]];
then
    echoAndLog "OK: git is installed"
else
    echoAndLog "WARN: git is not installed."
    echoAndLog "* Attempting to install git..."
    apt-get install -y git
fi

sshRunning=`/bin/systemctl status ssh | /usr/bin/awk '/Active/ {print $3}'`
if [ "X$sshRunning" == "X(running)" ] 
then
    echoAndLog "OK: ssh is running"
else
    echoAndLog "WARN: ssh is not running. It looks like ssh is ${sshRunning}"
    echoAndLog "* Attempting to start ssh..."
    /bin/systemctl start ssh | tee -a /ciniki/logs/qruqsp_setup.txt
fi



########################################
# FIXME: Edit and test the script below.  This was really just pseudo-script in the notes I took during manual configurtions.
########################################
#
#    Raspberry Pi SDR IGate
#    Last update 11/9/2015
#    It’s easy to build a receive-only APRS Internet Gateway (IGate) with only a Raspberry Pi and a software defined radio (RTL-SDR) dongle. Here’s how.
#    Hardware Required
#        Raspberry Pi
#            I happened to use the model 2 so I can’t say, with certainty that the earlier models would be fast enough to keep up. “top” shows about 93% cpu idle time so the older models are probably more than adequate.
#            The procedure here is known to work with the Raspbian operating system. Some adjustments might be required for other operating systems.
#        SDR Dongle
#            This connects to the USB port and an antenna. This is the one I used.
#            http://www.amazon.com/NooElec-RTL-SDR-RTL2832U-Software-Packages/dp/B008S7AVTC
#            There are many others that appear to be equivalent such as
#            https://www.adafruit.com/products/1497
#    Software Required
#        Dire Wolf
#            Install following the instructions in Raspberry-Pi-APRS.pdf.
#            *** You can stop at the section called Interface for Radio. Here we are using the SDR dongle rather than a USB audio adapter.
#            Don’t worry about the configuration part because we will build our own configuration file here.
#    RTL-SDR Library from http://sdr.osmocom.org/trac/wiki/rtl-sdr
#
# 14:23:58 Start with: https://github.com/wb2osz/direwolf/blob/master/doc/Raspberry-Pi-APRS.pdf
#
#    Raspberry Pi Packet TNC, APRS Digipeater, IGate
#    Version 1.3 – Beta Test -- February 2016
#    In the early days of Amateur Packet Radio, it was necessary to use a “Terminal Node Controller” (TNC) with specialized hardware. Those days are gone. You can now get better results at lower cost by connecting your radio to the “soundcard” interface of a computer and running free software.
#    The Raspberry Pi (RPi) is a good platform for running a software TNC, APRS digipeater, and IGate. Why use a larger computer and waste hundreds of watts of power? All you need to add is a USB Audio Adapter ($8 or less) and a simple PTT circuit to activate the transmitter.
#    This document is a Quick Start guide for running Dire Wolf on the Raspberry Pi and describes special considerations where it may differ from other Linux systems.
#    After completing the steps here, refer to the User Guide for more details on the Linux version.
#
#    ...
#
#    The Raspbian “Wheezy” and “Jessie” distributions from http://www.raspberrypi.org/downloads are known to work with the instructions here. I haven’t tried the others and don’t know how they might differ.
#    The Raspian operating system distribution comes with the gcc compiler and most required libraries pre- installed. If you use a different operating system version, you might need to install a suitable compiler and/or additional libraries.
#
#    ... 
#
# Verify that gcc is configured to generate hardware floating point code. 
# Enter the “gcc –v” command and observe the result. 
# Make sure that “--with-fpu=vfp --with-float=hard” appears in the configuration.
if [ `gcc -v 2>&1 | egrep -c 'with-fpu=vfp'` -ne 1 ]
then
    echoAndLog "FAIL: gcc is NOT configured with --with-fpu=vfp to generate hardware floating point code."
    exit 1
else
    echoAndLog "OK: gcc is configured with --with-fpu=vfp as required to generate hardware floating point code."
fi
if [ `gcc -v 2>&1 | egrep -c 'with-float=hard'` -ne 1 ]
then
    echoAndLog "FAIL: gcc is NOT configured with --with-float=hard to generate hardware floating point code."
    exit 1
else
    echoAndLog "OK: gcc is configured with --with-float=hard to generate hardware floating point code."
fi


echoAndLog "* Supressing interactive questions from apt-get: export DEBIAN_FRONTEND=noninteractive"
export DEBIAN_FRONTEND=noninteractive

echoAndLog "* Running \"apt-get -y update\" to get the latest software and firmware updates."
echoAndLog "  This might take a while ..."
apt-get -y update | tee -a /ciniki/logs/qruqsp_setup.txt

#echoAndLog "* Running \"apt-get -y dist-upgrade\" to get the latest software and firmware updates."
#echoAndLog "  This might take a while ..."
#apt-get -y dist-upgrade | tee -a /ciniki/logs/qruqsp_setup.txt

echoAndLog "The audio system on the Raspberry Pi has a history of many problems."
# it was even worse the last time I struggled with it. I believe it is no longer included in the current version of Raspbian. ( See http://elinux.org/R-Pi_Troubleshooting#Removal_of_installed_pulseaudio )
echoAndLog "* We will remove pulseaudio if it is installed. Note: this applies only to the Raspberry Pi, and probably other similar ARM-based systems. Pulseaudio is fine on desktop/laptop computers with x86 processors."
apt-get -y remove --purge pulseaudio | tee -a /ciniki/logs/qruqsp_setup.txt
# Do you want to continue? [Y/n] Y
apt-get -y autoremove
# Do you want to continue? [Y/n] Y
rm -rf /home/pi/.pulse

echoAndLog "Checking if Pi firmware is up to date..."

# Install sound library.
echoAndLog "* Install the \"libasound2-dev\" package"
apt-get -y install libasound2-dev | tee -a /ciniki/logs/qruqsp_setup.txt
# Failure to install libasound2-dev step will result in a compile error resembling “audio.c:...: fatal error: alsa/asoundlib.h: No such file or directory”

# echoAndLog "Download Dire Wolf source code from github"
# Follow these steps to clone the git repository and checkout the desired version.
# cd ~
for needDir in /ciniki/logs /ciniki/bin /ciniki/db /ciniki/sites /ciniki/apache-sites-enabled
do
    if [ -d ${needDir} ]
    then
        echoAndLog "OK: Folder exists: ${needDir}"
    else
        echoAndLog "* Creating Folder: ${needDir}"
        mkdir -p ${needDir}
        chown pi:pi ${needDir}
        chmod 2755 -R ${needDir}
    fi
done

# Build from source because a Raspbian package doesn’t seem to be available. Here is my “cheat sheet” version boiled down from http://hamlib.sourceforge.net/manuals/1.2.15/_rdmedevel.html
echoAndLog "Install built tools if not already installed..."
    apt-get -y install automake libtool texinfo
#echoAndLog "Attempting to git clone hamlib and make it to provide support for more types of PTT control..."
    # git clone git://hamlib.git.sourceforge.net/gitroot/hamlib/hamlib /ciniki/src/hamlib
    # Above URL fails with error: fatal: read error: Connection reset by peer
    # git clone https://sourceforge.net/p/hamlib/code/ci/master/tree /ciniki/src/hamlib
    # git clone https://github.com/N0NB/hamlib /ciniki/src/hamlib
    # Above results in no ./configure and it seems that maybe autoscan autoconf automake or similar is required for this repo
# FIXME: We would prefer to always git clone the latest version. For now we use wget and download hamlib-3.0.1

echoAndLog "This completes the instructions from Raspberry-Pi-APRS.pdf which are required at this time."
echoAndLog "We can stop at the section called Interface for Radio. Here we are using the SDR dongle rather than a USB audio adapter."
echoAndLog "Don’t worry about the configuration part because we will build our own configuration file here."
echoAndLog "RTL-SDR Library from http://sdr.osmocom.org/trac/wiki/rtl-sdr"
apt-get -y update | tee -a /ciniki/logs/qruqsp_setup.txt
apt-get -y install cmake build-essential libusb-1.0-0-dev | tee -a /ciniki/logs/qruqsp_setup.txt

#
# Make sure gpsd is installed
#
echoAndLog "Make sure gpsd is installed"
apt-get -y install gpsd


# Optional support for gpsd
# This is covered in the separate document, Raspberry-Pi-APRS-Tracker.pdf.
# https://github.com/wb2osz/direwolf/blob/master/doc/Raspberry-Pi-APRS-Tracker.pdf

# Make a backup of your SD card (optional)
echoAndLog "After going through all of these steps, you might want to make a backup so you can get back to this point quickly if the memory card gets trashed. Here’s how: https://www.raspberrypi.org/forums/viewtopic.php?p=239331"

echoAndLog "Installing mariadb-server if not already installed"
apt-get -y install mariadb-server | tee -a /ciniki/logs/qruqsp_setup.txt

checkFiles /etc/mysql/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

##
## FIXME: This is may not be working correctly on ANdrew's Pi. Andrew has more than one sql_mode = entry in his my.cnf
##sqlMode=`egrep -c 'sql_mode\s+=\s+ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' /etc/mysql/my.cnf`
##if [ "${sqlMode}X" == "1X" ]
##then
##    echoAndLog "OK: /etc/mysql/my.cnf contains the sql_mode settings that are required."
##else
##    datetime=`date "+%Y-%m-%d_%H%M%S"`
##    echoAndLog "* Making a backup of /etc/mysql/my.cnf into /etc/mysql/my.cnf.backup-${datetime}"
##    cp -p /etc/mysql/my.cnf /etc/mysql/my.cnf.backup-${datetime}
##    echoAndLog "* Update /etc/mysql/my.cnf with the sql_mode settings that are required."
##    echo " " > /tmp/mysql_conf_ending
##    echo "[mysqld]" >> /tmp/mysql_conf_ending
##    echo "sql_mode = ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" >> /tmp/mysql_conf_ending
##    echo "datadir = /ciniki/db/mysql" >> /tmp/mysql_conf_ending
##    cat /etc/mysql/my.cnf.backup-${datetime} /tmp/mysql_conf_ending > /etc/mysql/my.cnf
##fi

if [ -f /home/pi/.my.cnf ]
then
    echoAndLog "OK: /home/pi/.my.cnf exists"
    # FIXME: read password from my.cnf and use it later in the script
else
    echoAndLog "* Create /home/pi/.my.cnf with mysql user and password. This saves having to type the user and password for each mysql command."
    echo "[client]" > /home/pi/.my.cnf
    echo "user=admin" >> /home/pi/.my.cnf
    echo "password=${admin_password}" >> /home/pi/.my.cnf
fi

echoAndLog "Chown pi:pi /home/pi/.my.cnf and chmod 700 /home/pi/.my.cnf just in case it is not set correctly"
chown pi:pi /home/pi/.my.cnf | tee -a /ciniki/logs/qruqsp_setup.txt
chmod 700 /home/pi/.my.cnf | tee -a /ciniki/logs/qruqsp_setup.txt
echoAndLog "FIXME: It seems that Raspbian stretch switched from mysql to MariaDB and /home/pi/.my.cnf no longer works as it did with mysql. We wil have to run mysql commands as root nutil we figure this out."
# check that innodb_* and sql_mode settings have been added to /etc/mysql/mariadb.conf.d/50-server.cnf
innodbOptions=`egrep -c 'default-character-set = latin1|innodb_file_per_table = 1|character-set-server = latin1|collation-server = latin1_general_ci|default-character-set = latin1' /etc/mysql/mariadb.conf.d/51-ciniki.cnf`
if [ "${innodbOptions}X" == "4X" ]
then
    echoAndLog "OK: /etc/mysql/mariadb.conf.d/51-ciniki.cnf contains ${innodbOptions} of 8 of the innodb_* and sql_mode settings that are required."
else
    echoAndLog "*** UNEXPECTED: /etc/mysql/mariadb.conf.d/51-ciniki.cnf CONTAINS ONLY ${innodbOptions} of 8 of the innodb_* and sql_mode settings that are required."
    TODO="${TODO}\n *** UNEXPECTED: /etc/mysql/mariadb.conf.d/51-ciniki.cnf CONTAINS ONLY ${innodbOptions} of 8 of the innodb_* and sql_mode settings that are required."
    echoAndLog "*** Deleting and recreating /etc/mysql/mariadb.conf.d/51-ciniki.cnf"
    rm /etc/mysql/mariadb.conf.d/51-ciniki.cnf
#     datetime=`date "+%Y-%m-%d_%H%M%S"`
#     echoAndLog "* Making a backup of /etc/mysql/mariadb.conf.d/50-server.cnf into /etc/mysql/50-server.cnf.backup-${datetime}"
#     cp -p /etc/mysql/mariadb.conf.d/50-server.cnf /etc/mysql/50-server.cnf.backup-${datetime}
#     echoAndLog "* Update /etc/mysql/mariadb.conf.d/50-server.cnf with the innodb_* and sql_mode settings that are required."
#     awk '{gsub FIXME 
#     echo " " > /tmp/mysql_conf_ending
#     echo "[mysqld]" >> /tmp/mysql_conf_ending
#     echo "sql_mode = ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" >> /tmp/mysql_conf_ending
#     cat /etc/mysql/my.cnf.backup-${datetime} /tmp/mysql_conf_ending > /etc/mysql/my.cnf
fi

# check that innodb_* and sql_mode settings have been added to /etc/mysql/mariadb.conf.d/51-ciniki.cnf
if [ -f /etc/mysql/mariadb.conf.d/51-ciniki.cnf ]
then
    echoAndLog "OK: /etc/mysql/mariadb.conf.d/51-ciniki.cnf exists"
else
    echo "# DO NOT TOUCH THIS FILE because it is auto-generated" > /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "# These options are required to work-around InnoDB MariaDB 10.1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "[mysql]" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "default-character-set = latin1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "[mysqld]" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "#" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "# Additional settings for Ciniki and qruqsp" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "#" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
#    echo "innodb_large_prefix = 1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
#    echo "innodb_file_format = barracuda" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
#    echo "innodb_file_format_max = barracuda" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "innodb_file_per_table = 1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
#    echo "# sql_mode = \"NO_ENGINE_SUBSTITUTION\"" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "character-set-server = latin1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "collation-server = latin1_general_ci" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "sql_mode = ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    if [[ ${PREPARE_ONLY} -eq 1 ]]; then
        echo "datadir = /ciniki/db/mysql" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    fi
    echo "" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "[client]" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "default-character-set = latin1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    service mariadb stop | tee -a /ciniki/logs/qruqsp_setup.txt
    if [[ ${PREPARE_ONLY} -eq 1 ]]; then
        mv /var/lib/mysql /ciniki/db/
    fi
    service mariadb start | tee -a /ciniki/logs/qruqsp_setup.txt
fi

echoAndLog "Checking for qruqsp database..."
if [ `mysqlshow qruqsp | grep -c 'Database: qruqsp'` == "1" ]
then
    echoAndLog "OK: qruqsp database exists"
else
    echoAndLog "* Create qruqsp database because it does not already exist"
    mysqladmin --default-character-set=latin1 create qruqsp | tee -a /ciniki/logs/qruqsp_setup.txt
fi

echoAndLog "Checking for database admin user..."
if [ `mysql --user root -sse 'SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = "admin")' mysql` == "1" ]
then
    echoAndLog "OK: database admin exists"
else
    echoAndLog "* Create database admin user because it does not already exist"
    mysql -e "GRANT ALL PRIVILEGES ON qruqsp.* TO 'admin'@'localhost' IDENTIFIED BY '${admin_password}';" mysql
fi

echoAndLog "Install Apache and PHP if not already installed"
apt-get -y install apache2 php-xml php-imagick php-intl php-zip php-curl php-mysql php-json php-readline php-imap libapache2-mod-php | tee -a /ciniki/logs/qruqsp_setup.txt

if [ `egrep -c '127.0.1.1\s+qruqsp.local\s+qruqsp' /etc/hosts` == "1" ]
then
    echoAndLog "OK \"127.0.1.1  qruqsp.local  qruqsp\" exists in /etc/hosts"
else
    timestamp=`date "+%Y-%m-%d %H:%M:%S"`
    echo "${timestamp} ${@}" | tee -a /ciniki/logs/qruqsp_setup.txt
    echoAndLog "backup /etc/hosts to /etc/hosts.backup.${timestamp}"
    cp /etc/hosts /etc/hosts.backup.${timestamp} | tee -a /ciniki/logs/qruqsp_setup.txt
    echoAndLog "Add \"127.0.1.1  qruqsp.local  qruqsp\" to /etc/hosts"
    echo "127.0.1.1  qruqsp.local    qruqsp" > /ciniki/logs/hosts.qruqsp
    cat /etc/hosts.backup.${timestamp} /ciniki/logs/hosts.qruqsp > /etc/hosts
    rm /ciniki/logs/hosts.qruqsp
fi

#
# Setup /etc/hostname to be qruqsp
#
if [[ ${PREPARE_ONLY} -eq 1 ]]; then
    echo "qruqsp" >/etc/hostname
fi

#
# Setup the directory structure and get the latest pi code
#
for needDir in /ciniki/sites/qruqsp.local /ciniki/sites/qruqsp.local/site /ciniki/sites/qruqsp.local/logs /ciniki/sites/qruqsp.local/site/ciniki-mods /ciniki/sites/qruqsp.local/site/qruqsp-mods /ciniki/sites/qruqsp.local/site/ciniki-cache /ciniki/sites/qruqsp.local/site/ciniki-storage /ciniki/sites/qruqsp.local/site/ciniki-picode
do
    if [ -d ${needDir} ]
    then
        echoAndLog "OK: Folder exists: ${needDir}"
    else
        echoAndLog "* Creating Folder: ${needDir}"
        mkdir -p ${needDir}
        chown pi:pi ${needDir}
        chmod 2755 -R ${needDir}
    fi
done

#
# Mirror the latest code from ciniki-picode directory at qruqsp.org
#
sudo -u pi wget -nd -P /ciniki/sites/qruqsp.local/site/ciniki-picode -m https://qruqsp.org/ciniki-picode/files.html

#
# unzip the files, rerun every time to get the latest code
#
sudo -u pi ls /ciniki/sites/qruqsp.local/site/ciniki-picode/*.zip |sed 's/^\(.*\)\/\([[:alnum:]]\+\).\([[:alnum:]]\+\).zip/unzip -o -d \/ciniki\/sites\/qruqsp.local\/site\/\2-mods\/\3 \1\/\2.\3.zip/' | sh

#
# Copy the pi-installer.php file (Now included in piadmin module)
#
#sudo -u pi wget -O /ciniki/sites/qruqsp.local/site/pi-install.php https://raw.githubusercontent.com/QRUQSP/qruqsp/master/site/pi-install.php

#
# Setup black box mode, giving UI full control over pi functions
#
if [[ ${PREPARE_ONLY} -eq 1 ]]; then
    echo "this file enables qruqsp ui to have full control over pi" >/ciniki/sites/qruqsp.local/.blackbox
fi

# We always want to git pull and git submodule update so that we have the latest updates to the qruqsp code
#echoAndLog "* git pull"
#sudo -u pi git pull /ciniki/sites/qruqsp.local | tee -a /ciniki/logs/qruqsp_setup.txt
#echoAndLog "* git submodule update"
#(cd /ciniki/sites/qruqsp.local && sudo -u pi git submodule update --init /ciniki/sites/qruqsp.local) | tee -a /ciniki/logs/qruqsp_setup.txt

# echoAndLog "* Make sure we have updated qruqsp code using git submodule update --init"
# (cd /ciniki/sites/qruqsp.local && git submodule update --init) | tee -a /ciniki/logs/qruqsp_setup.txt

# FIXED: This should be in /ciniki/sites/qruqsp.local/apache.conf
# if [ -f /etc/apache2/sites-available/qruqsp.local.conf ]
if [ -f /ciniki/sites/qruqsp.local/apache.conf ]
then
    echoAndLog "OK: /ciniki/sites/qruqsp.local/apache.conf exists"
else
    echoAndLog "* Create /ciniki/sites/qruqsp.local/apache.conf"
    cat > /ciniki/sites/qruqsp.local/apache.conf <<EOL
LISTEN 8080
<VirtualHost *:8080>
    DocumentRoot /ciniki/sites/qruqsp.local/site
    <Directory />
        Options FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>
    <Directory /ciniki/sites/qruqsp.local/site/>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog /ciniki/sites/qruqsp.local/logs/error.log
    CustomLog /ciniki/sites/qruqsp.local/logs/access.log combined
</VirtualHost>
EOL
fi

if [ -s /ciniki/apache-sites-enabled/qruqsp.local.conf ]
then
    echoAndLog "OK: /ciniki/apache-sites-enabled/qruqsp.local.conf symbolic link exists"
else
    echoAndLog "* Create symbolic link /ciniki/apache-sites-enabled/qruqsp.local.conf /ciniki/sites/qruqsp.local/apache.conf"
    ln -s /ciniki/sites/qruqsp.local/apache.conf /ciniki/apache-sites-enabled/qruqsp.local.conf 
fi

APINC=`egrep -c "IncludeOptional /ciniki/apache-sites-enabled/\*.conf" /etc/apache2/apache2.conf`
if [ "${APINC}X" == "1X" ]
then
    echoAndLog "OK: /etc/apache2/apache2.conf already includes: IncludeOptional /ciniki/apache-sites-enabled/*.conf"
else
    echoAndLog "*Add: IncludeOptional /ciniki/apache-sites-enabled/*.conf to /etc/apache2/apache2.conf"
    echo "IncludeOptional /ciniki/apache-sites-enabled/*.conf" >> /etc/apache2/apache2.conf
fi

# FIXED: THis should be a2enmod rewrite instead of creating the link
#    echoAndLog "Link /etc/apache2/sites-enabled/qruqsp.local.conf and /etc/apache2/mods-enabled/rewrite.load"
#    ln -s /etc/apache2/sites-available/qruqsp.local.conf /etc/apache2/sites-enabled/qruqsp.local.conf
#    ls -l /etc/apache2/sites-available/qruqsp.local.conf /etc/apache2/sites-enabled/qruqsp.local.conf | tee -a /ciniki/logs/qruqsp_setup.txt
#    echoAndLog "Link /etc/apache2/mods-available/rewrite.load and /etc/apache2/mods-enabled/rewrite.load"
#    ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load
#    ls -l /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load | tee -a /ciniki/logs/qruqsp_setup.txt
#fi
# FIXED: Below does the same as above in a better way
echoAndLog "Make sure mod_rewrite is enabled"
# Result should be "Module rewrite already enabled"
a2enmod rewrite | tee -a /ciniki/logs/qruqsp_setup.txt

APACHE_RUN_USER=`awk -F '=' '/APACHE_RUN_USER/ {print $2}' /etc/apache2/envvars`
APACHE_RUN_GROUP=`awk -F '=' '/APACHE_RUN_GROUP/ {print $2}' /etc/apache2/envvars`

if [ "${APACHE_RUN_USER}X" == "piX" ] && [ "${APACHE_RUN_GROUP}X" == "piX" ]
then
    echoAndLog "OK: APACHE_RUN_USER=${APACHE_RUN_USER} in /etc/apache2/envvars"
    echoAndLog "OK: APACHE_RUN_GROUP=${APACHE_RUN_GROUP} in /etc/apache2/envvars"
else
    echoAndLog "* Currently: APACHE_RUN_USER=${APACHE_RUN_USER} in /etc/apache2/envvars"
    echoAndLog "* Change to: APACHE_RUN_USER=pi"
    echoAndLog "* Currently: APACHE_RUN_GROUP=${APACHE_RUN_GROUP} in /etc/apache2/envvars"
    echoAndLog "* Change to: APACHE_RUN_GROUP=pi"
    datetime=`date "+%Y-%m-%d_%H%M%S"`
    echoAndLog "* Backup /etc/apache2/envvars to /etc/apache2/envvars.${datetime}"
    cp -p /etc/apache2/envvars /etc/apache2/envvars.${datetime}
    awk -F '=' '{
        if ($1 ~ /APACHE_RUN_(USER|GROUP)/) {
            print $1 "=pi"
        }
        else {
            print $0
        }
    }' /etc/apache2/envvars.${datetime} > /etc/apache2/envvars
    syntaxOK=`/usr/sbin/apache2ctl configtest 2>&1 | grep -c 'Syntax OK'`
    if [ "${syntaxOK}X" == "1X" ]
    then
        echoAndLog "OK: /usr/sbin/apache2ctl configtest returned Syntax OK"
        echoAndLog "* Restart apache for configuration to pi user and group to take affect"
        /usr/sbin/apache2ctl stop | tee -a /ciniki/logs/qruqsp_setup.txt
        /usr/sbin/apache2ctl start | tee -a /ciniki/logs/qruqsp_setup.txt
    else
        echoAndLog "*** WARNING: /usr/sbin/apache2ctl configtest did NOT return Syntax OK"
        echoAndLog "* Restore: /etc/apache2/envvars.${datetime} to /etc/apache2/envvars"
        co -p /etc/apache2/envvars.${datetime} /etc/apache2/envvars
    fi
fi

#
# If in prepare mode, setup redirect
#
if [[ ${PREPARE_ONLY} -eq 1 ]]; then
    rm /var/www/html/index.html
    echo "<?php Header(\"Location: http://{\$_SERVER['HTTP_HOST']}:8080/\",301); exit;?>" > /var/www/html/index.php
fi

# php /ciniki/sites/qruqsp.local/site/qruqsp-install.php
# FIXME: PHP Warning:  mysqli_connect(): (HY000/1698): Access denied for user 'qruqsp'@'localhost' in /ciniki/sites/qruqsp.local/site/ciniki-mods/core/private/dbConnect.php on line 71
# FIXME  Error: ciniki.ciniki.core.33 - Failed to to connect to the database, please check your connection settings and try again.<br/><br/>Database error
# FIXME -de Aria on maria 10.1 or 10.0 and not incldued otherwise
MYSQLVER=`mysql --version | awk '{print substr ($0, index ($0, "Distrib")+8, 4)  }'`
if [ "$MYSQLVER}X" == "10.0X" ] || [ "$MYSQLVER}X" == "10.1X" ]
then
    DBENG="-de Aria"
    echoAndLog "WARNING: Aria Database Engine will be used as a work-around to MariaDB version ${MYSQLVER}"
else
    echoAndLog "OK: MySQL version is ${MYSQLVER} and threfore the Aria Database Engine will be InnoBB as preferred. The work-around for MariaDB versions 10.1 and 10.2 are not required."
fi

if [[ ${PREPARE_ONLY} -eq 0 ]]; then
    echoAndLog "OK: Running qruqsp-install"
    php /ciniki/sites/qruqsp.local/site/qruqsp-install.php ${DBENG} -dh ${database_host} -du ${database_username} -dp ${admin_password} -dn ${database_name} -ae ${admin_email} -au ${admin_username} -ap ${qruqsp_password} -mn ${master_name} -un {server_name} | tee -a /ciniki/logs/qruqsp_setup.txt
else
    echoAndLog "OK: Linking index to pi-install.php"
    sudo -u pi ln -s /ciniki/sites/qruqsp.local/site/qruqsp-mods/piadmin/scripts/pi-install.php /ciniki/sites/qruqsp.local/site/index.php
fi

# if I need to rerun:
# mysqladmin drop qruqsp
# rm -rf /ciniki/sites/qruqsp.local

CINIKICRONS=`crontab -l | egrep -c "/ciniki/sites/qruqsp.local/site/ciniki-mods/cron/scripts/cron.php"`
if [ "${CINIKICRONS}X" == "3X" ]
then
    echoAndLog "OK: root crontab already includes ${CINIKICRONS} ciniki cron.php entries"
else
    echoAndLog "*Adding root crontab entries for ciniki cron.php"
    sudo -u pi crontab -l > /tmp/cinikicron
    echo "*/5 * * * * /usr/bin/php /ciniki/sites/qruqsp.local/site/ciniki-mods/cron/scripts/cron.php ciniki.mail >>/ciniki/sites/qruqsp.local/logs/cron.log 2>&1" >> /tmp/cinikicron
    echo "*/5 * * * * /usr/bin/php /ciniki/sites/qruqsp.local/site/ciniki-mods/cron/scripts/cron.php -ignore ciniki.mail >>/ciniki/sites/qruqsp.local/logs/cron.log 2>&1" >> /tmp/cinikicron
    echo "* * * * * /usr/bin/php /ciniki/sites/qruqsp.local/site/qruqsp-mods/tnc/scripts/check.php >>/ciniki/sites/qruqsp.local/logs/cron.log 2>&1" >> /tmp/cinikicron
    echo "* * * * * /usr/bin/php /ciniki/sites/qruqsp.local/site/qruqsp-mods/43392/scripts/check.php >>/ciniki/sites/qruqsp.local/logs/cron.log 2>&1" >> /tmp/cinikicron
    echo "* * * * * /usr/bin/php /ciniki/sites/qruqsp.local/site/qruqsp-mods/i2c/scripts/poll.php >>/ciniki/sites/qruqsp.local/logs/i2c.log 2>&1" >> /tmp/cinikicron
    echo "1 0 1 * * /bin/bash /ciniki/sites/qruqsp.local/site/qruqsp-mods/piadmin/scripts/roll_apache_logs.sh >>/ciniki/sites/qruqsp.local/logs/cron.log 2>&1" >> /tmp/cinikicron
    sudo -u pi crontab /tmp/cinikicron
    rm /tmp/cinikicron
fi

#
# When prepare only mode specified, then setup for wifi hotspot
#
if [[ ${PREPARE_ONLY} -eq 1 ]]; then
    #
    # Setup for wifi hotspot
    #
    echoAndLog "Install hostapd and dnsmasq"
    apt-get -y install hostapd dnsmasq
    
    # Setup the /etc/hostapd/hostapd.conf file
    if [ -f /etc/hostapd/hostapd.conf ]
    then
        echoAndLog "It looks like we have already have a config for hostspot"
    else
        echoAndLog "Setup /etc/hostapd/hostapd.conf file"
        echo "interface=wlan0" >> /etc/hostapd/hostapd.conf
        echo "driver=nl80211" >> /etc/hostapd/hostapd.conf
        echo "ssid=QRUQSP" >> /etc/hostapd/hostapd.conf
        echo "hw_mode=g" >> /etc/hostapd/hostapd.conf
        echo "channel=1" >> /etc/hostapd/hostapd.conf
        echo "wmm_enabled=1" >> /etc/hostapd/hostapd.conf
        echo "macaddr_acl=0" >> /etc/hostapd/hostapd.conf
        echo "auth_algs=1" >> /etc/hostapd/hostapd.conf
        echo "ignore_broadcast_ssid=0" >> /etc/hostapd/hostapd.conf
        echo "wpa=2" >> /etc/hostapd/hostapd.conf
        echo "wpa_passphrase=hamradio" >> /etc/hostapd/hostapd.conf
        echo "wpa_key_mgmt=WPA-PSK" >> /etc/hostapd/hostapd.conf
        echo "wpa_pairwise=TKIP" >> /etc/hostapd/hostapd.conf
        echo "wpa_pairwise=CCMP" >> /etc/hostapd/hostapd.conf
    fi
    # setup the /etc/default/hostapd conf file
    HOSTAPD=`egrep -c "^[^#]*DAEMON_CONF=" /etc/default/hostapd`
    if [ "${HOSTAPD}X" == "0X" ]
    then
        echoAndLog "Add: DAEMON_CONF line to /etc/default/hostapd"
        echo "DAEMON_CONF='/etc/hostapd/hostapd.conf'" >> /etc/default/hostapd
    fi

    # Setup the /etc/dnsmasq/dnsmasq.conf file
    DNSMASQ=`egrep -c "^[^#]+dhcp-range=" /etc/dnsmasq.conf`;
    if [ "${DNSMASQ}X" == "0X" ]
    then
        echoAndLog "Setup /etc/dnsmasq.conf file"
        # Remove dhcp-mac, dhcp-reply
        sed -i 's/^dhcp-mac/#dhcp-mac/g' /etc/dnsmasq.conf
        sed -i 's/^dhcp-reply/#dhcp-mac/g' /etc/dnsmasq.conf
        echo "interface=wlan0" >> /etc/dnsmasq.conf
        echo "domain-needed" >> /etc/dnsmasq.conf
        echo "bogus-priv" >> /etc/dnsmasq.conf
        echo "dhcp-range=10.99.1.50,10.99.1.250,255.255.255.0,24h" >> /etc/dnsmasq.conf
    fi

    # Check for /etc/dhcpcd.conf setup
    DHCPWLAN=`egrep -c "^[^#]*interface wlan0=" /etc/dhcpcd.conf`;
    if [ "${DHCPWLAN}X" == "0X" ]
    then
        echoAndLog "Setup /etc/dhcpcd.conf file"
        echo "interface wlan0" >> /etc/dhcpcd.conf
        echo "    static ip_address=10.99.1.1/24" >> /etc/dhcpcd.conf
        echo "    nohook wpa_supplicant" >> /etc/dhcpcd.conf
    fi

    systemctl unmask hostapd | tee -a /ciniki/logs/qruqsp_setup.txt
    systemctl enable hostapd | tee -a /ciniki/logs/qruqsp_setup.txt
    systemctl start hostapd | tee -a /ciniki/logs/qruqsp_setup.txt
    systemctl start dnsmasq | tee -a /ciniki/logs/qruqsp_setup.txt
fi

#
# Make sure the pi user has been added to group tty so they can use
# the tty for direwolf to send and receive
#
echoAndLog "Make sure pi user is added to group tty for direwolf transmit"
usermod -a -G tty pi

#
# Setup apache2 to use /tmp instead of private tmp, this allows the php scripts
# access to the /tmp/kisspts for direwolf
#
if [ -d /etc/systemd/system/apache2.service ]
then
    echoAndLog "OK: apache2 PrivateTmp is set to false"
else
    cat /lib/systemd/system/apache2.service |sed 's/PrivateTmp=true/PrivateTmp=false/g' >/etc/systemd/system/apache2.service
fi

echoAndLog "Install lshw if not installed already"
apt-get -y install lshw

#
# The dtparam=i2c_arm=on should be commented out. The i2c is setup
# in on alternate gpio pins to allow for push button shutdown/startup.
#
DTOVERLAYI2CARM=`awk '/^dtparam.*=.*i2c/' /boot/config.txt`
if [ "${DTOVERLAYI2CARM}X" != "X" ]
then 
    echoAndLog "WARNING: ${DTOVERLAYI2CARM} enabled in /boot/config.txt"
else
    echoAndLog "* OK: dtparam=i2c_arm=on not enabled in /boot/config.txt"
fi

#
# Check for i2c enabled on alternate gpio pins. GPIO3 needs to
# be left alone so it can be used for clean shutdown and restart. 
#
DTOVERLAYI2C=`awk '/^dtoverlay.*=.*i2c-gpio/' /boot/config.txt`

if [ "${DTOVERLAYI2C}X" == "X" ]
then
    echo "dtoverlay=i2c-gpio,i2c_gpio_sda=17,i2c_gpio_scl=27" >> /boot/config.txt
    echoAndLog "* Added: dtoverlay=i2c-gpio in /boot/config.txt"
else
    echoAndLog "* OK: ${DTOVERLAYI2C} in /boot/config.txt"
fi

#
# Check to make sure GPIO3 is setup to clean shutdown pi
#
DTOVERLAYSHUTDOWN=`awk '/^dtoverlay.*=.*gpio-shutdown/' /boot/config.txt`

if [ "${DTOVERLAYSHUTDOWN}X" == "X" ]
then
    echo "dtoverlay=gpio-shutdown,gpio_pin=3" >> /boot/config.txt
    echoAndLog "* Added: dtoverlay=gpio-shutdown in /boot/config.txt"
else
    echoAndLog "* OK: ${DTOVERLAYSHUTDOWN} in /boot/config.txt"
fi

# Print any to do items here if we loaded them into this TODO variable earlier in the script. This is the last thing we want the user to see before END.
TODOS=`echo ${TODO} | grep -c TODO`
if [ "${TODOS}X" != "0X" ]
then
    echoAndLog "${TODO}"
fi

echoAndLog "------------------------------------------------------"
echoAndLog "| END $0"
echoAndLog "| See log in /ciniki/logs/qruqsp_setup.txt"
echoAndLog "------------------------------------------------------"
