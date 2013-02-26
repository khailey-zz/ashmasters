
/*


Notice the 3rd row final  column, it's UNDO. 1/2 of the query data is coming from UNDO
Seeing sequential read waits on a full table scan that shoul normally
be scattered read waits is a good flag that it might be undo coming from
an uncommited transaction.

This query can help identify that

AAS SQL_ID        PCT OBJ          SUB_OBJ OTYPE      EVENT      F# TABLESPAC CONTENTS
---- ----------------- ----------- ------- ---------- ---------- -- --------- ---------
.00 f9u2k84v884y7  33 CUSTOMERS    SYS_P27 TABLE PART  sequentia  1 SYSTEM    PERMANENT     
                   33 ORDER_PK             INDEX       sequentia  4 USERS     PERMANENT
                   33                                  sequentia  2 UNDOTBS1  UNDO
.01 0tvtamt770hqz 100 TOTO1                TABLE       scattered  7 NO_ASSM   PERMANENT 
.06 75621g9y3xmvd   3 CUSTOMERS    SYS_P36 TABLE PART  sequentia  4 USERS     PERMANENT
                    3 CUSTOMERS    SYS_P25 TABLE PART  sequentia  4 USERS     PERMANENT
                    3 CUSTOMERS    SYS_P22 TABLE PART  sequentia  4 USERS     PERMANENT
                    3 CUSTOMERS    SYS_P29 TABLE PART  sequentia  4 USERS     PERMANENT
                    3 CUSTOMERS    SYS_P21 TABLE PART  sequentia  4 USERS     PERMANENT

 Version When        Who            What?
 ------- ----------- -------------- ----------------------------------------------------------------------------------------------
 1.0     Jan 19 2013 K. Hailey      First version
 1.0.1   Feb 26 2013 M. Krijgsman   Bug fix: removed tcnt from order by ;)

*/


col tcnt for 9999
col aas for 999.99
col sql_id for a14
col cnt for 999
col pct for 999
col obj for a20
col sub_obj for a10
col otype for a15
col event for a15
col file# for 9999
col tablespace_name for a15

col f_minutes new_value v_minutes
select &minutes f_minutes from dual;

break on sql_id on aas on tcnt

select
       -- sum(cnt) over ( partition by io.sql_id order by sql_id ) tcnt,
       round(sum(cnt) over ( partition by io.sql_id order by sql_id ) / (&v_minutes*60),2) aas,
       io.sql_id,
       -- io.cnt cnt,
       100*cnt/sum(cnt) over ( partition by io.sql_id order by sql_id ) pct,
       --CURRENT_OBJ#  obj#,
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
       --o.object_name ,
       --o.object_type ,
       ash.p1,
       sql_id
)   io
  , dba_data_files f
  , all_objects o
  , dba_tablespaces tbs
where
   f.file_id = io.p1
   and o.object_id (+)= io.CURRENT_OBJ#
   and tbs.tablespace_name= f.tablespace_name 
Order by /* tcnt */, sql_id, cnt
/

clear breaks


