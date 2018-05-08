<?php
//
// This file is the install script which will configure and setup the database
// and configuration files on disk.  The script will only run if it can't find
// a ciniki-api.ini file.  This script can be uploaded to a webserver and it
// will download and install all the ciniki modules.
//


//
// Figure out where the root directory is.  This file may be symlinked
//
$ciniki_root = dirname(__FILE__);
$modules_dir = $ciniki_root . '/ciniki-mods';

//
// Verify no ciniki-api.ini file
//
if( file_exists($ciniki_root . '/ciniki-api.ini') ) {
    print_page('no', 'ciniki.installer.15', 'Already installed.</p><p><a href="/manager/">Login</a>');
    exit();
}

//
// Verify no .htaccess file exists.
//
if( file_exists($ciniki_root . '/.htaccess') ) {
    print_page('no', 'ciniki.installer.14', 'Already installed.</p><p><a href="/manager/">Login</a>');
    exit();
}

/*
-dh    $database_host = $args['database_host'];
-du    $database_username = $args['database_username'];
-dp    $database_password = $args['database_password'];
-dn    $database_name = $args['database_name'];
-ae    $admin_email = $args['admin_email'];
-au    $admin_username = $args['admin_username'];
-ap    $admin_password = $args['admin_password'];
-af    $admin_firstname = $args['admin_firstname'];
-al    $admin_lastname = $args['admin_lastname'];
-ad    $admin_display_name = $args['admin_display_name'];
-mn    $master_name = $args['master_name'];
-se    $system_email = $args['system_email'];
-sn    $system_email_name = $args['system_email_name'];
-sc    $sync_code_url = preg_replace('/\/$/', '', $args['sync_code_url']);
*/
$valid_args = array(
    '-de' => array('field'=>'database_engine', 'mandatory'=>'no'),
    '-dh' => array('field'=>'database_host', 'mandatory'=>'yes'),
    '-du' => array('field'=>'database_username', 'mandatory'=>'yes'),
    '-dp' => array('field'=>'database_password', 'mandatory'=>'no'),
    '-dn' => array('field'=>'database_name', 'mandatory'=>'yes'),
    '-ae' => array('field'=>'admin_email', 'mandatory'=>'yes'),
    '-au' => array('field'=>'admin_username', 'mandatory'=>'yes'),
    '-ap' => array('field'=>'admin_password', 'mandatory'=>'yes'),
    '-af' => array('field'=>'admin_firstname', 'mandatory'=>'no'),
    '-al' => array('field'=>'admin_lastname', 'mandatory'=>'no'),
    '-ad' => array('field'=>'admin_display_name', 'mandatory'=>'no'),
    '-mn' => array('field'=>'master_name', 'mandatory'=>'yes'),
    '-se' => array('field'=>'system_email', 'mandatory'=>'no'),
    '-sn' => array('field'=>'system_email_name', 'mandatory'=>'no'),
    '-sc' => array('field'=>'sync_code_url', 'mandatory'=>'no'),
    '-un' => array('field'=>'server_name', 'mandatory'=>'yes'),
    '-ru' => array('field'=>'request_uri', 'mandatory'=>'no'),
    '-80' => array('field'=>'disable_ssl', 'mandatory'=>'no'),
    );
//
// Check if running from command line, and display command line form
//
if( php_sapi_name() == 'cli' ) {
    //
    // Check for arguments
    //
    $args = array(
        'database_engine' => '',
        'database_host' => '',
        'database_username' => '',
        'database_password' => '',
        'database_name' => '',
        'admin_email' => '',
        'admin_username' => '',
        'admin_password' => '',
        'admin_firstname' => '',
        'admin_lastname' => '',
        'admin_display_name' => '',
        'master_name' => '',
        'system_email' => '',
        'system_email_name' => '',
        'sync_code_url' => '',
        'server_name' => '',
        'request_uri' => '',
        'http_host' => '',
        );
    //
    // Grab the args into array
    //
    if( isset($argv[1]) && $argv[1] != '' ) {
        array_shift($argv);
    }
    foreach($argv as $k => $arg) {
        if( $arg == '-80' ) {
            $args['disable_ssl'] = 'yes';
        }
        elseif( isset($valid_args[$arg]) ) {
            $args[$valid_args[$arg]['field']] = $argv[($k+1)];
        }
    }

    if( $args['admin_firstname'] == '' ) {  
        $args['admin_firstname'] = $args['admin_username'];
    }
    if( $args['admin_display_name'] == '' ) {
        $args['admin_display_name'] = $args['admin_username'];
    }
    if( $args['system_email'] == '' ) {  
        $args['system_email'] = $args['admin_email'];
    }
    if( $args['system_email_name'] == '' ) {  
        $args['system_email_name'] = $args['master_name'];
    }
    if( $args['http_host'] == '' ) {  
        $args['http_host'] = $args['server_name'];
    }
  
    $missing = '';
    foreach($valid_args as $k => $arg) {
        if( isset($arg['mandatory']) && $arg['mandatory'] == 'yes' && $args[$arg['field']] == '' ) {
            $missing .= "Missing argument: {$k} {$arg['field']} \n";
        }
    }

    if( $missing != '' ) {
        print $missing;
        exit;
    }

    $rc = install($ciniki_root, $modules_dir, $args);
    if( $rc['err'] != 'install' ) {
        print "Error: {$rc['err']} - {$rc['msg']}\n";
    } else {
        print "Installed\n";
    }
} 
//
// Running via web browser
//
else {
    if( !isset($_POST['callsign']) ) {
        print_page('yes', '', '');
    } else {
        //
        // Read in the /home/pi/.my.cnf 
        //
        $mysql_settings = file_get_contents("/home/pi/.my.cnf");
        $mycnf = parse_ini_string($mysql_settings, TRUE);
        
        $args = array(
            'database_engine' => 'mysql',
            'database_host' => 'localhost',
            'database_username' => $mycnf['client']['user'],
            'database_password' => $mycnf['client']['password'],
            'database_name' => 'qruqsp',
            'admin_email' => $_POST['email'],
            'admin_username' => strtolower($_POST['callsign']),
            'admin_password' => $_POST['password'],
            'admin_firstname' => $_POST['first'],
            'admin_lastname' => $_POST['last'],
            'admin_display_name' => strtoupper($_POST['callsign']),
            'master_name' => strtoupper($_POST['callsign']),
            'system_email' => $_POST['email'],
            'system_email_name' => $_POST['callsign'],
            'sync_code_url' => '',
            'server_name' => $_SERVER['SERVER_NAME'],
            'request_uri' => $_SERVER['REQUEST_URI'],
            'http_host' => $_SERVER['HTTP_HOST'],
            'disable_ssl' => 'yes',
            );

        $rc = install($ciniki_root, $modules_dir, $args);
        print_page($rc['form'], $rc['err'], $rc['msg']);
    }
}

exit();


