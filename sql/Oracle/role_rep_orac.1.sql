SELECT r.role,r.password_required Paswd_Req,
p.grantee,p.admin_option adm,
p.default_role dflt
FROM dba_roles r,dba_role_privs p
WHERE r.role = p.granted_role(+)
ORDER BY 1,3
