FROM public.ecr.aws/lambda/nodejs:16

ARG LIBS=/usr/lib64
ARG OUT=/root

# copy the test file to the container
COPY index.js .

RUN ls $LIBS > before.txt

# set up container
RUN yum -y update \
&& yum -y groupinstall "Development Tools" \
&& yum install -y gcc-c++ cairo-devel pango-devel python3

RUN ls $LIBS > after.txt

RUN npm init -y

# canvas is installed as part of chartjs-node-canvas
# (we install the chartjs-node-canvas so we can run a test)
RUN npm i chartjs-node-canvas@^4.1.6 chart.js@^3.9.1 --build-from-source

RUN mkdir lib

# moving the required libraries (we will need them when we deploy lambda)
# do not use "mv" as it breaks symbolic links!!!
# if you don't care duplicating binaries, you can jsut copy all of them...
RUN cp -L $LIBS/libpng15.so.15 lib \
&& cp -L $LIBS/libpixman-1.so.0 lib \
&& cp -L $LIBS/libcairo.so.2 lib \
&& cp -L $LIBS/libpangocairo-1.0.so.0 lib \
&& cp -L $LIBS/libpango-1.0.so.0 lib \
&& cp -L $LIBS/libpangoft2-1.0.so.0 lib \
&& cp -L $LIBS/libharfbuzz.so.0 lib \
&& cp -L $LIBS/libgraphite2.so.3 lib \
&& cp -L $LIBS/libgobject-2.0.so.0 lib \
&& cp -L $LIBS/libEGL.so.1 lib \
&& cp -L $LIBS/libxcb-shm.so.0 lib \
&& cp -L $LIBS/libxcb.so.1 lib \
&& cp -L $LIBS/libxcb-render.so.0 lib \
&& cp -L $LIBS/libXrender.so.1 lib \
&& cp -L $LIBS/libX11.so.6 lib \
&& cp -L $LIBS/libXext.so.6 lib \
&& cp -L $LIBS/libGL.so.1 lib \
&& cp -L $LIBS/libthai.so.0 lib \
&& cp -L $LIBS/libfribidi.so.0 lib \
&& cp -L $LIBS/libGLdispatch.so.0 lib \
&& cp -L $LIBS/libXau.so.6 lib \
&& cp -L $LIBS/libGLX.so.0 lib

# rebuild with new rpath; lambda containers are started within /var/task/ as their root
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

# We remove the original libraries simply to make our test more confident
RUN rm $LIBS/libpng15.so.15 \
&& rm $LIBS/libpixman-1.so.0 \
&& rm $LIBS/libcairo.so.2 \
&& rm $LIBS/libpangocairo-1.0.so.0 \
&& rm $LIBS/libpango-1.0.so.0 \
&& rm $LIBS/libpangoft2-1.0.so.0 \
&& rm $LIBS/libharfbuzz.so.0 \
&& rm $LIBS/libgraphite2.so.3 \
&& rm $LIBS/libgobject-2.0.so.0 \
&& rm $LIBS/libEGL.so.1 \
&& rm $LIBS/libxcb-shm.so.0 \
&& rm $LIBS/libxcb.so.1 \
&& rm $LIBS/libxcb-render.so.0 \
&& rm $LIBS/libXrender.so.1 \
&& rm $LIBS/libX11.so.6 \
&& rm $LIBS/libXext.so.6 \
&& rm $LIBS/libGL.so.1 \
&& rm $LIBS/libthai.so.0 \
&& rm $LIBS/libfribidi.so.0 \
&& rm $LIBS/libGLdispatch.so.0 \
&& rm $LIBS/libXau.so.6 \
&& rm $LIBS/libGLX.so.0


# run the render test
RUN node index.js

# copy to a dist folder
RUN mkdir $OUT/dist
RUN cp -Lra . $OUT/dist

RUN ldd $OUT/dist/node_modules/canvas/build/Release/canvas.node

# This tests if moving around our files broke the linking
# RUN ldd $OUT/dist/node_modules/canvas/build/Release/canvas.node
