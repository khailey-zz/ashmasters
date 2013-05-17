
col block_type for a18
col obj for a20
col otype for a15
col event for a15
col blockn for 999999
col p3 for  a30
select
       count(*),
       ash.p1,
       ash.p2,
       to_char(ash.p3) p3 , 
       nvl(o.object_name,CURRENT_OBJ#) obj,
       o.object_type otype,
       ash.SQL_ID
from v$active_session_history ash,
      all_objects o
where event like 'db file p%'
   and o.object_id (+)= ash.CURRENT_OBJ#
   and sample_time > sysdate - &minutes/(60*24)
group by
       ash.p1,
       ash.p2,
       ash.p3 , 
       o.object_name,
       CURRENT_OBJ#,
       o.object_type ,
       ash.SQL_ID
order by count(*)
/

