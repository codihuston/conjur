# TODO

- Replace authorization check (is_role_allowed_to) with casbin instead 
  (fetch secret)
- Instrument performance

# Casbin

```
cd dev
./start
./cli key
```

Use the API Key below to load policy examples.

## RBAC Model

```casbin
[request_definition]
r = sub, obj, act

[policy_definition]
p = sub, obj, act

[role_definition]
g = _, _

[policy_effect]
e = some(where (p.eft == allow))

[matchers]
m = g(r.sub, p.sub) && r.obj == p.obj && r.act == p.act
```

## Policy

This is the list of policy objects in the form of `sub, obj, act`,
e.g.) `alice, data1, read`.

```casbin
```

## Request

This is the form of the request sent to casbin. The RBAC Model and Policy
are used to determine if a request is valid or not:

```casbin
alice, data2, read
```

# Load Large Policy File

```bash
cd dev
./cli key

docker exec -it bash dev-client-1

CONJUR_APPLIANCE_URL="http://conjur:3000"
CONJUR_ACCOUNT="cucumber"
API_KEY="3fb6ck03tcm0deygwhd572wagf34q780btdgr5v25g2qdw3yfwtk3"
TOKEN=$(curl \
  --insecure \
  --header "Accept-Encoding: base64" \
  --data "$API_KEY" \
  "$CONJUR_APPLIANCE_URL/authn/$CONJUR_ACCOUNT/admin/authenticate"
)
echo $TOKEN

# Call API Endpoints
# Note: using --data-binary for large file (upload contents unchanged, no stripping, see: https://superuser.com/questions/1054742/how-to-post-file-contents-using-curl)
POLICY_BRANCH="root"
curl -H "Authorization: Token token=\"$TOKEN\"" \
     --verbose \
     -X POST \
     --data-binary @/src/conjur-server/dev/policies/casbin/15000/lobs.yml \
     "$CONJUR_APPLIANCE_URL/policies/$CONJUR_ACCOUNT/policy/$POLICY_BRANCH"

curl -H "Authorization: Token token=\"$TOKEN\"" \
     --verbose \
     -X POST \
     --data-binary @/src/conjur-server/dev/policies/casbin/15000/hosts.yml \
     "$CONJUR_APPLIANCE_URL/policies/$CONJUR_ACCOUNT/policy/$POLICY_BRANCH"
```

# SQL Queries

```bash
docker exec -it dev-pg-1 bash
psql -U postgres
```

## Get Role Graph

Not sure if useful...

```sql
SELECT * from role_graph('cucumber:policy:vault-synchronizer');
```

## Get All Groups

```sql
SELECT * from roles 
  WHERE role_id LIKE '%:group:%'
    OR role_id LIKE '%:layer:%';

docker exec dev-pg-1 psql -U postgres -c "\copy (SELECT * from roles WHERE role_id LIKE '%:group:%' OR role_id LIKE '%:layer:%') TO 'groups.csv' CSV HEADER;"
docker cp dev-pg-1:groups.csv ~/git/conjur/dev
```

For each group, this needs to be molded into:

```casbin
[role_definition]
g = _, _
```

## Get All Roles and Memberships

alice, read, variable1

```sql
SELECT role_id, member_id from role_memberships
  WHERE role_id LIKE '%:group:%'
    OR role_id LIKE '%:layer:%'
    OR role_id LIKE '%:host:%'
    OR role_id LIKE '%:user:%';
docker exec dev-pg-1 psql -U postgres -c "\copy (SELECT role_id, member_id from role_memberships WHERE role_id LIKE '%:group:%' OR role_id LIKE '%:layer:%' OR role_id LIKE '%:host:%' OR role_id LIKE '%:user:%') TO 'roles_and_memberships.csv' CSV HEADER;"

SELECT role_id, member_id from role_memberships WHERE  (role_id LIKE '%:group:%' OR role_id LIKE '%:layer:%' OR role_id LIKE '%:host:%' OR role_id LIKE '%:user:%') AND (member_id LIKE '%:group:%' OR member_id LIKE '%:layer:%' OR member_id LIKE '%:host:%' OR member_id LIKE '%:user:%');
docker exec dev-pg-1 psql -U postgres -c "\copy (SELECT role_id, member_id from role_memberships WHERE  (role_id LIKE '%:group:%' OR role_id LIKE '%:layer:%' OR role_id LIKE '%:host:%' OR role_id LIKE '%:user:%') AND (member_id LIKE '%:group:%' OR member_id LIKE '%:layer:%' OR member_id LIKE '%:host:%' OR member_id LIKE '%:user:%')) TO 'roles_and_memberships.csv' CSV HEADER;"

docker cp dev-pg-1:roles_and_memberships.csv ~/git/conjur/dev
```

This needs to be molded into the following, where role_id is first, and
member_id is second.

```casbin
g, alice, data2_admin
```

## Get All Roles and Permissions

Finally, for each role, we need to list their permissions:

```sql
SELECT role_id, resource_id, privilege FROM permissions;

docker exec dev-pg-1 psql -U postgres -c '\copy (SELECT role_id, resource_id, privilege FROM permissions) TO 'roles_and_permissions.csv' CSV HEADER;'
docker cp dev-pg-1:roles_and_permissions.csv ~/git/conjur/dev
```

# Build Casbin Model and Policy

```
./parse-csv-to-casbin.sh
```

# Test the Casbin Policy

Modify the sub, obj, act fields in `main.go` and run the file:

> NOTE: In casbin-model.conf, `role definition` should just be `g = _, _`
> it seems!

```
go run main.go
```

# References

- https://casbin.org/docs/understanding-casbin-detail/
- https://github.com/CasbinRuby/casbin-ruby
