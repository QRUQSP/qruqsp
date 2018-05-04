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

# Check for arguments
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

echoAndLog "* Running \"apt-get -y dist-upgrade\" to get the latest software and firmware updates."
echoAndLog "  This might take a while ..."
apt-get -y dist-upgrade | tee -a /ciniki/logs/qruqsp_setup.txt

echoAndLog "The audio system on the Raspberry Pi has a history of many problems."
# it was even worse the last time I struggled with it. I believe it is no longer included in the current version of Raspbian. ( See http://elinux.org/R-Pi_Troubleshooting#Removal_of_installed_pulseaudio )
echoAndLog "* We will remove pulseaudio if it is installed. Note: this applies only to the Raspberry Pi, and probably other similar ARM-based systems. Pulseaudio is fine on desktop/laptop computers with x86 processors."
apt-get -y remove --purge pulseaudio | tee -a /ciniki/logs/qruqsp_setup.txt
# Do you want to continue? [Y/n] Y
apt-get -y autoremove
# Do you want to continue? [Y/n] Y
rm -rf /home/pi/.pulse

echoAndLog "Checking if Pi firmware is up to date..."

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

# Install sound library.
echoAndLog "* Install the \"libasound2-dev\" package"
apt-get -y install libasound2-dev | tee -a /ciniki/logs/qruqsp_setup.txt
# Failure to install libasound2-dev step will result in a compile error resembling “audio.c:...: fatal error: alsa/asoundlib.h: No such file or directory”

echoAndLog "Download Dire Wolf source code from github"
# Follow these steps to clone the git repository and checkout the desired version.
# cd ~
for needDir in /ciniki/logs /ciniki/bin /ciniki/db/mysql /ciniki/src/direwolf /ciniki/src/hamlib /ciniki/sites /ciniki/apache-sites-enabled
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

if [ -f /ciniki/src/direwolf/Makefile ]
then
    echoAndLog "It looks like we have already pulled direwolf from github"
else
    echoAndLog "* git clone direwolf"
    git clone https://www.github.com/wb2osz/direwolf /ciniki/src/direwolf | tee -a /ciniki/logs/qruqsp_setup.txt
fi

# At this pint you should have the most recent stable version which is probably what you want in most cases. 
# There are times when you might want to get a specific older version. To get a list of them, type:
#   git tag
# You should see a list of releases and development snapshots, something like this:
    # 1.0
    # 1.1
    # 1.2
    # 1.3-beta
    # 1.3-dev-F
    # 1.3-dev-I
    # 1.3-dev-K
    # 1.4-dev-D
    # 1.4-dev-E
# To select a specific version, specify the tag like this:
#   git checkout 1.3
# In some cases, you might want the latest (sometimes unstable) development version to test a bug fix or get a preview of a new (possibly incomplete) feature that will be in the next release. In that case, type:
#   git checkout dev

# Optional support for hamlib
# Skip this step if you don’t want to use “hamlib.”
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
echoAndLog "Attempting to wget hamlib and make it to provide support for more types of PTT control..."
if [ -d /ciniki/src/hamlib-3.0.1 ]
then
    echoAndLog "OK: It looks like we have downloaded hamlib from sourceforge.net into /ciniki/src/hamlib-3.0.1"
else
    echoAndLog "* wget /ciniki/src/hamlib-latest.tar.gz"
    wget -O /ciniki/src/hamlib-latest.tar.gz "https://downloads.sourceforge.net/project/hamlib/hamlib/3.0.1/hamlib-3.0.1.tar.gz?r=https%3A%2F%2Fsourceforge.net%2Fprojects%2Fhamlib%2F%3Fsource%3Dtyp_redirect&ts=1514591482&use_mirror=svwh" | tee -a /ciniki/logs/qruqsp_setup.txt
    echoAndLog "* tar xzf /ciniki/src/hamlib-latest.tar.gz"
    (cd /ciniki/src && tar xzf /ciniki/src/hamlib-latest.tar.gz) | tee -a /ciniki/logs/qruqsp_setup.txt
