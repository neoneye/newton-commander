Our KCList daemon uses ASL (apple sys log) for logging purposes.
ASL is per default logs messages between "Emergency" to "Notice".

To see all the messages dumped from the KCList program
you need to change the syslog filter.



INSPECT CURRENT FILTER SETTINGS SYSLOG
======================================

prompt> sudo syslog -c syslogd
ASL Data Store filter mask: Emergency - Debug
prompt>



RESTORE DEFAULT FILTER SETTINGS SYSLOG
======================================

prompt> sudo syslog -c syslogd -n
Set ASL Data Store syslog filter mask: Emergency - Notice
prompt> 



SET DEBUG FILTER SETTINGS SYSLOG
======================================

prompt> sudo syslog -c syslogd -d
Set ASL Data Store syslog filter mask: Emergency - Debug
prompt> 


