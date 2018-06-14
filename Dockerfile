FROM ubuntu:14.04
MAINTAINER Ridwan Shariffdeen <ridwan@comp.nus.edu.sg>


RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends --force-yes \
    bc	\
    bison   \
    curl    \
    dejagnu	\
    flex    \
    g++ \
    libcap-dev	\
    libncurses5-dev \
    make \
    python \
    python-pip \
    subversion 

RUN apt-get install -y --force-yes  \
	build-essential \
	libc6-dev-i386
    
# building llvm-2.9
COPY llvm-2.9 /opt/llvm
RUN cd /opt/llvm; ./configure --enable-optimized --enable-assertions; make

# building clang
COPY clang-2.9 /opt/llvm/tools/clang
RUN /opt/llvm/tools/clang && make install


# building stp
COPY stp-r940 /opt/stp-r940
RUN cd /opt/stp-r940; ./scripts/configure --with-prefix=`pwd`/install --with-cryptominisat2; make OPTIMIZE=-O2 CFLAGS_M32= install; ulimit -s unlimited

# building uclibc
COPY klee-uclibc /opt/klee-uclibc
ENV PATH=$PATH:/opt/llvm-2.9/Release+Asserts/bin/
RUN cd /opt/klee-uclibc; ./configure -l; make -j4

# building zesti
COPY zesti /opt/zesti
RUN cd /opt/zesti; ./configure --with-llvm=/opt/llvm-2.9 --with-stp=/opt/stp-r940/install --with-uclibc=/opt/klee-uclibc --enable-posix-runtime; make ENABLE_OPTIMIZED=1 -j4

# test zesti
RUN cd /opt/zesti; make unittests;

# clean up
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
