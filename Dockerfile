FROM public.ecr.aws/lambda/nodejs:16

ARG LIBS=/usr/lib64
ARG OUT=/root

# copy the test file to the container
COPY index.js .

# set up container
RUN yum -y update \
&& yum -y groupinstall "Development Tools" \
&& yum install -y gcc-c++ cairo-devel pango-devel python3

RUN ls $LIBS

# canvas is installed as part of chartjs-node-canvas
RUN npm init -y

# make sure we look for binaries in the lib folder first
RUN npm i chartjs-node-canvas@^4.1.6 chart.js@^3.9.1 --build-from-source
RUN export LDFLAGS=-Wl,-rpath=/var/task/lib && cd node_modules/canvas && npx node-gyp rebuild

# moving the required libraries (as they are expected to be delived with the lamdba)
RUN mkdir lib
RUN mv $LIBS/libpng15.so.15 lib/
# RUN ls lib

# This is required to mimic where lambda tries to lookup the lib (for the test)
#RUN cp -r lib /var/task/

# run test
#RUN ls
#RUN ls node_modules/canvas/build/Release/

# copy to a dist folder
#RUN ls $LIBS
RUN mkdir $OUT/dist
RUN cp -ra . $OUT/dist
RUN ldd $OUT/dist/node_modules/canvas/build/Release/canvas.node

RUN node index.js
