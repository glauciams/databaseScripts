#!/bin/bash
#************************************************************************************
# File: rotina_monitoramento.sh
# Purpose: Monitora base de dados e processos
# Author: Equipe LLOGIC    Data: 03/11/2012  Versao: 1.0
# Contact: glaucia@dldba.com.br / alexandre.mduarte@dldba.com.br
#************************************************************************************
# Declaracao variaveis ambiente
ORACLE_BASE=/u01/app/oracle
ORACLE_HOME=$ORACLE_BASE/product/11.2/db_1
PATH=$PATH:$ORACLE_HOME/bin
NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1
SQLDIR=/home/oracle/dba_llogic
PWDDIR=/home/oracle/dba_llogic
LOGDIR=/home/oracle/dba_llogic/log
TMPDIR=/tmp
ORACLE_SID=GXVSIM
HOST_NAME=`uname -n`
REMETENT=gvxsim@simtv.com.br
DESTINAT= glaucia@dldba.com.br
SERVEMAIL=10.1.200.10

export ORACLE_BASE ORACLE_HOME PATH NLS_LANG SQLDIR TMPDIR PWDDIR LOGDIR ORACLE_SID HOST_NAME DESTINAT REMETENT SERVEMAIL

# Variaveis do script
Vserv=GXVSIM
Vproc=$1
Vuser=$2
Vdata=`date +"%d_%m_%y"`
Vdatamon=`date +"%m"`
Vdatalock=`date +"%d/%m/%y - %H:%M"`

func_monitor_lock()
{
echo "INICIO ROTINA MONITORAMENTO LOCK - $Vdata" >> $LOGDIR/rotina_monitoramento.log

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @/home/oracle/dba_llogic/MONITORA_LOCKS.SQL

if [ -e /tmp/monit_locks.log ] 
 then 
    ct_proc2=`grep "TEM LOCK" /tmp/monit_locks.log | wc -l`
    if [ $ct_proc2 -gt 0 ]
     then
      $PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "ATENCAO LOCK" -o message-file=/tmp/locks.sql -s $SERVEMAIL
    else
      echo $ORACLE_SID " - NAO TEM LOCK"
      rm -rf /tmp/monit_locks.log
    fi
fi

echo "TERMINO ROTINA MONITORAMENTO LOCK - $Vdata" >> $LOGDIR/rotina_monitoramento.log
} 


func_monitor_tablespace()
{
echo "INICIO ROTINA MONITORAMENTO TABLESPACE - $Vdata" >> $LOGDIR/rotina_monitoramento.log
$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @/home/oracle/dba_llogic/MONITORA_TABLESPACE.SQL
if [ -e /tmp/verifica_tbs.log ]
 then 
    ct_proc=`grep "TEM TBS ESTOURANDO" /tmp/verifica_tbs.log | wc -l` 
    if [ $ct_proc -gt 0 ]
     then
	   $PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "ATENCAO TABLESPACE" -o message-file=/tmp/monitora_tbs.txt -s $SERVEMAIL
    else
    echo $ORACLE_SID " - NAO TEM TABLESPACE ESTOURANDO"
    fi
fi
}

func_monitor_listener ()
{
echo "INICIO ROTINA MONITORAMENTO LISTENER - $Vdata" >> $LOGDIR/rotina_monitoramento.log

  ct_proc3=`ps -ef | grep lsn | grep -v grep | wc -l`
  if [ $ct_proc3 -gt 0 ]
  then
    echo "LISTENER IS UP"
  else
    $PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "Alert! Listener is down on server." -m "Alert! Listener is down on server."  -s $SERVEMAIL
  fi
echo "FIM ROTINA MONITORAMENTO LISTENER - $Vdata" >> $LOGDIR/rotina_monitoramento.log

}

func_monitor_servicos()
{
 echo "INICIO ROTINA MONITORAMENTO SERVICOS - $Vdata" >> $LOGDIR/rotina_monitoramento.log
 $ORACLE_BASE/admin/scripts/crsstat | awk ' {print $2 }'  > /tmp/verificaservicos.log
   ct_proc5=`grep "OFFLINE" /tmp/verificaservicos.log | wc -l`
   if [ $ct_proc5 -gt 0 ]
     then
      $PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "ATENCAO SERVICO FORA" -m "VERIFICAR crsstat"  -s $SERVEMAIL
    else
      echo "NAO TEM SERVICO FORA"
   fi
 echo "TERMINO ROTINA MONITORAMENTO SERVICOS - $Vdata" >> $LOGDIR/rotina_monitoramento.log
} 