fi

if [ -f /usr/local/lib/libhamlib.so ]
then
    echoAndLog "OK: It looks like hamlib has already been compiled and installed to suppport more types of PTT control..."
else
    echoAndLog "* Attempting to configure hamlib for more types of PTT control..."
    (cd /ciniki/src/hamlib-3.0.1 && ./configure) | tee -a /ciniki/logs/qruqsp_setup.txt
    echoAndLog "* Attempting to make hamlib for more types of PTT control..."
    make -C /ciniki/src/hamlib-3.0.1 | tee -a /ciniki/logs/qruqsp_setup.txt
    echoAndLog "* Attempting to make check hamlib for more types of PTT control..."
    make -C /ciniki/src/hamlib-3.0.1 check | tee -a /ciniki/logs/qruqsp_setup.txt
    echoAndLog "* Attempting to make install hamlib for more types of PTT control..."
    make -C /ciniki/src/hamlib-3.0.1 install | tee -a /ciniki/logs/qruqsp_setup.txt
fi

echoAndLog "Check for files that should have been created by the make of hamlib..."
# You should now have many new files including:
checkFiles /usr/local/include/hamlib/rig.h /usr/local/lib/libhamlib.so

if [ -f /usr/local/bin/direwolf ]
then
    echoAndLog "OK: It looks like direwolf had already been compiled and installed..."
else
    # When building direwolf, the compiler and linker know enough to search /usr/local/include/... and /usr/local/lib/... but when it comes time to run direwolf, you might see a message like this:
    # direwolf: error while loading shared libraries: libhamlib.so.2: cannot open shared object file: No such file or directory
    # Edit your ~/.bashrc file and add this after the initial comment lines, and before the part that tests for running interactively.
    export LD_LIBRARY_PATH=/usr/local/lib
    # Type this so it will take effect now, instead of waiting for next login:
    #    source ~/.bashrc
    # Edit direwolf/Makefile.linux and look for this section:
    # Uncomment following lines to enable hamlib support. 
    #CFLAGS += -DUSE_HAMLIB
    #LDFLAGS += -lhamlib
    perl -pi -e 's/#CFLAGS/CFLAGS/g; s/#LDFLAGS/LDFLAGS/g' /ciniki/src/direwolf/Makefile.linux
    egrep -i 'hamlib' /ciniki/src/direwolf/Makefile.linux | tee -a /ciniki/logs/qruqsp_setup.txt

    # Compile an install the Direwolf application.
    # cd ~/direwolf
    make -C /ciniki/src/direwolf | tee -a /ciniki/logs/qruqsp_setup.txt
    make -C /ciniki/src/direwolf install | tee -a /ciniki/logs/qruqsp_setup.txt

    # NOTE The above 'sudo make install' outputs the following but don't do it yet.
    # If this is your first install, not an upgrade, type this to put a copy
    # of the sample configuration file (direwolf.conf) in your home directory:
    # make install-conf
    # This gets done a little later after verification of a few required files

    make -C /ciniki/src/direwolf install-rpi

    # OUTPUT from make install-rpi
    # cp dw-start.sh ~
    # ln -f -s /usr/share/applications/direwolf.desktop ~/Desktop/direwolf.desktop
fi

