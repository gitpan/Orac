/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
n number;
text varchar2(2000);
usr varchar2(30);
v_dbname varchar2(30);
v_now varchar2(30);
v_memory_pigs varchar2(100);
asid number;
dreads number;
one_counter number;
two_counter number;
local_counter number;
exexs number;
rds_exec number;
cursor pig1 is
select d.username,sid,disk_reads,executions,
round(disk_reads/executions,2),sql_text
from sys.dba_users d,v$session,v$sqlarea
where command_type in (2,3,6,7,47) and
disk_reads > 10000 and
parsing_user_id = user_id and
address = sql_address(+) and
hash_value = sql_hash_value(+) and
disk_reads/executions > 25
order by disk_reads desc;
cursor pig2 is
select d.username,sid,buffer_gets,sql_text
from sys.dba_users d,v$session,v$sqlarea
where buffer_gets > 20000 and
parsing_user_id = user_id and
address = sql_address(+) and
hash_value = sql_hash_value(+)
order by 3 desc;
begin
dbms_output.enable(1000000);
one_counter := 100000;
two_counter := 200000;
select name dbname,to_char(sysdate,'DD/MM/YYYY HH24:MM') now
into v_dbname,v_now
from v$database;
dbms_output.put_line('99'||'^'||v_dbname||'^'||v_now);
select 'Memory Hogs - Top 5 queries using the largest amount of logical reads'
into v_memory_pigs
from dual;
dbms_output.put_line('3'||'^'||v_memory_pigs);
select '(These may flood SGA and cause often-used queries to be pushed from memory)'
into v_memory_pigs
from dual;
dbms_output.put_line('4'||'^'||v_memory_pigs);
select 'I/O Hogs - Top 20 SQL statements performing the most physical disk reads'
into v_memory_pigs
from dual;
dbms_output.put_line('5'||'^'||v_memory_pigs);
select '(This may show where most full table scans are being done,saturating the SGA)'
into v_memory_pigs
from dual;
dbms_output.put_line('6'||'^'||v_memory_pigs);
open pig1;
n := 0;
while true loop
fetch pig1 into usr,asid,dreads,exexs,rds_exec,text;
exit when pig1%NOTFOUND;
n := n + 1;
if n > 20 then
exit;
end if;
if (length(text) > 180) then
local_counter := 1;
while (length(text) > 180) loop
one_counter := one_counter + 1;
if local_counter = 1 then
local_counter := local_counter + 1;
dbms_output.put_line(one_counter||'^'||usr||'^'||asid||'^'||dreads||'^'||exexs||'^'||rds_exec||'^'||substr(text,1,180));
else
dbms_output.put_line(one_counter||'^^^^^^'||substr(text,1,180));
end if;
text := substr(text,181);
end loop;
one_counter := one_counter + 1;
dbms_output.put_line(one_counter||'^^^^^^'||text);
else
one_counter := one_counter + 1;
dbms_output.put_line(one_counter||'^'||usr||'^'||asid||'^'||
dreads||'^'||exexs||'^'||rds_exec||'^'||text);
end if;
end loop;
close pig1;
open pig2;
n := 0;
while true loop
fetch pig2 into usr,asid,dreads,text;
exit when pig2%NOTFOUND;
n := n + 1;
if n > 5 then
exit;
end if;
if (length(text) > 180) then
local_counter := 1;
while (length(text) > 180) loop
two_counter := two_counter + 1;
if local_counter = 1 then
local_counter := local_counter + 1;
dbms_output.put_line(two_counter||'^'||usr||'^'||asid||'^'||dreads||'^'||0||'^'||0||'^'||
substr(text,1,180));
else
dbms_output.put_line(two_counter||'^^^^^^'||substr(text,1,180));
end if;
text := substr(text,181);
end loop;
two_counter := two_counter + 1;
dbms_output.put_line(two_counter||'^^^^^^'||text);
else
two_counter := two_counter + 1;
dbms_output.put_line(two_counter||'^'||usr||'^'||asid||'^'||dreads||'^'||0||'^'||0||'^'||text);
end if;
end loop;
close pig2;
end;
