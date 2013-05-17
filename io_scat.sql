
col block_type for a18
col objn for a25
col otype for a15
col event for a25
select
       event,
       ash.p3,
       CURRENT_OBJ#||' '||o.object_name objn,
       o.object_type otype,
       CURRENT_FILE# filen,
       CURRENT_BLOCK# blockn,
       ash.SQL_ID
from v$active_session_history ash,
      all_objects o
where event like 'db file scattered read'
   and o.object_id (+)= ash.CURRENT_OBJ#
Order by sample_time
/