echoAndLog "You should now have files, and more, in these locations, under /usr/local, owned by root."
echoAndLog "Check for files that should have been created by the make of direwolf..."
checkFiles /usr/local/bin/direwolf /usr/local/bin/decode_aprs /usr/local/bin/tt2text /usr/local/bin/text2tt /usr/local/bin/ll2utm /usr/local/bin/utm2ll /usr/local/bin/log2gpx /usr/local/bin/gen_packets /usr/share/applications/direwolf.desktop /usr/share/direwolf/tocalls.txt /usr/share/direwolf/symbolsX.txt /usr/share/direwolf/symbols-new.txt /usr/share/direwolf/dw-icon.png /usr/share/applications/direwolf.desktop 
    # FIXME: the following files seem to be expected but missing. Do we really need these?
    # /home/pi/Desktop/direwolf.desktop /home/pi/dw-start.sh /home/pi/dw-start.sh /home/pi/direwolf.conf /home/pi/direwolf.conf.keep 

    # echoAndLog "Utility to interpret “raw” data you might find on http://aprs.fi or http://findu.com"
    # ls -l /usr/local/bin/tt2text /usr/local/bin/text2tt /usr/local/bin/ll2utm /usr/local/bin/utm2ll /usr/local/bin/log2gpx /usr/local/bin/gen_packets
    # echoAndLog "Utilities related to APRStt gateway, UTM coordinates, log file to GPX conversion, and test packet generation."
    # ls -l /usr/share/applications/direwolf.desktop
    # echoAndLog "Application definition with icon, command to execute, etc."
    # ls -l /usr/share/direwolf/tocalls.txt
    # echoAndLog "Mapping from destination address to system type. Search order for tocalls.txt is first the current working directory and then /usr/share/direwolf."
    # ls -l /usr/share/direwolf/symbolsX.txt /usr/share/direwolf/symbols-new.txt
    # echoAndLog "Descriptions and codes for APRS symbols."
    # ls -l /usr/share/direwolf/dw-icon.png
    # echoAndLog "Icon for the desktop."
    # ls -l /usr/local/share/doc/direwolf/* /usr/local/man/man1/*
    # echoAndLog "Various documentation."
    # ls -l /usr/local/share/doc/direwolf/examples/*
    # echoAndLog "Sample configuration and other examples."
    # echoAndLog "You should also have these files, under /home/pi."
    # ls -l /home/pi/Desktop/direwolf.desktop
    # echoAndLog "Symbolic link to /usr/share/applications/direwolf.desktop. This causes an icon to be displayed on the desktop."
    # ls -l /home/pi/dw-start.sh
    # echoAndLog "Script to start Dire Wolf if it is not running already."
    # ls -l  /home/pi/direwolf.conf

if [ -f /home/pi/direwolf.conf ]
then
    if [ "${1}X" == "initX" ]
    then
        echoAndLog "*** make install-conf. For now we will save your direwolf.conf"
        echoAndLog "Backup the direwolf.conf to direwolf.conf.backup_${datetime}"
        datetime=`date "+%Y-%m-%d_%H%M%S"`
        cp -p /home/pi/direwolf.conf /home/pi/direwolf.conf.backup_${datetime}
        ls -l /home/pi/direwolf.conf /home/pi/direwolf.conf.backup_${datetime} | tee -a /ciniki/logs/qruqsp_setup.txt
        make -C /ciniki/src/direwolf install-conf | tee -a /ciniki/logs/qruqsp_setup.txt
    else
        echoAndLog "*** WARNING: When upgrading from an earlier version, you will probably want to skip make install-conf because it will wipe out your earlier configuration file."
        echoAndLog "*** If this is your first time or you want to wipe out your earlier configuration file and start over then rerun this script with \"init\" as a command-line argument."
        echoAndLog "*** A reminder will be printed immediately before exit."
        TODO="*** TODO: If this is your first time or you want to wipe out your earlier configuration file and start over then rerun this script with \"init\" as a command-line argument as follows: sudo $0 init"
    fi
else
    echoAndLog "We assume that this is the first time installing Dire Wolf and performing this step and /home/pi/direwolf.conf.keep can be used to restore the old version."
    sudo -u pi make -C /ciniki/src/direwolf install-conf | tee -a /ciniki/logs/qruqsp_setup.txt
fi

