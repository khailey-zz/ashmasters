

col block_type for a18
col objn for a25
col otype for a15
col event for a15
col blockn for 999999
col username for a15
select
       count(*) cnt
       ,nvl(u.username,ash.user_id) username
       --,session_id
       --,ash.current_obj# 
       ,nvl(o.object_name,decode(CURRENT_OBJ#,-1,0,CURRENT_OBJ#)) obj
       --,ash.p1
       --,ash.p2 
       --,ash.sql_id
       --,ash.xid
from v$active_session_history ash,
        all_objects o,
      dba_users u
where ( event like 'db file s%' or event like 'direct%' )
   and sample_time > sysdate - &minutes/(60*24)
   and session_state='WAITING'
   --and current_obj#=-1
   and (sql_id is null or sql_id ='')
      and o.object_id (+)= ash.CURRENT_OBJ#
   and u.user_id (+) = ash.user_id 
group by 
       --session_id,
       ash.current_obj# 
       ,o.object_name
       ,u.username
       ,ash.user_id
       --ash.p1, 
       --ash.p2 
       --,ash.sql_id
       --,ash.xid
Order by count(*)
/


