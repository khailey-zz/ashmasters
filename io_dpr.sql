
--select --+ parallel(a,4) 
--count(*) from oto a;  

col block_type for a18
col objn for a25
col otype for a15
col event for a25
col p3 for 999
col fn for 999
col sid for 9999
col qsid for 9999
select
       session_id sid,
       QC_SESSION_ID qsid,
       --event,
       --ash.p1,
       --ash.p2,
       ash.p3,
       CURRENT_OBJ#||' '||o.object_name objn,
       o.object_type otype,
       CURRENT_FILE# fn,
       CURRENT_BLOCK# blockn,
       ash.SQL_ID
from v$active_session_history ash,
      all_objects o
where event like 'direct path read'
   and o.object_id (+)= ash.CURRENT_OBJ#
Order by sample_time
/


