### 
REMEDY_HOME=/afs/ir/users/t/s/tskirvin/work/remedy/libremedy-perl
REMEDY_CMDB_HOME=/afs/ir/users/t/s/tskirvin/work/remedy/libremedy-cmdb-perl

XML_SUNIA=/afs/ir/group/networking/www/monitor/test/cmdb/cmdb.xml
XML_WINDOWS=${REMEDY_CMDB_HOME}/sample/w.xml
XML=${REMEDY_CMDB_HOME}/sample/sample-reg.cmdbf.xml
PERLLIB="${REMEDY_CMDB_HOME}/lib:${REMEDY_HOME}/lib"

clean: 
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-clear \
		MDR.IMPORT.UNIX "restarting at `date`"

clean-loud: 
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-clear \
		--debug --debug --debug --debug --debug MDR.IMPORT.UNIX \
		"restarting at `date`"

current:
	@PERLLIB=${PERLLIB} ${REMEDY_HOME}/bin/remedy-dump \
		"BMC.CORE:BMC_BaseElement"

real:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-submit < ${XML}

server:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-server

client:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-register < ${XML}

query:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-query < ${XML}

sunia:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-submit < ${XML_SUNIA}

windows:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-submit < ${XML_WINDOWS}
