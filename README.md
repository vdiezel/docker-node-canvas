I have modified the bindings

$ docker build -t canvas-libs .
$ id=$(docker create canvas-libs)
$ docker cp $id:/root/dist ./path/to/function/dist
