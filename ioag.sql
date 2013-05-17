col block_type for a18
col obj for a20
col otype for a15
col event for a15
col blockn for 999999
col f_minutes new_value v_minutes
col p1 for 9999
col tablespace_name for a15
col aas for 99.999
select &minutes f_minutes from dual;
select
       io.cnt cnt,
       io.aas aas,
       io.event event,
       substr(io.obj,1,20) obj,
       io.p1 p1,
       f.tablespace_name tablespace_name
from 
(
  select
        count(*) cnt,
        round(count(*)/(&v_minutes*60),2) aas,
        substr(event,0,15) event, 
        nvl(o.object_name,decode(CURRENT_OBJ#,-1,0,CURRENT_OBJ#)) obj,
        ash.p1, 
        o.object_type otype
   from v$active_session_history ash,
        all_objects o
   where ( event like 'db file s%' or event like 'direct%' )
      and o.object_id (+)= ash.CURRENT_OBJ#
      and sample_time > sysdate - &v_minutes/(60*24)
   group by 
       substr(event,0,15) , 
       CURRENT_OBJ#, o.object_name ,
       o.object_type ,
       ash.p1
) io,
  dba_data_files f
where
   f.file_id = io.p1
Order by io.cnt
/
