  README ashmasters
    see http://ashmasters.com for information on
    Oracle Active Session History (ASH)

queries contained in repository

* ash_graph_ash - basic ASH load chart in ASCII art
* ash_graph_ash_histash - ASH load chart from DBA_HIST_ACTIVE_SESS_HISTORY only
* ash_graph_histash_by_dbid - ASH load chart from DBA_HIST_ACTIVE_SESS_HISTORY only, input DBID
* ash_graph_histash_by_dbid_program - ASH load chart from DBA_HIST_ACTIVE_SESS_HISTORY only, input DBID and PROGRAM
* ash_graph_histash_by_dbid_sqlid - ASH load chart from DBA_HIST_ACTIVE_SESS_HISTORY only, input DBID and a SQL_ID
* ash_graph_histash_dbid 
* ash_sql_elapsed - use ASH to find longest running SQL
* ash_sql_elapsed_hist - use ASH to find longest running SQL, give histogram of execution times
* ash_sql_elapsed_hist_longestid - use ASH to find longest running SQL, give histogram of execution times and execution id of longest running query
* ash_sql_top - top SQL from ASH
* eventmetric_latency - wait event latency from V$EVENTMETRIC, ie last 60 seconds
* io_sizes - I/O sizes from ASH
* system_event_latency - wait event latency from DBA_HIST_SYSTEM_EVENT 
* waitclassmetric_latency - User I/O  latency from V$WAITCLASSMETRIC, ie  over last 60 seconds

