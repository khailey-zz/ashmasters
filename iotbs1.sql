
col block_type for a18
col objn for a25
col otype for a15
col event for a15
col blockn for 999999


select 
       tf.cnt,
       tf.event,
       f.tablespace_name 
from (
      select
              count(*) cnt,
              substr(event,0,15) event, 
              ash.p1 p1
       from   v$active_session_history ash
       where ( event like 'db file s%' or event like 'direct%' )
              and sample_time > sysdate - &minutes/(60*24)
       group by
              substr(event,0,15) , 
              ash.p1
      ) tf,
        dba_data_files f
where
    f.file_id = tf.p1
Order by tf.cnt
/