function print_page($display_form, $err_code, $err_msg) {
?>
<!DOCTYPE html>
<html>
<head>
<title>QRUQSP Pi Installer</title>
<style>
body { background: #fafafa; }
/******* The top bar across the window ******/
.headerbar {
    width: 100%;
    height: 2.5em;
    margin: 0px;
    padding: 0px;
    table-layout: auto;
    z-index: 2;
}

.headerbar td {
    margin: 0px;
    padding: 0px;
    vertical-align: bottom;
    background: #778;
    padding: 0.2em 0.3em 0.2em 0.3em;
    border-left: 1px solid #889;
    border-right: 1px solid #667;
}

.headerbar td.leftbuttons {
    text-align:left;
    margin: 0px;
    cursor: pointer;
    height: 100%;
    vertical-align: bottom;
    min-width: 2.5em;
    padding-top: 0px;
}

.headerbar td.rightbuttons {
    text-align:right;
    margin: 0px;
    align: right;
    height: 100%;
    cursor: pointer;
    vertical-align: bottom;
    min-width: 2.0em;
    padding-top: 0px;
}

.headerbar td.avatar {
    text-align: center;
    width: 3.0em;
    cursor: pointer;
    vertical-align: middle;
}

.headerbar td.homebutton img.avatar {
    width: 1.8em;
    height: 1.8em;
    margin: 0px;
    border: 1px solid #eee;
    vertical-align: middle;
}

.headerbar td.title {
    min-width: 10%; 
    width: 80%;
    max-width:90%;
    font-size: 1.2em;
    text-align:center;
    color: #eee;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    vertical-align: middle;
    padding: 0.3em 0.2em 0.2em 0.2em;
    border-left: 0px;
    border-right: 0px;
}

.headerbar td img {
    width: 1.9em;
    padding: 0px;
    margin: 0px;
    vertical-align: middle;
}

.headerbar td.helpbutton {
    border-right: 0px;
    padding-top: 0px;
}

.headerbar td.homebutton {
    cursor: pointer;
    border-left: 0px;
}

.headerbar td.hide {
    border-left: 0px;
    border-right: 0px;
    cursor: inherit;
}

.headerbar td.show {
}

.headerbar td div.button {
    display: table-cell;
    font-size: 0.8em;
    vertical-align: bottom;
    height: 100%;
    min-width: 3.5em;
    max-width: 5em;
    text-align: center;
    padding: 0em 0.2em 0em 0.2em;
    color: #ddd;
    cursor: pointer;
}

.headerbar td div.button span {
    display: inline-block;
    width: 100%;
}

.headerbar td div.button span.icon {
    font-size: 1.1em;
    text-decoration: none;
    font-family: CinikiRegular;
    color: #99a;
    max-height: 20px;
    vertical-align: top;
}
input,
table,
form,
div {
    box-sizing: border-box;
}
/* These can be specific for help or apps by add #m_container or #m_help in front */
div.narrow {
    margin: 0 auto;
    width: 20em;
    padding-top: 1em;
    padding-bottom: 1em;
}
div.mediumflex,
div.medium {
    padding-top: 1em;
    padding-bottom: 1em;
}
div.leftpanel {
    vertical-align: top;
    display: inline-block;
    width: 45% !important;
}
div.rightpanel {
    vertical-align: top;
    display: inline-block;
    width: 45% !important;
    padding-left: 1em;
}

div.xlarge,
div.large {
    padding-top: 1em;
    padding-bottom: 1em;
}

div.wide {
    padding-top: 1em;
    padding-bottom: 1em;
}


h2 {
    display: block;
    font-size: 1.1em;
    font-weight: normal;
    text-align: left;
    padding: 0.2em 0em 0.2em 0.5em;
    margin: 0 auto;
    border: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    color: #555;
}

h2 span.count {
    position: relative;
    vertical-align: middle;
    top: -0.1em;
    margin-bottom: 0.3em;
    margin-top: -0.3em;
    padding: 0.2em 0.8em 0.2em 0.8em;
    font-size: 0.6em;
}

span.count {
    font-weight: normal;
    color: #777;
    background: #eee;
    display: inline-block;
    border: 1px solid #bbb;
    padding: 0.2em 0.7em 0.2em 0.7em;
    margin: 0px;
}

table.list td span.count {
    font-size: 0.7em;
    position: relative;
    margin-top: -0.3em;
    vertical-align: middle;
    top: -0.2em;
    margin-left: 0.5em;
}

div.narrow table.list,
div.medium table.list {
    width: 100%;
}

div.mediumflex table.list {
    min-width: 40em;
    max-width: 60em;
}

div.large table.list {
    width: 100%;
}

div.xlarge table.list {
    max-width: 100%;
}

table.list {
    text-align: left;
    padding: 0px;
    margin-bottom: 1em;
    table-layout: fixed;
}

table.form {
    table-layout: auto;
}

table.thread {
    table-layout: auto;
}

table.simplegrid {
    table-layout: auto;
    margin-top: 0;
/*    margin-left: auto;
    margin-right: auto; */
    width: 100%;
}

table.simplegrid th.sortable {
    cursor: pointer;
}

div.wide table.datepicker,
div.wide table.simplegrid {
    min-width: 40em;
}

div.wide h2 {
    width: 100%;
    min-width: 10em;
}

table.outline {
    border: 1px solid #ddd;
    padding: 0.1em 0.1em 0.1em 0.1em;
    background-color: rgba(255,255,255,0.4);
}

table.list > thead,
table.list > tbody,
table.list > tfoot {
    width: 100%;
}

table.list > thead > tr,
table.list > tfoot > tr,
table.list > tbody > tr {
    width: 100%;
}

table.border > thead:first-child > tr:first-child > th,
table.border > tbody:first-child > tr:first-child > td,
table.border > tfoot:first-child > tr:first-child > td {
    border-top: 1px solid #bbb;
}

table.border {
    background: #fff;
}

table.border > thead > tr > th:first-child,
table.border > tfoot > tr > td:first-child,
table.border > tbody > tr > td:first-child {
    border-left: 1px solid #bbb;
}

table.border > thead > tr > th:last-child,
table.border > tfoot > tr > td:last-child,
table.border > tbody > tr > td:last-child {
/*    border-right: 1px solid #bbb; */
    border-right: 0px;
}

table.fieldhistory > tbody > tr > td:last-child {
    border-right: 1px solid #bbb; 
}

table.list > tbody > tr > td,
table.list > tfoot > tr > td {
    padding: 0.7em 0.5em 0.7em 0.5em;
}
/* table.simplegrid > tbody > tr > td {
    padding: 0.6em 0.5em 0.5em 0.5em;
} */

table.border > tbody > tr > td,
table.border > tfoot > tr > td {
    border-bottom: 1px solid #bbb;
}

table.border > tbody > tr:last-child > td,
table.border > tfoot > tr:last-child > td {
    border-bottom: 0px;
}

table.fieldhistory > tbody > tr:last-child > td {
    border-bottom: 1px solid #bbb;
}

table.border > tfoot > tr:first-child > td {
    border-top: 1px solid #bbb;
}

table.list > thead > tr > th {
    padding: 0.5em;
    background: #eee;
}

table.border > thead > tr > th {
    border-bottom: 1px solid #bbb;
}

table.list > tbody > tr > td.noborder,
table.list > tfoot > tr > td.noborder {
    border-right: 0px;
}

table.list > tbody > tr > td.addbutton {
    text-align: right;
    width: 1.7em;
    text-align: center;
    padding-right: 0px;
    vertical-align: middle;
    line-height: 1.0em;
}

table.datepicker > tbody > tr > td.prev,
table.datepicker > tbody > tr > td.next,
table.list > tbody > tr > td.buttons,
table.list > tfoot > tr > td.buttons {
    text-align: center;
    vertical-align: middle;
    line-height: 1.0em;
    width: 1.9em;
    padding-right: 0.0em;
    padding-left: 0.0em;
}

table.datepicker > tbody > tr > td.prev {
    text-align: left;
    padding-left: 0.5em;
}

table.datepicker > tbody > tr > td.next {
    text-align: right;
    padding-right: 0.5em;
}

table.datepicker > tbody > tr > td.prev span.icon,
table.datepicker > tbody > tr > td.next span.icon,
table.list > tbody > tr > td.buttons span.icon,
table.list > tfoot > tr > td.buttons span.icon,
table.list > tbody > tr > td.addbutton span.icon {
    font-size: 0.9em;
    color: #aaa; 
}

table.border tr > td.label {
    border-left: 1px solid #bbb;    
    border-right: 0px solid #bbb;    
}

table.list tr.textfield > td.label {
    padding: 0.5em;
    text-align: right;
}

table.form tr.textfield > td.label > label {
    white-space: nowrap;
}

table.simplegrid td.label,
table.simplelist td.label {
    text-align: right;
    color: #bbb;
    font-size: 0.9em;
    width: 20%;
    min-width: 6em;
    padding: 0.9em 0.55em 0.8em 0.55em;
}

table.form td.button,
table.simplebuttons td.button {
    text-align: center;    
    cursor: pointer;
    font-weight: bold; 
    background: #555;
    color: #eee;
    padding: 0.5em 0.5em 0.45em 0.5em;
}

table.form td.save,
table.simplebuttons td.save {
    background: #555;
    color: #eee;
}

table.form td.delete,
table.simplebuttons td.delete {
    background: #f55;
    color: #eee;

}

table.border tr.textfield > td.hidelabel {
    border-left: 1px solid #bbb;    
    border-right: 0px;
}

table.list tr.textfield > td.hidelabel {
    padding: 0.5em 0 0.5em 0.5em;
    width: 5px !important;
    height: 1em;
    overflow: hidden;
}

table.list tr.textfield > td.hidelabel > label {
    display: none;
    overflow: hidden;
}

table.border tr > td.input {
    border-left: 1px solid #bbb;    
}


table.list tr > td.input {
    font-size: 1em;
    width: 100%;
    padding: 0.3em 0.5em 0.3em 0.2em;
    margin: 0px;
    vertical-align: center;
}

table.simplelist tr > td.input {
    width: 50%;
    border-left: 0px;
}

table.list tr > td input {
    width: 100%;
/*    height: 1.2em; */
    padding: 0.4em;
    padding-right: 0;
    font-size: 1.0em;
    color: #555;
    text-align: left;
    margin: 0px;
    border: 0px;
    text-overflow: ellipsis
    white-space: nowrap;
}

table.livesearch tr > td.search {
    padding-left: 0px;
    padding-right: 0px;
}

table.list tr.textfield > td > input.file {
    height: 1.5em;
}


table.list tr.textfield > td.select {
    width: 100%;
    height: 100%;
}

table.form td.select > select {
    width: 100%;
    height: 100%;
    padding: 0.4em;
    font-size: 1.0em;
    color: #555;
    text-align: left;
    margin: 0.4em;
    border: 0px;
    text-overflow: ellipsis
    white-space: nowrap;
    border: 1px solid #bbb;
}

table.list tr.textfield > td.toggle {
    border-left: 0px;
    text-align: left;
    padding: 0.5em;
}

div.narrow table.list tr.textfield > td.textarea,
div.medium table.list tr.textfield > td.textarea,
div.large table.list tr.textfield > td.textarea,
div.xlarge table.list tr.textfield > td.textarea,
div.wide table.list tr.textfield > td.textarea {
    width: 100%;
}

table.list tr.textfield > td.textarea {
    background: #fff;
    padding: 0 0em 0 0em;
    margin: 0px;
    padding: 0.4em; 
}

table.list tr.textfield > td > textarea {
    width: 100%;
    height: 10em;
    padding: 0.4em;
    padding: 0.0em;
    font-size: 1.0em;
    color: #555;
    text-align: left;
    margin: 0em;
    border: 0px;
}

table.list tr.textfield > td > textarea.small {
    height: 3em;
}

table.list tr.textfield > td > textarea.large {
    height: 20em;
}

table.list tr > td.noedit {
    padding: 0.5em;
    width: 95%;
    color: #777;
    line-height: 1.2em;
}

table.border tr > td.historybutton {
    border-right: 1px solid #bbb;    
}

table.list tr > td.historybutton {
    padding: 0.1em 0.5em 0.1em 0.2em;
    padding: 0px;
    cursor: pointer;
    vertical-align: middle;
    text-align: right;
}

table.list tr.textarea > td.historybutton {
    vertical-align: top;
}

span.rbutton_on,
span.rbutton_off {
    display: inline-block;
    border: 1px solid #777;
    padding: 0.25em 0.05em 0.25em 0.05em;
    width: 1.4em;
    margin: 0em 0.25em 0em 0.5em;
    cursor: pointer;
    text-align: center;
    font-size: 1.0em;
    text-decoration: none;
    font-family: CinikiRegular;
}

span.rbutton_on {
    color: #000;
}

span.rbutton_off {
    color: #bbb;
}

td.input span.rbutton_on,
td.input span.rbutton_off,
h2 span.rbutton_off {
    position: relative;
    /* margin-top: -0.3em; */
    /* top: -0.2em; */
    margin-left: 0.5em;
}

h2 span.rbutton_off {
    font-size: 0.7em;
}

table.list tr > td > img.calendarbutton {
    padding: 0.1em 0.5em 0.2em 0.2em;
    cursor: pointer;
    vertical-align: middle;
    text-align: right;
    margin-right: 0px;
    margin-left: auto;
    width: 1.4em;
}

table.border tr.fieldcalendar > td.calendar {
    border-left: 1px solid #bbb;    
    border-right: 1px solid #bbb;    
    border-bottom: 1px solid #bbb;    
}

table.list tr.fieldcalendar > td.calendar {
    text-align: left;
    padding: 0em;
    width: 100%;
    vertical-align: top;
    text-align: center;
}

table.list div.calendar {
    display: inline-block;
    margin: 1px;
    padding: 0px;
    vertical-align: top;
    border: 0px;
    min-width: 12em;
}

table.list table.calendar {
    background: #bbb;
    border: 0px;
    empty-cells: show;
    width: 100%;
    margin: 1px;
    padding: 0px;
    font-size: 0.8em;
    /* border-collapse: collapse; */
    border-top: 1px solid #bbb;
    border-left: 1px solid #bbb;
}

table.list table.calendar td {
    text-align: center;
    padding: 0.25em;
    background: #eee;
    border-right: 1px solid #bbb;
    border-bottom: 1px solid #bbb;
    cursor: pointer;
}

table.list table.calendar td.empty {
    background: #ddd;
    cursor: default;
}

table.list table.calendar td.today {
    background: #dfd;
}

table.list table.calendar td.selected {
    background: #ddf;
    font-weight: bold;
    text-decoration: underline;
}

table.list table.calendar td.newselection {
    background: #fdf;
}

table.list div.calendar table.calendar > thead td {
    background: #bbb;
    font-size: 1em;
}



table.form tr.fieldcolourpicker    div.colours,
table.form tr.fieldcolourpicker    div.colourpicker {
    display: inline-block;
    border: 0px;
    vertical-align: top;
    width: 50%;
    margin: 0px;
    padding: 0px;
    height: 100%;
}

table.form tr.fieldcolourpicker span.colourswatch {
    margin: 0.3em;
    cursor: pointer;
}

table.form tr.fieldcolourpicker div.colourpicker table.colourpicker {
    border: 1px solid #bbb;
    width: 100%;
}

table.form tr.fieldcolourpicker div.colourpicker table.colourpicker td {
    vertical-align: top;
    text-align: center;
    background: #eee;
    padding: 0.3em;
}

table.form tr.fieldcolourpicker div.colourpicker table.colourpicker td:first-child {
    border-right: 1px solid #bbb;
}

table.form tr.fieldcolourpicker div.colours table.colours {
    border: 1px solid #bbb;
    width: 100%;
}
table.form tr.fieldcolourpicker div.colours table.colours td {
    background: #eee;
    padding: 0.3em;
}

table.list table.fieldhistory tr td {
    padding: 0.5em;
    color: #555;
    text-align: left;
}

table.list > tbody > tr > td.truncate {
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
}

table.list td p {
    padding-top: 1em;
    line-height: 1.4em;
}
table.list td p:first-child {
    padding-top: 0em;
}
table.list td ul {
    margin-top: 1em;
    margin-bottom: 0em;
}
table.list td ul:first-child {
    margin-top: 0em;
}
table.list td dl {
    margin-top: 1em;
    margin-bottom: 0em;
}
table.list td dl:first-child {
    margin-top: 0em;
}
table.list td dl dt {
    display: block;
    clear: left;
    float: left;
}
table.list td dl dd {
    display: block;
    padding-left: 1em;
}


table.list td em {
    font-weight: bold;
}

p {
    margin: 0;
    /* padding: 1em 0.5em 1em 0.5em; */
}


table.list tr > td.helpbutton {
    padding: 0.1em 0.5em 0.1em 0.2em;
    cursor: pointer;
    vertical-align: middle;
    text-align: right;
    width: 1.4em;
}

table.list > tbody > tr.followup > td {
    font-size: 0.9em;
    vertical-align: top;
}

table.form table.fieldhistory {
    padding: 0em;
    width: 100%;
    empty-cells: show;
}

table.list table.fieldhistory tr td {
    padding: 0.5em;
    color: #555;
    text-align: left;
    font-size: 1em;
    background: #eee;
}

table.border table.fieldhistory td {
    border-bottom: 1px solid #777;
}

table.list table.fieldhistory td.fieldvalue {
    text-align: right;
    cursor: pointer;
    white-space: pre-line;
}

table.list td.searchresults {
    text-align: left;
    padding: 0em;
}

table.list td.nosearchresults {
    border-top: 1px solid #bbb;    
    border-left: 1px solid #bbb;    
    border-right: 1px solid #bbb;    
    border-bottom: 1px solid #bbb;    
}

table.list td.nosearchresults {
    text-align: left;
    padding: 0.5em;
}

table.form table.simplegrid,
table.list table.searchresults {
    padding: 0em;
    width: 100%;
    empty-cells: show;
    margin-bottom: 0em;
}

table.list table.searchresults tr td {
    border-left: 1px solid #bbb;    
    border-right: 1px solid #bbb;    
    border-bottom: 1px solid #bbb; 
}

table.list table.searchresults tr td {
    padding: 0.5em;
    color: #555;
    text-align: left;
    font-size: 1em;
    background: #eee;
    cursor: pointer;
}

table.list table.searchresults tr:first-child td {
    border-top: 1px solid #bbb;
}

table.border table.searchresults td {
    border-bottom: 1px solid #bbb;
}
table.border table.searchresults tr:last-child td {
    border-bottom: 0px;
}

table.list table.searchresults td.fieldvalue {
    text-align: right;
    cursor: pointer;
}

table.list table.searchresults td.buttons {
    text-align: right;
    padding: 0.2em 0.5em 0.2em 0.5em;
}

table.list table.searchresults td.buttons > button {
    text-align: center;
    font-size: 0.8em !important;
    padding: 0.2em 0.8em 0.2em 0.8em;
}

table.list td.alert {
    background: #fee;
}

table.simplegrid td.label {
    text-align: right;
}

table.simplegrid td.border {
    border-right: 1px solid #bbb;
}

table.simplegrid td.center {
    text-align: center;
}

table.dayschedule td.addlink,
table.simplegrid td.addlink {
    color: #bbb;
    padding-left: 1.9em;
}

table.dayschedule td.addlink {
    border-right: 0px;
}

table.list td div.dragdrop_cell {
    width: 100%;
    height: 1em;
}

table.simplegrid td.excel_deleted {
    background: #ddd;
}

table.simplegrid td.excel_keep {
    background: #efe;
}

table.list > tbody > tr > td.textbuttons {
    padding: 0.4em;
}

table.list > tbody > tr > td.multiline span.maintext {
    width: 100%;
    display: block;
}

table.list > tbody > tr > td span.subdue {
    font-size: 0.9em;
    font-decoration: normal;
    font-weight: normal;
    color: #999;
}

table.list > tbody > tr > td.multiline {
    padding: 0.5em 0.5em 0.45em 0.5em;
}

table.list > tbody > tr > td.multiline span.subtext {
    width: 100%;
    font-size: 0.8em;
    color: #999;
/*    padding-top: 0.1em; */
    display: block;
}
table.list > tbody > tr > td.multiline > span.singleline {
    overflow: hidden;
    text-overflow: ellipsis;
}

table.list > tbody > tr > td.nobreak {
    white-space: nowrap;
}

table.list > tbody > tr > td.multiline span.subsubtext {
    width: 100%;
    font-size: 0.8em;
    color: #999;
    padding-top: 0.1em;
    display: block;
}

table.list > tbody > tr > td.aligntop,
table.list > tfoot > tr > td.aligntop {
    vertical-align: top;
}

table.list > tbody > tr > td.aligncenter,
table.list > tfoot > tr > td.aligncenter {
    text-align: center;
}

table.list td span.icon {
    font-size: 1.1em;
    text-decoration: none;
    font-family: CinikiRegular;
    color: #777; 
    max-height: 20px;
    vertical-align: top;
}


table.simplegrid td.lightborderright {
    border-right: 1px solid #ddd;
}

table.simplegrid td.thumbnail {
    padding: 0.5em;
    width: 2em;
}

table.simplegrid td.thumbnail img {
}

table.form td.input div.image_preview {
    width: 100%;
    text-align: center;
}

table.form td.input div.image_preview img {
    background-color: #fff;
    padding: 8px;
    border: 1px solid #aaa;
    max-width: 95%;
}

table.datepicker {
    width: 100%;
    table-layout: auto;
}

table.datepicker > tbody > tr > td.date {
    text-align: center;
}

table.datepickersearch > tbody > tr > td.date {
    text-align: left;
}

table.simplelist > tbody > tr > td.search,
table.datepickersearch > tbody > tr > td.search {
    text-align: right;
    width: 40%;
    padding: 0px;
    vertical-align: middle;
    padding-right: 0.5em;
    padding-left: 0.5em;
    margin-left: -0.5em;
}

table.simplelist > tbody > tr > td.search input,
table.datepickersearch > tbody > tr > td.search input {
    width: 100%;
    height: 100%;
    padding: 0.3em;
    padding-right: 0;
    font-size: 1.0em;
    color: #555;
    text-align: left;
    margin: 0.3em;
    text-overflow: ellipsis
    white-space: nowrap;
    border: 1px solid #ddd;    
}

table.form > tbody > tr > td.multiselect,
table.form > tbody > tr > td.multitoggle,
table.form > tbody > tr > td.joinedflags,
table.form > tbody > tr > td.flags {
    padding: 0em 0.25em 0em 0.25em;
}

table.form > tbody > tr > td div.buttons {
    display: inline-block;
    padding-left: 0.6em;
    margin: 0px;
}

table.form > tbody > tr > td div.nopadbuttons {
    padding-left: 0em;
}

table.form > tbody > tr > td.multiselect div,
table.form > tbody > tr > td.multitoggle div {
    display: inline-block;
}

table.form > tbody > tr > td.multiselect span.hint,
table.form > tbody > tr > td.multitoggle span.hint {
    color: #999;
    padding-left: 0.6em;
}

table.form > tbody > tr > td.joinedflags div {
    display: table;
}

table.form span.flag_on {
    color: #000;
}

table.form span.flag_off {
    color: #bbb;
}

table.form td.joinedflags span.flag_on,
table.form td.joinedflags span.flag_off, 
table.form td div span.toggle_on,
table.form td div span.toggle_off {
    display: inline-block;
    border: 1px solid #777;
    font-weight: bold; 
    padding: 0.4em 0.5em 0.4em 0.5em;
    margin: 0.3em 0 0.3em 0;
    cursor: pointer;
    font-size: 0.9em;
}

table.form td div span.toggle_on {
    color: #000;
}

table.form td div span.toggle_off {
    color: #bbb;
}

table.form td span.flag_on span.icon,
table.form td span.flag_off span.icon,
table.form td span.toggle_on span.icon,
table.form td span.toggle_off span.icon {
    color: inherit;
}

table.paneltabs {
    margin-bottom: 0.5em;
}

table.paneltabs > tbody > tr > td {
    padding: 0em;
}

table.paneltabs td div span.toggle_on,
table.paneltabs td div span.toggle_off {
    font-size: 1.0em;
    margin: 0em;
}

span.username {
}

span.age {
    font-size: 0.8em;
    color: #888;
    font-style: italic;
}

input.submit {
    color: #333;
    font-size: 1em;
}

.clickable {
    cursor: pointer;
}

table.services > tbody > tr > td.jobs {
    padding: 0.1em;
}

/* Text block markups */
div.wide table.text {
    min-width: 40em;
    table-layout: auto;
}

table.text tr.text td pre {
    overflow-x: scroll;
}

table.text tr.text td p:first-child,
table.text tr.text td pre:first-child {
    padding-top: 0px;
    margin-top: 0px;
}

table.text tr.text td p:last-child,
table.text tr.text td pre:last-child {
    padding-bottom: 0px;
    margin-bottom: 0px;
}

/********** Error screen ********/
#m_error {
    position: absolute;
    top: 0;
    left: 0;
    z-index: 98;
    width: 100%;
    height: 90%;
}

#m_error button {
    width: 10em;
    margin-top: 5px;
    margin-bottom: 5px;
    text-align: center;
    font-size: 1em;
    color: #333;
    cursor: pointer;
}


