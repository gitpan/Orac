/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor i_c is
select uniqueness,upper(owner),upper(index_name),upper(table_owner),upper(table_name),
ini_trans,max_trans,tablespace_name,initial_extent,next_extent,min_extents,max_extents,
freelists,freelist_groups,pct_increase,pct_free,table_type
from sys.dba_indexes
where owner = ?
and table_name = ?
order by owner,index_name;
cursor s_c (s_own VARCHAR2,s_ind VARCHAR2) is
select bytes
from sys.dba_segments
where segment_name = s_ind and owner = s_own and segment_type = 'INDEX';
cursor c_c (c_own varchar2,c_ind varchar2) is
select upper(column_name),column_position
from sys.dba_ind_columns where index_name = c_ind and index_owner = c_own
order by column_position;
l_unq sys.dba_indexes.uniqueness%TYPE;
l_on sys.dba_indexes.owner%TYPE;
l_ind_nam sys.dba_indexes.index_name%TYPE;
l_towner sys.dba_indexes.table_owner%TYPE;
l_tn sys.dba_indexes.table_name%TYPE;
l_ini_trans sys.dba_indexes.ini_trans%TYPE;
l_max_trans sys.dba_indexes.max_trans%TYPE;
l_tbsp sys.dba_indexes.tablespace_name%TYPE;
l_iex sys.dba_indexes.initial_extent%TYPE;
l_nexex sys.dba_indexes.next_extent%TYPE;
l_min_extents sys.dba_indexes.min_extents%TYPE;
l_maxexs sys.dba_indexes.max_extents%TYPE;
l_freel sys.dba_indexes.freelists%TYPE;
l_freel_g sys.dba_indexes.freelist_groups%TYPE;
l_pctin sys.dba_indexes.pct_increase%TYPE;
l_pct_free sys.dba_indexes.pct_free%TYPE;
l_tab_typ sys.dba_indexes.table_type%TYPE;
l_seg_byts sys.dba_segments.bytes%TYPE;
l_col_nam sys.dba_ind_columns.column_name%TYPE;
l_col_pos sys.dba_ind_columns.column_position%TYPE;
l_ln number := 0;
init_ext_siz varchar2(16);
nxt_ext_siz varchar2(16);
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
open i_c;
loop
fetch i_c into l_unq,l_on,l_ind_nam,l_towner,l_tn,l_ini_trans,l_max_trans,l_tbsp,l_iex,
l_nexex,l_min_extents,l_maxexs,l_freel,l_freel_g,l_pctin,l_pct_free,l_tab_typ;
exit when i_c%NOTFOUND;
if ? = 'Y' then
open s_c (l_on,l_ind_nam);
fetch s_c into l_seg_byts;
if s_c%found then
l_iex := l_seg_byts;
if l_nexex > l_iex then
l_nexex := l_iex;
end if;
end if;
close s_c;
end if;
if to_char(l_ini_trans) = '0' then
l_ini_trans := 1;
end if;
if to_char(l_max_trans) = '0' then
l_max_trans := 1;
end if;
if l_unq = 'UNIQUE' then
a_lin := wri(a_lin,'create unique index '||l_on,0);
elsif l_unq = 'BITMAP' then
a_lin := wri(a_lin,'create bitmap index '||l_on,0);
else
a_lin := wri(a_lin,'create index '||l_on,0);
end if;
a_lin := wri(a_lin,'.'||l_ind_nam,0);
a_lin := wri(a_lin,' on ',0);
a_lin := wri(a_lin,l_towner,0);
a_lin := wri(a_lin,'.'||l_tn,0);
if l_tab_typ = 'TABLE' then
a_lin := wri(a_lin,' (',0);
open c_c(l_on,l_ind_nam);
loop
fetch c_c into l_col_nam,l_col_pos;
exit when c_c%notfound;
if l_col_pos <> 1 then
a_lin := wri(a_lin,',',0);
end if;
a_lin := wri(a_lin,chr(34)||l_col_nam||chr(34),0);
end loop;
close c_c;
a_lin := wri(a_lin,')',0);
end if;
a_lin := wri(a_lin,' TABLESPACE '||l_tbsp,0);
a_lin := wri(a_lin,' INITRANS '||to_char(l_ini_trans),0);
a_lin := wri(a_lin,' MAXTRANS '||to_char(l_max_trans),0);
a_lin := wri(a_lin,' PCTFREE '||to_char(l_pct_free),1);
/* Calculate extent sizes in Mbytes or Kbytes,if possible */
if mod(l_iex,1048576) = 0 then
init_ext_siz :=
to_char(l_iex / 1048576)||'M';
elsif mod(l_iex,1024) = 0 then
init_ext_siz :=
to_char(l_iex / 1024)||'K';
else
init_ext_siz := to_char(l_iex);
end if;
if mod(l_nexex,1048576) = 0 then
nxt_ext_siz :=
to_char(l_nexex / 1048576)||'M';
elsif mod(l_nexex,1024) = 0 then
nxt_ext_siz :=
to_char(l_nexex / 1024)||'K';
else
nxt_ext_siz := to_char(l_nexex);
end if;
a_lin := wri(a_lin,' STORAGE (INITIAL '||init_ext_siz,0);
a_lin := wri(a_lin,' NEXT '||nxt_ext_siz,0);
a_lin := wri(a_lin,' MINEXTENTS '||to_char(l_min_extents),0);
a_lin := wri(a_lin,' MAXEXTENTS '||to_char(l_maxexs),0);
a_lin := wri(a_lin,' PCTINCREASE '||to_char(l_pctin),0);
a_lin := wri(a_lin,' FREELISTS '||to_char(l_freel),0);
a_lin := wri(a_lin,' FREELIST GROUPS '||to_char(l_freel_g),0);
a_lin := wri(a_lin,');',1);
end loop;
close i_c;
exception
when others then
raise_application_error(-20000,'Unexpected error on '||l_ind_nam||','||l_col_nam||': '||to_char(SQLCODE)||' - Aborting...');
end;
