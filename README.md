Repository that contains the Dockerfile to create a node-canvas
binary for the AWS Lambda container

You might need to sudo your commands

1. Run docker

`docker build -t canvas-node .`

2. Store the dist folder somewhere on your machine
(storing under /tmp/ here, which might up in different folders based on distribution)

`id=$(docker create canvas-node)`
`docker cp $id:/root/dist /tmp/canvas-node-dist`
