#!/bin/sh

export ORACLE_BASE=/oracle/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0
export ORACLE_SID=ORCL1
export GRID_HOME=/grid/app/grid_home
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch:/usr/bin:/usr/sbin:/bin:/sbin:/usr/X11R6/bin
export DATE=`date +%Y%m%d%H%M`
export NLS_DATE_FORMAT='yyyy-mm-dd HH24:MI:SS'

echo "Rman Backup SID=$ORACLE_SID Start Time : `date` -- ###Start### " >> /home/oracle/rman_log/${ORACLE_SID}_${DATE}_full.log 

rman target / << EOF >> /home/oracle/rman_log/${ORACLE_SID}_${DATE}_full.log

run {

ALLOCATE CHANNEL ch1 DEVICE TYPE SBT_TAPE PARMS 'SBT_LIBRARY=/opt/veeam/VeeamPluginforOracleRMAN/libOracleRMANPlugin.so' FORMAT 'fd51da7c-ba2f-4c38-91ee-31d0fe3d23f3/orcl1_RMAN_%I_%d_%T_%U.vab';
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;

backup
incremental level = 0
database
include current controlfile;
sql 'alter system archive log current';
backup archivelog all delete all input;
CROSSCHECK BACKUP;
CROSSCHECK ARCHIVELOG ALL;
RELEASE CHANNEL ch1;
}EXIT;
EOF

echo "Rman Backup SID=$ORACLE_SID End Time : `date` -- ###End### " >> /home/oracle/rman_log/${ORACLE_SID}_${DATE}_full.log
