    see http://ashmasters.com for information on
    Oracle Active Session History (ASH)

queries contained in repository

* ash_bbw.sql - buffer busy wait analysis
* ash_enq.sql - enqueue wait analays
* ash_graph_ash.sql - basic ASH load chart in ASCII art
* ash_graph_ash_histash.sql - ASH load chart from DBA_HIST_ACTIVE_SESS_HISTORY only
* ash_graph_histash_by_dbid.sql - ASH load chart from DBA_HIST_ACTIVE_SESS_HISTORY only, input DBID
* ash_graph_histash_by_dbid_program.sql - ASH load chart from DBA_HIST_ACTIVE_SESS_HISTORY only, input DBID and PROGRAM
* ash_graph_histash_by_dbid_sqlid.sql - ASH load chart from DBA_HIST_ACTIVE_SESS_HISTORY only, input DBID and a SQL_ID
* ash_io_sizes.sql - I/O sizes from ASH
* ash_sql_elapsed.sql - use ASH to find longest running SQL
* ash_sql_elapsed_hist.sql - use ASH to find longest running SQL, give histogram of execution times
* ash_sql_elapsed_hist_longestid.sql - use ASH to find longest running SQL, give histogram of execution times and execution id of longest running query
* ash_top_procedure.sql - top procedures and who they call
* ash_top_session.sql - top SESSION from ASH ordered by time broke into wait, I/O and CPU time
* ash_top_sql.sql - top SQL from ASH ordered by time broke into wait, I/O and CPU time
* ash_top_sql_w_top_obj.sql - top SQL from ASH ordered by time broke into wait, I/O and CPU time, include top object for I/O waits
* latency_eventmetric.sql - wait event latency from V$EVENTMETRIC, ie last 60 seconds
* latency_system_event.sql - wait event latency from DBA_HIST_SYSTEM_EVENT 
* latency_waitclassmetric.sql - User I/O  latency from V$WAITCLASSMETRIC, ie  over last 60 seconds


