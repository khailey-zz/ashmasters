
select
       ash.SQL_ID,
       QC_SESSION_ID qsid,
       count(*) cnt,
       count (distinct session_id) deg,
       nvl(o.object_name,to_char(CURRENT_OBJ#))  obj,
       o.object_type otype,
       decode(session_state, 'WAITING',event,'CPU') event
from   v$active_session_history ash,
        all_objects o
where  o.object_id (+)= ash.CURRENT_OBJ#
   and qc_session_id is not null
group by qc_session_id, sql_id, o.object_name,
         o.object_type, CURRENT_OBJ#, event, session_state
Order by qc_session_id, sql_id

