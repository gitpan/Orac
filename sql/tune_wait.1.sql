/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor init_c is
select name,to_char(sysdate,'MM/DD/YY')
from v$database;
cursor sess_wt_c is
select /*+ use_nl(w,s) */
w.sid,s.username,w.event,w.p1,w.p2,w.p3,decode(w.state,'WAITING',
substr(to_char(w.seconds_in_wait,'9999999'),2),
'WAITING UNKNOWN TIME','      ?','WAITED SHORT TIME','   < 10','WAITED KNOWN TIME',
substr(to_char(w.wait_time,'9999999'),2),'???????'),
decode(w.state,'WAITING','CURR','WAITING UNKNOWN TIME',' ','WAITED SHORT TIME',' ',
'WAITED KNOWN TIME','prev','????'),s.paddr,s.type
from v$session_wait w,v$session s
where w.sid = s.sid and (to_char(w.sid) = '0' or '0' = '0')
and s.status = 'ACTIVE' and w.event <> 'rdbms ipc message' and
w.event <> 'smon timer' and
w.event <> 'SQL*Net message from client'
order by 1;
cursor sess_c is
select sid,username,paddr
from v$session
where to_char(sid) = '0';
cursor sess_ev_c (my_sid in number) is
select event,total_waits,total_timeouts,time_waited,average_wait
from v$session_event
where sid = my_sid
order by 1;
cursor bg_pr_c (my_paddr in raw) is
select name
from v$bgprocess
where paddr = my_paddr;
cursor dba_df_c (my_p1 in number) is
select tablespace_name
from sys.dba_data_files
where file_id = my_p1;
cursor ltch_c (my_latch# in number) is
select name
from v$latchname
where latch# = my_latch#;
cursor lck_c (my_lk_n in varchar2) is
select sid,id1,id2,decode(lmode,1,'null',2,'Read',3,'Writ',4,'PrRd',5,'PrWr',6,'Excl','????'),block
from v$lock
where type = my_lk_n and lmode > 0;
cursor sys_ev_c is
select event,total_waits,total_timeouts,time_waited,average_wait
from v$system_event
where total_waits > 0
order by total_waits desc;
l_nm sys.v_$database.name%TYPE;
l_today varchar2(8);
l_unm sys.v_$session.username%TYPE;
l_paddr sys.v_$session.paddr%TYPE;
l_type sys.v_$session.type%TYPE;
l_ev sys.v_$session_event.event%TYPE;
l_ev29 char(29);
l_tw sys.v_$session_event.total_waits%TYPE;
l_tots sys.v_$session_event.total_timeouts%TYPE;
l_twt sys.v_$session_event.time_waited%TYPE;
l_avwt sys.v_$session_event.average_wait%TYPE;
l_sid sys.v_$session_wait.sid%TYPE;
l_p1 sys.v_$session_wait.p1%TYPE;
l_p2 sys.v_$session_wait.p2%TYPE;
l_p3 sys.v_$session_wait.p3%TYPE;
l_wt_str varchar2(10);
l_wtis_str varchar2(4);
l_tbsp sys.dba_data_files.tablespace_name%TYPE;
l_ltn sys.v_$latchname.name%TYPE;
do_dba_file boolean;
do_locks boolean;
head boolean;
lk_n varchar2(2);
lock_mode number;
l_id1 sys.v_$lock.id1%TYPE;
l_id2 sys.v_$lock.id2%TYPE;
mode_desc varchar2(4);
l_bl sys.v_$lock.block%TYPE;
l_sev sys.v_$system_event.event%TYPE;
l_ev31 char(31);
l_stot_wt sys.v_$system_event.total_waits%TYPE;
l_stot_tim sys.v_$system_event.total_timeouts%TYPE;
l_stim_wt sys.v_$system_event.time_waited%TYPE;
l_sav_wt sys.v_$system_event.average_wait%TYPE;
contention number;
l_ln number;
a_lin varchar2(80);
function wri(x_lin in varchar2,x_str in varchar2,x_force in number)
return varchar2 is
begin
if length(x_lin) + length(x_str) > 79 then
l_ln := l_ln + 1;
dbms_output.put_line( x_lin);
if x_force = 0 then
return '          '||x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line( '          '||x_str);
return '';
end if;
else
if x_force = 0 then
return x_lin||x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line( x_lin||x_str);
return '';
end if;
end if;
end wri;
begin
a_lin := '';
l_ln := 0;
open init_c;
fetch init_c into l_nm,l_today;
if init_c%NOTFOUND then
l_nm := '????';
l_today := '??/??/??';
end if;
close init_c;
a_lin := wri(a_lin,rpad('Database: '||l_nm,28)||'SESSION WAIT STATISTICS'||lpad(l_today,29),1);
a_lin := wri(a_lin,'',1);
a_lin := wri(a_lin,'                                           '||'            Wait Wait',1);
a_lin := wri(a_lin,'  SID Username     Event                   '||'           hsecs   is',1);
a_lin := wri(a_lin,'----- ------------ ------------------------'||'-------- ------- ----',1);
open sess_wt_c;
loop
fetch sess_wt_c into l_sid,l_unm,l_ev,l_p1,l_p2,l_p3,l_wt_str,l_wtis_str,l_paddr,l_type;
exit when sess_wt_c%NOTFOUND;
if l_type = 'BACKGROUND' then
open bg_pr_c(l_paddr);
fetch bg_pr_c into l_unm;
if bg_pr_c%NOTFOUND then
l_unm := '<n/a>';
end if;
close bg_pr_c;
end if;
if l_unm is null then
l_unm := '<null>';
end if;
a_lin := wri(a_lin,rpad(substr(to_char(l_sid,'99999'),2),5)||
' '||rpad(substr(l_unm,1,12),12)||' '||rpad(substr(l_ev,1,32),32)||' '||
rpad(substr(l_wt_str,1,7),7)||' '||rpad(substr(l_wtis_str,1,4),4),1);
do_locks := false;
do_dba_file := false;
if l_ev = 'db file sequential read' then
do_dba_file := true;
elsif l_ev = 'db file scattered read' then
do_dba_file := true;
elsif l_ev = 'DFS enqueue lock acquisition' then
do_locks := true;
elsif l_ev = 'DFS lock acquisition' then
do_locks := true;
elsif l_ev = 'DFS lock handle' then
do_locks := true;
elsif l_ev = 'latch free' then
open ltch_c(l_p2);
fetch ltch_c into l_ltn;
if ltch_c%FOUND then
a_lin := wri(a_lin,'                        Latch '||l_ltn,0);
a_lin := wri(a_lin,' (# of sleeps = '||to_char(l_p3)||')',1);
end if;
close ltch_c;
end if;
if do_dba_file then
open dba_df_c(l_p1);
fetch dba_df_c into l_tbsp;
if dba_df_c%FOUND then
a_lin := wri(a_lin,'                   Tablespace '||l_tbsp,0);
a_lin := wri(a_lin,' (File ID '||to_char(l_p1)||',block '||to_char(l_p2)||')',1);
end if;
close dba_df_c;
end if;
if do_locks then
lk_n := chr(bitand(l_p1,-16777216) / 16777215)||chr(bitand(l_p1,16711680) / 65535);
lock_mode := bitand(l_p1,65536);
a_lin := wri(a_lin,'                   Trying to enqueue lock'||
' type '||lk_n||',mode '||to_char(lock_mode),1);
head := false;
open lck_c(lk_n);
loop
fetch lck_c into
l_sid,l_id1,l_id2,mode_desc,
l_bl;
exit when lck_c%NOTFOUND;
if not head then
head := true;
a_lin := wri(a_lin,'             '||'      Blocked by lock(s):',1);
end if;
a_lin := wri(a_lin,'                        SID '||rpad(substr(to_char(l_sid,'99999'),
2),5)||' Mode '||mode_desc,0);
if l_bl = 0 then
a_lin := wri(a_lin,' non-blocking',1);
elsif l_bl = 1 then
a_lin := wri(a_lin,' ** BLOCKING **',1);
else
a_lin := wri(a_lin,'',1);
end if;
end loop;
close lck_c;
end if;
end loop;
close sess_wt_c;
if '0' = '0' then
a_lin := wri(a_lin,'',1);
a_lin := wri(a_lin,'             ============ SYSTEM-WIDE'||' EVENT STATISTICS ============',1);
a_lin := wri(a_lin,'',1);
a_lin := wri(a_lin,'                                   '||
'   Total      Total        Time         Avg',1);
a_lin := wri(a_lin,'Event                              '||
'   Waits    Timeouts      Waited        Wait',1);
a_lin := wri(a_lin,'------------------------------- ---'||
'-------- ----------- ----------- -----------',1);
open sys_ev_c;
loop
fetch sys_ev_c into l_sev,l_stot_wt,l_stot_tim,
l_stim_wt,l_sav_wt;
exit when sys_ev_c%NOTFOUND;
l_ev31 := substr(l_sev,1,31);
a_lin := wri(a_lin,l_ev31||to_char(l_stot_wt,'99999999990')||to_char(l_stot_tim,'99999999990')||
to_char(l_stim_wt,'99999999990')||
to_char(l_sav_wt,'99999999990'),1);
end loop;
close sys_ev_c;
a_lin := wri(a_lin,'',1);
a_lin := wri(a_lin,'-------------------------------------'||
'------------------------------------------',1);
a_lin := wri(a_lin,'',1);
else
open sess_c;
fetch sess_c into l_sid,l_unm,l_paddr;
if sess_c%FOUND then
if l_unm is null then
open bg_pr_c (l_paddr);
fetch bg_pr_c into
l_unm;
if bg_pr_c%NOTFOUND then
l_unm := '<n/a>';
end if;
close bg_pr_c;
end if;
a_lin := wri(a_lin,'',1);
a_lin := wri(a_lin,'              ========== SID:  '||to_char(l_sid)||'    Username: '||
l_unm||' ==========',1);
a_lin := wri(a_lin,'',1);
a_lin := wri(a_lin,
'                                    '||'                       Total         Avg',1);
a_lin := wri(a_lin,'                                    '||
'                        .01          .01',1);
a_lin := wri(a_lin,'                                    '||
'Total      Total        secs         secs',1);
a_lin := wri(a_lin,'Event                               '||
'Waits    Timeouts      Waited        Wait',1);
a_lin := wri(a_lin,'----------------------------- ------'||
'----- ----------- ----------- -----------',1);
contention := 0;
open sess_ev_c (l_sid);
loop
fetch sess_ev_c into l_ev,l_tw,l_tots,l_twt,l_avwt;
exit when sess_ev_c%NOTFOUND;
l_ev29 := substr(l_ev,1,29);
a_lin := wri(a_lin,l_ev29||to_char(l_tw,'99999999990')||to_char(l_tots,'99999999990')||
to_char(l_twt,'99999999990')||to_char(round(l_avwt),'99999999990'),0);
if round(l_avwt) <> 0 then
a_lin := wri(a_lin,' *',1);
contention := 1;
else
a_lin := wri(a_lin,'',1);
end if;
end loop;
close sess_ev_c;
if contention = 1 then
a_lin := wri(a_lin,'',1);
a_lin := wri(a_lin,'   * = Indicates contention',1);
end if;
end if;
close sess_c;
end if;
end;
