
col block_type for a18
col objn for a25
col otype for a15
col event for a15
col blockn for 999999
col segment_name for a20
col partition_name for a15
col owner for a15
set timing on
/*
drop table myextents;
l
create table myextents as select * from dba_extents;
l
select
       count(*),
       ext.owner,
       ext.segment_name,
       ext.partition_name,
       ext.segment_type
       --ash.p1, 
       --ash.p2
from v$active_session_history ash,
     myextents ext
where ( event like 'db file s%' or event like 'direct%' )
   and sample_time > sysdate - &minutes/(60*24)
   and session_state='WAITING'
   and ( current_obj# = -1 or current_obj#=0 )
   and  ext.file_id(+)=ash.p1 and
        ash.p2 between  ext.block_id and ext.block_id + ext.blocks
group by 
       ext.owner,
       ext.segment_name,
       ext.partition_name,
       ext.segment_type
       --ash.p1, 
       --ash.p2, 
       --ash.sql_id
Order by count(*)
*/


select
       count(*),
       ash.p1, 
       ash.p2
from v$active_session_history ash
where ( event like 'db file s%' or event like 'direct%' )
   and sample_time > sysdate - &minutes/(60*24)
   and session_state='WAITING'
   and ( current_obj# = -1 or current_obj#=0 )
group by 
       ash.p1, 
       ash.p2
Order by count(*)
/





