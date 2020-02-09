create user operador identified by op3r4d0r
default tablespace users
quota unlimited on users;

grant connect, resource, create session to operador;
grant select ANY DICTIONARY to OPERADOR;



 -- Create capacity planning statistics collect table
  CREATE TABLE OPERADOR.CAPACITY_PLANNING_COLLECT 
   (	V_DATABASE VARCHAR2(50), 
	V_INSTANCE VARCHAR2(50), 
	V_DATA DATE, 
	V_CPU_ORA_CONSUMED VARCHAR2(50), 
	V_CPU_OS VARCHAR2(50), 
	V_VERSION VARCHAR2(255), 
	V_SESSION VARCHAR2(50), 
	V_ACTIVE_SESSION VARCHAR2(50), 
	V_PROCESS VARCHAR2(50), 
	V_ACTIVE_SQL VARCHAR2(50), 
	V_DB_SIZE VARCHAR2(50) ) ;
  
  -- Create capacity planning statistics collect Procedure
  create or replace PROCEDURE OPERADOR.CAPACITY_PLANNING_COLECT  IS
V_DATABASE varchar2(50);
V_INSTANCE varchar2(50);
V_DATA date;
V_CPU_ORA_CONSUMED  varchar2(50);
V_CPU_OS  varchar2(50);
V_VERSION  varchar2(255);
V_SESSION  varchar2(50);
V_ACTIVE_SESSION varchar2(50);
v_process varchar2(50);
V_ACTIVE_SQL varchar2(50);
v_db_size varchar2(50);

begin

select name into V_DATABASE from V$DATABASE; 
select INSTANCE_NAME into V_INSTANCE from V$INSTANCE;
select sysdate into V_DATA from DUAL;
select ROUND(value/100,3) into V_CPU_ORA_CONSUMED from V$SYSMETRIC where METRIC_NAME='CPU Usage Per Sec' and GROUP_ID =2;
SELECT ROUND((prcnt.busy*parameter.cpu_count)/100,3) INTO V_CPU_OS FROM
  (SELECT value busy
  FROM v$sysmetric
  WHERE metric_name='Host CPU Utilization (%)'
  AND group_id     =2
  ) prcnt,
  ( select value CPU_COUNT from V$PARAMETER where name='cpu_count'
  ) PARAMETER;  
  
SELECT BANNER INTO V_VERSION
from V$VERSION
where UPPER (BANNER) like 'ORACLE%';

select TO_CHAR ( COUNT(*) ) INTO V_SESSION from V$SESSION;

SELECT TO_CHAR (COUNT(*) ) INTO V_ACTIVE_SESSION FROM V$SESSION WHERE STATUS = 'ACTIVE';

select TO_CHAR (COUNT(*) ) into v_process from V$PROCESS;

SELECT TO_CHAR( COUNT( DISTINCT (SID)) ) into v_active_sql
FROM v$session s,
  v$sqltext t
WHERE s.sql_address  = t.address
AND s.sql_hash_value = t.hash_value
AND S.STATUS         = 'ACTIVE'
and S.USERNAME      is not null;

select TO_CHAR(SUM(DF.BYTES)/1024/1024 || ' Mb' ) into V_DB_SIZE from DBA_DATA_FILES DF;

dbms_output.put_line ('db size:' || V_DB_SIZE);


insert into OPERADOR.CAPACITY_PLANNING_COLLECT values (
V_DATABASE ,V_INSTANCE ,V_DATA, V_CPU_ORA_CONSUMED , V_CPU_OS,V_VERSION,V_SESSION ,V_ACTIVE_SESSION,v_process,V_ACTIVE_sql ,v_db_size );

commit;
end CAPACITY_PLANNING_COLECT;


-- Create job (Criar no SYS)
DECLARE 
  X NUMBER; 
BEGIN 
  SYS.DBMS_JOB.SUBMIT 
  ( job       => X  
   ,what      => 'BEGIN 
  OPERADOR.CAPACITY_PLANNING_COLECT; 
  COMMIT; 
END;' 
   ,NEXT_DATE => sysdate
   ,interval  => 'sysdate+1' 
   ,no_parse  => FALSE 
  ); 

COMMIT; 
end; 
