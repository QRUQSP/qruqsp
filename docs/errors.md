QRUQSP Errors
=============

Error handling in QRUQSP is done with error codes and messages which are returned from each function. If a module
has an error condition, the following should be returned.

```
return array('stat'=>'fail', 'err'=>array('code'=>'package.module.1', 'msg'=>'The error message'));
```

Error Codes
-----------
Each module manages it's own error codes. Each code must contain the package dot module dot code. The code must be unique
within the module. 

To make sure there are no duplicates or find the next available code, run the command:

```
~/projects/qruqsp/qruqsp.local/dev-tools/mod_errors.php
```

This will return the list of error codes found within a module and any gaps or duplications.

Nested Errors
-------------
Error codes can be nested to create a chain of errors. If a function call returns an error, you can add 
the returned error code to your own message.

```
$rc = ciniki_core_dbHashQuery($q, $strsql, 'package.module', 'item');
if( $rc['stat'] != 'ok' ) {
    return array('stat'=>'fail', 'err'=>array('code'=>'package.module.1', 'msg'=>'The error message', 'err'=>$rc['err']));
}
```

This way each function can add a message, and the entire chain can be reviewed to find the error.