#Verifica caso haja erro no alert log
func_monitor_erroslog()
{
 echo "INICIO ROTINA MONITORAMENTO ERROS LOG - $Vdata" >> $LOGDIR/rotina_monitoramento.log
 ct_proc6=`tail -10 $ORACLE_BASE/admin/$ORACLE_SID/bdump/alert_$ORACLE_SID.log| grep -i ORA-|wc -l`
   if [ $ct_proc6 -gt 0 ]
     then
       tail -10 $ORACLE_BASE/admin/$ORACLE_SID/bdump/alert_$ORACLE_SID.log > /tmp/alert.log
       $PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "ATENCAO ERRO NO ALERT" -o message-file=/tmp/alert.log -s $SERVEMAIL
    else
      echo "NAO TEM ERRO NO ALERT"
   fi
 echo "TERMINO ROTINA MONITORAMENTO ERROS LOG - $Vdata" >> $LOGDIR/rotina_monitoramento.log
} 

#Monitora Load da CPU
func_load_cpu ()
{
  echo "INICIO ROTINA LOAD ISSUE - $Vdata" >> $LOGDIR/rotina_monitoramento.log
 
  # Set up limit below
    NOTIFY="15.0"
    FTEXT='load average:'
  # 15 min
    F15M="$(uptime | awk -F "$FTEXT" '{ print $2 }' | cut -d, -f3)"
  # compare it with last 15 min load average
    RESULT=$(echo "$F15M > $NOTIFY" | bc)  
  # if load >= 6.0 create a file /tmp/file.txt

    if [ "$RESULT" == "1" ]; then
           echo 'LOAD ISSUE ON ' $Vserv - $F15M  > /tmp/load_issue.txt
            $PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "Load CPU Issues" -o message-file=/tmp/load_issue.txt  -s $SERVEMAIL
    else
      echo "LOAD IS OK"
    fi

  echo "FIM ROTINA LOAD ISSUE - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}

#Monitora erros no arquivo mail
func_monitor_mail()
{

echo "INICIO ROTINA VERIFICA ERROS NO MAIL - $Vdata" >> $LOGDIR/rotina_monitoramento.log

ARQMSG= /tmp/mon_erro_mail.txt
insterro=`grep -i "ORA-" /var/spool/mail/oracle`
insterro2=`grep -i "No such file or directory" /var/spool/mail/oracle`
Vdata1=`date +"%d_%m_%y"`

if [[ $insterro != "" ]] || [[ $insterro2 != "" ]]
then
        echo "Arquivo /var/spool/mail/oracle com erros!!" >> /tmp/mon_erro_mail.txt
	 echo "" >> /tmp/mon_erro_mail.txt
        cp -p /var/spool/mail/oracle /tmp/arquivo_mail$Vdata1.log
        grep -i "ORA-" /tmp/arquivo_mail$Vdata1.log >> /tmp/mon_erro_mail.txt
	 grep -i "No such file or directory" /tmp/arquivo_mail$Vdata1.log >> /tmp/mon_erro_mail.txt
	 echo "" >> /tmp/mon_erro_mail.txt
        echo "Mail de envio automatico - favor nao responder." >> /tmp/mon_erro_mail.txt
        tail -20 /tmp/mon_erro_mail.txt >> /tmp/mon_erro_mail2.txt

	 #Envia e-mail de notificacao
     $PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "ATENCAO - ERRO NO MAIL" -o message-file=/tmp/mon_erro_mail2.txt -s $SERVEMAIL  
	 rm /tmp/arquivo_mail$Vdata1.log
	 rm /tmp/mon_erro_mail2.txt
        > /tmp/mon_erro_mail.txt
fi

echo "FIM ROTINA VERIFICA ERROS NO MAIL - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}

func_erase_mail()
{
mail << EOF
del 1-1000
EOF
}

#############################################
# Monitora DG's
#############################################
func_monitor_dg()
{
echo "INICIO ROTINA MONITORAMENTO DG - $Vdata" >> $LOGDIR/rotina_monitoramento.log

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @/home/oracle/dba_llogic/MONITORA_DG.sql

if [ -e /tmp/verifica_dg.log ]
 then 
    ct_proc6=`grep "DG ESTOURANDO" /tmp/verifica_dg.log | wc -l` 
    if [ $ct_proc6 -gt 0 ]
     then
       $PWDDIR/sendEmail -f oracle@oracleprod01.loginlogistica.com.br -t equipe.dba@loginlogistica.com.br -cc daniel.augusto@alog.com.br -u "ATENCAO DG" -o message-file=/tmp/monitora_dg.txt -s 172.27.254.42:25
    else
    echo "LROPRD1 - NAO TEM DG ESTOURANDO"
    fi
fi

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@RAC_LROCRP @/home/oracle/dba_llogic/MONITORA_DG.sql

if [ -e /tmp/verifica_dg.log ]
 then 
    ct_proc6=`grep "DG ESTOURANDO" /tmp/verifica_dg.log | wc -l` 
    if [ $ct_proc6 -gt 0 ]
     then
       $PWDDIR/sendEmail -f oracle@oraprd1.loginlogistica.com.br -t equipe.dba@loginlogistica.com.br -cc daniel.augusto@alog.com.br -u "ATENCAO DG" -o message-file=/tmp/monitora_dg.txt -s 172.27.254.42:25
    else
    echo "LROCRP - NAO TEM DG ESTOURANDO"
    fi
fi

echo "TERMINO ROTINA MONITORAMENTO DG - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}


###############################################################
# Monitora objetos invalidos
# Instancias monitoradas: RAC_LROPRD, RAC_LROCRP, COSMOS, BPEL
##############################################################
func_objetos_invalidos ()
{
  echo "INICIO ROTINA VERIFICA OBJETOS INVALIDOS - $Vdata" >> $LOGDIR/rotina_monitoramento.log

   > /tmp/invalid_object.txt
   touch /tmp/invalid_object.txt
 
  echo " ==== INICIO VERIFICACAO OBJETOS INVALIDOS === " >>  /tmp/invalid_object.txt
  echo "  " >>  /tmp/invalid_object.txt

  $ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @/home/oracle/dba_llogic/MONITORA_INVALIDOS.SQL
  echo "GXVSIM" >>  /tmp/invalid_object.txt
  cat /tmp/invalid_object.alert >>  /tmp/invalid_object.txt

  echo " ====  FIM VERIFICACAO OBJETOS INVALIDOS ==== " >>  /tmp/invalid_object.txt
  echo " " >>  /tmp/invalid_object.txt
  
  $PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "INFORMATIVO OBJETOS INVALIDOS - PRODUCAO" -o message-file=/tmp/invalid_object.txt -s $SERVEMAIL  
   echo "TERMINO ROTINA VERIFICA OBJETOS INVALIDOS - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}


#Monitora instancias remotamente. 
##################################################################################################################
#  Mapa dos Monitores de Instancia:
# oracleprod01 -> RAC_LROCRP, COSMOS e BPEL
# oraprd1 -> RAC_LROPRD
# ora-homol2 -> CRP3
# oraprd2 -> LDODSV01, LDOHML01, LDOTST01
##################################################################################################################
func_monitor_instancia()
{
echo "INICIO ROTINA MONITORAMENTO INSTANCIA - $Vdata" >> $LOGDIR/rotina_monitoramento.log

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@RAC_LROCRP @/home/oracle/dba_llogic/MONITORA_INSTANCIA.sql

if [ -e /tmp/monit_instancia.txt ]
 then 
    ct_proc15=`cat /tmp/monit_instancia.txt| grep 1 | wc -l` 
    if [ $ct_proc15 -ne 1 ]
     then
       $PWDDIR/sendEmail -f oracle@RAC_LROCRP.loginlogistica.com.br -t equipe.dba@loginlogistica.com.br -cc daniel.augusto@alog.com.br -u "ATENCAO INSTANCIA FORA" -m "   =======   INSTANCIA FORA DO AR    =======  " -s 172.27.254.42:25
    else
    echo "RAC_LROCRP - INSTANCIA NO AR"
    fi
fi


$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@COSMOS @/home/oracle/dba_llogic/MONITORA_INSTANCIA.sql

if [ -e /tmp/monit_instancia.txt ]
 then 
    ct_proc15=`cat /tmp/monit_instancia.txt| grep 1 | wc -l` 
    if [ $ct_proc15 -ne 1 ]
     then
       $PWDDIR/sendEmail -f oracle@COSMOS.loginlogistica.com.br -t equipe.dba@loginlogistica.com.br -cc daniel.augusto@alog.com.br -u "ATENCAO INSTANCIA FORA" -m "   =======   INSTANCIA FORA DO AR    =======  " -s 172.27.254.42:25
    else
    echo "COSMOS - INSTANCIA NO AR"
    fi
fi

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@BPEL @/home/oracle/dba_llogic/MONITORA_INSTANCIA.sql

if [ -e /tmp/monit_instancia.txt ]
 then 
    ct_proc15=`cat /tmp/monit_instancia.txt| grep 1 | wc -l` 
    if [ $ct_proc15 -ne 1 ]
     then
       $PWDDIR/sendEmail -f oracle@BPEL.loginlogistica.com.br -t equipe.dba@loginlogistica.com.br -cc daniel.augusto@alog.com.br -u "ATENCAO INSTANCIA FORA" -m "   =======   INSTANCIA FORA DO AR    =======  " -s 172.27.254.42:25
    else
    echo "BPEL - INSTANCIA NO AR"
    fi
fi

echo "TERMINO ROTINA MONITORAMENTO INSTANCIA - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}

#########################################################################
func_filesystem ()
{

echo "INICIO ROTINA MONITORAMENTO FILESYSTEM - $Vdata" >> $LOGDIR/rotina_monitoramento.log

# WRITTEN BY : Milind Sarambale - DSS CARE DBA : dbsupp@gmail.com 
# EDITED BY : Glaucia Melo: glauciamelo@gmail.com
#Initialize the Environment variable setup 
export LOG_RET=500 #logfile retention time in days

#Parameters Specific to the Server 
export SCRIPT_HOME=/home/oracle/dba_llogic
export THRESHOLD=90 #this is a threshold limit 
export FAIL_CODE=0 
export DATE=`date +"%d/%m/%y"`
export TIME=`date +"%H:%M"`


# Clear log file
> $SCRIPT_HOME/log/filesystem.log 

#Define Functions 
################################## 
# INITIATE THE SYSMON PROCESS 
################################## 
start_sysmon() 
{ 
touch $SCRIPT_HOME/log/infracare.sysmon.log 
echo "#BEGIN SYSMON PROCESS FOR MONITORING $HOST_NAME" >>$SCRIPT_HOME/log/infracare.sysmon.log 
echo "SYSMON Process starting on $DATE $TIME" >>$SCRIPT_HOME/log/infracare.sysmon.log 
echo "SERVER : $HOST_NAME" >>$SCRIPT_HOME/log/infracare.sysmon.log 
} 
################################## 
# END THE SYSMON PROCESS 
################################## 
end_sysmon() 
{ 
echo "#END SYSMON PROCESS FOR MONITORING SERVERS" >>$SCRIPT_HOME/log/infracare.sysmon.log 
mv $SCRIPT_HOME/log/infracare.sysmon.log $SCRIPT_HOME/log/infracare.sysmon.log.${RUN_DATE} 
find ${SCRIPT_HOME}/log -name ‘*.log.*’ -mtime +${LOG_RET} -exec rm -f {} \; 2> /dev/null & 
} 
############################# 
#NOTIFY 
############################# 
notify() 
{ 
#/bin/mail -s "SYSMON REPORTING ISSUES ON ${HOST_NAME} on $DATE at $TIME" $MAIL_USERS < $SCRIPT_HOME/log/infracare.sysmon.log.${RUN_DATE} 
$PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -u "SYSMON REPORTING ISSUES ON ${HOST_NAME} on $DATE at $TIME" -o message-file=$SCRIPT_HOME/log/infracare.sysmon.log.${RUN_DATE} -s $SERVEMAIL  
>$SCRIPT_HOME/log/infracare.sysmon.log.
>$SCRIPT_HOME/log/filesystem.log
}

############################# 
#CHECKING DISK STATUS 
############################# 
check_space() 
{ 
df -H | grep -vE '^Filesystem|tmpfs|cdrom|mnt' | awk '{ print $5 " " $6 }'| grep -vE 'dev|usr|var|boot|home' >> $SCRIPT_HOME/log/filesystem.log 
while read line 
do 
echo $line 
usep=`(echo $line | awk '{ print $1}' | cut -d '%' -f1 )` 
echo $usep 
filesystem=`(echo $line | awk '{ print $2 }' )` 
echo $filesystem 
export usep filesystem 
if [ $usep -ge ${THRESHOLD} ]; then 
echo "INFRACARE:001:Filesystem Running out of space \"$filesystem ($usep%)\" on $(hostname) as on $(date)" >> $SCRIPT_HOME/log/infracare.sysmon.log 
FAIL_CODE=1 
fi 
done <$SCRIPT_HOME/log/filesystem.log 
}

########################################### 
#END OF FUNCTIONS 
########################################### 
############################## 
#ENABLE FUNCTIONS 
############################## 
start_sysmon 
check_space 
end_sysmon 
echo "Fail_CODE is $FAIL_CODE" 
if [ $FAIL_CODE = 1 ] 
then 
notify 
else
echo "NO FILESYSTEM ISSUES"
fi

echo "TERMINO ROTINA MONITORAMENTO FILESYSTEM - $Vdata" >> $LOGDIR/rotina_monitoramento.log

}

func_monitor_processes ()
{

echo "INICIO ROTINA MONITORAMENTO PROCESSOS MAQUINA - $Vdata" >> $LOGDIR/rotina_monitoramento.log

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @/home/oracle/dba_llogic/MONITORA_PROCESSOS.SQL
ct_proc31=`ps -ef | wc -l`
ct_proc30=`cat /tmp/monit_processes.log`
  if [ $ct_proc31 -gt $ct_proc30 ]
  then
   	$PWDDIR/sendEmail -f $REMETENT -t $DESTINAT -m  "Processos no banco estourando!! 90% de utilizacao! "  -u "ATENCAO PROCESSOS" -s $SERVEMAIL  
  else
    echo "NUMERO DE PROCESSOS NA MAQUINA OK"
  fi
echo "FIM ROTINA MONITORAMENTO PROCESSOS MAQUINA - $Vdata" >> $LOGDIR/rotina_monitoramento.log

}

# Conta sessoes logadas ha mais de 4 horas.
#func_conta_sessao
#{
#echo "INICIO ROTINA CONTA SESSAO BDBOOKP - $Vdata" >> $LOGDIR/rotina_monitoramento.log
#
#sqlplus -S /nolog  <<EOF
#conn / as sysdba
#@/home/oracle/dba_llogic/conta_sessoes_bdbookp.sql
#exit
#EOF
#$PWDDIR/sendEmail -f oracle@oracleprod01.loginlogistica.com.br -t ows.glaucia@loginlogistica.com.br -cc gustavo.richard@loginlogistica.com.br -u "SESSOES BDBOOKP" -o message-file=/tmp/conta_sessao.txt -s 172.27.254.42:25
#echo "FIM ROTINA CONTA SESSOES BDBOOKP - $Vdata" >> $LOGDIR/rotina_monitoramento.log
#}

func_atualizaindex()
{
echo "INICIO ROTINA ATUALIZA INDEX - $Vdata" >> $LOGDIR/rotina_monitoramento.log

$ORACLE_HOME/bin/sqlplus -S system/orabpelprod@BPEL @/home/oracle/dba_llogic/updateindexes.sql
$ORACLE_HOME/bin/sqlplus -S system/orabpelprod@BPEL @/tmp/updateindexes.txt

echo "TERMINO ROTINA ATUALIZA INDEX - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}


func_monitor_sessoes_antigas ()
{
echo "INICIO ROTINA MATA SESSOES IDLE - $Vdata" >> $LOGDIR/rotina_monitoramento.log

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @/home/oracle/dba_llogic/sessions.sql

if [ -e /tmp/session_ct.log ]
 then 
    ct_proc4=`grep "TEM PROCESSO" /tmp/session_ct.log | wc -l`
    if [ $ct_proc4 -gt 0 ]
     then
       $PWDDIR/sendEmail -f oracle@oracleprod01.loginlogistica.com.br -t equipe.dba@loginlogistica.com.br -cc ows.glaucia@loginlogistica.com.br -u "SESSIONS BDBOOKP" -o message-file=/tmp/sessoes_que_serao_mortas.sql -s 172.27.254.42:25
    fi
fi
echo "TERMINO ROTINA MATA SESSOES IDLE - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}

func_monitor_mensal ()
{
echo "INICIO ROTINA MONITORAMENTO MENSAL - $Vdata" >> $LOGDIR/rotina_monitoramento.log

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @/u01/app/oracle/admin/scripts/sql/monitormensal.sql
mv /tmp/databasemonthreport.html /tmp/databasemonthreport$Vdatamon.html
$PWDDIR/sendEmail -f oracle@heb-db1.hebara.com.br -t fred.mello@hebara.com.br -cc glaucia@dldba.com.br alexandre.mduarte@dldba.com.br -u MONITOR MENSAL $HOST_NAME -m "SEGUE ARQUIVO ANEXO" -a /tmp/databasemonthreport$Vdatamon.html -s smtp.gmail.com:587 -xu ti@hebara.com.br -xp $senhaemail

echo "TERMINO ROTINA MONITORAMENTO MENSAL - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}


func_monitor_semanal_dg ()
{
echo "INICIO ROTINA MONITORAMENTO SEMANAL DG - $Vdata" >> $LOGDIR/rotina_monitoramento.log

$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@$Vserv @/home/oracle/dba_llogic/monitordgsemanal.sql
cd /tmp
cat /tmp/monitorstoragesemanal.txt >> /tmp/monitorstoragesemanal.log
$ORACLE_HOME/bin/sqlplus -S $Vuser/$Vpwd@RAC_LROCRP @/home/oracle/dba_llogic/monitordgsemanal.sql
cd /tmp
cat /tmp/monitorstoragesemanal.txt >> /tmp/monitorstoragesemanal.log

#$PWDDIR/sendEmail -f oracle@loginlogistica.com.br -t equipe.dba@loginlogistica.com.br -u MONITOR SEMANAL DG -m "SEGUE ARQUIVO ANEXO" -a /tmp/monitorstoragesemanal.log -s 172.27.254.42:25

# Apaga os arquivos gerados para não manter lixo no sistema
rm /tmp/monitorstoragesemanal.txt

echo "TERMINO ROTINA MONITORAMENTO SEMANAL DG - $Vdata" >> $LOGDIR/rotina_monitoramento.log
}

# Inicio script

if [ "$Vproc" = "" ] || [ "$Vuser" = "" ]
 then
    echo "UTILIZACAO ERRADA DO SCRIPT - $Vdata" >> $LOGDIR/rotina_monitoramento.log
    echo "UTILIZACAO ERRADA DO SCRIPT"
    echo "Sintaxe: rotina_monitoramento.sh <PROCEDIMENTO> <USUARIO>"
    exit
fi

if [ "$Vuser" = "bdbookp" ] || [ "$Vuser" = "BDBOOKP" ]
 then
    Vuser=`cat $PWDDIR/.users | cut -f 1 -d :|grep -i $Vuser`
    #Vpwd=`cat $PWDDIR/.users  | cut -f 2 -d :|grep -i $Vuser`
    Vpwd=`cat $PWDDIR/.users  | grep -i $Vuser | cut -f 2 -d ":"`
    case "$Vproc" in
      TBS|tbs) func_monitor_tablespace
           ;;
    esac
 else
   if [ "$Vuser" = "operador" ] || [ "$Vuser" = "OPERADOR" ]
    then
       Vuser=`cat $PWDDIR/.users | cut -f 1 -d :|grep -i $Vuser`
       Vpwd=`cat $PWDDIR/.users  | grep -i $Vuser | cut -f 2 -d ":"`
       case "$Vproc" in
         TBS|tbs) func_monitor_tablespace
           ;;
         LCK|lck) func_monitor_lock
           ;;
	  LSN|lsn) func_monitor_listener
           ;;
         SES|ses) func_monitor_sessoes_antigas 
           ;;
         SERV|serv) func_monitor_servicos
           ;;
	  ERRLOG|errlog) func_monitor_erroslog
	    ;;
	  VERLOG|verlog) func_verifica_logados
	    ;;
	  TRANSLOG|translog) func_transfere_logados
	    ;;
	  VERCPU|vercpu) func_load_cpu
	    ;;
	  MONMAIL|monmail) func_monitor_mail
	    ;;
	  ERASEMAIL|erasemail) func_erase_mail
	    ;;
	  MONDG|mondg) func_monitor_dg
	    ;;
	  OBJINV|objinv) func_objetos_invalidos
	    ;;
	  INST|inst) func_monitor_instancia
	    ;;
	  FS|fs) func_filesystem
	    ;;
	  PROC|proc) func_monitor_processes
	    ;;
         IND|ind) func_atualizaindex
           ;;
         MONMENSAL|monmensal) func_monitor_mensal
           ;;
         MONSEMANALDG|monsemanaldg) func_monitor_semanal_dg
           ;;
       esac
   fi
fi

