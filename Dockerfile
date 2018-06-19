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
	libc6-dev-i386 \
    groff-base
    
# building llvm-2.9
COPY llvm-2.9 /opt/llvm
RUN cd /opt/llvm; ./configure --enable-optimized --enable-assertions; make -j4 install

# building llvm-gcc-4.2
RUN mkdir /opt/llvm/tools/llvm-gcc && ln -s /usr/lib/x86_64-linux-gnu /usr/lib64
COPY llvm-gcc-4.2 /opt/llvm/tools/llvm-gcc/llvm-gcc-4.2
RUN cd /opt/llvm/tools/llvm-gcc/llvm-gcc-4.2 && ./configure
ENV BUILDOPTIONS=LLVM_VERSION_INFO=2.9
RUN cd /opt/llvm/tools/llvm-gcc && mkdir obj && mkdir install && cd obj && ../llvm-gcc-4.2/configure --prefix=`pwd`/../install --program-prefix=llvm- \
    --enable-llvm=/opt/llvm --enable-languages=c,c++$EXTRALANGS $TARGETOPTIONS --disable-multilib && make -j4 $BUILDOPTIONS && make -j4 install

# building stp
COPY stp-r940 /opt/stp-r940
RUN cd /opt/stp-r940; ./scripts/configure --with-prefix=`pwd`/install --with-cryptominisat2; make OPTIMIZE=-O2 CFLAGS_M32= install; ulimit -s unlimited

# building uclibc
COPY klee-uclibc /opt/klee-uclibc
ENV PATH=$PATH:/opt/llvm/tools/llvm-gcc/install/bin
RUN cd /opt/klee-uclibc; ./configure -l; make -j4

# building zesti
COPY zesti /opt/zesti
RUN cd /opt/zesti; ./configure --with-llvm=/opt/llvm --with-stp=/opt/stp-r940/install --with-uclibc=/opt/klee-uclibc --enable-posix-runtime; make ENABLE_OPTIMIZED=1 -j4

# test zesti
RUN cd /opt/zesti; make unittests;

# building clang
COPY clang-2.9 /opt/llvm/tools/clang
RUN cd /opt/llvm; ./configure --enable-optimized --enable-assertions;
RUN ln -s /usr/lib/x86_64-linux-gnu /usr/lib64; cd /opt/llvm/tools/clang && make -j8 install

# clean up
RUN DEBIAN_FRONTEND=noninteractive apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
