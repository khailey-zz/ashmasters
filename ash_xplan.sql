/**********************************************************************
 * File:        ash_xplan.sql
 * Type:        SQL*Plus script containing DDL
 * Author:      Tim Gorman (Evergreen Database Technologies, Inc.)
 * Date:        22-NOV-2013
 *
 * Description:
 *      SQL*Plus script to create a PL/SQL package named ASH_XPLAN
 *      which augments the information provided by the DISPLAY_CURSOR
 *      procedure in the built-in DBMS_XPLAN package.
 *
 *      ASH_XPLAN queries the GV$ACTIVE_SESSION_HISTORY view to obtain
 *      information summarized by SQL_PLAN_LINE_ID, specifically to
 *      obtain the "ASH Time" spent at each line of the execution plan.
 *
 * Note:
 *	I have not yet had the opportunity to test this script in an
 *	Oracle RAC environment just yet.
 *
 * Modifications:
 *********************************************************************/
set echo on feedback on timing on
spool ash_xplan

REM 
REM Create package header for ASH_XPLAN...
REM 
create or replace package ash_xplan
as
	function display_cursor(in_sql_id		in varchar2	default NULL,
				in_cursor_child_no	in number	default 0,
				in_format		in varchar2	default 'TYPICAL')
		return sys.dbms_xplan_type_table
		pipelined;
end ash_xplan;
/
show errors

