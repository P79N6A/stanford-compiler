FROM ubuntu:xenial
ENV http_proxy http://web-proxy.tencent.com:8080
ENV https_proxy http://web-proxy.tencent.com:8080
RUN mv /etc/apt/sources.list .sources.bak
COPY sources.list /etc/apt/sources.list
RUN apt-get update && apt-get upgrade --assume-yes
RUN apt-get install --assume-yes flex bison build-essential 
ADD . /stanford-compiler
RUN export PATH=/stanford-compiler/cool/bin:$PATH
