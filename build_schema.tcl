#!/bin/tclsh
puts "SETTING CONFIGURATION"
global complete
proc wait_to_complete {} {
    global complete
    set complete [vucomplete]
    if {!$complete} {after 5000 wait_to_complete} else { exit }
}
puts "SETTING CONFIGURATION"
dbset db pg
dbset bm TPC-C
diset connection pg_host [lindex $argv 0]
diset connection pg_port [lindex $argv 1]
diset tpcc pg_superuser [lindex $argv 2]
diset tpcc pg_superuserpass [lindex $argv 3]
diset tpcc pg_count_ware [lindex $argv 4]
diset tpcc pg_num_vu [lindex $argv 5]
diset tpcc vacuum true
print dict
buildschema
wait_to_complete