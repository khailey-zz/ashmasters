#!/bin/ksh 

# ./collect.sh delphix delphix 172.16.100.250 orcl 1521 &


function usage
{
       echo "Usage: $(basename $0) <username> <password> <host> [sid] [port]"
       echo "  username        database username"
       echo "  username        database password"
       echo "  host            hostname or IP address"
       echo "  sid             optional database sid (default: orcl)"
       echo "  port            optional database port (default: 1521)"
       echo "  run time (secs) optional (default: 43200 , ie 12 hours) "
       exit 2
}

[[ $# -lt 3 ]] && usage
[[ $# -gt 5 ]] && usage

UN=delphix
PW=delphix
HOST=172.16.100.250
SID=orcl
PORT=1521
RUN_TIME=43200     # total run time, 12 hours default 43200
RUN_TIME=86400     # total run time, 24 hours default 86400
RUN_TIME=864000    # total run time, 10 days  default 864000
RUN_TIME=-1        #  run continuously

[[ $# -gt 0 ]] && UN=$1
[[ $# -gt 1 ]] && PW=$2
[[ $# -gt 2 ]] && HOST=$3
[[ $# -gt 3 ]] && SID=$4
[[ $# -gt 4 ]] && PORT=$5
[[ $# -gt 5 ]] && RUN_TIME=$6

# the dtrace will take an IP address as an argument and filter for just that IP 
# DTRACE_HOST=$HOST


    # seems to sample at sample rate +3 secs, ie 7 actual works out to 10 secs
    FAST_SAMPLE="avgreadsz avgreadms avgwritesz avgwritems throughput aas wts systat ash"     # list of stats to sample 
    FAST_SAMPLE="ash"     # list of stats to sample 
    DEBUG=${DEBUG:-0}            # 1 output debug, 2 include SQLplus output

    MON_HOME=${MON_HOME:-/tmp/MONITOR} 
    MON_HOME=${MON_HOME:-$HOME/MONITOR} 
    LOG=${LOG:-"$MON_HOME/log"}
    TMP=${TMP:-"$MON_HOME/tmp"}
    CLEAN=${CLEAN:-"$MON_HOME/clean"}

    mkdir $LOG > /dev/null 2>&1
    mkdir $TMP > /dev/null 2>&1
    mkdir $CLEAN > /dev/null 2>&1

    MACHINE=`uname -a | awk '{print $1}'`
    case $MACHINE  in
    Linux)
            MKNOD=/bin/mknod
            ;;
    AIX)
            MKNOD=/usr/sbin/mknod
            ;;
    SunOS)
            MKNOD=/etc/mknod
            ;;
    HP-UX)
            MKNOD=mknod
            ;;
    *)
            MKNOD=mknod
            ;;
    esac


  # create OUPUT directory
    if [ ! -f "$MON_HOME" ]; then
       mkdir $MON_HOME > /dev/null 2>&1
    fi

  # "collect.sh end" will end all running collect.sh's
    if test x$1 = xend ; then
       if [ -f $MON_HOME/*\.end ]; then
           rm $MON_HOME/*\.end
       fi
       if [ -f $MON_HOME/*/*\.end ]; then
           rm $MON_HOME/*/*\.end
       fi
       exit
    fi

  # setup OUTPUT file name template
  # CURR_DATE=`date "+%d%m_%H%M%S"`  
  # CURR_DATE=`date "+%m%d_%H"`  
    CURR_DATE=`date "+%u_%H"`  

  # MON_NODE="`hostname | sed -e 's/\..*//'`"

    TARGET=${HOST}:${SID}
    SUF=.dat


    OUTPUT=${LOG}/${TARGET}_connect.log
    CLEANUP=${CLEAN}/${TARGET}_cleanup.sh
    SQLTESTOUT=${TMP}/${TARGET}_collect.out
    OPEN=${TMP}/${TARGET}_collect.open
    PIPE=${TMP}/${TARGET}_collect.pipe
    EXIT=${CLEAN}/${TARGET}_collect.end

  # exit if removed
    touch $EXIT

  # printout setup
    for i in 1; do
    echo
    echo
    echo "SYS=$SYS" 
    echo "RUN_TIME=$RUN_TIME" 
    echo "FAST_SAMPLE=$FAST_SAMPLE" 
    echo "HOST=$HOST" 
    echo "DEBUG=$DEBUG" 
    echo
    done > $OUTPUT
    cat $OUTPUT

  # create a UNIX named pipe
  # in order to avoid disconnects when attaching sqlplus to the named pipe
  # create an empty file and "tail -f" this empty file into the pipe
  # this will prevent the pipe from closing on the sqlplus session
  # otherwise the sqlplus session would exit after every cat to the pipe
  # had finished

  # setup sqlplus connection reading off a pipe
    rm $OPEN $PIPE > /dev/null 2>&1
    touch  $OPEN
    cmd="$MKNOD $PIPE p"
    eval $cmd
    tail -f $OPEN >> $PIPE &
    OPENID="$!"


  # run SQLPLUS silent unless DEBUG is 2 or higher 
       SILENT=""
    if [ $DEBUG -lt 2 ]; then
       SILENT="-s"
    fi
  # SID
    CONNECT="$UN/$PW@(DESCRIPTION= (ADDRESS_LIST= (ADDRESS= (PROTOCOL=TCP) (HOST=$HOST) (PORT=$PORT))) (CONNECT_DATA= (SERVER=DEDICATED) (SID=$SID)))"
  # SERVICE_ID
   #CONNECT="$UN/$PW@(DESCRIPTION= (ADDRESS_LIST= (ADDRESS= (PROTOCOL=TCP) (HOST=$HOST) (PORT=$PORT))) (CONNECT_DATA= (SERVER=DEDICATED) (SERVICE_NAME=$SID)))"
    cmd="sqlplus $SILENT \"$CONNECT\" < $PIPE > /dev/null &" 
    echo "$cmd" >> ${OUTPUT}
    eval $cmd 
    SQLID="$!"

  # setup exit/cleanup stuff
    for i in 1; do
      echo "date" 
      echo "("
      echo "rm $PIPE $OPEN $EXIT"  
      echo "kill -9 $SQLID $OPENID $VMSTATID"
      echo ") > /dev/null 2>&1"
      echo "rm  $LOG/${HOST}:${SID}_connect.log"
    done > $CLEANUP
    chmod 755 $CLEANUP
    trap "echo $CLEANUP;sh $CLEANUP" 0 3 5 9 15 

    if [ ! -p $PIPE ]; then
       echo "error creating named pipe "
       echo "command was:"
       echo "             $cmd"
       eval $CMD
       exit
    fi

#   /******************************/
#   *                             *
#   * BEGIN FUNCTION DEFINITIONS  *
#   *                             *
#   /******************************/
#

function debug {
if [ $DEBUG -ge 1 ]; then
   #   echo "   ** beg debug **"
   var=$*
   nvar=$#
   if test x"$1" = xvar; then
     shift
     let nvar=nvar-1
     while (( $nvar > 0 ))
     do
        eval val='$'{$1} 1>&2
        echo "       :$1:$val:"  1>&2
        shift
        let nvar=nvar-1
     done
   else
     while (( $nvar > 0 ))
     do
        echo "       :$1:"  1>&2
        shift
        let nvar=nvar-1
     done
   fi
   #   echo "   ** end debug **"
fi
}                         

function check_exit {
        if [  ! -f $EXIT ]; then
           echo "exit file removed, exiting at `date`"
           cat $CLEANUP
           $CLEANUP 
           exit
        fi
}

function sqloutput  {
    cat << EOF >> $PIPE &
       set pagesize 0
       set feedback off
       spool $SQLTESTOUT
       select 1 from dual;
       spool off
EOF
}

function testconnect {
     rm $SQLTESTOUT 2> /dev/null
     if [ $CONNECTED -eq 0 ]; then
        limit=10
     else
        limit=60
     fi
     debug "before sqloutput"
     sqloutput
     debug "after sqloutput"
     count=0
     found=1
     debug "before while"
     while [ $count -lt $limit -a $found -eq 1 ]; do
        if [ -f $SQLTESTOUT ]; then
          grep '^ *1'  $SQLTESTOUT > /dev/null  2>&1
          found=$?
        else 
          debug  "sql output file: $SQLTESTOUT, not found"
        fi
          debug "found $found"
          debug "loop#   $count limit $limit "
          if [ $CONNECTED -eq 0 ]; then
             echo "Trying to connect"
          fi
          let TO_SLEEP=TO_SLEEP-count
          sleep $count
          count=`expr $count + 1`
          check_exit
     done
     debug "after while"
     if [ $count -ge $limit ]; then
       echo "output from sqlplus: "
       if [ -f $SQLTESTOUT ]; then
          cat $SQLTESTOUT 
       else
          echo "sqlplus output file: $SQLTESTOUT, not found"
          echo "check user name and password for sqlplus"
          echo "try 'export DEBUG=1' and rerun"
       fi
       echo "loop#  $count limit $limit " >> $OUTPUT
       echo "collect.sh : timeout waiting connection to sqlplus"
       echo "collect.sh : timeout waiting connection to sqlplus" >> $OUTPUT
       eval $CMD
       exit
     fi
     echo "count# $count limit $limit " >> $OUTPUT
}


       #select 'echo '||to_char(sysdate,'DD-MON-YY HH24:MI:SS')||' >> '||p.spid||'.pstack'

function ash  {
     cat << EOF
       spool  ${TMP}/${TARGET}_ash.tmp
       select 'echo "'||to_char(sysdate,'DD-MON-YY HH24:MI:SS')||' '||
                        s.sid||' '||
                        s.serial#||' '||
                        s.event||' '||
                        s.sql_id||  
                        '" >> ${MON_HOME}/${CURR_DATE}/'||p.spid||'.pstack'
       from v\$process p, v\$session s
       where p.addr = s.paddr
        --and  s.event='enq: TX - row lock contention'
        and  s.event='Disk file operations I/O'
        and  SECONDS_IN_WAIT > 10
     ;
       select 'pstack '||p.spid||' >> ${MON_HOME}/${CURR_DATE}/'||p.spid||'.pstack'
       from v\$process p, v\$session s
       where p.addr = s.paddr
        --and  s.event='enq: TX - row lock contention'
        and  s.event='Disk file operations I/O'
        and  SECONDS_IN_WAIT > 10
     ;
     spool off
EOF
}



function tight_loop {
   #
   # collect stats once a minute
   # every second see if the minute had changed
   # every second check EXIT file exists
   # if EXIT file has been deleted, then exit
   # 
   # change the directory day of the week 1-7
   # CURR_DATE=`date "+%u_%H"`  
   # day of the week 1-7
     check_exit
     SLEPTED=0
     SAMPLE_RATE=1
     debug var SLEPTED SAMPLE_RATE
     start_time=0  
     CURR_DATE=`date "+%u"`  
     echo $CURR_DATE > $MON_HOME/currrent_data.out
     LAST_DATE=-1
     while [  $SLEPTED -lt $RUN_TIME -o $RUN_TIME=-1 ]  && [ -f $EXIT ]; do
      # date = 1-7, day of the week

        CURR_DATE=`date "+%u"`  
        if [ $LAST_DATE -ne $CURR_DATE ]; then
          echo $CURR_DATE > $MON_HOME/currrent_data.out
          mkdir ${MON_HOME}/${CURR_DATE} > /dev/null 2>&1
          rm ${MON_HOME}/${CURR_DATE}/*.dat  > /dev/null 2>&1
          LAST_DATE=$CURR_DATE
        fi
        curr_time=`date "+%H%M%S" | sed -e 's/^0//' `  
       if [ $curr_time -gt  $start_time -o $curr_time -eq 0 ]; then
          if [  $curr_time -eq 0 ]; then
              start_time=1
          else 
              start_time=$curr_time
          fi
          debug "start_time $start_time curr_time $curr_time "
          for i in $FAST_SAMPLE; do
             ${i} >> $PIPE
          done
#          testconnect
           sleep .5 
          for i in  $FAST_SAMPLE; do
            # prepend each line with the current time hour concat minute ie 0-2359
            # then start over, but output directory will change to next day
            cat ${TMP}/${TARGET}_${i}.tmp  
            sh ${TMP}/${TARGET}_${i}.tmp  
            cat ${TMP}/${TARGET}_${i}.tmp  | sed -e "s/^/#$curr_time\n/" >> ${MON_HOME}/${CURR_DATE}/${TARGET}:${i}$SUF
          done
#          (sample_id_tmp=`tail -1 ${TMP}/${TARGET}_ash.tmp | awk -F, '{print $2}'`) > /dev/null 2>&1
#          if test x"$sample_id_tmp" = x ; then
#              sample_id_tmp=0
#          fi
#          #echo "sample_id_tmp:$sample_id_tmp:"
#          #echo "sample_id    :$sample_id:"
#          if [ $sample_id_tmp -gt $sample_id ] ; then
#            sample_id=$sample_id_tmp
#          fi
#          check_exit
       fi
        sleep .1
        debug "sleeping $SAMPLE_RATE"
     done
}


function setup_sql {
  cat << EOF
  set echo on
  set pause off
  set linesize 2500
  set verify off
  set feedback off
  set heading off
  set pagesize 0
  set trims on
  set trim on
  column start_day    new_value start_day 
  select  to_char(sysdate,'J')     start_day  from dual;
  column pt           new_value pt
  column seq          new_value seq
  column curr_time    new_value curr_time
  column elapsed      new_value elapsed     
  column timer        new_value timer       
  set echo off
EOF
}
#  alter session set sql_trace=false;
#  REM drop sequence orastat;
#  REM create sequence orastat;


#   /******************************/
#   *                             *
#   *   END FUNCTION DEFINITIONS  *
#   *                             *
#   /******************************/



#   /******************************/
#   *                             *
#   *      BEGIN PROGRAM          *
#   *                             *
#   /******************************/


  CURRENT=0
  TO_SLEEP=$SLOW_RATE

  CONNECTED=0
  setup_sql >> $PIPE
  testconnect
  echo "Connected, starting collect at `date`"
  CONNECTED=1
  setup_sql >> $PIPE

   echo "starting stats collecting "
 # BEGIN COLLECT LOOP
       sample_id=0
       tight_loop
 # END COLLECT LOOP

 # CLEANUP
   echo "run time expired, exiting at `date`"
   cat $CLEANUP
   $CLEANUP 

