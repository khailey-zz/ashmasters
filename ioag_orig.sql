


col block_type for a18
col objn for a35
col otype for a15
col event for a15
col blockn for 999999
/*
*/
select cnt,
       --event,
       round(cnt/nullif(((
	      to_date(beg,'DD/MM/YY HH24:MI:SS')-
	      to_date(end,'DD/MM/YY HH24:MI:SS'))*24*60*60),0)
	 ,2) aas,
       objn,
       otype
from (
select
       count(*) cnt,
       to_char(nvl(min(sample_time),sysdate),'DD/MM/YY HH24:MI:SS') end,
       to_char(nvl(max(sample_time),sysdate),'DD/MM/YY HH24:MI:SS') beg,
       substr(event,0,15) event, 
       CURRENT_OBJ#||' '||o.object_name objn,
       o.object_type otype
from v$active_session_history ash,
      all_objects o
where ( event like 'db file s%' or event like 'direct%' )
   and o.object_id (+)= ash.CURRENT_OBJ#
   and sample_time > sysdate - &minutes/(60*24)
group by 
       substr(event,0,15) , 
       CURRENT_OBJ#, o.object_name ,
       o.object_type 
)
Order by cnt 
/


