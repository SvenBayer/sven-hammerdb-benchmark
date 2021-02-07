#!/bin/tclsh
proc runtimer { seconds } {
set x 0
set timerstop 0
while {!$timerstop} {
incr x
after 1000
  if { ![ expr {$x % 60} ] } {
          set y [ expr $x / 60 ]
          puts "Timer: $y minutes elapsed"
  }
update
if {  [ vucomplete ] || $x eq $seconds } { set timerstop 1 }
    }
return
}
puts "SETTING CONFIGURATION"
dbset db pg
diset connection pg_host [lindex $argv 0]
diset connection pg_port [lindex $argv 1]
diset tpcc pg_superuser [lindex $argv 2]
diset tpcc pg_superuserpass [lindex $argv 3]
diset tpcc pg_driver timed
diset tpcc pg_rampup [lindex $argv 4]
diset tpcc pg_duration [lindex $argv 5]
diset tpcc pg_vacuum true
diset tpcc pg_timeprofile true
print dict

# vuset logtotemp 1
vuset timestamps 1
loadscript

puts "SEQUENCE STARTED"
set virtual_users [lindex $argv 6]
foreach z $virtual_users {
    puts "run_with_num_users = $z"
    vuset vu $z
    vucreate
    vurun
    runtimer [expr [lindex $argv 4] * 60 + [lindex $argv 5] * 60 + 60 * 10]
    vudestroy
    after 5000
}
puts "TEST SEQUENCE COMPLETE"
exit