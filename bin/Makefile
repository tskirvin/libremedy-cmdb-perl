REM_HOME=~/work/remedy/libremedy-perl

clean: 
	./cmdb-clear MDR.IMPORT.PUPPET "restarting at `date`"

clean-loud: 
	./cmdb-clear --debug --debug --debug --debug --debug MDR.IMPORT.PUPPET "restarting at `date`"

current:
	${REM_HOME}/bin/remedy-dump "BMC.CORE:BMC_BaseElement"

import:
	./cmdb-submit < sample-tiny.cmdbf.xml

real:
	./cmdb-submit < sample.cmdbf.xml

server:
	./cmdb-server

client:
	./cmdb-register < sample-tiny.cmdbf.xml
