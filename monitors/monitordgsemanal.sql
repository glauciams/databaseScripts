-- Monitor Storage Weekly - Equipe DBA 
-- Created by Glaucia Melo - glauciamelo@gmail.com
-- Date: 18/03/2010 
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

				  
				  
spool /tmp/monitorstoragesemanal.txt
select name|| ' ; DataFilesMB; '|| sum(df.bytes)/1024/1024 || ' ;'
from dba_data_files df, v$database
group by name
union
select name|| ' ; TempFilesMB; '|| sum(tf.bytes)/1024/1024  || ' ;'
from dba_temp_files tf, v$database
group by name;
spool off
exit
