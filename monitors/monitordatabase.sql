-- Monitor Database script - Equipe DBA 
-- Created by Glaucia Melo - glauciamelo@gmail.com
-- Date: 30/10/2009 
--
SET LINESIZE 1000 ;
SET VERIFY OFF ;
SET FEEDBACK OFF ;
SET HEADING OFF;
SET PAGES 1000  ;
SET SERVEROUTPUT OFF;

--
ALTER SESSION SET NLS_LANGUAGE= 'AMERICAN' NLS_TERRITORY= 'AMERICA'
                  NLS_CURRENCY= '$' NLS_ISO_CURRENCY= 'AMERICA'
                  NLS_NUMERIC_CHARACTERS= '.,'
                  NLS_CALENDAR= 'GREGORIAN'
                  NLS_DATE_FORMAT= 'DD-MM-YYYY'
                  NLS_DATE_LANGUAGE= 'AMERICAN'
                  NLS_SORT= 'BINARY';

				  
				  
---------
-- Database Start
spool /tmp/databasestart.txt
SELECT NAME|| ' -> Database Started on ' || TO_CHAR(STARTUP_TIME,'DD-MM-YYYY "at" HH24:MI')
FROM V$INSTANCE, v$database;
spool off

-- Database usage in MB
spool /tmp/databaseuse.txt
select name|| ' -> DataFiles: '|| sum(df.bytes)/1024/1024 || ' Mb'
from dba_data_files df, v$database
group by name
union
select name|| ' -> TempFiles: '|| sum(tf.bytes)/1024/1024  || ' Mb'
from dba_temp_files tf, v$database
group by name;
spool off

-- SGA SIZE 

spool /tmp/databasesga.txt
COLUMN SIZE FORMAT 999999999999 HEADING "SIZE" JUSTIFY RIGHT
select	decode(name,	'Database Buffers',
		'Database Buffers (DB_BLOCK_SIZE*DB_BLOCK_BUFFERS)',
		'Redo Buffers',
		'Redo Buffers     (LOG_BUFFER)', name) "Memory",
		to_char(value)		"Size"
	from sys.v_$sga
UNION ALL
	select	'------------------------------------------------------'	"Memory",
		to_char(to_number(null))		"Size"
  	from	dual
UNION ALL
	select	'Total Memory' "Memory",
		sum(value/1024/1024)||' MB'	"Size"
  	from	sys.v_$sga;
spool off

-- Tablespace Usage Summary
SET HEADING ON
spool /tmp/databasetbs.txt
select TABLESPACE_NAME, STATUS, TBS_MAXSIZE/1024/1024 "TBS_MAXSIZE MB" , FREE_SPACE/1024/1024 "FREE_SPACE MB"
from 
   ( select SUM(bytes) tbs_size, 
            SUM(decode(sign(maxbytes - bytes), -1, bytes, maxbytes)) 
            tbs_maxsize, tablespace_name tablespace 
     from 
     ( 
     select nvl(bytes, 0) bytes, nvl(maxbytes, 0) maxbytes, tablespace_name 
      from dba_data_files 
     union all 
     select nvl(bytes, 0) bytes, nvl(maxbytes, 0) maxbytes, tablespace_name 
      from dba_temp_files 
     ) 
     group by tablespace_name 
   ) d, 
   ( select SUM(bytes) free_space, 
            tablespace_name tablespace 
     from dba_free_space 
     group by tablespace_name 
   ) s, 
   dba_tablespaces t 
where t.tablespace_name = d.tablespace(+) 
  and t.tablespace_name = s.tablespace(+) 
  and substr(t.contents, 1, 1) = 'P'
  order by t.tablespace_name;	
spool off  

-- Invalid Objects Summary
spool /tmp/databaseinvalid.txt
select owner, object_type, substr(object_name,1,30) object_name, status
from dba_objects
where status='INVALID'
order by owner,object_type;
spool off

-- Block Contention
spool /tmp/databaseblockcontention.txt
SELECT class,SUM(COUNT) total_waits, SUM(TIME) total_time 
FROM v$waitstat 
GROUP BY class;
spool off

-- Novos objetos criados nas últimas 24 horas. (ou no caso de mensal, rodar dos últimos 30 dias)
spool /tmp/databasecreatedobj.txt
SELECT SUBSTR(OWNER,1,15)OWNED_BY,
       SUBSTR(OBJECT_TYPE,1,15) OBJ_TYPE,
       SUBSTR(OBJECT_NAME,1,25) NEW_OBJECT,
       SUBSTR(TO_CHAR(CREATED, 'DD/MM/YYYY'),1,11) CREATED_ON
 FROM DBA_OBJECTS
WHERE CREATED > SYSDATE -1
  AND OWNER NOT IN ('SYS','SYSTEM')
ORDER BY 1,2,3 ;
spool off

