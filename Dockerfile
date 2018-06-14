FROM ubuntu:14.04
MAINTAINER Ridwan Shariffdeen <ridwan@comp.nus.edu.sg>

# preparing environment
RUN mkdir /zesti && mkdir /llvm-clang-src

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y  --no-install-recommends --force-yes \
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
    subversion  \
    wget

RUN echo "deb http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" >> /etc/apt/sources.list  &&  \
    echo "deb-src http://llvm.org/apt/trusty/ llvm-toolchain-trusty-3.4 main" >> /etc/apt/sources.list && \
    wget -O - http://llvm.org/apt/llvm-snapshot.gpg.key|sudo apt-key add -  

RUN apt-get update && apt-get install -y --force-yes  \
        build-essential \
        libc6-dev-i386 
    
# building llvm-3.4.2
COPY llvm-3.4.2 /llvm-clang-src/llvm
COPY clang-3.4.2 /llvm-clang-src/llvm/tools/clang
COPY compiler-rt-3.4 /llvm-clang-src/llvm/projects/compiler-rt
RUN mkdir /llvm-clang-src/build; cd /llvm-clang-src/build ; ../llvm/configure --enable-optimized --enable-assertions; make -j4


# building stp
COPY stp-r940 /opt/stp-r940
RUN cd /opt/stp-r940; ./scripts/configure --with-prefix=`pwd`/install --with-cryptominisat2; make OPTIMIZE=-O2 CFLAGS_M32= install; ulimit -s unlimited

# building uclibc
COPY klee-uclibc /opt/klee-uclibc
ENV PATH=$PATH:/llvm-clang-src/build/Release+Asserts/bin/
RUN cd /opt/klee-uclibc; ./configure -l; make -j4

# building zesti
COPY zesti /opt/zesti
RUN cd /opt/zesti; ./configure --with-stp=/opt/stp-r940/install --with-uclibc=/opt/klee-uclibc --enable-posix-runtime; make ENABLE_OPTIMIZED=1 -j4

# test zesti
RUN cd /opt/zesti; make unittests;

# clean up
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
