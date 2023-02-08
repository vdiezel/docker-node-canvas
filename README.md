Repository that contains the Dockerfile to create a node-canvas
binary for the AWS Lambda container

You might need to sudo your commands

1. Run docker

`docker build -t canvas-node .`

2. Store the dist folder somewhere on your machine
(storing under /tmp/ here, which might end up in different folders based on distribution)

`id=$(docker create canvas-node)`
`docker cp $id:/root/dist /tmp/canvas-node-dist`

3. Take the `lib` folder from the dist and put it into the service that
contains lambda functions that need canvas. Take the `canvas.node` from
node_modules/canvas/build/Release directory and store it somewhere in your
service directory. You will need to overwrite the `canvas.node` binary
in the node_modules of your service before you deploy code to lambda!
