package kubernetes.admission

# Should probably restrict the namespaces to which this policy applies to (?)

# Change this list to include the allowed list of repos. 
white_list = ["my-repo"]

# We deny if there exsists any container image with a registry 
# that does not reside within the provided white-listed registries.        
deny[msg] {
    containers := get_containers(input.request.kind)
    # Compare each resource's images against the white-listed registries.
    result := [x | x := get_matching(containers[_])]
    # Check if any container image failed.
    any(result)
    # Gets info for nice message.
    cont := [x |
    result[i]
    x := {"name": containers[i].name, "image": containers[i].image}
    ]

    msg := sprintf("Container %q has invalid image repository %q.\nAllowed repositories are %v \n", [cont[j].name, cont[j].image, white_list])
}

# Determines if any image registry is not in the allowed registries.
get_matching(container) = res {
    res := count([repo |
    repo := white_list[_]
    output := split(container.image, "/")
    repo == output[0]
    ]) == 0
}

# Get containers for "Pods"
get_containers(kind) = res {
    kind.kind == "Pod"
    res := input.request.object.spec.containers
}

# Get containers for resources under the apiGroup "apps".
get_containers(kind) = res {
    kind.group == "apps"
    res := input.request.object.spec.template.spec.containers
}

# Get containers for resources under the apiGroup "extensions".
get_containers(kind) = res {
    kind.group == "extensions"
    res := input.request.object.spec.template.spec.containers
}