/********** Loading Spinner **************/
#m_loading {
    width: 100%;
    height: 100%;
    overflow: hidden;
    position: fixed;
    top: 0px;
    left: 0px;
    background: #fff;
    text-align: center;
    vertical-align: middle;
    opacity: .5;
    z-index:99;
}

#m_loading table {
    width: 100%;
    height: 100%;
}

div.scrollable {
    overflow: auto;
    width: 100%;
}
table.form td.textarea,
table.form td.search input,
table.form td.multiselect input,
table.form td.input input {
    -webkit-border-radius: 3px;
    -webkit-box-shadow: #eee 0px 1px 1px inset;
    border: 1px solid #ddd;
    margin-right: 1.5em;
    box-sizing: border-box;
}

table.simplelist input,
table.datepicker input {
    -webkit-border-radius: 3px;
    -webkit-box-shadow: #eee 0px 1px 1px inset;
}

input, textarea {
    -webkit-appearance: none;
}

input:focus {
    outline: none;
}

table.form tr.textfield > td > input.search {
    height: 2.0em;
}

h2 {
    text-shadow: #fff 1px 1px 0px;
}

span.count {
    -webkit-border-radius: 1.2em;
    text-shadow: #fff 1px 1px 0px;
}

button, input.button {
    box-sizing: border-box;
    border-radius: 3px;
    border: 1px solid #ccc;
    background: -webkit-gradient(linear, left top, left bottom, from(#999), to(#555));
    padding: 0.5em 0.5em 0.45em 0.5em;
    padding: 0.5em;
    color: #eee;
    font-size: 1.0em;
    font-weight: bold;
    width: 100%;
}
textarea {
    -webkit-appearance: none;
}

input:-webkit-autofill {
    background: #fff !important;
}

table.list {
    -webkit-border-radius: 3px;
}

table.list > tbody:first-child > tr:first-child > td:first-child > textarea,
table.list > tbody:first-child > tr table,
table.list > tbody:first-child > tr table tr:first-child > td:first-child,
table.header > thead > tr:first-child > th:first-child,
table.noheader > tbody:first-child > tr:first-child > td:first-child,
table.list > tfoot:first-child > tr:first-child > td:first-child {
    -webkit-border-top-left-radius: 3px;
}

table.list > tbody:first-child > tr:first-child > td:last-child > textarea,
table.list > tbody:first-child > tr table,
table.list > tbody:first-child > tr table tr:first-child > td:last-child,
table.header > thead > tr:first-child > th:last-child,
table.noheader > tbody:first-child > tr:first-child > td:last-child,
table.list > tfoot:first-child > tr:first-child > td:last-child {
    -webkit-border-top-right-radius: 3px;
}
table.list > tbody:last-child > tr:last-child > td:first-child > textarea,
table.list > tbody:last-child > tr table,
table.list > tbody:last-child > tr table tr:last-child > td:first-child,
table.list > thead:last-child > tr:last-child > th:first-child,
table.list > tbody:last-child > tr:last-child > th:first-child,
table.list > tbody:last-child > tr:last-child > td:first-child,
table.list > tfoot > tr:last-child > td:first-child {
    -webkit-border-bottom-left-radius: 3px;
}
table.list > tbody:last-child > tr:last-child > td:last-child > textarea,
table.list > tbody:last-child > tr table,
table.list > tbody:last-child > tr table tr:last-child > td:last-child,
table.list > thead:last-child > tr:last-child > th:last-child,
table.list > tbody:last-child > tr:last-child > td:last-child,
table.list > tfoot > tr:last-child > td:last-child {
    -webkit-border-bottom-right-radius: 3px;
}

table.list td > div.colourswatches > span.selected {
    -webkit-box-shadow: #777 1px 1px 3px;
}

body {
    font-size: 100%;
    color: #303030;
    font-family: arial, helvetica;
    padding: 0px;
    margin: 0px;
    border: 0px;
    height: 100%;
}

.headerbar {
    border-bottom: 1px solid #667;
}

#m_error table.list td {
    background: #fff;
}

#m_container {
    margin: 0px;
    border: 0px;
    padding: 0px;
    width: 100%;
    height: 100%;
}

