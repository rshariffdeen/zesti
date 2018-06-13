FROM ubuntu:14.04
MAINTAINER Ridwan Shariffdeen <ridwan@comp.nus.edu.sg>

# create directories
RUN mkdir /zesti
COPY llvm-2.9 /zesti/llvm-2.9
COPY zesti /zesti/zesti


# preparing environment

RUN apt-get update
RUN apt-get install \
    curl    \
    g++ \
    bison   \
    flex    \
    bc

# building llvm-2.9
COPY llvm-2.9.tgz /zesti/llvm-2.9.tgz
RUN cd /zesti; tar zxvf llvm-2.9.tgz; cd llvm-2.9; ./configure --enable-optimized --enable-assertions; make