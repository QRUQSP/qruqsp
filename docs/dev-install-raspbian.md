Development Install for Raspbian
================================

To install QRUQSP on Raspbian, you will need to know how to use the command line.

Download and setup Raspbian
---------------------------

Download the latest raspbian image from https://www.raspberrypi.org/downloads/raspbian and burn to SD card. 

Setup for QRUQSP
----------------


Open a terminal or login via SSH. Then download the setup.sh for QRUQSP.

```
wget https://raw.githubusercontent.com/QRUQSP/qruqsp/master/setup.sh
```

**WARNING: If you are not starting with a fresh install of Raspbian, please make a backup first**

**WARNING: This script will also reset the wifi on the Raspberry Pi to be QRUQSP**

Run the setup script. This will install Apache2, PHP, MariaDB and other dependencies for QRUQSP.
```
sudo bash ./setup.sh -p
```

Once the script finishes, open the IP Address in a web browser and fill out the form to finish the setup of your station.

If you have any questions, please contact us at https://qruqsp.org/contact
