#!/bin/bash
#************************************************************************************
# File: rotina_analyze.sh
# Purpose: Executa a atualizacao das estatisticas dos indices de determinado usuario
#************************************************************************************
# Declaracao variaveis ambiente
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_2
PATH=$PATH:$ORACLE_HOME/bin
NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1
SQLDIR=$ORACLE_BASE/admin/scripts/sql
PWDDIR=$ORACLE_BASE/admin/scripts
LOGDIR=$ORACLE_BASE/admin/scripts/log
TMPDIR=/tmp

export ORACLE_BASE ORACLE_HOME PATH NLS_LANG SQLDIR TMPDIR PWDDIR LOGDIR

# Declaracao variaveis do script
Vserv=$1
Vuser=$2
Vdata=`date +"%d/%m/%y - %H:%M"`

# Inicio script

echo "INICIO ROTINA ANALYZE NO $Vserv - $Vdata" >> $LOGDIR/rotina_analyze.log

if [ "$Vserv" = "" ] || [ "$Vuser" = "" ]
 then
    echo "UTILIZACAO ERRADA DO SCRIPT - $Vdata" >> $LOGDIR/rotina_analyze.log
    echo "UTILIZACAO ERRADA DO SCRIPT"
    echo "Sintaxe: rotina_analyze.sh <SERVIDOR> <USUARIO>"
    exit
fi

if [ "$2" = "SYS" ] || [ "$2" = "SYSTEM" ] || [ "$2" = "sys" ] || [ "$2" = "system" ]
 then
    echo "ESTE USUARIO NAO PODE SER USADO PARA GERAR ESTATISTICAS !!! - $Vdata" >> $LOGDIR/rotina_analyze.log
    echo "ESTE USUARIO NAO PODE SER USADO PARA GERAR ESTATISTICAS !!!"
    exit
fi

for i in `cat $PWDDIR/.users | cut -f 1 -d :`
 do
  if [ "$Vuser" = "$i" ]
   then
     Vpwd=`cat $PWDDIR/.users | grep -i $i | cut -f 2 -d :`
  fi
done

if [ "$Vpwd" = "" ]
 then
    echo "USUARIO NAO CADASTRADO PARA GERAR ESTATISTICA - $Vdata" >> $LOGDIR/rotina_analyze.log
    echo "USUARIO NAO CADASTRADO PARA GERAR ESTATISTICA !!!"
    exit
fi

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @$SQLDIR/gera_analyze.sql
$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @$TMPDIR/compute_stat.sql

#/bin/rm /tmp/compute_stat.sql 2>&1 >/dev/null

echo "TERMINO ROTINA ANALYZE NO $Vserv - $Vdata" >> $LOGDIR/rotina_analyze.log