REM 
REM Create package body for ASH_XPLAN...
REM 
create or replace package body ash_xplan
as
	--
	/* 
	 * Internal type definition for use within functions and procedures...
	 */
	type t_int		is table of integer;
	g_printout_bool		boolean;
	--
	/* 
	 * Internal function IS_NONZERO_ELEMENTS to return TRUE if the collection contains non-null, non-zero values...
	 */
	function is_nonzero_elements(in_a in t_int) return boolean
	is
	begin
		--
		for i in in_a.first..in_a.last loop
			--
			if nvl(in_a(i), 0) <> 0 then
				return(TRUE);
			end if;
			--
		end loop;
		--
		return(FALSE);
		--
	end is_nonzero_elements;
	--
	/* 
	 * Internal function FMT_NBR to display all number in 8-chars or less...
	 */
	function fmt_nbr(in_n in number, in_mult in integer) return varchar2
	is
		v_rtn		varchar2(32);
	begin
		--
		if in_n is null or in_n = 0 then return(' ');
		end if;
		--
		if    in_n >= power(in_mult,8) then v_rtn := to_char(round(in_n/power(in_mult,8),2), 'TM9')||'Z';
		elsif in_n >= power(in_mult,7) then v_rtn := to_char(round(in_n/power(in_mult,7),2), 'TM9')||'Y';
		elsif in_n >= power(in_mult,6) then v_rtn := to_char(round(in_n/power(in_mult,6),2), 'TM9')||'X';
		elsif in_n >= power(in_mult,5) then v_rtn := to_char(round(in_n/power(in_mult,5),2), 'TM9')||'P';
		elsif in_n >= power(in_mult,4) then v_rtn := to_char(round(in_n/power(in_mult,4),2), 'TM9')||'T';
		elsif in_n >= power(in_mult,3) then v_rtn := to_char(round(in_n/power(in_mult,3),2), 'TM9')||'G';
		elsif in_n >= power(in_mult,2) then v_rtn := to_char(round(in_n/power(in_mult,2),2), 'TM9')||'M';
		elsif in_n >= in_mult then          v_rtn := to_char(round(in_n/in_mult,2), 'TM9')||'K';
		else                                v_rtn := to_char(in_n, 'TM9');
		end if;
		--
		if in_mult = 1024 then		return(v_rtn);
		elsif in_mult = 1000 then	return(lower(v_rtn));
		else	raise_application_error(-20000,'Parameter IN_MULT can only be 1024 or 1000');
		end if;
		--
	end fmt_nbr;
	--
	/* 
	 * Internal proecdure DISPLAY_MODIFIED_XPLAN to display output from DBMS_XPLAN with additional information prepended...
	 */
	function display_modified_xplan(in_label in varchar2,
					in_a_line_id in t_int,
					in_a_int in t_int,
					in_mult in number,
					in_str in varchar2,
					inout_amend_bool in out boolean,
					out_str out varchar2) return boolean
	is
		v_line_id		gv$active_session_history.sql_plan_line_id%type;
		v_nbr			number := to_number(null);
	begin
		--
		if in_str like 'Plan hash value: %' then
			--
			inout_amend_bool := TRUE;
			g_printout_bool := TRUE;
			--
		elsif in_str like 'Query Block Name / Object Alias %' or
		      in_str like 'Predicate Information %' then
			--
			inout_amend_bool := FALSE;
			--
		end if;
		--
		if inout_amend_bool = TRUE then
			--
			if in_str like '----------%----------' then
				--
				out_str := lpad('-',10,'-')||in_str;
				--
			elsif in_str like '|%Id%|%Name%|' then
				--
				out_str := '|'||rpad(in_label,9,' ')||in_str;
				--
			elsif in_str like '|%|' then
				--
				v_line_id := to_number(replace(replace(substr(in_str,2,4),'*',''),' ',''));
				--
				for i in in_a_line_id.first..in_a_line_id.last loop
					--
					if v_line_id = in_a_line_id(i) then
						--
						v_nbr := in_a_int(i);
						--
					end if;
					--
				end loop;
				--
				out_str := '|'||lpad(case when nvl(v_nbr, 0) = 0 then ' ' else fmt_nbr(v_nbr,in_mult) end,8,' ')||' '||in_str;
				--
			else
				--
				out_str := in_str;
				--
			end if;
			--
		else
			--
			out_str := in_str;
			--
		end if;
		--
		return(g_printout_bool);
		--
	end display_modified_xplan;
	--
	/* 
	 * Create function DISPLAY_CURSOR to mimic the same function in the built-in DBMS_XPLAN package...
	 */
	function display_cursor(in_sql_id		in varchar2	default NULL,
				in_cursor_child_no	in number	default 0,
				in_format		in varchar2	default 'TYPICAL')
		return sys.dbms_xplan_type_table
		pipelined
	is
		--
		cursor get_sql_execs(p_sql_id in varchar2, p_child in number)
		is
		select   sql_exec_id,
			 sql_exec_start,
			 to_char(min(sample_time), 'DD-MON-YYYY HH24:MI:SS') started_at,
			 to_char(max(sample_time), 'DD-MON-YYYY HH24:MI:SS') last_seen,
			 (max(sample_time) - min(sample_time)) elapsed,
			 (systimestamp - max(sample_time)) since_it_finished
		from	 gv$active_session_history
		where	 sql_id = p_sql_id
		and	 sql_child_number = p_child
		group by sql_exec_id,
			 sql_exec_start
		order by sql_exec_start nulls first;
		--
		cursor get_events(p_sql_id in varchar2, p_child in number)
		is
		select	decode(x.qcsid,null,null,x.qcinst_id||'@'||x.qcsid||','||nvl(x.qcserial#,x.serial#)) qcsid,
			s.inst_id||'@'||s.sid||','||s.serial# sid,
			case when nvl(x.qcsid, x.sid) = x.sid
			      and nvl(x.qcserial#, x.serial#) = x.serial#
			      and nvl(x.qcinst_id, x.inst_id) = x.inst_id
			     then 'QC'
			     else 'WORKER'
			end type,
			e.event, e.time_waited/100 time_waited, e.total_waits,
			e.average_wait/100 avg_wait, e.max_wait/100 max_wait
		from	gv$session s,
			gv$px_session x,
			gv$session_event e
		where	s.sql_id = p_sql_id
		and	s.sql_child_number = p_child
		and	x.inst_id (+) = s.inst_id
		and	x.sid (+) = s.sid
		and	x.serial# (+) = s.serial#
		and	e.inst_id = s.inst_id
		and	e.sid = s.sid
		order by 1, 2, 3, 5 desc;
		--
		a_ash_line		t_int;
		a_ash_secs		t_int;
		a_mon_line		t_int;
		a_mon_last_secs		t_int;
		a_mon_a_rows		t_int;
		a_mon_pread		t_int;
		a_mon_pwrite		t_int;
		a_mon_pga_mem		t_int;
		a_mon_temp_spc		t_int;
		rtn			sys.dbms_xplan_type := sys.dbms_xplan_type(null);
		v_amend_bool		boolean;
		v_sql_exec_id		gv$active_session_history.sql_exec_id%type;
		v_sql_exec_start	gv$active_session_history.sql_exec_start%type;
		v_line_id		gv$active_session_history.sql_plan_line_id%type;
		v_ashtime		integer;
		v_lines			integer;
		v_min_all_time		gv$active_session_history.sample_time%type;
		v_min_sql_time		gv$active_session_history.sample_time%type;
		v_all_secs		integer;
		v_sql_secs		integer;
		v_last_secs		integer;
		v_a_rows		integer;
		v_pread			integer;
		v_pwrite		integer;
		v_pga_mem		integer;
		v_temp_spc		integer;
		--
	begin
		--
		/* 
		 * ...capture ASH sample "horizon" information...
		 */
		select	min(sample_time),
			((extract(day from (systimestamp - min(sample_time)))*86400)+
			 (extract(hour from (systimestamp - min(sample_time)))*3600)+
			 (extract(minute from (systimestamp - min(sample_time)))*60)+
			  extract(second from (systimestamp - min(sample_time)))),
			min(case when sql_id = in_sql_id and sql_child_number = in_cursor_child_no then sample_time else null end),
			((extract(day from (systimestamp - min(case when sql_id = in_sql_id and sql_child_number = in_cursor_child_no
								    then sample_time else null end)))*86400)+
			 (extract(hour from (systimestamp - min(case when sql_id = in_sql_id and sql_child_number = in_cursor_child_no
								     then sample_time else null end)))*3600)+
			 (extract(minute from (systimestamp - min(case when sql_id = in_sql_id and sql_child_number = in_cursor_child_no
								       then sample_time else null end)))*60)+
			  extract(second from (systimestamp - min(case when sql_id = in_sql_id and sql_child_number = in_cursor_child_no
								       then sample_time else null end))))
		into	v_min_all_time,
			v_all_secs,
			v_min_sql_time,
			v_sql_secs
		from	gv$active_session_history;
		--
		/* 
		 * ...display a "text box" with information about SQL executions captured within ASH running this SQL child cursor...
		 */
		v_lines := 0;
		v_sql_exec_id := null;
		v_sql_exec_start := null;
		for x in get_sql_execs(in_sql_id, in_cursor_child_no) loop
			--
			v_sql_exec_id := x.sql_exec_id;
			v_sql_exec_start := x.sql_exec_start;
			v_lines := v_lines + 1;
			--
			if v_lines = 1 then
				--
				rtn.plan_table_output := null;
				pipe row (rtn);
				rtn.plan_table_output := 'Current datetime:                       '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS');
				pipe row (rtn);
				--
				rtn.plan_table_output := rpad('-',14,'-')|| /* sql_exec_id */
							 rpad('-',23,'-')|| /* sql_exec_start */
							 rpad('-',23,'-')|| /* started_at */
							 rpad('-',23,'-')|| /* last_seen */
							 rpad('-',26,'-')|| /* elapsed */
							 rpad('-',30,'-');  /* since_it_finished */
				pipe row (rtn);
				rtn.plan_table_output := '|'||rpad(' SQL Exec ID',13,' ')|| /* sql_exec_id */
							 '|'||rpad(' SQL started At',22,' ')|| /* sql started_at */
							 '|'||rpad(' Session Started At',22,' ')|| /* sess started_at */
							 '|'||rpad(' Session Last Seen',22,' ')|| /* sess last_seen */
							 '|'||rpad(' Elapsed',25,' ')|| /* elapsed */
							 '|'||rpad(' Since It Finished',28,' ')||'|';  /* since_it_finished */
				pipe row (rtn);
				rtn.plan_table_output := rpad('-',14,'-')|| /* sql_exec_id */
							 rpad('-',23,'-')|| /* SQL started_at */
							 rpad('-',23,'-')|| /* Sess started_at */
							 rpad('-',23,'-')|| /* Sess last_seen */
							 rpad('-',26,'-')|| /* elapsed */
							 rpad('-',30,'-');  /* since_it_finished */
				pipe row (rtn);
				--
			end if;
			--
			rtn.plan_table_output := '|'||rpad(' '||x.sql_exec_id,13,' ')|| /* sql_exec_id */
						 '|'||rpad(' '||x.sql_exec_start,22,' ')|| /* sql_started_at */
						 '|'||rpad(' '||x.started_at,22,' ')|| /* session started_at */
						 '|'||rpad(' '||x.last_seen,22,' ')|| /* session last_seen */
						 '|'||rpad(' '||x.elapsed,25,' ')|| /* elapsed */
						 '|'||rpad(' '||x.since_it_finished,28,' ')||'|';  /* since_it_finished */
			pipe row (rtn);
			--
		end loop;
		--
		if v_lines > 0 then
			--
			rtn.plan_table_output := rpad('-',14,'-')|| /* SQL exec_id */
						 rpad('-',23,'-')|| /* SQL started_at */
						 rpad('-',23,'-')|| /* Sess started_at */
						 rpad('-',23,'-')|| /* Sess last_seen */
						 rpad('-',26,'-')|| /* elapsed */
						 rpad('-',30,'-');  /* since_it_finished */
			pipe row (rtn);
			--
		end if;
		--
		if v_lines = 0 or v_sql_exec_id is null or v_sql_exec_start is null then
			--
			raise_application_error(-20000, 'No executions for SQL_ID="'||in_sql_id||
				'", child='||in_cursor_child_no||' found in GV$ACTIVE_SESSION_HISTORY');
		end if;
		--
		/* 
		 * ...retrieve "ASHtime" information from GV$ASH...
		 */
		select			sql_plan_line_id, count(*) cnt
		bulk collect into	a_ash_line, a_ash_secs
		from			gv$active_session_history
		where			sql_id = in_sql_id
		and			sql_child_number = in_cursor_child_no
		and			sql_exec_id = v_sql_exec_id
		and			sql_exec_start = v_sql_exec_start
		group by		sql_plan_line_id
		order by		sql_plan_line_id;
		--
		/* 
		 * ...retrieve monitoring information from GV$SQL_PLAN_MONITOR...
		 */
		select			plan_line_id, (sysdate-last_change_time)*86400, output_rows,
					physical_read_bytes, physical_write_bytes,
					workarea_mem, workarea_tempseg
		bulk collect into	a_mon_line, a_mon_last_secs, a_mon_a_rows,
					a_mon_pread, a_mon_pwrite,
					a_mon_pga_mem, a_mon_temp_spc
		from			gv$sql_plan_monitor
		where			sql_id = in_sql_id
		and			sql_exec_id = v_sql_exec_id
		and			sql_exec_start = v_sql_exec_start
		order by		plan_line_id;
		--
		rtn.plan_table_output := NULL;
		pipe row (rtn);
		--
		/* 
		 * ...prepend ASHtime information to the "text box" returned by DBMS_XPLAN.DISPLAY_CURSOR...
		 */
		if is_nonzero_elements(a_ash_secs) = TRUE then
			--
			v_amend_bool := FALSE;
			g_printout_bool := FALSE;
			for x in (select plan_table_output
				  from   table(dbms_xplan.display_cursor(sql_id=>in_sql_id,
									 cursor_child_no=>in_cursor_child_no,
									 format=>in_format))) loop
				--
				if display_modified_xplan(' ASHtime ', a_ash_line, a_ash_secs, 1000, x.plan_table_output, v_amend_bool, rtn.plan_table_output) = TRUE then
					pipe row(rtn);
				end if;
				--
				if v_amend_bool = TRUE and x.plan_table_output like 'Plan hash value: %' then
					--
					rtn.plan_table_output := 'Current datetime:                       '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS');
					pipe row (rtn);
					rtn.plan_table_output := 'Min ASH Sample Time:                    '||to_char(v_min_all_time,'DD-MON-YYYY HH24:MI:SS')||' ('||
							(systimestamp-v_min_all_time)||' elapsed since)';
					pipe row (rtn);
					rtn.plan_table_output := 'Min ASH Sample Time for this SQL child: '||to_char(v_min_sql_time,'DD-MON-YYYY HH24:MI:SS')||' ('||
							(systimestamp-v_min_sql_time)||' elapsed since)';
					pipe row (rtn);
					--
					if round((v_sql_secs / v_all_secs)*100,0) >= 90 /* SQL running for more than 90% of the ASH horizon */ then
						--
						rtn.plan_table_output := '>>> WARNING: history for this SQL child cursor may be longer than the horizon of ASH sampling <<<';
						pipe row (rtn);
						rtn.plan_table_output := '>>> WARNING: do not expect the "ASHtime" values to be accurate as some ASH data has been lost <<<';
						pipe row (rtn);
						--
					end if;
					--
				end if;
				--
			end loop;
			--
		end if;
		--
		/* 
		 * ...prepend last-active-time information from V$SQL_PLAN_MONITOR to the "text box" returned by DBMS_XPLAN.DISPLAY_CURSOR...
		 */
		if is_nonzero_elements(a_mon_last_secs) = TRUE then
			--
			v_amend_bool := FALSE;
			g_printout_bool := FALSE;
			for x in (select plan_table_output
				  from   table(dbms_xplan.display_cursor(sql_id=>in_sql_id,
									 cursor_child_no=>in_cursor_child_no,
									 format=>in_format))) loop
				--
				if display_modified_xplan(' LastAct ', a_mon_line, a_mon_last_secs, 1000, x.plan_table_output, v_amend_bool, rtn.plan_table_output) = TRUE then
					pipe row(rtn);
				end if;
				--
			end loop;
			--
		end if;
		--
		/* 
		 * ...prepend rows-retrieved information from V$SQL_PLAN_MONITOR to the "text box" returned by DBMS_XPLAN.DISPLAY_CURSOR...
		 */
		if is_nonzero_elements(a_mon_a_rows) = TRUE then
			--
			v_amend_bool := FALSE;
			g_printout_bool := FALSE;
			for x in (select plan_table_output
				  from   table(dbms_xplan.display_cursor(sql_id=>in_sql_id,
									 cursor_child_no=>in_cursor_child_no,
									 format=>in_format))) loop
				--
				if display_modified_xplan(' RowsRtn ', a_mon_line, a_mon_a_rows, 1000, x.plan_table_output, v_amend_bool, rtn.plan_table_output) = TRUE then
					pipe row(rtn);
				end if;
				--
			end loop;
			--
		end if;
		--
		/* 
		 * ...prepend physical-read information from V$SQL_PLAN_MONITOR to the "text box" returned by DBMS_XPLAN.DISPLAY_CURSOR...
		 */
		if is_nonzero_elements(a_mon_pread) = TRUE then
			--
			v_amend_bool := FALSE;
			g_printout_bool := FALSE;
			for x in (select plan_table_output
				  from   table(dbms_xplan.display_cursor(sql_id=>in_sql_id,
									 cursor_child_no=>in_cursor_child_no,
									 format=>in_format))) loop
				--
				if display_modified_xplan(' PhyRead ', a_mon_line, a_mon_pread, 1024, x.plan_table_output, v_amend_bool, rtn.plan_table_output) = TRUE then
					pipe row(rtn);
				end if;
				--
			end loop;
			--
		end if;
		--
		/* 
		 * ...prepend physical-write information from V$SQL_PLAN_MONITOR to the "text box" returned by DBMS_XPLAN.DISPLAY_CURSOR...
		 */
		if is_nonzero_elements(a_mon_pwrite) = TRUE then
			--
			v_amend_bool := FALSE;
			g_printout_bool := FALSE;
			for x in (select plan_table_output
				  from   table(dbms_xplan.display_cursor(sql_id=>in_sql_id,
									 cursor_child_no=>in_cursor_child_no,
									 format=>in_format))) loop
				--
				if display_modified_xplan(' PhyWrt  ', a_mon_line, a_mon_pwrite, 1024, x.plan_table_output, v_amend_bool, rtn.plan_table_output) = TRUE then
					pipe row(rtn);
				end if;
				--
			end loop;
			--
		end if;
		--
		/* 
		 * ...prepend PGA memory information from V$SQL_PLAN_MONITOR to the "text box" returned by DBMS_XPLAN.DISPLAY_CURSOR...
		 */
		if is_nonzero_elements(a_mon_pga_mem) = TRUE then
			--
			v_amend_bool := FALSE;
			g_printout_bool := FALSE;
			for x in (select plan_table_output
				  from   table(dbms_xplan.display_cursor(sql_id=>in_sql_id,
									 cursor_child_no=>in_cursor_child_no,
									 format=>in_format))) loop
				--
				if display_modified_xplan(' PGA Mem ', a_mon_line, a_mon_pga_mem, 1024, x.plan_table_output, v_amend_bool, rtn.plan_table_output) = TRUE then
					pipe row(rtn);
				end if;
				--
			end loop;
			--
		end if;
		--
		/* 
		 * ...prepend PGA spill to temporary tablespace information from V$SQL_PLAN_MONITOR to the "text box" returned by DBMS_XPLAN.DISPLAY_CURSOR...
		 */
		if is_nonzero_elements(a_mon_temp_spc) = TRUE then
			--
			v_amend_bool := FALSE;
			g_printout_bool := FALSE;
			for x in (select plan_table_output
				  from   table(dbms_xplan.display_cursor(sql_id=>in_sql_id,
									 cursor_child_no=>in_cursor_child_no,
									 format=>in_format))) loop
				--
				if display_modified_xplan(' Pga2Tmp ', a_mon_line, a_mon_temp_spc, 1024, x.plan_table_output, v_amend_bool, rtn.plan_table_output) = TRUE then
					pipe row(rtn);
				end if;
				--
			end loop;
			--
		end if;
		--
		/*
		 * ...display session-wait information enclosed in a "text box"...
		 */
		v_lines := 0;
		for x in get_events(in_sql_id, in_cursor_child_no) loop
			--
			v_lines := v_lines + 1;
			--
			/* 
			 * ...display the headers and open the "text box" for the session-wait information...
			 */
			if v_lines = 1 then
				--
				rtn.plan_table_output := lpad(' ',50,' ')||'Session-level wait-event information';
				pipe row (rtn);
				rtn.plan_table_output := rpad('-',15,'-')|| /* qcsid */
							 rpad('-',15,'-')|| /* sid */
							 rpad('-',8,'-')|| /* type */
							 rpad('-',30,'-')|| /* event */
							 rpad('-',18,'-')|| /* time_waited */
							 rpad('-',15,'-')|| /* total_waits */
							 rpad('-',15,'-')|| /* avg_wait */
							 rpad('-',15,'-');  /* max_wait */
				pipe row (rtn);
				rtn.plan_table_output := '|'||rpad(' QCSID',14,' ')|| /* qcsid */
							 '|'||rpad(' SID',14,' ')|| /* sid */
							 '|'||rpad(' Type',7,' ')|| /* type */
							 '|'||rpad(' Event Name',29,' ')|| /* Event */
							 '|'||rpad(' Time Waited (s)',17,' ')|| /* time_waited */
							 '|'||rpad(' Total Waits',14,' ')|| /* total_waits */
							 '|'||rpad(' Avg Wait (s)',14,' ')|| /* avg_wait */
							 '|'||rpad(' Max Wait (s)',13,' ')||'|';  /* max_wait */
				pipe row (rtn);
				rtn.plan_table_output := rpad('-',15,'-')|| /* qcsid */
							 rpad('-',15,'-')|| /* sid */
							 rpad('-',8,'-')|| /* type */
							 rpad('-',30,'-')|| /* event */
							 rpad('-',18,'-')|| /* time_waited */
							 rpad('-',15,'-')|| /* total_waits */
							 rpad('-',15,'-')|| /* avg_wait */
							 rpad('-',15,'-');  /* max_wait */
				pipe row (rtn);
				--
			end if;
			--
			/* 
			 * ...display the session-wait information...
			 */
			rtn.plan_table_output := '|'||rpad(' '||x.qcsid,14,' ')|| /* qcsid */
						 '|'||rpad(' '||x.sid,14,' ')|| /* sid */
						 '|'||rpad(' '||x.type,7,' ')|| /* type */
						 '|'||rpad(' '||x.event,29,' ')|| /* Event */
						 '|'||lpad(' '||trim(to_char(x.time_waited,'999,999,999,990')),16,' ')||' '|| /* time_waited */
						 '|'||lpad(' '||trim(to_char(x.total_waits,'999,999,999,990')),13,' ')||' '|| /* total_waits */
						 '|'||lpad(' '||trim(to_char(x.avg_wait,'999,999,999,990')),13,' ')||' '|| /* avg_wait */
						 '|'||lpad(' '||trim(to_char(x.max_wait,'999,999,999,990')),12,' ')||' '||'|';  /* max_wait */
			pipe row (rtn);
			--
		end loop;
		--
		/* 
		 * ...print out the concluding text to close the "text box" containing the session-wait information...
		 */
		if v_lines > 0 then
			--
			rtn.plan_table_output := rpad('-',15,'-')|| /* qcsid */
						 rpad('-',15,'-')|| /* sid */
						 rpad('-',8,'-')|| /* type */
						 rpad('-',30,'-')|| /* event */
						 rpad('-',18,'-')|| /* time_waited */
						 rpad('-',15,'-')|| /* total_waits */
						 rpad('-',15,'-')|| /* avg_wait */
						 rpad('-',15,'-');  /* max_wait */
			pipe row (rtn);
			--
		end if;
		--
		return;
		--
	end display_cursor;
	--
end ash_xplan;
/
show errors

spool off
set echo off feedback 6 timing off
