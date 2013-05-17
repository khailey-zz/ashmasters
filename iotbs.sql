col block_type for a18
col objn for a25
col otype for a15
col event for a25
col blockn for 999999
col p1 for 9999
col aas for 999.99
col f_minutes new_value v_minutes
select &minutes f_minutes from dual;
select io.cnt,
       round(io.cnt/(&v_minutes*60),2) aas, 
       io.event,
       io.p1 p1,
       f.tablespace_name
from (
       select
              count(*) cnt,
              substr(event,0,25) event,
              ash.p1 p1
       from v$active_session_history ash
       where ( event like 'db file s%' or event like 'direct%' )
          and sample_time > sysdate - &v_minutes/(60*24)
       group by 
            event , 
             ash.p1
      ) io,
      dba_data_files f
where
          f.file_id = io.p1
Order by io.cnt
/


