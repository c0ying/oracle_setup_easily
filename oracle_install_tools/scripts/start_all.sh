#!/bin/sh

ORACLE_HOME=/opt/app/oracle/product/11.2.0/db_1
ORACLE_SID=ORCL
ORACLE_BASE=/opt/app/oracle
ORACLE_HOME_LISTNER=$ORACLE_HOME

$ORACLE_HOME/bin/lsnrctl start;
$ORACLE_HOME/bin/dbstart $ORACLE_HOME;
