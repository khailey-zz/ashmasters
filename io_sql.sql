col AAS      for  99.999
col SQL_ID   for  A13
col CNT	     for  9999
col PCT      for  999
col OBJ      for  A20
col SUB_OBJ  for  A10
col OTYPE    for  A10
col EVENT    for  A10
col FILE#    for  999
col TABLESPACE_NAME  for A15
col CONTENTS for A15

break on sql_id on aas

col f_minutes new_value v_minutes
select &minutes f_minutes from dual;
--select &v_minutes from dual;

select
       round(sum(cnt) over ( partition by io.sql_id order by sql_id ) / (&v_minutes*60),2) aas,
       io.sql_id,
       io.cnt cnt,
       100*cnt/sum(cnt) over ( partition by io.sql_id order by sql_id ) pct,
       o.object_name obj,
       o.subobject_name sub_obj,
       o.object_type otype,
       substr(io.event,8,10) event,
       io.p1 file#,
       f.tablespace_name tablespace_name,
       tbs.contents
from 
(
  select
        sql_id,
	event,
        count(*) cnt,
        count(*) / (&v_minutes*60) aas,
        CURRENT_OBJ# ,
        ash.p1
   from v$active_session_history ash
   where ( event like 'db file s%' or event like 'direct%' )
      and sample_time > sysdate - &v_minutes/(60*24)
   group by 
       CURRENT_OBJ#, 
       event,
       ash.p1,
       sql_id
) io,
   dba_data_files f
   ,all_objects o
   , dba_tablespaces tbs
where
   f.file_id = io.p1
   and o.object_id (+)= io.CURRENT_OBJ#
   and tbs.tablespace_name= f.tablespace_name 
Order by aas, sql_id, cnt
/

