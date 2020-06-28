# Remove Docker image GITHUB_SHA tag created by pipeline from Docker Hub

if [ -z ${GITHUB_SHA+x} ]; then
    echo "GITHUB_SHA not set, skipping Docker tag deletion." >&2
else
    : "${DOCKERHUB_USERNAME:?Missing DOCKERHUB_USERNAME}"
    : "${DOCKERHUB_PASSWORD:?Missing DOCKERHUB_PASSWORD}"

    echo "Deleting Docker Hub tag: ${GITHUB_SHA}" >&2

    TOKEN=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"username": "'${DOCKERHUB_USER}'",
                 "password": "'${DOCKERHUB_PASSWORD}'"}' \
                "https://hub.docker.com/v2/users/login/" | \
            jq -r .token)

    curl -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT ${TOKEN}" \
        "https://hub.docker.com/v2/repositories/elastisys/ckctl/tags/${GITHUB_SHA}/"
fi
