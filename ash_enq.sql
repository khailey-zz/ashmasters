COL lock_name FORMAT A30 
COL waiter format 99999 HEADING "Waiter"
COl lmode FORMAT 99 HEADING "Lock|mode"
COL p2 FORMAT 9999999
COL p3 FORMAT 9999999
COL object FORMAT A30
COL otype FORMAT A7
COL filen FORMAT 9999
COL blocker FORMAT 99999

SET LINESIZE 200


select
       substr(event,0,20)                  lock_name,
       ash.session_id                      waiter,
       mod(ash.p1,16)                     lmode,
       ash.p2                                   p2,
       ash.p3                                   p3,
       o.object_name                      object,
       o.object_type                        otype,
       CURRENT_FILE#                filen,
       CURRENT_BLOCK#           blockn,
       ash.SQL_ID                          waiting_sql,
       BLOCKING_SESSION         blocker
       --,ash.xid
from
         v$active_session_history ash,
         all_objects o
where
           event like 'enq: %'
   and o.object_id (+)= ash.CURRENT_OBJ#
/

