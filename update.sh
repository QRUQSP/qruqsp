#!/bin/sh

cd /ciniki/sites/qruqsp.local
echo 'Updating main repo...'
git pull
echo 'Updating submodules...'
git submodule update --init
echo 'Updating database...'
/usr/bin/php /ciniki/sites/qruqsp.local/site/ciniki-mods/sysadmin/scripts/upgradeDatabase.php
