docker build --no-cache --rm -f Containerfile -t beast:demo .
docker run --interactive --tty -p 8080:8080 beast:demo
echo "browse http://localhost:8080/"
