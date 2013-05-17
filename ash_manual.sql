col  ASH_DATE for 999999999999
col SID_SERIAL for A10
col USERNAME	for A15	       
col SQL_ID	     for a14
col SQL_ID_CHILD  for a14
col TYPE for a10
col EVENT for A25
col EVENT2 for A25
col CLASS for A15

 select
      (cast(sysdate as date)-to_date('01-JAN-1970','DD-MON-YYYY'))*(86400)  ash_date,
         concat(s.sid,concat('_',s.serial#))  sid_serial,
         decode(type,'BACKGROUND',substr(program,-5,4),u.username)  username,
      --   s.sql_id sql_id,
      --  sql_plan_hash_value is not in v$session but in x$ksusea KSUSESPH
      --   s.SQL_CHILD_NUMBER  sql_id_child,
         s.type type,
       decode(s.WAIT_TIME,0,replace(s.event,' ','_') , 'ON CPU') event ,
       s.event event2,
       decode(s.WAIT_TIME,0,replace(s.wait_class,' ','_') , 'CPU' ) class
      from
             v$session s,
             all_users u
      where
        u.user_id=s.user# and
        s.sid != ( select distinct sid from v$mystat  where rownum < 2 ) and
            (  ( s.wait_time != 0  and  /* on CPU  */ s.status='ACTIVE'  /* ACTIVE */)
                 or
                ( s.wait_class  != 'Idle' and s.wait_time != 0 )
            )
/



/*
 select
      (cast(sysdate as date)-to_date('01-JAN-1970','DD-MON-YYYY'))*(86400) ||','||
         1  ||','||
         concat(s.sid,concat('_',s.serial#))  ||','||
         decode(type,'BACKGROUND',substr(program,-5,4),u.username)  ||','||
         s.sql_id ||','||
      --  sql_plan_hash_value is not in v$session but in x$ksusea KSUSESPH
         s.SQL_CHILD_NUMBER ||','||
         s.type ||','||
       decode(s.WAIT_TIME,0,replace(s.event,' ','_') , 'ON CPU') ||','||
       decode(s.WAIT_TIME,0,replace(s.wait_class,' ','_') , 'CPU' )
      from
             v$session s,
             all_users u
      where
        u.user_id=s.user# and
        s.sid != ( select distinct sid from v$mystat  where rownum < 2 ) and
             (  ( s.wait_time != 0  and  s.status='ACTIVE'  )
                 or
               s.wait_class  != 'Idle'
            )
*/

--            (  ( s.wait_time != 0  and  /* on CPU  */ s.status='ACTIVE'  /* ACTIVE */)
