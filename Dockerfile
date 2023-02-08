FROM public.ecr.aws/lambda/nodejs:16

ARG LIBS=/usr/lib64
ARG OUT=/root

# DEBUGGING: copy the test file to the container
# COPY index.js .

# DEBUGGING: store libraries that are part of the image for
# comparison which libraries are added after "yum install"
RUN ls $LIBS > before.txt

# set up container
# if you want to install support for .jpeg, .gif or .svg, you will need more packages here
# because we only use what is required for .png here!
# There are some infos based on platform/distribution here:
# https://github.com/Automattic/node-canvas/wiki

RUN yum -y update \
&& yum -y groupinstall "Development Tools" \
&& yum install -y gcc-c++ cairo-devel pango-devel python3

# DEBUGGING: To check which libraries are added
RUN ls $LIBS > after.txt

RUN npm init -y

# DEBUGGING: canvas is installed as part of chartjs-node-canvas
# (we install the chartjs-node-canvas so we can run a test)
# Use this instead of "npm i canvas" only if you want to run a test agains the index.js
# RUN npm i chartjs-node-canvas@^4.1.6 chart.js@^3.9.1 --build-from-source

RUN npm i canvas --build-from-source

RUN mkdir lib

# moving the required libraries (we will need them when we deploy lambda);
# do not use "mv" as it breaks symbolic links!!!
# How do you now which libraies are required?
# 1. The build process might fail telling you what is missing
# 2. The "ldd" command prints out what libraries are dynamicly linked
# and where the canvas.node expects them to be
#
# This part is annoying and will require tinkering if you use another runtime:
#
# I simply copied all required libraries from 'ldd' here.
# I've commented the ones that come with the lambda container (check the file
# that lists all present libraries in /lib64 on AWS Lambda Node16, because somehow
# they are different than what this docker container provides)

# Total lib size: 8MB

RUN cp -L $LIBS/libpixman-1.so.0 lib/ \
&& cp -L $LIBS/libcairo.so.2 lib/ \
&& cp -L $LIBS/libpng15.so.15 lib/ \
&& cp -L $LIBS/libpangocairo-1.0.so.0 lib/ \
&& cp -L $LIBS/libpango-1.0.so.0 lib/ \
&& cp -L $LIBS/libgobject-2.0.so.0 lib/ \
&& cp -L $LIBS/libglib-2.0.so.0 lib/ \
# && cp -L $LIBS/libfreetype.so.6 lib/ \
# && cp -L $LIBS/libstdc++.so.6 lib/ \
# && cp -L $LIBS/libm.so.6 lib/ \
# && cp -L $LIBS/libgcc_s.so.1 lib/ \
# && cp -L $LIBS/libpthread.so.0 lib/ \
# && cp -L $LIBS/libc.so.6 lib/ \
&& cp -L $LIBS/libfontconfig.so.1 lib/ \
&& cp -L $LIBS/libEGL.so.1 lib/ \
# && cp -L $LIBS/libdl.so.2 lib/ \
&& cp -L $LIBS/libxcb-shm.so.0 lib/ \
&& cp -L $LIBS/libxcb.so.1 lib/ \
&& cp -L $LIBS/libxcb-render.so.0 lib/ \
&& cp -L $LIBS/libXrender.so.1 lib/ \
&& cp -L $LIBS/libX11.so.6 lib/ \
&& cp -L $LIBS/libXext.so.6 lib/ \
# && cp -L $LIBS/libz.so.1 lib/ \
&& cp -L $LIBS/libGL.so.1 lib/ \
# && cp -L $LIBS/librt.so.1 lib/ \
&& cp -L $LIBS/libpangoft2-1.0.so.0 lib/ \
&& cp -L $LIBS/libthai.so.0 lib/ \
&& cp -L $LIBS/libfribidi.so.0 lib/ \
# && cp -L $LIBS/libpcre.so.1 lib/ \
# && cp -L $LIBS/libffi.so.6 lib/ \
# && cp -L $LIBS/libbz2.so.1 lib/ \
# && cp -L $LIBS/libexpat.so.1 lib/ \
# && cp -L $LIBS/libuuid.so.1 lib/ \
&& cp -L $LIBS/libGLdispatch.so.0 lib/ \
&& cp -L $LIBS/libXau.so.6 lib/ \
&& cp -L $LIBS/libGLX.so.0 lib/ \
&& cp -L $LIBS/libharfbuzz.so.0 lib/ \
&& cp -L $LIBS/libgraphite2.so.3 lib/

# rebuild with new rpath; lambda containers are started within /var/task/ as their root
# so we expect /lib to be in the root of the deployed package
# rpath sets the library path for canvas.node
RUN export LDFLAGS=-Wl,-rpath=/var/task/lib && cd node_modules/canvas && npx node-gyp rebuild

# DEBUGGING: test if the RPATH is set correctly
# You expect your RPATH to point to what you have defined in rpath above
RUN objdump -p node_modules/canvas/build/Release/canvas.node | grep RPATH

# DEBUGGING: test if there is not secret RUNPATH that might mess with us
# You expect not seeing a RUNPATH as it might interfere with RPATH
RUN readelf -d node_modules/canvas/build/Release/canvas.node | grep 'R.*PATH'

# DEBUGGING: check all libraries are properly linked
# You expect that no library points to "not found"
# otherwise you either did not install it, didn't put it into your rpath
# or didn't set the correct rpath for the LDFLAGS
RUN ldd node_modules/canvas/build/Release/canvas.node

# DEBUGGING: run the render test
# creates a "test.png" in the dist that should show a graph
# RUN node index.js

# copy to a dist folder
RUN mkdir $OUT/dist
RUN cp -Lra . $OUT/dist

# DEBUGGING: This tests if moving around our files broke the linking
# RUN ldd $OUT/dist/node_modules/canvas/build/Release/canvas.node
