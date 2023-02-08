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
# This part is annoying and will require tinkering
#
# I simply copied all required libraries here (15MB in this case). You can put in more effort
# and figure out which libaries are installed in your lambda container and
# not copy them.
# I tried shortly but failed (see commented package list below), either because I broke the linking to the
# present libraries in /lib64 or because the package I tested it on was
# actually on the docker container but not in our deployed lambda in AWS
# (which would be scary), so I hope I messed up.

RUN cp -L $LIBS/libpixman-1.so.0 lib/ \
&& cp -L $LIBS/libcairo.so.2 lib/ \
&& cp -L $LIBS/libpng15.so.15 lib/ \
&& cp -L $LIBS/libpangocairo-1.0.so.0 lib/ \
&& cp -L $LIBS/libpango-1.0.so.0 lib/ \
&& cp -L $LIBS/libgobject-2.0.so.0 lib/ \
&& cp -L $LIBS/libglib-2.0.so.0 lib/ \
&& cp -L $LIBS/libfreetype.so.6 lib/ \
&& cp -L $LIBS/libstdc++.so.6 lib/ \
&& cp -L $LIBS/libm.so.6 lib/ \
&& cp -L $LIBS/libgcc_s.so.1 lib/ \
&& cp -L $LIBS/libpthread.so.0 lib/ \
&& cp -L $LIBS/libc.so.6 lib/ \
&& cp -L $LIBS/libfontconfig.so.1 lib/ \
&& cp -L $LIBS/libEGL.so.1 lib/ \
&& cp -L $LIBS/libdl.so.2 lib/ \
&& cp -L $LIBS/libxcb-shm.so.0 lib/ \
&& cp -L $LIBS/libxcb.so.1 lib/ \
&& cp -L $LIBS/libxcb-render.so.0 lib/ \
&& cp -L $LIBS/libXrender.so.1 lib/ \
&& cp -L $LIBS/libX11.so.6 lib/ \
&& cp -L $LIBS/libXext.so.6 lib/ \
&& cp -L $LIBS/libz.so.1 lib/ \
&& cp -L $LIBS/libGL.so.1 lib/ \
&& cp -L $LIBS/librt.so.1 lib/ \
&& cp -L $LIBS/libpangoft2-1.0.so.0 lib/ \
&& cp -L $LIBS/libthai.so.0 lib/ \
&& cp -L $LIBS/libfribidi.so.0 lib/ \
&& cp -L $LIBS/libpcre.so.1 lib/ \
&& cp -L $LIBS/libffi.so.6 lib/ \
&& cp -L $LIBS/libbz2.so.1 lib/ \
&& cp -L $LIBS/libexpat.so.1 lib/ \
&& cp -L $LIBS/libuuid.so.1 lib/ \
&& cp -L $LIBS/libGLdispatch.so.0 lib/ \
&& cp -L $LIBS/libXau.so.6 lib/ \
&& cp -L $LIBS/libGLX.so.0 lib/ \
&& cp -L $LIBS/libharfbuzz.so.0 lib/ \
&& cp -L $LIBS/libgraphite2.so.3 lib/

# These are the only libraries that are not part of
# the image, but somehow I still had to copy all dependencies
# in order to get lambda running, so we end up with 15MB instead of 7MB

#RUN cp -L $LIBS/libpng15.so.15 lib \
#&& cp -L $LIBS/libpixman-1.so.0 lib \
#&& cp -L $LIBS/libcairo.so.2 lib \
#&& cp -L $LIBS/libpangocairo-1.0.so.0 lib \
#&& cp -L $LIBS/libpango-1.0.so.0 lib \
#&& cp -L $LIBS/libpangoft2-1.0.so.0 lib \
#&& cp -L $LIBS/libharfbuzz.so.0 lib \
#&& cp -L $LIBS/libgraphite2.so.3 lib \
#&& cp -L $LIBS/libgobject-2.0.so.0 lib \
#&& cp -L $LIBS/libEGL.so.1 lib \
#&& cp -L $LIBS/libxcb-shm.so.0 lib \
#&& cp -L $LIBS/libxcb.so.1 lib \
#&& cp -L $LIBS/libxcb-render.so.0 lib \
#&& cp -L $LIBS/libXrender.so.1 lib \
#&& cp -L $LIBS/libX11.so.6 lib \
#&& cp -L $LIBS/libXext.so.6 lib \
#&& cp -L $LIBS/libGL.so.1 lib \
#&& cp -L $LIBS/libthai.so.0 lib \
#&& cp -L $LIBS/libfribidi.so.0 lib \
#&& cp -L $LIBS/libGLdispatch.so.0 lib \
#&& cp -L $LIBS/libXau.so.6 lib \
#&& cp -L $LIBS/libGLX.so.0 lib

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

# DEBUGGING: We remove the original libraries simply to make our test more confident
#RUN rm $LIBS/libpixman-1.so.0 \
#&& rm $LIBS/libcairo.so.2 \
#&& rm $LIBS/libpng15.so.15 \
#&& rm $LIBS/libpangocairo-1.0.so.0 \
#&& rm $LIBS/libpango-1.0.so.0 \
#&& rm $LIBS/libgobject-2.0.so.0 \
#&& rm $LIBS/libglib-2.0.so.0 \
#&& rm $LIBS/libfreetype.so.6 \
#&& rm $LIBS/libstdc++.so.6 \
#&& rm $LIBS/libm.so.6 \
#&& rm $LIBS/libgcc_s.so.1 \
#&& rm $LIBS/libpthread.so.0 \
#&& rm $LIBS/libc.so.6 \
#&& rm $LIBS/libfontconfig.so.1 \
#&& rm $LIBS/libEGL.so.1 \
#&& rm $LIBS/libdl.so.2 \
#&& rm $LIBS/libxcb-shm.so.0 \
#&& rm $LIBS/libxcb.so.1 \
#&& rm $LIBS/libxcb-render.so.0 \
#&& rm $LIBS/libXrender.so.1 \
#&& rm $LIBS/libX11.so.6 \
#&& rm $LIBS/libXext.so.6 \
#&& rm $LIBS/libz.so.1 \
#&& rm $LIBS/libGL.so.1 \
#&& rm $LIBS/librt.so.1 \
#&& rm $LIBS/libpangoft2-1.0.so.0 \
#&& rm $LIBS/libthai.so.0 \
#&& rm $LIBS/libfribidi.so.0 \
#&& rm $LIBS/libpcre.so.1 \
#&& rm $LIBS/libffi.so.6 \
#&& rm $LIBS/libbz2.so.1 \
#&& rm $LIBS/libexpat.so.1 \
#&& rm $LIBS/libuuid.so.1 \
#&& rm $LIBS/libGLdispatch.so.0 \
#&& rm $LIBS/libXau.so.6 \
#&& rm $LIBS/libGLX.so.0 \
#&& rm $LIBS/libharfbuzz.so.0 \
#&& rm $LIBS/libgraphite2.so.3

# DEBUGGING: run the render test
# creates a "test.png" in the dist that should show a graph
# RUN node index.js

# copy to a dist folder
RUN mkdir $OUT/dist
RUN cp -Lra . $OUT/dist

# DEBUGGING: This tests if moving around our files broke the linking
# RUN ldd $OUT/dist/node_modules/canvas/build/Release/canvas.node
