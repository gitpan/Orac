/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor t_c is
select upper(owner),upper(table_name),pct_free,pct_used,ini_trans,max_trans,
tablespace_name,initial_extent,next_extent,min_extents,max_extents,freelists,freelist_groups,pct_increase
from sys.dba_tables
where owner = ?
and table_name = ?
order by owner,table_name;
cursor s_c (s_own VARCHAR2,s_tab VARCHAR2) is
select bytes
from sys.dba_segments
where segment_name = s_tab and owner = s_own and segment_type = 'TABLE';
cursor c_c (c_own VARCHAR2,c_tab VARCHAR2) is
select owner,upper(column_name),upper(data_type),data_length,data_precision,data_scale,
nullable,default_length,data_default,column_id
from sys.dba_tab_columns
where table_name = c_tab and owner = c_own
order by column_id;
l_on sys.dba_tables.owner%TYPE;
l_tn sys.dba_tables.table_name%TYPE;
l_pfre sys.dba_tables.pct_free%TYPE;
l_pct_used sys.dba_tables.pct_used%TYPE;
l_ini_trans sys.dba_tables.ini_trans%TYPE;
l_max_trans sys.dba_tables.max_trans%TYPE;
l_tbsp sys.dba_tables.tablespace_name%TYPE;
l_iex sys.dba_tables.initial_extent%TYPE;
l_nexex sys.dba_tables.next_extent%TYPE;
l_min_ex sys.dba_tables.min_extents%TYPE;
l_maxexs sys.dba_tables.max_extents%TYPE;
l_frelsts sys.dba_tables.freelists%TYPE;
l_frelst_gps sys.dba_tables.freelist_groups%TYPE;
l_pctin sys.dba_tables.pct_increase%TYPE;
l_seg_byts sys.dba_segments.bytes%TYPE;
l_col_nam sys.dba_tab_columns.column_name%TYPE;
l_data_type sys.dba_tab_columns.data_type%TYPE;
l_data_length sys.dba_tab_columns.data_length%TYPE;
l_data_precision sys.dba_tab_columns.data_precision%TYPE;
l_data_scale sys.dba_tab_columns.data_scale%TYPE;
l_nlbl sys.dba_tab_columns.nullable%TYPE;
l_def_len sys.dba_tab_columns.default_length%TYPE;
l_dat_def sys.dba_tab_columns.data_default%TYPE;
l_col_id sys.dba_tab_columns.column_id%TYPE;
l_ln number := 0;
l_init_exsiz varchar2(16);
l_nxtex_siz varchar2(16);
a_lin varchar2(80);
function wri(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
if length(x_lin) + length(x_str) > 80 then
l_ln := l_ln + 1;
dbms_output.put_line(x_lin);
if x_force = 0 then
return x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line(x_str);
return '';
end if;
else
if x_force = 0 then
return x_lin||x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line(x_lin||x_str);
return '';
end if;
end if;
end wri;
begin
a_lin := '';
open t_c;
loop
fetch t_c into l_on,l_tn,l_pfre,l_pct_used,l_ini_trans,l_max_trans,
l_tbsp,l_iex,l_nexex,l_min_ex,l_maxexs,l_frelsts,l_frelst_gps,l_pctin;
exit when t_c%notfound;
if ? = 'Y' then
open s_c (l_on,l_tn);
fetch s_c into l_seg_byts;
if s_c%found then
l_iex := l_seg_byts;
if l_nexex > l_iex then
l_nexex := l_iex;
end if;
end if;
close s_c;
end if;
a_lin := wri(a_lin,'create table ',0);
a_lin := wri(a_lin,l_on||'.'||l_tn,0);
a_lin := wri(a_lin,' (',0);
if (to_char(l_ini_trans) = '0') then
l_ini_trans := 1;
end if;
if (to_char(l_max_trans) = '0') then
l_max_trans := 1;
end if;
open c_c(l_on,l_tn);
loop
fetch c_c into l_on,l_col_nam,l_data_type,l_data_length,l_data_precision,
l_data_scale,l_nlbl,l_def_len,l_dat_def,l_col_id;
exit when c_c%notfound;
if l_col_id <> 1 then
a_lin := wri(a_lin,',',0);
end if;
a_lin := wri(a_lin,chr(34)||l_col_nam||chr(34),0);
a_lin := wri(a_lin,' '||l_data_type,0);
if l_data_type = 'CHAR' or l_data_type = 'VARCHAR2' or l_data_type = 'RAW' then
a_lin := wri(a_lin,'('||l_data_length||')',0);
end if;
if (l_data_type = 'NUMBER' and nvl(l_data_precision,0) != 0) or l_data_type = 'FLOAT' then
if nvl(l_data_scale,0) = 0 then
a_lin := wri(a_lin,'('||l_data_precision||')',0);
else
a_lin := wri(a_lin,'('||l_data_precision||','||l_data_scale||')',0);
end if;
end if;
if l_def_len != 0 then
if l_def_len < 80 then
a_lin := wri(a_lin,' DEFAULT ',0);
a_lin := wri(a_lin,l_dat_def,0);
else
dbms_output.put_line( 'Skipping default clause on '||'column '||l_col_nam);
dbms_output.put_line( ' on table '||l_tn);
dbms_output.put_line( ' since length is '||to_char(l_def_len));
end if;
end if;
if l_nlbl = 'N' then
a_lin := wri(a_lin,' NOT NULL',0);
end if;
end loop;
close c_c;
a_lin := wri(a_lin,')',1);
a_lin := wri(a_lin,' PCTFREE '||to_char(l_pfre),0);
a_lin := wri(a_lin,' PCTUSED '||to_char(l_pct_used),0);
a_lin := wri(a_lin,' INITRANS '||to_char(l_ini_trans),0);
a_lin := wri(a_lin,' MAXTRANS '||to_char(l_max_trans),0);
a_lin := wri(a_lin,' TABLESPACE '||l_tbsp,1);
a_lin := wri(a_lin,' STORAGE (',0);
if mod(l_iex,1048576) = 0 then
l_init_exsiz := to_char(l_iex / 1048576)||'M';
elsif mod(l_iex,1024) = 0 then
l_init_exsiz := to_char(l_iex / 1024)||'K';
else
l_init_exsiz := to_char(l_iex);
end if;
if mod(l_nexex,1048576) = 0 then
l_nxtex_siz := to_char(l_nexex / 1048576)||'M';
elsif mod(l_nexex,1024) = 0 then
l_nxtex_siz := to_char(l_nexex / 1024)||'K';
else
l_nxtex_siz := to_char(l_nexex);
end if;
a_lin := wri(a_lin,' INITIAL '||l_init_exsiz,0);
a_lin := wri(a_lin,' NEXT '||l_nxtex_siz,0);
a_lin := wri(a_lin,' MINEXTENTS '||to_char(l_min_ex),0);
a_lin := wri(a_lin,' MAXEXTENTS '||to_char(l_maxexs),0);
a_lin := wri(a_lin,' PCTINCREASE '||to_char(l_pctin),0);
a_lin := wri(a_lin,' FREELISTS '||to_char(l_frelsts),0);
a_lin := wri(a_lin,' FREELIST GROUPS '||
to_char(l_frelst_gps),0);
a_lin := wri(a_lin,');',1);
end loop;
close t_c;
exception
when others then
raise_application_error(-20000,'Unexpected error on '||l_tn||','||l_col_nam||': '||to_char(SQLCODE)||' - Aborting...');
end;
