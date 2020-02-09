-- Finalidade: Rotina Informações de Monitoramento de Locks
-- 16/09/2008 - Equipe DBA - OWS
--
SET LINESIZE 1000 ;
SET VERIFY OFF ;
SET FEEDBACK OFF ;
SET PAGESIZE 999 ;
SET SERVEROUTPUT OFF;
SET HEADING OFF;
--
ALTER SESSION SET NLS_LANGUAGE= 'AMERICAN' NLS_TERRITORY= 'AMERICA'
                  NLS_CURRENCY= '$' NLS_ISO_CURRENCY= 'AMERICA'
                  NLS_NUMERIC_CHARACTERS= '.,'
                  NLS_CALENDAR= 'GREGORIAN'
                  NLS_DATE_FORMAT= 'DD-MM-YYYY'
                  NLS_DATE_LANGUAGE= 'AMERICAN'
                  NLS_SORT= 'BINARY';

SELECT DISTINCT (decode(PROCS,0,NULL,'TEM LOCK'))
FROM (
select count(1) PROCS
    from
    gv$process p,
    gv$session s,
(SELECT
hold.inst_id hold_inst_id,
hold.sid hold_sid,hold.serial# hold_Serial#,
wait.inst_id wait_inst_id ,wait.sid wait_sid,wait.serial# wait_serial#
,(ctime) ctime
 FROM
 gv$session_wait sw,
 gv$session wait,
 GV$LOCK l,
 gv$session hold
 WHERE
 sw.event like  'enq%'
 and wait.sid = sw.sid
 and wait.inst_id = sw.inst_id
 and l.id1 = sw.p2
 and l.id2 = sw.p3
 and l.block <> 0
 and hold.sid = l.sid
-- and hold.USERNAME <> 'GESPLAN'
 and l.ctime > 2
 and hold.inst_id = l.inst_id) lockdetail
where
   s.inst_id = p.inst_id and
   p.addr = s.paddr and
   s.sid  = lockdetail.wait_sid   and
   s.inst_id = lockdetail.wait_inst_id
)
.
spool /tmp/monit_locks.log 
/
spool off

spool /tmp/locks.sql
--
select 
' ==> LOCKADOR = '        || substr(chr(39)||lockdetail.hold_inst_id ||'-'||lockdetail.hold_sid||','||lockdetail.hold_serial#||chr(39),1,20) || chr(10)||
' ==> LOCKADO = '         || substr(chr(39)||lockdetail.wait_inst_id ||'-'||lockdetail.wait_sid||','||lockdetail.wait_serial#||chr(39),1,20) || chr(10)||
' ==> OSUSER = '          || substr(osuser,1,10) || chr(10)||
' ==> ORAUSER = '         || substr(s.username,1,10) || chr(10)||
' ==> SO_PROCESS = '      || spid || chr(10)||
' ==> ORA_PID = '         || process || chr(10)||
' ==> IDLE = '            || substr(floor(last_call_et/3600)||':'||floor(mod(last_call_et,3600)/60)||':'||mod(mod(last_call_et,3600),60),1,15) || chr(10)||
' ==> MINLOCK = '         || trunc(ctime/60) || chr(10)||
' ==> MODULE - ACTION = ' || s.module  || ' - ' || s.action
as INFO_LOCK 
    from
    gv$process p,
    gv$session s,
(SELECT
hold.inst_id hold_inst_id,
hold.sid hold_sid,hold.serial# hold_Serial#,
wait.inst_id wait_inst_id ,wait.sid wait_sid,wait.serial# wait_serial#
,(ctime) ctime
 FROM
 gv$session_wait sw,
 gv$session wait,
 GV$LOCK l,
 gv$session hold
 WHERE
 sw.event like  'enq%'
 and wait.sid = sw.sid
 and wait.inst_id = sw.inst_id
 and l.id1 = sw.p2
 and l.id2 = sw.p3
 and l.block <> 0
 and hold.sid = l.sid
 and l.ctime > 2
 and hold.inst_id = l.inst_id) lockdetail
where
   s.inst_id = p.inst_id and
   p.addr = s.paddr and
   s.sid  = lockdetail.wait_sid   and
   s.inst_id = lockdetail.wait_inst_id;

--
spool off
exit
