select role from dba_roles
where UPPER(role) = UPPER( ? )
order by 1
