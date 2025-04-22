# syntax=docker/dockerfile:1
FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y

RUN apt-get install build-essential git autotools-dev automake cmake -y
RUN apt-get install libsctp-dev cmake-curses-gui libpcre2-dev python3 python3-pip python3-dev -y
RUN apt-get install bison byacc -y

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir matplotlib tikzplotlib

# SWIG Installation
RUN git clone https://github.com/swig/swig.git
RUN cd swig && git checkout release-4.1 && ./autogen.sh && ./configure --prefix=/usr/ && make -j8 && make install

# FlexRIC Installation
RUN git clone https://gitlab.eurecom.fr/mosaic5g/flexric.git && \
    cd flexric && \
    git checkout tags/v2.0.0

ADD ./dos /flexric/dos
COPY ./patches/dos.patch /flexric/
COPY ./patches/prevention.patch /flexric/


ARG DOS_PREV_ENABL
ENV DOS_PREV_ENABLER $DOS_PREV_ENABL

RUN echo $DOS_PREV_ENABLER

RUN cd flexric && git apply -v ./dos.patch && git apply -v ./prevention.patch && mkdir build && cd build && cmake -DDOS_PREV_BOOL=${DOS_PREV_ENABLER} .. && make -j8 && make install

RUN chmod +x ./flexric/dos/start.sh
CMD ./flexric/dos/start.sh ${START_MODE}
