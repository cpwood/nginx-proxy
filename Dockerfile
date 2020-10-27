FROM nginx:1.19.3
LABEL maintainer="Jason Wilder mail@jasonwilder.com"
ARG TARGETPLATFORM

# Install wget and install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
    wget \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*


# Configure Nginx and apply fix for very long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/worker_processes  1/worker_processes  auto/' /etc/nginx/nginx.conf

# Install Forego
RUN if ["$TARGETPLATFORM" = "linux/amd64"] ; then wget -O forego.tgz https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz ; fi
RUN if ["$TARGETPLATFORM" = "linux/arm/v7"] ; then wget -O forego.tgz https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-arm.tgz ; fi
RUN if ["$TARGETPLATFORM" = "linux/arm64"] ; then wget -O forego.tgz https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-arm64.tgz ; fi

RUN tar xvf forego.tgz -C /usr/local/bin && \
	chmod u+x /usr/local/bin/forego

# https://bin.equinox.io/c/ekMN3bCZFUn/forego-stable-linux-amd64.tgz
RUN chmod u+x /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.7.4

RUN if ["$TARGETPLATFORM" = "linux/amd64"] ; then wget -O dockergen.tar.gz https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-amd64-$DOCKER_GEN_VERSION.tar.gz ; fi
RUN if ["$TARGETPLATFORM" = "linux/arm/v7"] ; then wget -O dockergen.tar.gz https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-armhf-$DOCKER_GEN_VERSION.tar.gz ; fi
RUN if ["$TARGETPLATFORM" = "linux/arm64"] ; then wget -O dockergen.tar.gz https://github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-linux-armhf-$DOCKER_GEN_VERSION.tar.gz ; fi

RUN tar -C /usr/local/bin -xvzf dockergen.tar.gz \
 && rm /dockergen.tar.gz

COPY network_internal.conf /etc/nginx/

COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs", "/etc/nginx/dhparam"]

ENTRYPOINT ["/app/docker-entrypoint.sh"]
CMD ["forego", "start", "-r"]
