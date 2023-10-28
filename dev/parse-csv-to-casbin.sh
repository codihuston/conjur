#!/bin/bash

GROUPS_FILE="groups.csv"
ROLE_MEMBRERSHIPS_FILE="roles_and_memberships.csv"
ROLE_PERMISSIONS_FILE="roles_and_permissions.csv"

CASBIN_ROLE_DEFINITION="g = _, _"
# CASBIN_ROLE_DEFINITION=""
# while IFS="," read -r role_id created_at policy_id
# do
#   CASBIN_ROLE_DEFINITION+="\n$role_id = _, _"
# done < <(tail -n +2 $GROUPS_FILE)
# echo -e "$CASBIN_ROLE_DEFINITION"

CASBIN_POLICY_ROLE_PERMISSIONS=""
while IFS="," read -r role_id resource_id privilege
do
  CASBIN_POLICY_ROLE_PERMISSIONS+="\np, $role_id, $resource_id, $privilege"
done < <(tail -n +2 $ROLE_PERMISSIONS_FILE)
# echo -e "$CASBIN_POLICY_ROLE_PERMISSIONS"

CASBIN_POLICY_ROLE_MEMBERSHIPS=""
while IFS="," read -r role_id member_id
do
  CASBIN_POLICY_ROLE_MEMBERSHIPS+="\ng, $member_id, $role_id"
done < <(tail -n +2 $ROLE_MEMBRERSHIPS_FILE)

# echo -e "$CASBIN_POLICY_ROLE_MEMBERSHIPS"

# Output the casbin file
cat > casbin-model.conf <<EOF
[request_definition]
r = sub, obj, act

[policy_definition]
p = sub, obj, act

[role_definition]
$(echo -e "$CASBIN_ROLE_DEFINITION")

[policy_effect]
e = some(where (p.eft == allow))

[matchers]
m = g(r.sub, p.sub) && r.obj == p.obj && r.act == p.act
EOF

cat > casbin-policy.csv <<EOF
$(echo -e "$CASBIN_POLICY_ROLE_PERMISSIONS")

$(echo -e "$CASBIN_POLICY_ROLE_MEMBERSHIPS")
EOF
