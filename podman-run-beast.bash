podman build --no-cache --rm --file Containerfile --tag beast:demo .
podman run --interactive --tty --publish 8080:8080 beast:demo
echo "browse http://localhost:8080/"
