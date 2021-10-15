FROM ubuntu:20.04 as builder
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

#生成libbcc的deb包: libbcc_0.22.0-1_amd64.deb
RUN cd /root/bcc && \
    /usr/lib/pbuilder/pbuilder-satisfydepends && \
    PARALLEL=$(nproc) ./scripts/build-deb.sh release

#安装libbcc.so
FROM ubuntu:20.04
LABEL maintainer="rubinus.chu@mail.com"

#替换aliyun
RUN  sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
RUN  apt clean && apt update

#设置zone为国内
ENV  TZ=Asia/Shanghai
RUN  apt -y install --no-install-recommends tzdata && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt -y install --no-install-recommends libelf1
COPY --from=builder /root/bcc/libbcc_*.deb /tmp/libbcc.deb

RUN dpkg -i /tmp/libbcc.deb

RUN rm -rf /tmp/* && rm -rf /var/cache/apk/* && rm -rf /var/lib/apt/lists/* && apt autoremove

#设置工作目录
WORKDIR /go/

#添加可执行文件
COPY ./ebpf_exporter /go/
COPY ./examples /go/examples

RUN ["chmod", "+x", "ebpf_exporter"]

#设置Web端口，一般不用更改
EXPOSE 9435

ENTRYPOINT ["/go/ebpf_exporter"]
