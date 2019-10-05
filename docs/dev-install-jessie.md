Development Install for Ubuntu
==============================

**NOTE** This file has been superceeded by [Raspbian](dev-install-raspbian.md).

Packages required
-----------------

Update your packages list.
```
sudo apt-get update
```

Install the MySQL 5.7 Server (directions from: http://www.debiantutorials.com/install-mysql-server-5-6-debian-7-8/)
```
sudo apt-get -y install mysql-server
```

Add the following line to /etc/mysql/my.cnf so that default values don't have to specified
for each column of each table. QRUQSP was designed to use defaults assigned by Mysql not the schema.
The lines should be added at the end of the file after the includes of other configuration files.
```
[mysqld]
sql_mode = ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
```

Setup a .my.cnf in your home directory with the following content. This saves having to type the user and password for each mysql command.
```
[client]
user=root
password=
```

Create the database
```
mysqladmin create qruqsp
```

Install apache and php
```
sudo apt-get -y install apache2 php5 php5-imagick php5-intl php5-curl php5-mysql php5-json php5-readline php5-imap libapache2-mod-php5
```

Hosts file
----------
Edit your /etc/hosts file and add the following line.
```
127.0.1.1   qruqsp.local    qruqsp
```

Setup QRUQSP
------------

Setup the website and clone the repo.
```
sudo mkdir /ciniki
sudo chown pi:pi /ciniki
sudo chmod 2755 -R /ciniki
mkdir /ciniki/sites
cd /ciniki/sites
git clone https://github.com/qruqsp/qruqsp qruqsp.local
```

Update the submodules for the project to make sure you have the latest code
```
cd qruqsp.local
git submodule update --init
```

Apache
------
Create the log directory for apache logs.
```
cd /ciniki/sites/qruqsp.local
mkdir logs
```

Edit the file /etc/apache2/sites-available/qruqsp.local.conf
```
<VirtualHost *:80>
    DocumentRoot /qruqsp/sites/qruqsp.local/site
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
```

Link the file into sites-enabled
```
cd /etc/apache2/sites-enabled
sudo ln -s ../sites-available/qruqsp.local.conf
```

Link the rewrite module
```
cd /etc/apache2/mods-enabled
sudo ln -s ../mods-available/rewrite.load
```

Edit the apache environment variables and set the user and group lines to the following:
Edit the environment variables to set user.
```
export APACHE_RUN_USER=pi
export APACHE_RUN_GROUP=pi
```

Test the new configuration to make sure the webserver will restart
```
sudo /usr/sbin/apache2ctl configtest
```

If everything is ok, restart apache with the new configuration
```
sudo /usr/sbin/apache2ctl stop
sudo /usr/sbin/apache2ctl start
```

Install QRUQSP/dev-tools (optional)
-----------------------------------
The dev-tools packages contains useful scripts to help you test and setup new modules.

```
cd /ciniki/sites/qruqsp.local
git clone https://github.com/qruqsp/dev-tools.git
```

Copy the run.ini.default to run.ini and configure with your local settings. This will allow you to 
execute ./run.php and see the history of API calls and repeat any calls you want, useful for testing the API.

```
cd /ciniki/sites/qruqsp.local
cp run.ini.default run.ini
```

Setup github.com username/password caching
------------------------------------------

Turn on the password caching for git so you don't have to enter your github username/password everytime you push.

```
git config --global credential.helper cache
```
