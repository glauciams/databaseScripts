-- Rotina para Monitoramento dos DGs - Equipe DBA - OWS
--
SET LINESIZE 1000 ;
SET VERIFY OFF ;
SET FEEDBACK OFF ;
SET SERVEROUTPUT OFF;
SET HEADING OFF;
set pages 1000  
col grpnumber format 999999 
col status format a15
col name format a20
col total_mb format 9999999999
col livre format 9999999999
col Pct_used format 999.0 head "%Usado" 
set linesize 500
--
ALTER SESSION SET NLS_LANGUAGE= 'AMERICAN' NLS_TERRITORY= 'AMERICA'
                  NLS_CURRENCY= '$' NLS_ISO_CURRENCY= 'AMERICA'
                  NLS_NUMERIC_CHARACTERS= '.,'
                  NLS_CALENDAR= 'GREGORIAN'
                  NLS_DATE_FORMAT= 'DD-MM-YYYY'
                  NLS_DATE_LANGUAGE= 'AMERICAN'
                  NLS_SORT= 'BINARY';

select decode(DG,0,NULL,'DG ESTOURANDO')
from 
(
select count(*) DG --group_number grpnumber, name NOME_DG, substr(state,1,15) status, type TIPO, total_mb,
--free_mb livre, ((total_mb - nvl(free_mb,0)) / total_mb) *100 Pct_used
from v$asm_diskgroup
where trunc((total_mb - nvl(free_mb,0)) / total_mb *100) > 95
)
.
spool /tmp/verifica_dg.log
/
spool off


spool /tmp/monitora_dg.txt

select name || ' ESTOURANDO COM '|| SUBSTR(((total_mb - nvl(free_mb,0)) / total_mb) *100,1,5) ||'% DE USO!' INFO_DGS
--group_number grpnumber, 
--name NOME_DG, 
--substr(state,1,15) status, 
--type TIPO, 
--total_mb,
--free_mb livre, 
--((total_mb - nvl(free_mb,0)) / total_mb) *100 Pct_used
from v$asm_diskgroup
where trunc((total_mb - nvl(free_mb,0)) / total_mb *100) > 90;



spool off
exit



 