-- Job status
spool /tmp/databasejobstatus.txt
COLUMN BROKEN FORMAT A8 HEADING "BROKEN" JUSTIFY LEFT
SELECT JOB, SUBSTR(LOG_USER,1,10) AS LOG_USER, SUBSTR(PRIV_USER,1,10) AS PRIV_USER, SUBSTR(SCHEMA_USER,1,10) AS SCHEMA_USER, LAST_DATE, LAST_SEC, BROKEN AS "BROKEN"
FROM DBA_JOBS;
spool off

-- Status das Constraints
spool /tmp/databaseconstraintstatus.txt
SELECT OWNER, 
DECODE(CONSTRAINT_TYPE  , 'C','CHECK - TABLE'
                        , 'O','READ ONLY - VIEW'
                        , 'P','PRIMARY KEY'
                        , 'R','REFERENCIAL - FK'
                        , 'U','UNIQUE KEY'
                        , 'V','CHECK - VIEW'
                        ,CONSTRAINT_TYPE) AS "CONSTRAINT_TYPE", 
STATUS, COUNT(*) TOTAL
FROM DBA_CONSTRAINTS
WHERE OWNER NOT IN ('SYS', 'SYSTEM')
AND STATUS <> 'ENABLED'
GROUP BY OWNER, CONSTRAINT_TYPE, STATUS
ORDER BY OWNER, CONSTRAINT_TYPE, STATUS;
spool off


-- Usuários definidos no perfil DEFAULT
spool /tmp/databasedefaultprofile.txt
SELECT USERNAME, CREATED, PROFILE
FROM DBA_USERS
WHERE PROFILE = 'DEFAULT';
spool off

-- Usuários definidos na tablespace SYSTEM
spool /tmp/databasetbssystem.txt
SELECT USERNAME, DEFAULT_TABLESPACE DEFAULT_TS, TEMPORARY_TABLESPACE TEMP_TS
FROM DBA_USERS
WHERE USERNAME NOT IN ('SYS', 'SYSTEM')
 AND (DEFAULT_TABLESPACE='SYSTEM' OR TEMPORARY_TABLESPACE='SYSTEM')
ORDER BY USERNAME;
spool off



-- Atividade de I/O nas Tablespaces onde leitura ou escrita > 5000
spool /tmp/databasetbsio.txt
SELECT TABLESPACE_NAME, 
 SUM(PHYBLKRD) PHYSREADS, 
 SUM(PHYBLKWRT)PHYSWRITES, 
 SUM(READTIM) READTIME, 
 SUM(WRITETIM) WRITETIME, 
 SUM(READTIM) + SUM(WRITETIM) TOTALTIME
FROM DBA_DATA_FILES DDF, V$FILESTAT VFS
WHERE DDF.FILE_ID = VFS.FILE#
GROUP BY TABLESPACE_NAME
HAVING SUM(PHYBLKWRT) + SUM(PHYBLKRD) > 5000
ORDER BY TOTALTIME DESC;
spool off
---------
-- MEMORY INFO
-- Taxa de acerto em Buffer Pool
spool /tmp/databasebufferpool.txt
COLUMN RATIO FORMAT 99999 HEADING "RATIO" JUSTIFY RIGHT
SELECT NAME, (1 - (PHYSICAL_READS/(CONSISTENT_GETS+DB_BLOCK_GETS)))*100 RATIO
FROM V$BUFFER_POOL_STATISTICS
ORDER BY NAME;
spool off

-- Informações de ajuste de log_buffer e Redo Log
spool /tmp/databaselogbuffer.txt
COLUMN NAME FORMAT A40 HEADING "Statistic" JUSTIFY LEFT
COLUMN VALUE FORMAT 999999999999 HEADING "Value" JUSTIFY RIGHT
SELECT NAME, VALUE
FROM V$SYSSTAT
WHERE NAME LIKE 'redo%';
spool off

-- Execucao de Objetos na Shared Pool (Execs > 100)
spool /tmp/databaseshared.txt
COLUMN EXECUTIONS FORMAT 999999999 HEADING "EXECUTIONS" JUSTIFY RIGHT
SELECT OWNER, NAME, TYPE, EXECUTIONS
FROM V$DB_OBJECT_CACHE
WHERE EXECUTIONS > 100
AND TYPE IN ('PACKAGE', 'PACKAGE BODY', 'FUNCTION', 'PROCEDURE')
ORDER BY 4 DESC;
spool off

-- Número de objetos que falharam ao obter espaço na Shared Pool
spool /tmp/databasesharedspace.txt
COLUMN REQUEST_FAILURES FORMAT 999999999 HEADING "REQUEST_FAILURES" JUSTIFY RIGHT
SELECT REQUEST_FAILURES
FROM V$SHARED_POOL_RESERVED
WHERE REQUEST_FAILURES > 0;
spool off

-- Estatísticas de Latch
spool /tmp/databaselatch.txt
SELECT NAME, GETS, MISSES, IMMEDIATE_GETS, IMMEDIATE_MISSES, SLEEPS
FROM V$LATCH
WHERE GETS > 0;
spool off
exit



 