echoAndLog "This step should have copied the initial configuration file to the home directory, /home/pidirewolf.conf. This is the initial configuration file."
ls -l /home/pi/direwolf.conf | tee -a /ciniki/logs/qruqsp_setup.txt
echoAndLog "Configuration file.  Search order is current working directory then the user’s home directory."
echoAndLog "Go to your home directory and try to run direwolf."
echoAndLog "cd ~ "
echoAndLog "direwolf"
echoAndLog "NOTE: You should see something like the following examples, because we have not yet configured it for using an audio device."
echoAndLog "  EXAMPLE: Dire Wolf version ..."
echoAndLog "  EXAMPLE: Audio device for both receive and transmit: default (channel 0)"
echoAndLog "  EXAMPLE: Could not open audio device default for input"
echoAndLog "  EXAMPLE: No such file or directory"
echoAndLog "  EXAMPLE: Pointless to continue without audio device."
sudo -u pi /usr/local/bin/direwolf | tee -a /ciniki/logs/qruqsp_setup.txt
echoAndLog "We will perform the necessary configuration in a later step."
# tput init resets the silly ANSI color scheme that is set by direwolf
tput init

echoAndLog "This completes the instructions from Raspberry-Pi-APRS.pdf which are required at this time."
echoAndLog "We can stop at the section called Interface for Radio. Here we are using the SDR dongle rather than a USB audio adapter."
echoAndLog "Don’t worry about the configuration part because we will build our own configuration file here."
echoAndLog "RTL-SDR Library from http://sdr.osmocom.org/trac/wiki/rtl-sdr"
apt-get -y update | tee -a /ciniki/logs/qruqsp_setup.txt
apt-get -y install cmake build-essential libusb-1.0-0-dev | tee -a /ciniki/logs/qruqsp_setup.txt

if [ -d /ciniki/src/rtl-sdr/cmake ]
then
    echoAndLog "OK: It appears that we already did git clone rtl-sdr"
else
    echoAndLog "* Attempting to git clone rtl-sdr"
    git clone git://git.osmocom.org/rtl-sdr.git /ciniki/src/rtl-sdr | tee -a /ciniki/logs/qruqsp_setup.txt
fi

if [ -d /ciniki/src/rtl-sdr/build ]
then
    echoAndLog "OK: It appears that we already did a build of rtl-sdr"
else
    mkdir /ciniki/src/rtl-sdr/build
    (cd /ciniki/src/rtl-sdr/build && cmake ../ -DINSTALL_UDEV_RULES=ON -DDETACH_KERNEL_DRIVER=ON) | tee -a /ciniki/logs/qruqsp_setup.txt
    make -C /ciniki/src/rtl-sdr/build | tee -a /ciniki/logs/qruqsp_setup.txt
    make -C /ciniki/src/rtl-sdr/build install | tee -a /ciniki/logs/qruqsp_setup.txt
    (cd /ciniki/src/rtl-sdr/build && ldconfig) | tee -a /ciniki/logs/qruqsp_setup.txt
fi


# git clone rtl_433
if [ -d /ciniki/src/rtl_433/build ]
then
    echoAndLog "OK: It appears that we already did a build of rtl_433"
else
    git clone https://github.com/merbanan/rtl_433 /ciniki/src/rtl_433 | tee -a /ciniki/logs/qruqsp_setup.txt
    mkdir -p /ciniki/src/rtl_433/build
    (cd /ciniki/src/rtl_433/build && cmake ../) | tee -a /ciniki/logs/qruqsp_setup.txt
    make -C /ciniki/src/rtl_433/build | tee -a /ciniki/logs/qruqsp_setup.txt
    make -C /ciniki/src/rtl_433/build install | tee -a /ciniki/logs/qruqsp_setup.txt
#    (cd /ciniki/src/rtl_433/build && ldconfig) | tee -a /ciniki/logs/qruqsp_setup.txt
fi

# Optional support for gpsd
# This is covered in the separate document, Raspberry-Pi-APRS-Tracker.pdf.
# https://github.com/wb2osz/direwolf/blob/master/doc/Raspberry-Pi-APRS-Tracker.pdf

