FROM public.ecr.aws/lambda/nodejs:16

ARG LIBS=/usr/lib64
ARG OUT=/root

# copy the test file to the container
COPY index.js .

# set up container
RUN yum -y update \
&& yum -y groupinstall "Development Tools" \
&& yum install -y gcc-c++ cairo-devel pango-devel python3

RUN npm init -y

# canvas is installed as part of chartjs-node-canvas
# (we install the chartjs-node-canvas so we can run a test)
RUN npm i chartjs-node-canvas@^4.1.6 chart.js@^3.9.1 --build-from-source

RUN mkdir lib

# moving the required libraries (we will need them when we deploy lambda)
RUN cp -L $LIBS/libpng15.so.15 lib

# We remove the original libraries simply to make our test more confident
RUN rm $LIBS/libpng15.so.15

# rebuild with new rpath; lambda containers ar started within /var/task/ as their root
# so we expect /lib to be in the root of the deployed package
# rpath sets the library path for canvas.node
RUN export LDFLAGS=-Wl,-rpath=/var/task/lib && cd node_modules/canvas && npx node-gyp rebuild

# tests to make sure our linking works

# test if the RPATH is set correctly
RUN objdump -p node_modules/canvas/build/Release/canvas.node | grep RPATH

# test if there is not secret RUNPATH that might mess with us
RUN readelf -d node_modules/canvas/build/Release/canvas.node | grep 'R.*PATH'

# check all libraries are properly linked
RUN ldd node_modules/canvas/build/Release/canvas.node

# run the render test
RUN node index.js

# copy to a dist folder
RUN mkdir $OUT/dist
RUN cp -Lra . $OUT/dist

RUN ldd $OUT/dist/node_modules/canvas/build/Release/canvas.node

# This tests if moving around our files broke the linking
# RUN ldd $OUT/dist/node_modules/canvas/build/Release/canvas.node
