-- Rotina para Monitoramento dos Processos da Máquina - Equipe DBA - OWS
--
SET LINESIZE 1000 ;
SET VERIFY OFF ;
SET FEEDBACK OFF ;
SET PAGES 0 ;
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

select (value*90/100) from sys.V_$PARAMETER where name =  'processes'
.
spool /tmp/monit_processes.log
/
spool off          
exit 