# Make a backup of your SD card (optional)
echoAndLog "After going through all of these steps, you might want to make a backup so you can get back to this point quickly if the memory card gets trashed. Here’s how: https://www.raspberrypi.org/forums/viewtopic.php?p=239331"

echoAndLog "Installing mysql-server if not already installed"
apt-get -y install mysql-server | tee -a /ciniki/logs/qruqsp_setup.txt

checkFiles /etc/mysql/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# FIXME: This is may not be working correctly on ANdrew's Pi. Andrew has more than one sql_mode = entry in his my.cnf
sqlMode=`egrep -c 'sql_mode\s+=\s+ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' /etc/mysql/my.cnf`
if [ "${sqlMode}X" == "1X" ]
then
    echoAndLog "OK: /etc/mysql/my.cnf contains the sql_mode settings that are required."
else
    datetime=`date "+%Y-%m-%d_%H%M%S"`
    echoAndLog "* Making a backup of /etc/mysql/my.cnf into /etc/mysql/my.cnf.backup-${datetime}"
    cp -p /etc/mysql/my.cnf /etc/mysql/my.cnf.backup-${datetime}
    echoAndLog "* Update /etc/mysql/my.cnf with the sql_mode settings that are required."
    echo " " > /tmp/mysql_conf_ending
    echo "[mysqld]" >> /tmp/mysql_conf_ending
    echo "sql_mode = ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" >> /tmp/mysql_conf_ending
    cat /etc/mysql/my.cnf.backup-${datetime} /tmp/mysql_conf_ending > /etc/mysql/my.cnf
fi

if [ -f /home/pi/.my.cnf ]
then
    echoAndLog "OK: /home/pi/.my.cnf exists"
    # FIXME: read password from my.cnf and use it later in the script
else
    echoAndLog "* Create /home/pi/.my.cnf with mysql user and password. This saves having to type the user and password for each mysql command."
    echo "[client]" > /home/pi/.my.cnf
    echo "user=admin" >> /home/pi/.my.cnf
    echo "password=${admin_password}" >> /home/pi/.my.cnf
    # FIXME: random password 32 characters
    # FIXME: create admin user
    # FIXME: mysql grant all on *.* to 'admin'@'localhost' identified by $password
fi

echoAndLog "Chown pi:pi /home/pi/.my.cnf and chmod 700 /home/pi/.my.cnf just in case it is not set correctly"
chown pi:pi /home/pi/.my.cnf | tee -a /ciniki/logs/qruqsp_setup.txt
chmod 700 /home/pi/.my.cnf | tee -a /ciniki/logs/qruqsp_setup.txt
echoAndLog "FIXME: It seems that Raspbian stretch switched from mysql to MariaDB and /home/pi/.my.cnf no longer works as it did with mysql. We wil have to run mysql commands as root nutil we figure this out."
# check that innodb_* and sql_mode settings have been added to /etc/mysql/mariadb.conf.d/50-server.cnf
innodbOptions=`egrep -c 'default-character-set = latin1|innodb_large_prefix = 1|innodb_file_format = barracuda|innodb_file_format_max = barracuda|innodb_file_per_table = 1|character-set-server = latin1|collation-server = latin1_general_ci|default-character-set = latin1' /etc/mysql/mariadb.conf.d/51-ciniki.cnf`
if [ "${innodbOptions}X" == "8X" ]
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
    echo "innodb_large_prefix = 1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "innodb_file_format = barracuda" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "innodb_file_format_max = barracuda" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "innodb_file_per_table = 1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "# sql_mode = \"NO_ENGINE_SUBSTITUTION\"" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "character-set-server = latin1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "collation-server = latin1_general_ci" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "[client]" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
    echo "default-character-set = latin1" >> /etc/mysql/mariadb.conf.d/51-ciniki.cnf
fi


