FROM quay.io/bashell/alpine-bash:latest

MAINTAINER Chaiwat Suttipongsakul "cwt@bashell.com"

RUN apk update && apk upgrade \
 && apk add python py-virtualenv openssl ca-certificates git \
 && rm -rf /var/cache/*/*

RUN apk update && apk upgrade \
 && apk add python-dev musl-dev gcc make \
 && mv /usr/bin/make /usr/bin/make.orig \
 && echo '#!/bin/bash' > /usr/bin/make \
 && echo '/usr/bin/make.orig -j `nproc` $*' >> /usr/bin/make \
 && chmod 755 /usr/bin/make \
 && cd / && virtualenv kallithea \
 && /kallithea/bin/pip install futures \
 && /kallithea/bin/pip install gunicorn \
 && /kallithea/bin/pip install "gevent<1.3" \
 && /kallithea/bin/pip install supervisor \
 && /kallithea/bin/pip install kallithea \
 && rm -f /usr/bin/make \
 && mv /usr/bin/make.orig /usr/bin/make \
 && apk del python-dev musl-dev gcc make \
 && rm -rf /root/.cache && rm -rf /var/cache/*/* \
 && for cache in `find /kallithea -iname '*.py[co]'`; do rm -f $cache; done \
 && mkdir -p /kallithea/var/repo

ADD supervisord.conf /kallithea/var/supervisord.conf
ADD production.ini /kallithea/var/production.ini

WORKDIR /kallithea/var

RUN /kallithea/bin/paster setup-db --user=admin \
                                   --password=password \
                                   --email=admin@example.com \
                                   --repos=/kallithea/var/repo \
                                   --force-yes \
                           /kallithea/var/production.ini > /dev/null

VOLUME [/kallithea/var]

EXPOSE 5000/tcp

CMD ["/kallithea/bin/supervisord","-c","/kallithea/var/supervisord.conf"]