#mc_apps {
    left: 0px;
    width: 100%;
    margin: 0px;
    padding: 0px;
}

div.narrow {
    width: 20em;
    margin: 0 auto;
    padding-top: 1em;
    padding-bottom: 1em;
}

div.medium {
    width: 92%;
    max-width: 40em;
    margin: 0 auto;
}

div.mediumflex {
    min-width: 30em;
    max-width: 50em;
    margin: 0 auto;
}

div.large {
    width: 50em;
    max-width: 95%;
    margin: 0 auto;
}

div.xlarge {
    width: 60em;
    max-width: 95%;
    margin: 0 auto;
}

div.panel {
    text-align: center;
    margin: 0 auto;
    width: 100%;
}

div.wide {
    display: inline-block;
    text-align: center;
    margin: 0 auto;
    padding-left: 1em;
    padding-right: 1em;
}

div.narrow h2,
div.mediumflex h2,
div.medium h2 {
    width: 100%;
}

div.headerbar {
    font-size: 1em;
    margin: 0px;
    padding: 0px;
    height: 2.5em;
    width: 100%;
    border-bottom: 1px solid #ddd;
}

input {
    padding: 0.2em;
}

#m_help {
    float: right;
    min-height: 100%;
}

table.list tr.textfield > td > input.datetime {
    max-width: 12em;
}

