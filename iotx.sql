col block_type for a18
col objn for a25
col otype for a15
col event for a15
col blockn for 999999
select
       --count(*) cnt
       --ash.p1, 
       --ash.p2, 
        ash.sql_id
       ,ash.xid
from v$active_session_history ash
where ( event like 'db file s%' or event like 'direct%' )
   and sample_time > sysdate - &minutes/(60*24)
   and session_state='WAITING'
/*
group by 
       --ash.p1, 
       --ash.p2, 
       --ash.sql_id
        xid
--Order by count(*)
*/
order by sql_id, xid
/




