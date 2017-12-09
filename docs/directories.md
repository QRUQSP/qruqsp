Directory Layout
----------------

### /docs 
All non-module specific documentation is stored in the this directory in markdown format. Any module specific documentation will be stored in each module in it's docs directory.

### /scripts
Any packaging or compiling scripts reside in this directory.

### /site 
All module code and libraries reside in this directory. This directory can be published to a web server or if running location the virtual host root can be pointed at this directory.

### /site/ciniki-cache
Directory for caching rendered audio, or scaled images as examples. This directory is not exposed via the web server.

### /site/ciniki-code
When the modules and libraries are packages for distribution, they are placed in this directory.

### /site/ciniki-lib
Any libraries required for QRUQSP are stored in this directory. 
These libraries will be packaged up and available via code sync.

### /site/ciniki-mods
This directory contains the modules for Ciniki Core Package. 

### /site/qruqsp-mods
This directory contains the modules for QRUQSP. 
Each module has it's own structure as outlined below. 
Each module is also packaged into a zip file for transfer to other nodes.

### /site/ciniki-storage
All non-database information is stored here. Images and Audio are stored in this directory.


Module Layout
-------------

Each module will have the following directories.

### /db
The database schema and upgrade files for this module.

### /docs
Any documentation for this module.

### /hooks
The functions for each module to communicate with other modules.

### /private 
The private functions for this module. These should not be called by other modules.

### /public
The API methods for interacting with this module.

### /scripts
Any scripts for this module

In addition, each module should contain the following files:

- /LICENSE.md - The license for this module.
- /README.md - The description of this module.
- /_info.ini - The name and settings for this module. Used to determine if a module is required or optional.


