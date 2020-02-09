-- Rotina para Monitoramento dos Objetos Inválidos - Equipe DBA - OWS
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


SELECT  COUNT(*)
FROM    DBA_OBJECTS 
WHERE   STATUS = 'INVALID' 
ORDER BY OWNER, OBJECT_TYPE, OBJECT_NAME
.
spool /tmp/invalid_object.alert
/
spool off          
exit 

