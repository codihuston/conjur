package main

import (
	"fmt"

	casbin "github.com/casbin/casbin/v2"
)

func main() {
	e, _ := casbin.NewEnforcer("casbin-model.conf", "casbin-policy.csv")

	sub := "cucumber:host:vault-synchronizer-hosts/lob-1/safe-1/host-1"   // the user that wants to access a resource.
	obj := "cucumber:variable:vault-synchronizer/lob-1/safe-1/variable-1" // the resource that is going to be accessed.
	act := "read"                                                         // the operation that the user performs on the resource.

	fmt.Println("Can   : ", sub)
	fmt.Println("Action: ", act)
	fmt.Println("Obj   : ", obj)
	if res, _ := e.Enforce(sub, obj, act); res {
		// permit alice to read data1
		fmt.Println("true")
	} else {
		// deny the request, show an error
		fmt.Println("false")
	}
}