table.list tr.textfield > td > input.timeduration {
    max-width: 6em;
}

table.list tr.gridfields > td.input input.integer,
table.list tr.gridfields > td.input input.small,
table.list tr.gridfields > td.input input.date,
table.list tr.gridfields > td.input input.hexcolour,
table.list tr.gridfields > td.input input.time,
table.list tr > td input.integer,
table.list tr > td input.small,
table.list tr > td input.date,
table.list tr > td input.hexcolour,
table.list tr > td input.time {
    max-width: 8em;
}

table.list tr.textfield > td > input.medium {
    max-width: 15em;
}

table.list tr.textfield > td > input.large {
    max-width: 45em;
}

table.list > tbody > tr.followup > td.userdetails {
    border-right: 1px dashed #bbb;
    text-decoration: normal;
    white-space: nowrap;
}

table.list > tbody > tr.followup > td.content {
    text-decoration: normal;
    white-space: pre-wrap;
}

</style>
</head>
<body id="m_body">
<div id='m_container' class="s-normal">
    <table id="mc_header" class="headerbar" cellpadding="0" cellspacing="0">
        <tr>
        <td id="mc_home_button" style="display:none;"><img src="ciniki-mods/core/ui/themes/default/img/home_button.png"/></td>
        <td id="mc_title" class="title">QRUQSP Pi Installer</td>
        <td id="mc_help_button" style="display:none;"><img src="ciniki-mods/core/ui/themes/default/img/help_button.png"/></td>
        </tr>
    </table>
    <div id="mc_content">
    <div id="mc_content_scroller" class="scrollable">
    <div id="mc_apps">
        <div id="mapp_installer" class="mapp">
            <div id="mapp_installer_content" class="panel">
                <div class="medium">
                <?php
                    if( $err_code == 'installed' ) {
                        print "<h2 class=''>Installed</h2><div class='bordered error'><p>QRUQSP has been installed and configured, you can now login at </p><p><a href='/manager'>/manager</a></p></div>";

                    }
                    elseif( $err_code != '' ) {
                        print "<h2 class='error'>Error</h2><div class='bordered error'><p>Error $err_code - $err_msg</p></div>";
                    }
                ?>
                <?php if( $display_form == 'yes' ) { ?>
                    <form id="mapp_installer_form" method="POST" name="mapp_installer_form">
                        <div class="section">
                        <h2></h2>
                        <table class="list noheader form outline" cellspacing='0' cellpadding='0'>
                            <tbody>
                            <tr class="textfield"><td class="label"><label for="first">First</label></td>
                                <td class="input"><input type="text" id="first" name="first" /></td></tr>
                            <tr class="textfield"><td class="label"><label for="last">Last</label></td>
                                <td class="input"><input type="text" id="last" name="last" /></td></tr>
                            <tr class="textfield"><td class="label"><label for="email">Email</label></td>
                                <td class="input"><input type="email" id="email" name="email" /></td></tr>
                            <tr class="textfield"><td class="label"><label for="callsign">Callsign</label></td>
                                <td class="input"><input type="text" id="callsign" name="callsign" /></td></tr>
                            <tr class="textfield"><td class="label"><label for="password">Password</label></td>
                                <td class="input"><input type="password" id="password" name="password" /></td></tr>
                            </tbody>
                        </table>
                        </div>
                        <div style="text-align:center;">
                            <input type="submit" value=" Configure Station " class="button">
                        </div>
                    </form>
                <?php } ?>
            </div>
            </div>
        </div>
    </div>
    </div>
    </div>
