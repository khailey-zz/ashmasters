
/*

Jared Still - 2015-03-17
jkstill@gmail.com

based on https://github.com/khailey/ashmasters/blob/master/cpu_consumed_verses_cpuwait.sql

Gather metrics across all instances of RAC
Attempted to normalize times, as collections times can vary by 1 minute between all instances.

Not quite accurate, but sufficient I think for getting aggregated performance metrics

*/


with AASIO as (
           select
              class, sum(AAS) AAS, begin_time, end_time
              from (
                 select
                 decode(n.wait_class,'User I/O','User I/O',
                                     'Commit','Commit',
                                     'Wait')                               CLASS,
                 sum(round(m.time_waited/m.INTSIZE_CSEC,3))  AAS,
                 -- normalize the begin/end times between instances
                 -- not perfect but I think close enough for general trends
                 -- should never be more than 2 minutes variance assuming 3+ instances
                 -- 1 minute variance for 2 instances
                 min(BEGIN_TIME) over (partition by decode(n.wait_class,'User I/O','User I/O', 'Commit','Commit', 'Wait')) begin_time ,
                 min(END_TIME) over (partition by decode(n.wait_class,'User I/O','User I/O', 'Commit','Commit', 'Wait')) end_time
           from  gv$waitclassmetric  m,
                 gv$system_wait_class n
           where m.wait_class_id=n.wait_class_id
             and n.wait_class != 'Idle'
                                 and n.inst_id = m.inst_id
           group by  decode(n.wait_class,'User I/O','User I/O', 'Commit','Commit', 'Wait'), BEGIN_TIME, END_TIME
           order by begin_time
         )
         group by class, begin_time, end_time
),
CORES as (
   select cpu_core_count from dba_cpu_usage_statistics where timestamp= (select max(timestamp) from dba_cpu_usage_statistics)
),
AASSTAT as (
             select class, aas, begin_time, end_time from aasio
          union
             select 'CPU_ORA_CONSUMED'                                     CLASS,
                    round(sum(value)/100,3)                                     AAS,
                 min(BEGIN_TIME) begin_time,
                 max(END_TIME) end_time
             from gv$sysmetric
             where metric_name='CPU Usage Per Sec'
               and group_id=2
            group by metric_name
          union
           select 'CPU_OS'                                                CLASS ,
                    round((prcnt.busy*parameter.cpu_count)/100,3)          AAS,
                 BEGIN_TIME ,
                 END_TIME
            from
              ( select sum(value) busy, min(BEGIN_TIME) begin_time,max(END_TIME) end_time from gv$sysmetric where metric_name='Host CPU Utilization (%)' and group_id=2 ) prcnt,
              ( select sum(value) cpu_count from gv$parameter where name='cpu_count' )  parameter
          union
             select
               'CPU_ORA_DEMAND'                                            CLASS,
               nvl(round( sum(decode(session_state,'ON CPU',1,0))/60,2),0) AAS,
               cast(min(SAMPLE_TIME) as date) BEGIN_TIME ,
               cast(max(SAMPLE_TIME) as date) END_TIME
             from gv$active_session_history ash
              where SAMPLE_TIME >= (select min(BEGIN_TIME) begin_time from gv$sysmetric where metric_name='CPU Usage Per Sec' and group_id=2 )
               and SAMPLE_TIME < (select max(END_TIME) end_time from gv$sysmetric where metric_name='CPU Usage Per Sec' and group_id=2 )
)
select
		 sysdate timestamp,
       to_char(BEGIN_TIME,'YYYY-MM-DD HH24:MI:SS') BEGIN_TIME,
       to_char(END_TIME,'YYYY-MM-DD HH24:MI:SS') END_TIME,
       cpu.cpu_core_count cores,
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
       min(BEGIN_TIME) BEGIN_TIME,
       max(END_TIME) END_TIME,
       sum(decode(CLASS,'CPU_ORA_CONSUMED',AAS,0)) CPU_ORA_CONSUMED,
       sum(decode(CLASS,'CPU_ORA_DEMAND'  ,AAS,0)) CPU_ORA_DEMAND,
       sum(decode(CLASS,'CPU_OS'          ,AAS,0)) CPU_OS,
       sum(decode(CLASS,'Commit'          ,AAS,0)) COMMIT,
       sum(decode(CLASS,'User I/O'        ,AAS,0)) READIO,
       sum(decode(CLASS,'Wait'            ,AAS,0)) WAIT
from AASSTAT
)
, cores cpu
/
