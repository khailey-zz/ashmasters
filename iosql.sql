



col block_type for a18
col obj for a20
col objn for 999999
col otype for a15
col event for a15
col blockn for 999999
col p1 for 9999
col tablespace_name for a15

col f_minutes new_value v_minutes
select &minutes f_minutes from dual;

break on sql_id on tcnt

select
       sum(cnt) over ( partition by io.sql_id order by sql_id ) tcnt,
       io.sql_id,
       io.cnt cnt,
       io.aas aas,
       --io.event event,
       io.objn objn,
       io.obj obj,
       io.p1 p1,
       f.tablespace_name tablespace_name
from 
(
  select
        sql_id,
        count(*) cnt,
        round(count(*)/(&v_minutes*60),2) aas,
        CURRENT_OBJ# objn,
        nvl(o.object_name,decode(CURRENT_OBJ#,-1,0,CURRENT_OBJ#)) obj,
        o.object_type otype,
        ash.p1
   from v$active_session_history ash
        ,all_objects o
   where ( event like 'db file s%' or event like 'direct%' )
      and o.object_id (+)= ash.CURRENT_OBJ#
      and sample_time > sysdate - &v_minutes/(60*24)
   group by 
       CURRENT_OBJ#, 
       o.object_name ,
       o.object_type ,
       ash.p1,
       sql_id
) io,
   dba_data_files f
where
   f.file_id = io.p1
Order by tcnt, io.sql_id, io.cnt
/


