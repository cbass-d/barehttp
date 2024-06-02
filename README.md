# barehttp
A very, very, simple http server written is x86_64 assembly.

Returns a static simple HTML response when connecting to `localhost:4545`

To build:
```
$ ./build.sh
$ ./build.sh -r ## Runs the server after building
$ ./build.sh -t ## Runs the server with strace (useful for debugging) 
```
Requirements:
* nasm