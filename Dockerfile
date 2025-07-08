FROM alpine:latest

WORKDIR /

ENV TZ        Asia/Shanghai
ENV LANG      zh_CN.UTF-8
ENV LANGUAGE  zh_CN.UTF-8
ENV LC_ALL    zh_CN.UTF-8

#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
RUN apk --no-cache add \
    jq \
    curl \
    unzip \
    bash \
    ca-certificates \
    tzdata

COPY update.sh update.sh
COPY entrypoints.sh entrypoints.sh

ENTRYPOINT ["sh", "-c"]
CMD ["bash", "./entrypoints.sh"]

