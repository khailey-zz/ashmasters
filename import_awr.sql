

/* 

Exporting AWR, straight forward  procedure in article on

http://gavinsoorma.com/2009/07/25/exporting-and-importing-awr-snapshot-data/
 
SQL> CREATE DIRECTORY AWR_DATA AS ‘/u01/oracle/’;

Then run export script supplied by Oracle

SQL> @?/rdbms/admin/awrextr.sql

Enter value for directory_name: AWR_DATA
Using the dump directory: AWR_DATA
Enter value for file_name: awrexp

*/


-- create tablespace AWR datafile '/home/oracle/oracle/product/10.2.0/oradata/orcl/AWR_01.dbf' size 200M;
   Drop Directory AWR_DMP;
   Create Directory AWR_DMP AS '&AWR_DMP_LOCATION';
   drop user awr_stage cascade;
   create user awr_stage
          identified by awr_stage
          default tablespace awr
          temporary tablespace temp;
   grant  connect to awr_stage;
   alter  user awr_stage quota unlimited on awr;
   alter  user awr_stage temporary tablespace temp;
-- load data
   begin
     dbms_swrf_internal.awr_load(schname  => 'AWR_STAGE',
 				 dmpfile  => '&DMP_FILE_NAME_wo_dmp_extention', -- file w/o .dmp
                                 dmpdir   => 'AWR_DMP');
   end;
/
-- change dbid
   def dbid=&DBID;
   @awr_change_dbid
   commit;
-- move data
   def schema_name='AWR_STAGE'
   select  '&schema_name' from dual;
   variable schname varchar2(30);
   begin
     :schname := '&schema_name';
     dbms_swrf_internal.move_to_awr(schname => :schname);
   end;
/
   col host_name for a30
   select distinct dbid,  db_name, instance_name, host_name from
   dba_hist_database_instance;
