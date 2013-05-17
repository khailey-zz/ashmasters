col block_type for a18
col obj for a20
col otype for a15
col event for a15
col blockn for 999999
col p3 for 999
select
       substr(event,0,15) event,
       ash.p1,
       ash.p2,
       ash.p3 p3, 
       --CURRENT_OBJ#||' '||o.object_name objn,
       nvl(o.object_name,CURRENT_OBJ#) obj,
       o.object_type otype,
       --CURRENT_FILE# filen,
       --CURRENT_BLOCK# blockn, 
       ash.SQL_ID
       --,blocking_session bsid
from v$active_session_history ash,
      all_objects o
where event like 'db file s%'
   and o.object_id (+)= ash.CURRENT_OBJ#
   and sample_time > sysdate - &minutes/(60*24)
Order by sample_time
/
