
/* 

see: http://dboptimizer.com/2011/09/20/display_cursor/

output looks like

Enter value for sql_id: g2w9n4gksyys6
    old  59:     stats.sql_id='&v_sql_id'  and
    new  59:     stats.sql_id='g2w9n4gksyys6'  and

     CN   ELAPSED    LIO_RATIO TCF_GRAPH   E_ROWS       A_ROWS operation
    --- ------------ --------- ------ ------------ ------------ ------------------------------------------------------------
      0            0         0                                1 SELECT STATEMENT
           5,720,456         0                   1            1  HASH GROUP BY
              29,711         0                            1,909   NESTED LOOPS
                   0         0  +++              1        1,909    NESTED LOOPS
           1,969,304         0  +++              1        1,909     NESTED LOOPS
                   0         0  +++              1        2,027      NESTED LOOPS
           7,939,649         0  +++              1        1,656       NESTED LOOPS
             716,054         0  +++              1        1,657        NESTED LOOPS
             270,201         0  ++              39       23,171         HASH JOIN
                  23         0                   5            1          JOIN FILTER CREATE :BF0000
                  31         1                   5            1           TABLE ACCESS BY INDEX ROWID PS_PAY_CALENDAR
                  14         2                   5            1            INDEX RANGE SCAN PS0PAY_CALENDAR
             141,467         0              18,503       23,171          VIEW  VW_SQ_1
           3,032,120         0              18,503       23,171           HASH GROUP BY
             152,564         0             163,420       33,020            JOIN FILTER USE :BF0000
             407,746         0             163,420       33,020             MERGE JOIN
                  55         0                   5            1              SORT JOIN
                  12         2                   5            1               INDEX RANGE SCAN PS0PAY_CALENDAR
              79,435         0              40,000       33,020              SORT JOIN
             119,852         0              40,000       40,000               INDEX FAST FULL SCAN WB_JOB
           2,959,031        13  -           23,171        1,657         TABLE ACCESS BY INDEX ROWID WB_JOB
             944,887         1              23,171       23,174          INDEX RANGE SCAN WB_JOB
             102,650         0               1,657        1,656        VIEW PUSHED PREDICATE  VW_SQ_2
              73,769         0               1,657        1,657         SORT AGGREGATE
              25,617         0               1,657        1,657          FIRST ROW
             225,497         1               1,657        1,657           INDEX RANGE SCAN (MIN/MAX) WB_JOB
             357,872         0               3,312        2,027       TABLE ACCESS BY INDEX ROWID WB_RETROPAY_EARNS
           3,655,774         1               3,312        2,027        INDEX RANGE SCAN WB_RETROPAY_EARNS_IDX1
             199,884         0               2,027        1,909      TABLE ACCESS BY INDEX ROWID PS_RETROPAY_RQST
             317,793         1               2,027        1,909       INDEX RANGE SCAN PS_RETROPAY_RQST
              71,534         0               1,909        1,909     INDEX RANGE SCAN PS#RETROPAYPGM_TBL
              18,396         0               1,909        1,909    TABLE ACCESS BY INDEX ROWID PS_RETROPAYPGM_TBL

The 3 important parts of this query are

Elapsed is per row source, not cumulative of it’s children
LIO_RATIO
TCP_GRAPH
Elapsed time format has a huge drawback in the display_cursor output as each lines elapsed time includes the elapsed time of all the children which makes an execution plan difficult to scan and see where the time is being spent. In the above output the elapsed time represents the elapsed time of each row source line.

LIO_RATIO shows the number of buffers accessed per row returned. Ideally 1 buffer or less is accessed per row returned. When the number of buffers per row becomes large, it’s a good indication that there is a more optimal method to get the rows.  The I/O stats include the stats of the child row source, so the query has to get the I/O from the childern and subtract from the parent, making the query a bit more complex.

TCP_GRAPH graphically shows the ratio of estimated rows to actual rows. The estimated rows used is cardinality* starts, not just cardinality. This value can be compared directly to actual_rows and the difference in order of magnitude is shown. Each ‘+’ represents and order of magnitude larger and each “-” represents an order of magnitude smaller. The more orders of magnitude, either way, the more the optimizers calculations are off and thus like more pointing to a possible plan that is suboptimal.

In the above output there   are 5 lines where the optimizer only expect 1 row and the actual results were over 1000, ie 3 orders of magnitude difference. These are the three lines with “+++”
There is one line with “-” where actual was an order of magnitude smaller. On that same line we see it’s one of the slower lines almost 3 seconds and that the were 13 lio’s per row returned, which is sign of inefficiency.

*/


col cn format 99
col ratio format 99
col ratio1 format A6
--set pagesize 1000
set linesize 140
break on sql_id on cn
col lio_rw format 999
col "operation" format a60
col a_rows for 999,999,999
col e_rows for 999,999,999
col elapsed for 999,999,999

Def v_sql_id=&SQL_ID

select
       -- sql_id,
       --hv,
       childn                                         cn,
       --ptime, stime,
       case when stime - nvl(ptime ,0) > 0 then
          stime - nvl(ptime ,0)
        else 0 end as elapsed,
       nvl(trunc((lio-nvl(plio,0))/nullif(a_rows,0)),0) lio_ratio,
       --id,
       --parent_id,
       --starts,
       --nvl(ratio,0)                                    TCF_ratio,
       ' '||case when ratio > 0 then
                rpad('-',ratio,'-')
             else
               rpad('+',ratio*-1 ,'+')
       end as                                           TCF_GRAPH,
       starts*cardinality                              e_rows,
                                                       a_rows,
       --nvl(lio,0) lio, nvl(plio,0)                      parent_lio,
                                                         "operation"
from (
  SELECT
      stats.LAST_ELAPSED_TIME                             stime,
      p.elapsed                                  ptime,
      stats.sql_id                                        sql_id
    , stats.HASH_VALUE                                    hv
    , stats.CHILD_NUMBER                                  childn
    , to_char(stats.id,'990')
      ||decode(stats.access_predicates,null,null,'A')
      ||decode(stats.filter_predicates,null,null,'F')     id
    , stats.parent_id
    , stats.CARDINALITY                                    cardinality
    , LPAD(' ',depth)||stats.OPERATION||' '||
      stats.OPTIONS||' '||
      stats.OBJECT_NAME||
      DECODE(stats.PARTITION_START,NULL,' ',':')||
      TRANSLATE(stats.PARTITION_START,'(NRUMBE','(NR')||
      DECODE(stats.PARTITION_STOP,NULL,' ','-')||
      TRANSLATE(stats.PARTITION_STOP,'(NRUMBE','(NR')      "operation",
      stats.last_starts                                     starts,
      stats.last_output_rows                                a_rows,
      (stats.last_cu_buffer_gets+stats.last_cr_buffer_gets) lio,
      p.lio                                                 plio,
      trunc(log(10,nullif
         (stats.last_starts*stats.cardinality/
          nullif(stats.last_output_rows,0),0)))             ratio
  FROM
       v$sql_plan_statistics_all stats
       , (select sum(last_cu_buffer_gets + last_cr_buffer_gets) lio,
                 sum(LAST_ELAPSED_TIME) elapsed,
                 child_number,
                 parent_id,
                 sql_id
         from v$sql_plan_statistics_all
         group by child_number,sql_id, parent_id) p
  WHERE
    stats.sql_id='&v_sql_id'  and
    p.sql_id(+) = stats.sql_id and
    p.child_number(+) = stats.child_number and
    p.parent_id(+)=stats.id
)
order by sql_id, childn , id
/