</div>
</body>
</html>
<?php
}

//
// Install Procedure
//
function install($ciniki_root, $modules_dir, $args) {

    $database_host = $args['database_host'];
    $database_username = $args['database_username'];
    $database_password = $args['database_password'];
    $database_name = $args['database_name'];
    $admin_email = $args['admin_email'];
    $admin_username = $args['admin_username'];
    $admin_password = $args['admin_password'];
    $admin_firstname = $args['admin_firstname'];
    $admin_lastname = $args['admin_lastname'];
    $admin_display_name = $args['admin_display_name'];
    $master_name = $args['master_name'];
    $system_email = $args['system_email'];
    $system_email_name = $args['system_email_name'];
    $sync_code_url = preg_replace('/\/$/', '', $args['sync_code_url']);

    $manage_api_key = md5(date('Y-m-d-H-i-s') . rand());

    //
    // Build the config file
    //
    $config = array('ciniki.core'=>array(), 'ciniki.users'=>array());
    $config['ciniki.core']['php'] = '/usr/bin/php';
    $config['ciniki.core']['root_dir'] = $ciniki_root;
    $config['ciniki.core']['modules_dir'] = $ciniki_root . '/ciniki-mods';
    $config['ciniki.core']['lib_dir'] = $ciniki_root . '/ciniki-lib';
    $config['ciniki.core']['storage_dir'] = $ciniki_root . '/ciniki-storage';
    $config['ciniki.core']['cache_dir'] = $ciniki_root . '/ciniki-cache';
    $config['ciniki.core']['backup_dir'] = $ciniki_root . '/ciniki-backups';

    // Default session timeout to 7 days 
    $config['ciniki.core']['session_timeout'] = 604800;

    // Database information
    if( isset($args['database_engine']) && $args['database_engine'] != '' ) {
        $config['ciniki.core']['database.engine'] = $args['database_engine'];
    }
    $config['ciniki.core']['database'] = $database_name;
    $config['ciniki.core']['database.names'] = $database_name;
    $config['ciniki.core']["database.$database_name.hostname"] = $database_host;
    $config['ciniki.core']["database.$database_name.username"] = $database_username;
    $config['ciniki.core']["database.$database_name.password"] = $database_password;
    $config['ciniki.core']["database.$database_name.database"] = $database_name;

    // The master tenantn ID will be set later on, once information is in database
    $config['ciniki.core']['master_tnid'] = 0;
    $config['ciniki.core']['qruqsp_tnid'] = 0;


    $config['ciniki.core']['alerts.notify'] = $admin_email;
    $config['ciniki.core']['system.email'] = $system_email;
    $config['ciniki.core']['system.email.name'] = $system_email_name;

    // Configure packages and modules 
    $config['ciniki.core']['packages'] = 'ciniki,qruqsp';

    // Sync settings
    $config['ciniki.core']['sync.name'] = $master_name;
    $config['ciniki.core']['sync.url'] = "https://" . $args['server_name'] . "/" . preg_replace('/^\//', '', dirname($args['request_uri']) . "ciniki-sync.php");
    $config['ciniki.core']['sync.full.hour'] = "13";
    $config['ciniki.core']['sync.partial.hour'] = "13";
    $config['ciniki.core']['sync.code.url'] = $sync_code_url;
    $config['ciniki.core']['sync.log_lvl'] = 0;
    $config['ciniki.core']['sync.log_dir'] = dirname($ciniki_root) . "/logs";
    $config['ciniki.core']['sync.lock_dir'] = dirname($ciniki_root) . "/logs";
    $config['ciniki.core']['manage.url'] = "https://" . $args['server_name'] . "/" . preg_replace('/^\//', '', dirname($args['request_uri']) . "manager");

    // Configure users module settings for password recovery
    $config['ciniki.users']['password.forgot.notify'] = $admin_email;
    $config['ciniki.users']['password.forgot.url'] = "https://" . $args['server_name'] . "/" . preg_replace('/^\/$/', '', dirname($args['request_uri']));

    $config['ciniki.web'] = array();
    $config['ciniki.mail'] = array();

    $config['qruqsp.core'] = array();
    $config['qruqsp.core']['log_dir'] = dirname($ciniki_root) . '/logs';
    $config['qruqsp.43392'] = array();
    $config['qruqsp.43392']['listener'] = 'active';

    //
    // Setup ciniki variable, just like ciniki-mods/core/private/init.php script, but we
    // can't load that script as the config file isn't on disk, and the user is not 
    // in the database
    //
    $ciniki = array('config'=>$config);
    $ciniki['request'] = array('api_key'=>$manage_api_key, 'auth_token'=>'', 'method'=>'', 'args'=>array());

    //
    // Check to see if the code already exists on server, if not grab the code and install
    //
    if( !file_exists($ciniki_root . "/ciniki-mods/core") ) {
        if( $sync_code_url == '' ) {
            return array('form'=>'yes', 'err'=>'ciniki.installer.200', 'msg'=>"Ciniki has not been downloaded, please check Code URL.}");
        }
        $remote_versions = file_get_contents($sync_code_url . '/_versions.ini');
        if( $remote_versions === false ) {
            return array('form'=>'yes', 'err'=>'ciniki.installer.201', 'msg'=>"Unable to sync code, please check Code URL.}");
        }
        $remote_modules = parse_ini_string($remote_versions, true);
        
        # Create directory structure
        if( !file_exists($ciniki_root . "/ciniki-mods") ) {
            mkdir($ciniki_root . "/ciniki-mods");
        }
        if( !file_exists($ciniki_root . "/ciniki-cache") ) {
            mkdir($ciniki_root . "/ciniki-cache");
        }
        if( !file_exists($ciniki_root . "/ciniki-backups") ) {
            mkdir($ciniki_root . "/ciniki-backups");
        }
        if( !file_exists($ciniki_root . "/ciniki-storage") ) {
            mkdir($ciniki_root . "/ciniki-storage");
        }
        if( !file_exists($ciniki_root . "/ciniki-code") ) {
            mkdir($ciniki_root . "/ciniki-code");
        }
        if( !file_exists($ciniki_root . "/ciniki-lib") ) {
            mkdir($ciniki_root . "/ciniki-lib");
        }

        # This code also exists in ciniki-mods/core/private/syncUpgradeSystem
        foreach($remote_modules as $mod_name => $module) {
            $remote_zip = file_get_contents($sync_code_url . "/$mod_name.zip");
            if( $remote_zip === false ) {
                return array('form'=>'yes', 'err'=>'ciniki.installer.202', 'msg'=>"Unable to get {$mod_name}.zip, please check Code URL.}");
            }
            $zipfilename = $ciniki_root . "/ciniki-code/$mod_name.zip";
            if( ($bytes = file_put_contents($zipfilename, $remote_zip)) === false ) {
                return array('form'=>'yes', 'err'=>'ciniki.installer.203', 'msg'=>"Unable to save {$zipfilename}");
            }
            if( $bytes == 0 ) {
                return array('form'=>'yes', 'err'=>'ciniki.installer.204', 'msg'=>"Unable to open {$zipfilename}");
            }
            $zip = new ZipArchive;
            $res = $zip->open($zipfilename);
            if( $res === true ) {
                $mpieces = preg_split('/\./', $mod_name);
                $mod_dir = $ciniki_root . '/' . $mpieces[0] . '-' . $mpieces[1] . '/' . $mpieces[2];
                if( !file_exists($mod_dir) ) {
                    mkdir($mod_dir);
                }
                $zip->extractTo($mod_dir);
                $zip->close();
            } else {
                return array('form'=>'yes', 'err'=>'ciniki.installer.205', 'msg'=>"Unable to open {$mod_name}.zip");
            }
        }
    }

    //
    // Initialize the database connection
    //
    require_once($modules_dir . '/core/private/loadMethod.php');
    ciniki_core_loadMethod($ciniki, 'ciniki', 'core', 'private', 'dbInit');
    $rc = ciniki_core_dbInit($ciniki);
    if( $rc['stat'] != 'ok' ) {
        return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to to connect to the database, please check your connection settings and try again.<br/><br/>" . $rc['err']['msg']);
    }

    //
    // Run the upgrade script, which will upgrade any existing tables,
    // so we don't have to check first if they exist.
    // 
    ciniki_core_loadMethod($ciniki, 'ciniki', 'core', 'private', 'dbUpgradeTables');
    $rc = ciniki_core_dbUpgradeTables($ciniki);
    if( $rc['stat'] != 'ok' ) {
        return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to to connect to the database, please check your connection settings and try again.<br/><br/>" . $rc['err']['msg']);
    }

    // FIXME: Add code to upgrade other packages databases


    //
    // Check if any data exists in the database
    //
    $strsql = "SELECT 'num_rows', COUNT(*) FROM ciniki_core_api_keys, ciniki_users";
    ciniki_core_loadMethod($ciniki, 'ciniki', 'core', 'private', 'dbCount');
    $rc = ciniki_core_dbCount($ciniki, $strsql, 'core', 'count');
    if( $rc['stat'] != 'ok' ) {
        return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to check for existing data<br/><br/>" . $rc['err']['msg']);
    }
    if( $rc['count']['num_rows'] != 0 ) {
        return array('form'=>'yes', 'err'=>'ciniki.installer.220', 'msg'=>"Failed to check for existing data");
    }
    $db_exists = 'no';

    //
    // FIXME: Check if api_key already exists for ciniki-manage, and add if doesn't
    //



    //
    // FIXME: Add the user, if they don't already exist
    //

    //
    // Start a new database transaction
    //
    ciniki_core_loadMethod($ciniki, 'ciniki', 'core', 'private', 'dbTransactionStart');
    ciniki_core_loadMethod($ciniki, 'ciniki', 'core', 'private', 'dbTransactionRollback');
    ciniki_core_loadMethod($ciniki, 'ciniki', 'core', 'private', 'dbTransactionCommit');
    ciniki_core_loadMethod($ciniki, 'ciniki', 'core', 'private', 'dbInsert');
    $rc = ciniki_core_dbTransactionStart($ciniki, 'core');
    if( $rc['stat'] != 'ok' ) {
        return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
    }

    if( $db_exists == 'no' ) {
        //
        // Add the user
        //
        $strsql = "INSERT INTO ciniki_users (id, uuid, email, username, password, avatar_id, perms, status, timeout, "
            . "firstname, lastname, display_name, date_added, last_updated) VALUES ( "
            . "'1', UUID(), '$admin_email', '$admin_username', SHA1('$admin_password'), 0, 1, 1, 0, "
            . "'$admin_firstname', '$admin_lastname', '$admin_display_name', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'users');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }

        //
        // Add the master tenant, if it doesn't already exist
        //
        $strsql = "INSERT INTO ciniki_tenants (id, uuid, name, tagline, description, status, date_added, last_updated) VALUES ("
            . "'1', UUID(), '$master_name', '', '', 1, UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }
        $config['ciniki.core']['master_tnid'] = 1;
        $config['ciniki.core']['qruqsp_tnid'] = 1;
        if( isset($args['disable_ssl']) && $args['disable_ssl'] == 'yes' ) {
            $config['ciniki.core']['ssl'] = "'off'";
        }
        $config['ciniki.web']['master.domain'] = $args['http_host'];
        $config['ciniki.web']['poweredby.url'] = "http://ciniki.com/";
        $config['ciniki.web']['poweredby.name'] = "Ciniki";
        $config['ciniki.mail']['poweredby.url'] = "http://ciniki.com/";
        $config['ciniki.mail']['poweredby.name'] = "Ciniki";

        //
        // Add sysadmin as the owner of the master tenant
        //
        $strsql = "INSERT INTO ciniki_tenant_users (uuid, tnid, user_id, package, permission_group, status, date_added, last_updated) VALUES ("
            . "UUID(), '1', '1', 'ciniki', 'owners', '1', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }

        //
        // Enable modules: bugs, questions for master tenant
        //
/*        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'ciniki', 'bugs', 1, 'all_customers', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }
        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'ciniki', 'web', 1, '', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        } */

        //
        // Enable the QRUQSP modules
        //
/*        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'qruqsp', 'aprs', 1, '', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        } */
/*        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'qruqsp', 'tnc', 1, '', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }
        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'qruqsp', 'qsn', 1, '', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }
        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'qruqsp', 'qsl', 1, '', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }
        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'qruqsp', 'qrz', 1, '', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        } 
        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'qruqsp', 'qny', 1, '', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        } */
        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
            . "VALUES ('1', 'qruqsp', '43392', 1, '', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }

//        $strsql = "INSERT INTO ciniki_tenant_modules (tnid, package, module, status, ruleset, date_added, last_updated) "
//            . "VALUES ('1', 'ciniki', 'questions', 1, 'all_customers', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
//        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'tenants');
//        if( $rc['stat'] != 'ok' ) {
//            ciniki_core_dbTransactionRollback($ciniki, 'core');
//            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
//        }

        //
        // Setup notification settings
        //
        $strsql = "INSERT INTO ciniki_bug_settings (tnid, detail_key, detail_value, date_added, last_updated) "
            . "VALUES ('1', 'add.notify.owners', 'yes', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'bugs');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }

//        $strsql = "INSERT INTO ciniki_question_settings (tnid, detail_key, detail_value, date_added, last_updated) "
//            . "VALUES ('1', 'add.notify.owners', 'yes', UTC_TIMESTAMP(), UTC_TIMESTAMP())";
//        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'questions');
//        if( $rc['stat'] != 'ok' ) {
//            ciniki_core_dbTransactionRollback($ciniki, 'core');
//            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
//        }

        //
        // Add the api key for the UI
        //
        $strsql = "INSERT INTO ciniki_core_api_keys (api_key, status, perms, user_id, appname, notes, "
            . "last_access, expiry_date, date_added, last_updated) VALUES ("
            . "'$manage_api_key', 1, 0, 2, 'ciniki-manage', '', 0, 0, UTC_TIMESTAMP(), UTC_TIMESTAMP())";
        $rc = ciniki_core_dbInsert($ciniki, $strsql, 'core');
        if( $rc['stat'] != 'ok' ) {
            ciniki_core_dbTransactionRollback($ciniki, 'core');
            return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
        }
    }

    // 
    // Save ciniki-api config file
    //
    $new_config = "";
    foreach($config as $module => $settings) {
        $new_config .= "[$module]\n";
        foreach($settings as $key => $value) {
            $new_config .= "    $key = $value\n";
        }
        $new_config .= "\n";
    }
    $num_bytes = file_put_contents($ciniki_root . '/ciniki-api.ini', $new_config);
    if( $num_bytes == false || $num_bytes < strlen($new_config)) {
        unlink($ciniki_root . '/ciniki-api.ini');
        ciniki_core_dbTransactionRollback($ciniki, 'core');
        return array('form'=>'yes', 'err'=>'ciniki.installer.99', 'msg'=>"Unable to write configuration, please check your website settings.");
    }

    //
    // Save ciniki-manage config file
    //
    $manage_config = ""
        . "[ciniki.core]\n"
        . "manage_root_url = /ciniki-mods\n"
        . "themes_root_url = " . preg_replace('/^\/$/', '', dirname($args['request_uri'])) . "/ciniki-mods/core/ui/themes\n"
        . "json_url = " . preg_replace('/^\/$/', '', dirname($args['request_uri'])) . "/ciniki-json.php\n"
        . "api_key = $manage_api_key\n"
        . "site_title = '" . $master_name . "'\n"
        . "help.mode = online\n"
        . "help.url = https://qruqsp.org/\n"
        . "";

    $num_bytes = file_put_contents($ciniki_root . '/ciniki-manage.ini', $manage_config);
    if( $num_bytes == false || $num_bytes < strlen($manage_config)) {
        unlink($ciniki_root . '/ciniki-api.ini');
        unlink($ciniki_root . '/ciniki-manage.ini');
        ciniki_core_dbTransactionRollback($ciniki, 'core');
        return array('form'=>'yes', 'err'=>'ciniki.installer.98', 'msg'=>"Unable to write configuration, please check your website settings.");
    }

    //
    // Save the .htaccess file
    //
    $htaccess = ""
        . "# Block evil spam bots\n"
        . "# List found on : http://perishablepress.com/press/2006/01/10/stupid-htaccess-tricks/#sec1\n"
        . "RewriteBase /\n"
        . "RewriteCond %{HTTP_USER_AGENT} ^Anarchie [OR]\n"
        . "RewriteCond %{HTTP_USER_AGENT} ^ASPSeek [OR]\n"
        . "RewriteCond %{HTTP_USER_AGENT} ^attach [OR]\n"
        . "RewriteCond %{HTTP_USER_AGENT} ^autoemailspider [OR]\n"
        . "RewriteCond %{HTTP_USER_AGENT} ^Xaldon\ WebSpider [OR]\n"
        . "RewriteCond %{HTTP_USER_AGENT} ^Xenu [OR]\n"
        . "RewriteCond %{HTTP_USER_AGENT} ^Zeus.*Webster [OR]\n"
        . "RewriteCond %{HTTP_USER_AGENT} ^Zeus\n"
        . "RewriteRule ^.* - [F,L]\n"
        . "\n"
        . "# Block access to internal code\n"
        . "\n"
        . "Options All -Indexes\n"
        . "RewriteEngine On\n"
        . "# Force redirect to strip www from front of domain names\n"
        . "RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]\n"
        . "RewriteRule ^(.*)$ http://%1/$1 [R=301,L]\n"
        . "# Allow access to artweb themes and cache, everything is considered public\n"
        . "RewriteRule ^ciniki-web-layouts/(.*\.)(css|js|png|eot|ttf|woff|svg)$ ciniki-mods/web/layouts/$1$2 [L]\n"
        . "RewriteRule ^ciniki-web-themes/(.*\.)(css|js|html|png|jpg)$ ciniki-mods/web/themes/$1$2 [L]\n"
        . "RewriteRule ^ciniki-web-cache/(.*\.)(css|js|gif|jpg|png|mp3|ogg|wav)$ ciniki-mods/web/cache/$1$2 [L]\n"
        . "RewriteRule ^ciniki-code/(.*\.)(zip|ini)$ ciniki-code/$1$2 [L]\n"
        . "RewriteBase /\n"
        . "\n"
        . "AddType text/cache-manifest .manifest\n"
        . "\n"
        . "RewriteCond %{REQUEST_FILENAME} -f [OR]\n"
        . "RewriteCond %{REQUEST_FILENAME} -d\n"
        . "RewriteRule ^manager/(.*)$ ciniki-manage.php [L]                                            # allow all ciniki-manage\n"
        . "RewriteRule ^(manager)$ ciniki-manage.php [L]                                             # allow all ciniki-manage\n"
        . "RewriteRule ^([a-z]+-mods/[^\/]*/ui/.*)$ $1 [L]                                                  # Allow manage content\n"
//        . "RewriteRule ^(ciniki-manage-themes/.*)$ $1 [L]                                           # Allow manage-theme content\n"
        . "RewriteRule ^(ciniki-web-themes/.*)$ $1 [L]                                              # Allow manage-theme content\n"
        . "RewriteRule ^(ciniki-mods/web/layouts/.*)$ $1 [L]                                    # Allow web-layouts content\n"
        . "RewriteRule ^(ciniki-mods/web/themes/.*)$ $1 [L]                                     # Allow web-themes content\n"
        . "RewriteRule ^(ciniki-mods/web/cache/.*\.(css|js|jpg|png|mp3|ogg|wav))$ $1 [L]                                      # Allow web-cache content\n"
        . "RewriteRule ^(ciniki-login|ciniki-sync|ciniki-json|index|ciniki-manage).php$ $1.php [L]  # allow entrance php files\n"
        . "RewriteRule ^([_0-9a-zA-Z-]+/)(.*\.php)$ index.php [L]                                  # Redirect all other php requests to index\n"
        . "RewriteRule ^$ index.php [L]                                                              # Redirect all other requests to index\n"
        . "RewriteRule . index.php [L]                                                              # Redirect all other requests to index\n"
        . "\n"
        . "php_value post_max_size 20M\n"
        . "php_value upload_max_filesize 20M\n"
        . "php_value magic_quotes 0\n"
        . "php_flag magic_quotes off\n"
        . "php_value magic_quotes_gpc 0\n"
        . "php_flag magic_quotes_gpc off\n"
        . "php_value session.cookie_lifetime 3600\n"
        . "php_value session.gc_maxlifetime 3600\n"
        . "";

    $num_bytes = file_put_contents($ciniki_root . '/.htaccess', $htaccess);
    if( $num_bytes == false || $num_bytes < strlen($htaccess)) {
        unlink($ciniki_root . '/ciniki-api.ini');
        unlink($ciniki_root . '/ciniki-manage.ini');
        unlink($ciniki_root . '/.htaccess');
        ciniki_core_dbTransactionRollback($ciniki, 'core');
        return array('form'=>'yes', 'err'=>'ciniki.installer.97', 'msg'=>"Unable to write configuration, please check your website settings.");
    }

    //
    // Create symlinks into scripts
    //
    symlink($ciniki_root . '/ciniki-mods/core/scripts/sync.php', $ciniki_root . '/ciniki-sync.php');
    symlink($ciniki_root . '/ciniki-mods/core/scripts/json.php', $ciniki_root . '/ciniki-json.php');
    symlink($ciniki_root . '/ciniki-mods/core/scripts/manage.php', $ciniki_root . '/ciniki-manage.php');
    symlink($ciniki_root . '/ciniki-mods/core/scripts/login.php', $ciniki_root . '/ciniki-login.php');

    $rc = ciniki_core_dbTransactionCommit($ciniki, 'core');
    if( $rc['stat'] != 'ok' ) {
        ciniki_core_dbTransactionRollback($ciniki, 'core');
        unlink($ciniki_root . '/ciniki-api.ini');
        unlink($ciniki_root . '/ciniki-manage.ini');
        unlink($ciniki_root . '/.htaccess');
        unlink($ciniki_root . '/ciniki-json.php');
        unlink($ciniki_root . '/ciniki-manage.php');
        unlink($ciniki_root . '/ciniki-login.php');
        unlink($ciniki_root . '/index.php');
        return array('form'=>'yes', 'err'=>'ciniki.' . $rc['err']['code'], 'msg'=>"Failed to setup database<br/><br/>" . $rc['err']['msg']);
    }

    if( file_exists($ciniki_root . '/index.php') ) {
        unlink($ciniki_root . '/index.php');
    }
    symlink($ciniki_root . '/ciniki-mods/web/scripts/index.php', $ciniki_root . '/index.php');

    return array('form'=>'no', 'err'=>'installed', 'msg'=>'');
}

?>
