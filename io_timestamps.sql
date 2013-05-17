



col block_type for a18
col objn for a25
col otype for a15
col event for a15
col blockn for 999999
col aas for 999999
col delta for a15
col delta for 999.9999
col mnt for a17
col mxt for a17
col cnt for 99999
/*
*/
select
       count(*) cnt,
       cast(max(sample_time) as date) - cast(min(sample_time) as date) delta, 
       to_char(cast(min(sample_time) as date),'DD/YY/MM HH24:mi:ss') mnt, 
       to_char(cast(max(sample_time) as date),'DD/YY/MM HH24:mi:ss') mxt,
       substr(event,0,15) event, 
       CURRENT_OBJ#||' '||o.object_name objn,
       o.object_type otype
from v$active_session_history ash,
      all_objects o
where ( event like 'db file s%' or event like 'direct%' )
      and o.object_id (+)= ash.CURRENT_OBJ#
   --and sample_time > sysdate - &minutes/(60*24)
   --and rownum < 10
group by 
       substr(event,0,15) , 
       CURRENT_OBJ#, o.object_name ,
       o.object_type 
Order by cnt 
/

