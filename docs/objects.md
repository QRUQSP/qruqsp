Module Objects
==============

Each module contains modules which map to the database tables. Creating objects is an easy
way to define how information is stored and sync'd between databases in addition to 
providing an easy way to store and retrieve information in the database.

The following core functions provide easy access to managing objects.

### core/private/objectAdd.php

This function will load the object definition and take the arguments provided map them to the definition, 
filling in any missing ones if possible with default values and saving it to the database table.

### core/private/objectUpdate.php

Update the object in the database.

### core/private/objectDelete.php

Remove the object data from the database. This does not check any dependancies, it's assumed that has already been done.

### core/private/objectLoad.php

Load the object definition, typically only used by core object functions.

### core/private/objectGet.php

Load the object into a hash array.

Create the database schema
--------------------------

Each object should map to 1 database table. The following template provides the required fields.

```
#
# Description
# -----------
#
#
# Fields
# ------
# id:                       The ID assigned to the item.
# uuid:                     The Universal Unique ID.
# station_id:               The station the item is attached to.
#
# date_added:               The UTC date and time the record was added.
# last_updated:             The UTC date and time the record was last updated.
#
create table qruqsp_module_items (
    id int not null auto_increment,
    uuid char(36) not null,
    station_id int not null,

    date_added datetime not null,
    last_updated datetime not null,
    primary key (id),
    unique index (uuid),
    index sync (station_id, uuid, last_updated)
) ENGINE='InnoDB', COMMENT='v1.01';
```

### Status or List fields

If a column in the table should be a defined list of attributes or a status field, it should be definied as follows.

```
    status tinyint unsigned not null,
```

With the documentation for the field added under Fields in the top of the file.

```
# status:           The current status for the object.
#                       10 - Active
#                       20 - Enhanced
#                       40 - On Hold
#                       60 - Archived
```

For something like a status field, the list should progress from active to inactive, archived or deleted. That way
it's easy to search for all active objects by status < 40.

The numbers should have gaps between them to allow for additions in the future without them having to be placed
at the end of the list.

The human readable values for the list should be added to the private/maps.php function.

### Define the object

The object must get added to private/objects.php so it can be initialized and used by the object. The object should
matched the database schema without the id, uuid, station_id, date_added and last_updated fields.

```
    $objects['object'] = array(
        'name'=>'Object Name',
        'o_name'=>'objectname',
        'o_container'=>'objectpluralname',
        'sync'=>'yes',
        'table'=>'package_module_objectpluralname',
        'fields'=>array(
            'field'=>array('name'=>'Field Name'),
            'objectreference'=>array('name'=>'Reference another field', 'ref'=>'package.module.object'),
            'field'=>array('name'=>'Field with Default', 'default'=>'10'),
        ),
        'history_table'=>'package_module_history',
    );
```

### Setup the text mappings

Add the text mappings to the private/maps.php file. The 'object' name should match 
the name of the object defined in private/objects.php

```
    $maps['object'] = array('status'=>array(
        '10'=>'Active',
        '20'=>'Enhanced',
        '40'=>'On Hold',
        '60'=>'Archived',
    ));
```

### Initialize the object

Once the object has be setup in private/objects.php it can be initialized.

```
../../../dev-tools/mod_init_object.php <object> <object_id>
```
