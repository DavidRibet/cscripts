@@&&stgtab_sqlbaseline_script.
--
COL con_id FOR 999 HEA 'Con|ID';
COL pdb_name FOR A30 HEA 'PDB Name' FOR A30 TRUNC;
COL created FOR A19 HEA 'Created';
COL plan_name FOR A30 HEA 'Plan Name';
COL origin FOR A29 HEA 'Origin';
COL timestamp FOR A19 HEA 'Timestamp';
COL last_executed FOR A19 HEA 'Last Executed';
COL last_modified FOR A19 HEA 'Last Modified';
COL description FOR A200 HEA 'Description';
COL executions FOR 999,999,990 HEA 'Executions';
COL et_per_exec_ms FOR 999,999,990.000 HEA 'Elapsed Time|AVG (ms)';
COL cpu_per_exec_ms FOR 999,999,990.000 HEA 'CPU Time|AVG (ms)';
COL buffers_per_exec FOR 999,999,999,990 HEA 'Buffer Gets|AVG';
COL reads_per_exec FOR 999,999,999,990 HEA 'Disk Reads|AVG';
COL rows_per_exec FOR 999,999,999,990 HEA 'Rows Processed|AVG';
COL elapsed_time FOR 999,999,999,999,990 HEA 'Elapsed Time|Total (us)';
COL cpu_time FOR 999,999,999,999,990 HEA 'CPU Time|Total (us)';
COL buffer_gets FOR 999,999,999,990 HEA 'Buffer Gets|Total';
COL disk_reads FOR 999,999,999,990 HEA 'Disk Reads|Total';
COL rows_processed FOR 999,999,999,990 HEA 'Rows Processed|Total';
COL enabled FOR A10 HEA 'Enabled';
COL accepted FOR A10 HEA 'Accepted';
COL fixed FOR A10 HEA 'Fixed' PRI;
COL reproduced FOR A10 HEA 'Reproduced';
COL adaptive FOR A10 HEA 'Adaptive';
COL plan_id FOR 999999999990 HEA 'Plan ID';
COL plan_hash_2 FOR 999999999990 HEA 'Plan Hash 2';
COL plan_hash FOR 999999999990 HEA 'Plan Hash';
COL plan_hash_full FOR 999999999990 HEA 'Plan Hash|Full';
--
PRO
PRO SQL PLAN BASELINES - LIST (dba_sql_plan_baselines)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(s.created, '&&cs_datetime_full_format.') AS created, 
       s.con_id,
       c.name AS pdb_name,
       s.plan_name, 
       s.enabled, s.accepted, s.fixed, s.reproduced, s.adaptive, 
       s.origin, 
       TO_CHAR(s.last_executed, '&&cs_datetime_full_format.') AS last_executed, 
       TO_CHAR(s.last_modified, '&&cs_datetime_full_format.') AS last_modified, 
       s.description
  FROM cdb_sql_plan_baselines s,
       v$containers c
 WHERE s.signature = :cs_signature
   AND c.con_id = s.con_id
 ORDER BY 
       s.created, s.con_id, s.plan_name
/
--
PRO
PRO SQL PLAN BASELINES - PERFORMANCE (dba_sql_plan_baselines)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
SELECT TO_CHAR(s.created, '&&cs_datetime_full_format.') AS created, 
       s.con_id,
       c.name AS pdb_name,
       s.plan_name, 
       s.enabled, s.accepted, s.fixed, s.reproduced, s.adaptive, 
       s.origin, 
       s.elapsed_time/GREATEST(s.executions,1)/1e3 AS et_per_exec_ms,
       s.cpu_time/GREATEST(s.executions,1)/1e3 AS cpu_per_exec_ms,
       s.buffer_gets/GREATEST(s.executions,1) AS buffers_per_exec,
       s.disk_reads/GREATEST(s.executions,1) AS reads_per_exec,
       s.rows_processed/GREATEST(s.executions,1) AS rows_per_exec,
       s.executions,
       s.elapsed_time,
       s.cpu_time,
       s.buffer_gets,
       s.disk_reads,
       s.rows_processed
  FROM cdb_sql_plan_baselines s,
       v$containers c
 WHERE s.signature = :cs_signature
   AND c.con_id = s.con_id
 ORDER BY 
       s.created, s.con_id, s.plan_name
/
--
PRO
PRO SQL PLAN BASELINES - IDS (dba_sql_plan_baselines)
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
-- only works from PDB. do not use CONTAINERS(table_name) since it causes ORA-00600: internal error code, arguments: [kkdolci1], [], [], [], [], [], [],
SELECT TO_CHAR(a.created, '&&cs_datetime_full_format.') created,
       o.name plan_name,
       DECODE(BITAND(o.flags, 1),   0, 'NO', 'YES') enabled,
       DECODE(BITAND(o.flags, 2),   0, 'NO', 'YES') accepted,
       DECODE(BITAND(o.flags, 4),   0, 'NO', 'YES') fixed,
       DECODE(BITAND(o.flags, 64),  0, 'YES', 'NO') reproduced,
       DECODE(BITAND(o.flags, 256), 0, 'NO', 'YES') adaptive,
       p.plan_id,
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_2"]')) plan_hash_2, -- plan_hash_value ignoring transient object names (must be same than plan_id)
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash"]')) plan_hash, -- normal plan_hash_value
       TO_NUMBER(extractvalue(xmltype(p.other_xml),'/*/info[@type = "plan_hash_full"]')) plan_hash_full, -- adaptive plan (must be different than plan_hash_2 on loaded plans)
       TO_CHAR(p.timestamp, '&&cs_datetime_full_format.') timestamp,
       a.description
  FROM sys.sqlobj$plan p,
       sys.sqlobj$ o,
       sys.sqlobj$auxdata a,
       sys.sql$text t
 WHERE p.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND p.id = 1
   AND p.signature = :cs_signature
   AND p.other_xml IS NOT NULL
   AND o.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND o.signature = p.signature
   AND o.plan_id = p.plan_id
   AND a.obj_type = 2 /* 1:profile, 2:baseline, 3:patch */
   AND a.signature = p.signature
   AND a.plan_id = p.plan_id
   AND t.signature = p.signature
 ORDER BY
       a.created,
       o.name
/
--