echoAndLog "Checking for database admin user..."
if [ `mysql --user root -sse 'SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = "admin")' mysql` == "1" ]
then
    echoAndLog "OK: database admin exists"
else
    echoAndLog "* Create database admin user because it does not already exist"
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' IDENTIFIED BY '${admin_password}';" mysql
fi

echoAndLog "Checking for qruqsp database..."
if [ `mysqlshow qruqsp | grep -c 'Database: qruqsp'` == "1" ]
then
    echoAndLog "OK: qruqsp database exists"
else
    echoAndLog "* Create qruqsp database because it does not already exist"
    mysqladmin --default-character-set=latin1 create qruqsp | tee -a /ciniki/logs/qruqsp_setup.txt
#    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' IDENTIFIED BY password '${admin_password}';" mysql
fi
echoAndLog "Install Apache and PHP if not already installed"
apt-get -y install apache2 php7.0-xml php7.0-imagick php7.0-intl php7.0-curl php7.0-mysql php7.0-json php7.0-readline php7.0-imap libapache2-mod-php7.0 | tee -a /ciniki/logs/qruqsp_setup.txt

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

if [ -f /ciniki/sites/qruqsp.local/site/qruqsp-install.php ]
then
    echoAndLog "OK: It looks like we already did a git clone of qruqsp into /ciniki/sites/qruqsp.local"
else
    echoAndLog "* git clone qruqsp"
    sudo -u pi git clone https://github.com/qruqsp/qruqsp /ciniki/sites/qruqsp.local | tee -a /ciniki/logs/qruqsp_setup.txt
fi

for needDir in /ciniki/sites/qruqsp.local/logs
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

# We always want to git pull and git submodule update so that we have the latest updates to the qruqsp code
echoAndLog "* git pull"
sudo -u pi git pull /ciniki/sites/qruqsp.local | tee -a /ciniki/logs/qruqsp_setup.txt
echoAndLog "* git submodule update"
sudo -u pi git submodule update --init /ciniki/sites/qruqsp.local | tee -a /ciniki/logs/qruqsp_setup.txt

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

if [ -d /ciniki/sites/qruqsp.local/.git ]
then
    echoAndLog "OK: /ciniki/sites/qruqsp.local/.git exists"
else
    echoAndLog "* FIXME: Do we want to automate the steps below and if so what values should be entered in run.ini?"
    echoAndLog "* WARNING: /ciniki/sites/qruqsp.local/.git does not exist"
    echoAndLog "Copy /ciniki/sites/qruqsp.local/dev-tools/run.ini.default /ciniki/sites/qruqsp.local/run.ini and configure with your local settings."
    echoAndLog "This will allow you to execute ./run.php and see the history of API calls and repeat any calls you want, useful for testing the API."
    echoAndLog "* FIXME: Turn on the password caching for git so you don't have to enter your github username/password everytime you push. Example usage below:"
    echoAndLog "    git config --global credential.helper cache"
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
    ln -s /ciniki/sites/qruqsp.local/site/pi-install.php /ciniki/sites/qruqsp.local/site/index.php
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
    crontab -l > /tmp/cinikirootcron
    echo "*/5 * * * * sudo -u www-data /usr/bin/php /ciniki/sites/qruqsp.local/site/ciniki-mods/cron/scripts/cron.php ciniki.mail >>/ciniki/sites/qruqsp.local/logs/cron.log 2>&1" >> /tmp/cinikirootcron
    echo "*/5 * * * * sudo -u www-data /usr/bin/php /ciniki/sites/qruqsp.local/site/ciniki-mods/cron/scripts/cron.php -ignore ciniki.mail >>/ciniki/sites/qruqsp.local/logs/cron.log 2>&1" >> /tmp/cinikirootcron
    crontab /tmp/cinikirootcron
    rm /tmp/cinikirootcron
fi

echoAndLog "Install lshw if not installed already"
apt-get -y install lshw

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
