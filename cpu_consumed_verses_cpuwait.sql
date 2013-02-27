

/* 

see

   http://dboptimizer.com/2011/07/21/oracle-cpu-time


output looks like

SQL> /

 CPU_TOTAL     CPU_OS    CPU_ORA CPU_ORA_WAIT     COMMIT     READIO       WAIT
---------- ---------- ---------- ------------ ---------- ---------- ----------
    14.887       .387     13.753         .747          0          0       .023

SQL> /

 CPU_TOTAL     CPU_OS    CPU_ORA CPU_ORA_WAIT     COMMIT     READIO       WAIT
---------- ---------- ---------- ------------ ---------- ---------- ----------
    21.989      7.469     12.909        1.611          0          0       .044

SQL> /

 CPU_TOTAL     CPU_OS    CPU_ORA CPU_ORA_WAIT     COMMIT     READIO       WAIT
---------- ---------- ---------- ------------ ---------- ---------- ----------
    26.595     12.125     11.841        2.629          0          0       .025

SQL> /

 CPU_TOTAL     CPU_OS    CPU_ORA CPU_ORA_WAIT     COMMIT     READIO       WAIT
---------- ---------- ---------- ------------ ---------- ---------- ----------
    27.045     12.125     11.841        3.079          0          0       .025


*/


with AASSTAT as (
           select
                 decode(n.wait_class,'User I/O','User I/O',
                                     'Commit','Commit',
                                     'Wait')                               CLASS,
                 sum(round(m.time_waited/m.INTSIZE_CSEC,3))                AAS
           from  v$waitclassmetric  m,
                 v$system_wait_class n
           where m.wait_class_id=n.wait_class_id
             and n.wait_class != 'Idle'
           group by  decode(n.wait_class,'User I/O','User I/O', 'Commit','Commit', 'Wait')
          union
             select 'CPU_ORA_CONSUMED'                                     CLASS,
                    round(value/100,3)                                     AAS
             from v$sysmetric
             where metric_name='CPU Usage Per Sec'
               and group_id=2
          union
            select 'CPU_OS'                                                CLASS ,
                    round((prcnt.busy*parameter.cpu_count)/100,3)          AAS
            from
              ( select value busy from v$sysmetric where metric_name='Host CPU Utilization (%)' and group_id=2 ) prcnt,
              ( select value cpu_count from v$parameter where name='cpu_count' )  parameter
          union
             select
               'CPU_ORA_DEMAND'                                            CLASS,
               nvl(round( sum(decode(session_state,'ON CPU',1,0))/60,2),0) AAS
             from v$active_session_history ash
             where SAMPLE_TIME > sysdate - (60/(24*60*60))
)
select
       ( decode(sign(CPU_OS-CPU_ORA_CONSUMED), -1, 0, (CPU_OS - CPU_ORA_CONSUMED )) +
       CPU_ORA_CONSUMED +
        decode(sign(CPU_ORA_DEMAND-CPU_ORA_CONSUMED), -1, 0, (CPU_ORA_DEMAND - CPU_ORA_CONSUMED ))) CPU_TOTAL,
       decode(sign(CPU_OS-CPU_ORA_CONSUMED), -1, 0, (CPU_OS - CPU_ORA_CONSUMED )) CPU_OS,
       CPU_ORA_CONSUMED CPU_ORA,
       decode(sign(CPU_ORA_DEMAND-CPU_ORA_CONSUMED), -1, 0, (CPU_ORA_DEMAND - CPU_ORA_CONSUMED )) CPU_ORA_WAIT,
       COMMIT,
       READIO,
       WAIT
from (
select
       sum(decode(CLASS,'CPU_ORA_CONSUMED',AAS,0)) CPU_ORA_CONSUMED,
       sum(decode(CLASS,'CPU_ORA_DEMAND'  ,AAS,0)) CPU_ORA_DEMAND,
       sum(decode(CLASS,'CPU_OS'          ,AAS,0)) CPU_OS,
       sum(decode(CLASS,'Commit'          ,AAS,0)) COMMIT,
       sum(decode(CLASS,'User I/O'        ,AAS,0)) READIO,
       sum(decode(CLASS,'Wait'            ,AAS,0)) WAIT
from AASSTAT)
/

