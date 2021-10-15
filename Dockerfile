FROM ubuntu:20.04
LABEL maintainer="rubinus.chu@mail.com"

#替换aliyun
RUN  sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN  apt-get clean && apt-get update

#设置zone为国内
ENV  TZ=Asia/Shanghai
RUN  apt-get -y install tzdata && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

#安装aliyun没有的deb包 for perl
RUN apt-get -y install dpkg-dev
COPY libsereal-encoder-perl_4.011+ds-1build1_amd64.deb /root/
RUN dpkg -i /root/libsereal-encoder-perl_4.011+ds-1build1_amd64.deb

#安装编译工具
RUN  apt-get -y install gcc g++ libc-dev libc6-dev make pbuilder build-essential

RUN  apt-get -y install aptitude

#复制bcc源代码
COPY bcc /root/bcc

#生成libbcc的deb包
RUN cd /root/bcc && \
    /usr/lib/pbuilder/pbuilder-satisfydepends && \
    PARALLEL=$(nproc) ./scripts/build-deb.sh release

#安装libbcc.so
RUN dpkg -i /root/bcc/libbcc_*.deb && rm -rf /var/cache/apt

#设置工作目录
WORKDIR /go/

#添加可执行文件
COPY ./ebpf_exporter /go/
COPY ./examples /go/examples

RUN ["chmod", "+x", "ebpf_exporter"]

#设置Web端口，一般不用更改
EXPOSE 9435


ENTRYPOINT ["/go/ebpf_exporter","--config.file=examples/accept.yaml"]
