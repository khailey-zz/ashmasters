




set linesize 100
set verify off
set echo off
set feedback off
set heading off

column wait_event format a25

column collected new_value _collected
column runs new_value _runs
column beg new_value _beg
column end new_value _end
column mins_ago new_value _mins_ago
column duration new_value _duration
column end_time new_value _end_time

select &mins_ago+0  mins_ago, &duration+0 duration from dual;
select decode(&_mins_ago,0,15,&_mins_ago) mins_ago , 
       decode(&_duration,0,15,&_duration) duration from dual;
select  &_mins_ago , &_mins_ago - &_duration end_time  from dual;

set heading on
select nvl(count(*),0) collected, 
       max(sample_id),min(sample_id) ,
       nvl(max(sample_id)-min(sample_id),0)+1 runs,
       --nvl(min(sample_time),sysdate) beg,
       --nvl(max(sample_time),sysdate) end
       to_char(nvl(min(sample_time),sysdate),'DD/MM/YY HH24:MI:SS') beg,
       to_char(nvl(max(sample_time),sysdate),'DD/MM/YY HH24:MI:SS') end
from v$active_session_history
where sample_time >= sysdate - (&_mins_ago)/(24*60) 
  and sample_time <= sysdate - (&_end_time)/(24*60)
  -- and session_type!=81;
set termout off
set heading off
set termout on

select
        'Analysis Begin Time :   ' || '&_beg' || '                               ',
        'Analysis End   Time :   ' || '&_end' || '                               ',
        'Start time, mins ago:   ' || '&_mins_ago' || '                             ',
        'Request Duration    :   ' || '&_duration' || '                             ',
        'Collections         :   ' || '&_runs' || '                             ',
        'Data Values         :   ' || '&_collected' || '                             ',
        --'Elapsed Time:  ' || to_char(round((to_date(&_end)-to_date(&_beg))*24*60))||' mins '
        'Elapsed Time:  ' || to_char(round((to_date('&_end','DD/MM/YY HH24:MI:SS')-to_date('&_beg','DD/MM/YY HH24:MI:SS'))*24*60))||' mins '
from dual
/
--where &_collected > 0;

set heading on
break on report
compute sum of "Ave_Act_Sess" on Report

select * from (
   select 
        substr(decode(session_state,'ON CPU','ON CPU',event),0,25) wait_event, 
        count(*)  cnt,
        round( 100* (count(*)/&_collected) +0.00  , 2.2) "% Active",
        round( (count(*)/&_runs) +0.00, 2.2) "Ave_Act_Sess"
   from 
        v$active_session_history  ash
   where
        sample_time >= sysdate - &_mins_ago/(24*60)
    and sample_time <= sysdate - (&_end_time)/(24*60) 
   group by decode(session_state,'ON CPU','ON CPU',event) 
   order by count(*)
) where cnt/&_collected > 0.001
 and &_collected > 0
;

set verify on
set echo on
set feedback on
clear computes
clear breaks


