#!/bin/sh

#oracle profile check
export ORACLE_HOME=$ORACLE_BASE/product/19c/db
export ORACLE_SID=pico
export GRID_HOME=/grid/app/19c/grid
export PATH=$ORACLE_HOME/bin:$ORACLE_HOME/bin:/oracle/app/19c/grid/bin:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/usr/sbin
export DATE=`date +%Y%m%d%H%M`
export NLS_DATE_FORMAT='yyyy-mm-dd HH24:MI:SS'

#oracle backup comment
echo "Rman Backup SID=$ORACLE_SID Start Time : `date` -- ###Start### " >> /home/oracle/rman_log/${ORACLE_SID}_${DATE}_arch.log

#rman backup start
rman target / << EOF >> /home/oracle/rman_log/${ORACLE_SID}_${DATE}_arch.log

run {
CONFIGURE CONTROLFILE AUTOBACKUP ON;

ALLOCATE CHANNEL ch2 DEVICE TYPE SBT_TAPE PARMS 'SBT_LIBRARY=/opt/veeam/VeeamPluginforOracleRMAN/libOracleRMANPlugin.so' FORMAT '88788f9e-d8f5-4eb4-bc4f-9b3f5403bcec/s1wmsdb_RMAN_%I_%d_%T_%U.vab';
CROSSCHECK ARCHIVELOG ALL;

sql 'alter system archive log current';
backup 
filesperset = 32
(archivelog  all   delete input );

RELEASE CHANNEL ch2;
}EXIT;
EOF

echo "Rman Backup SID=$ORACLE_SID End Time : `date` -- ###End### " >> /home/oracle/rman_log/${ORACLE_SID}_${DATE}_arch.log
