### 
REMEDY_HOME=/afs/ir/users/t/s/tskirvin/work/remedy/libremedy-perl
REMEDY_CMDB_HOME=/afs/ir/users/t/s/tskirvin/work/remedy/libremedy-cmdb-perl

SUBMIT=cmdb-submit
DEREG_SUBMIT=cmdb-submit-deregister
REGISTER=cmdb-register

DEBUG=--debug --debug --debug --debug --debug

XML_DEREG=${REMEDY_CMDB_HOME}/sample/sample-dereg.cmdbf.xml
XML_SUNIA=/afs/ir/service/cmdb/data/in/short.xml
# XML_SUNIA=/afs/ir/group/networking/www/monitor/test/cmdb/cmdb.xml
XML_WINDOWS=${REMEDY_CMDB_HOME}/sample/w.xml
XML_TEST=${REMEDY_CMDB_HOME}/sample/local-1.xml
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

deregister:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/${DEREG_SUBMIT} < ${XML_DEREG}

deregister-debug:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/${DEREG_SUBMIT} ${DEBUG} < ${XML_DEREG}

deregister-reg:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/${REGISTER} ${DEBUG} < ${XML_DEREG}

real:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/${SUBMIT} < ${XML}

real-debug:
	PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/${SUBMIT} ${DEBUG} < ${XML}

server:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-server

client:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-register < ${XML}

query:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/cmdb-query < ${XML}

sunia:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/${SUBMIT} < ${XML_SUNIA}

windows:
	@PERLLIB=${PERLLIB} ${REMEDY_CMDB_HOME}/bin/${SUBMIT} < ${XML_WINDOWS}

system-register:
	PERLLIB=$(PERLLIB) ${REMEDY_CMDB_HOME}/bin/cmdb-remctl cmdb-sandbox.stanford.edu < ${XML}

test:
	PERLLIB=$(PERLLIB) ${REMEDY_CMDB_HOME}/bin/${SUBMIT} < ${XML_TEST}

test-debug:
	PERLLIB=$(PERLLIB) ${REMEDY_CMDB_HOME}/bin/${SUBMIT} ${DEBUG} < ${XML_TEST}
