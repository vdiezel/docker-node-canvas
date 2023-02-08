Repository that contains the Dockerfile to create a custom node-canvas
binary for the AWS Lambda container with only PNG support (can be extended easily though).

You might need to sudo your commands

1. Run docker

`docker build -t canvas-node .`

2. Store the dist folder somewhere on your machine
(storing under /tmp/ here, which might end up in different folders based on distribution and how
you set up docker)

`id=$(docker create canvas-node)`
`docker cp $id:/root/dist /tmp/canvas-node-dist`

3. Take the `lib` folder from the dist and put it into the package of your
lambda function (so most likely next to the `node_modules`). Take the `canvas.node` from
node_modules/canvas/build/Release directory of the dist and store it somewhere.
You will need to overwrite the `canvas.node` binary (also in node_modules/canvas/build/Release)
in the node_modules of your lambda function with the binary from the docker container before you deploy the code to lambda!
You can also delete all libraries in the `node_modules/canvas/build/Release` directory that you either don't need
(e.g .svg, .jpeg and .gif libraries if you build your canvas without support for them). In my example, I delete all libraries there
and simply put the generated `canvas.node` there.
