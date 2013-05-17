


col p1 for a20
col p2 for a20
col p3 for a20
col name for a40
set linesize 120
select name,
         parameter1 p1, 
         parameter2 p2, 
         parameter3 p3
from v$event_name where name in (
'db file sequential read',
'db file scattered read',
'db file parallel read',
'read by other session',
'direct path read', 
'direct path write',
'direct path read temp',
'direct path write temp',
'direct path write (lob)'
)
;

