QRUQSP Modules
==============

The main qruqsp repo is a super git repo for both the Ciniki and QRUQSP packages. The submodule are 
stored in site/ciniki-mods and site/qruqsp-mods for each package.

Module List
-----------

### core
This module is required for every QRUQSP project. This module contains the functions to access and modify the information 
in the database, control who has access to the information and a list of stations in the database.

### images
All images used in any other module should be stored in this module and referenced. This module manages the storage
of images and the processing to reduce size for websites etc.

### sysadmin
A collection of tools to manage the system. This may not be required on all installs and so it is a separate module from core.

### systemdocs
This module contains code parsers to import and understand the code to the database. Once the code is in the database
the list of tables, documentation and other information can be accessed.

### bugs
This module tracks the bugs and questions submitted by users of the system. Bugs are typically submitted when something goes wrong
and the UI presents the user with the option of submitting a bug.

### qsl
This module is used for logging what's been heard on the air.

Module Layout
-------------

Each module should contain most of the directories below. Each function must be in it's own file.

### db
This directory contains all the database schema and upgrade files. 

### hooks
The functions that can be called from other modules to get or update information in this module.

### public
The public API functions go in this directory. The API code will check for a filename that matches the requested method in this directory.

### private
The private code for the module should go in this directory. These functions should not be called from other modules. If another module
needs information it should use functions under hooks.

### ui
The ui code resides in this directory.

### web
The functions that are called from the web module go in this directory. If this module does not publish anything via the web
module then this directory isn't required.

Module Files
------------

The following are standard files for each module. Most of them are created by the mod_init.php script.

### README.md
This contains the basic description of the module and a link to the license file.
The README.md will need to be edited to add the description of the module. 

### LICENSE.md
This is the MIT license for the module.

### _info.ini
This file contains the modules configuration in php ini format.

```
name = <Module Name>
optional = yes
public = no
```

For modules like core that must be included or assumed "on" for each station, set optional = no.
For modules that are ready to be published in the API, set public = yes.

### db/package_module_history.php
This database schema stores all the history for the module. It should always be the standard format created by mod_init.php.
If required, it can be altered on a per module basis but it's not recommended at this time.

### hooks/uiSettings.php
This function returns any settings for the module that will be passed back to the UI. It also returns the list of main
station menu items for the UI and any settings menu items. This allows each module to add menu items without the core
module knowing anything about this module. 

### private/checkAccess.php
This function is called by every API function in the module to determine if the user making the request has permission 
to the specific API function. Each module can set it's access permissions differently if required. 

### private/maps.php
The maps functions returns the list of database/object field mappings to human readable strings. These are names for flags or status fields
in the database schemas.

### private/objects.php
The objects function returns the list of objects for the module. Each object corresponds to the database table to store that object.

The core/private/object*.php functions use this file to Add, Update Delete, List objects in the this module. These definitions are also
used in any syncronization code.

### private/flags.php
The flags function will return the available flags for a module. This allows sysadmins to enable/disable features for a module.

### ui/main.js
This file should contain the UI code that is used from the main station menu. Each JS file is considered and "app" and will be loaded 
into it's own container in the UI. Most modules have all their UI code, with the exception of settings, in this file. It allows all the
UI code to be loaded once.

### ui/settings.js
This file should contain all the settings management for this module. If the module doesn't have any settings, there is no need for this file.


Creating a new submodule
------------------------
The new submodule must first be created on github.com under the QRUQSP project. The module should be initialized with a README so there 
are no warnings when checking out an empty module.

```
# Login to github.com and create a new repository
```

Once the submodule has been created, it needs to be added to the super repo. The submodule must not be added as the git@github.com 
user because then anybody who checks out the super repo needs write permissions to access the submodule. Including the submodule
initially as https://github.com/ will provide read only access to anybody who wants it. After the permissions to push changes
to github.com is added using git remote add push.

```
cd ~/projects/qruqsp/qruqsp.local
# hey you with the keyboard replace "<submodule_name>" with the submodule you need
git submodule add https://github.com/qruqsp/<submodule_name>.git site/qruqsp-mods/<submodule_name>
```

### Initialize the new submodule

Once the submodule has been added, it needs to be initialized with required files.

```
rm README.md
../../../dev-tools/mod_init.php <submodule_title>
```

### Update the README.md
You'll now need to edit the README.md file to update the description.


Creating objects
----------------
Once the module has been setup, the [Module Objects](objects.md) can be created.

