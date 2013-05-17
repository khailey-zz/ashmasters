

select current_obj#, sum(greatest(1,1/time_waited)) as estimated_io_requests,
                     sum(greatest(1,time_waited)) as estimated_wait_time
from v$active_session_history
where  time_waited > 0
and event='db file sequential read'
group by current_obj#
order by 3 desc
/ 

select current_obj#, 10*sum(greatest(1,1/time_waited)) as estimated_io_requests,
                     10*sum(greatest(1,time_waited)) as estimated_wait_time,
                     sum(greatest(1,time_waited))/
                       sum(greatest(1,1/time_waited)) avg,
                     avg(time_waited),
                     max(time_waited), 
                     min(time_waited)
from dba_hist_active_sess_history
where  time_waited > 0
and event='db file sequential read'
group by current_obj#
order by 3 desc
/ 

select current_obj#, 10*sum(greatest(1,1/time_waited)) as estimated_io_requests,
                     avg(greatest(1,time_waited)) as estimated_wait_time, 
from dba_hist_active_sess_history
where  time_waited > 0
and event='db file sequential read'
group by current_obj#
order by 3 desc
/ 

