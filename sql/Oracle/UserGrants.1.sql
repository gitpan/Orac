select username from all_users
union
select 'PUBLIC' from dual
order by 1
