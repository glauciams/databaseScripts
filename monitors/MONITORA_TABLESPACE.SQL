-- Rotina para Monitoramento de Tablespaces - Equipe DBA - OWS
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

select decode(TBS,0,NULL,'TEM TBS ESTOURANDO')
from 
(
select count(*) TBS
from 
   ( select SUM(bytes) tbs_size, 
            SUM(decode(sign(maxbytes - bytes), -1, bytes, maxbytes)) 
tbs_maxsize, 
            tablespace_name tablespace 
     from ( select nvl(bytes, 0) bytes, nvl(maxbytes, 0) maxbytes, 
tablespace_name 
            from dba_data_files 
            union all 
            select nvl(bytes, 0) bytes, nvl(maxbytes, 0) maxbytes, 
tablespace_name 
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
where t.tablespace_name = d.tablespace(+) and 
       t.tablespace_name = s.tablespace(+) 
       and substr(t.contents, 1, 1) = 'P'
       AND (trunc((d.tbs_size-nvl(s.free_space, 0))/1024/1024) + 50) > trunc(d.tbs_maxsize/1024/1024)
	and trunc((d.tbs_size-nvl(s.free_space, 0))*100/d.tbs_maxsize) > 90
)
.
spool /tmp/verifica_tbs.log
/
spool off

spool /tmp/monitora_tbs.txt
select 
'TABLESPACE '||t.tablespace_name  || ' ESTOURANDO COM '
|| decode(d.tbs_maxsize, 0, 0, trunc((d.tbs_size-nvl(s.free_space, 0))*100/d.tbs_maxsize))||'% DE USO!' 
       -- trunc((d.tbs_size-nvl(s.free_space, 0))/1024/1024) ktbs_em_uso, 
       -- trunc(d.tbs_size/1024/1024) ktbs_size, 
       -- trunc(d.tbs_maxsize/1024/1024) ktbs_maxsize, 
       -- trunc(nvl(s.free_space, 0)/1024/1024) kfree_space, 
       -- trunc((d.tbs_maxsize - d.tbs_size + nvl(s.free_space, 0))/1024/1024) kspace, 
       -- decode(d.tbs_maxsize, 0, 0, trunc((d.tbs_size-nvl(s.free_space, 0))*100/d.tbs_maxsize)) kperc 
from 
   ( select SUM(bytes) tbs_size, 
            SUM(decode(sign(maxbytes - bytes), -1, bytes, maxbytes)) 
tbs_maxsize, 
            tablespace_name tablespace 
     from ( select nvl(bytes, 0) bytes, nvl(maxbytes, 0) maxbytes, 
tablespace_name 
            from dba_data_files 
            union all 
            select nvl(bytes, 0) bytes, nvl(maxbytes, 0) maxbytes, 
tablespace_name 
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
where t.tablespace_name = d.tablespace(+) and 
       t.tablespace_name = s.tablespace(+) 
       and substr(t.contents, 1, 1) = 'P'
       AND (trunc((d.tbs_size-nvl(s.free_space, 0))/1024/1024) + 50) > trunc(d.tbs_maxsize/1024/1024)
       and trunc((d.tbs_size-nvl(s.free_space, 0))*100/d.tbs_maxsize) > 90; 
spool off
exit
