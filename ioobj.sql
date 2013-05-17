
col block_type for a18
col objn for a25
col otype for a15
col event for a15
col blockn for 999999
col tablespace_name for a15
select &minutes f_minutes from dual;
select
       count(*) cnt,
       round(count(*)/(&v_minutes*60),2) aas,
       CURRENT_OBJ#||' '||o.object_name objn,
       o.object_type otype
from v$active_session_history ash,
      all_objects o
where ( event like 'db file s%' or event like 'direct%' )
   and o.object_id (+)= ash.CURRENT_OBJ#
   and sample_time > sysdate - &v_minutes/(60*24)
   and session_state='WAITING'
group by 
       CURRENT_OBJ#, o.object_name ,
       o.object_type 
Order by count(*)
/


