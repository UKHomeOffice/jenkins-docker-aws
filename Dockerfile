FROM quay.io/ukhomeofficedigital/centos-base:v0.2.0

#RUN rpm -iUvh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
RUN yum install -y wget && wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm && \
  rpm -ivh epel-release-7-6.noarch.rpm


RUN yum install -y -q python-pip java-headless fontconfig dejavu-sans-fonts git parallel which; yum clean all; pip install awscli

# Install jenkins
ENV JENKINS_VERSION 1.620
RUN yum install -y -q http://pkg.jenkins-ci.org/redhat/jenkins-${JENKINS_VERSION}-1.1.noarch.rpm

#ADD docker.repo /etc/yum.repos.d/docker.repo

ENV DOCKER_VERSION 1.10.3
# Install docker (NB: Must mount in docker socket for it to work)
#RUN curl -O -sSL https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-${DOCKER_VERSION}-1.el7.centos.x86_64.rpm
#RUN rpm -iUvh docker-engine-${DOCKER_VERSION}-1.el7.centos.x86_64.rpm
ENV DVM_VERSION 0.4.0

RUN curl -s https://raw.githubusercontent.com/getcarina/dvm/${DVM_VERSION}/install.sh | sh && \
  source /root/.dvm/dvm.sh && \
  dvm install ${DOCKER_VERSION}

RUN echo source /root/.dvm/dvm.sh >> /root/.bashrc && echo dvm install ${DOCKER_VERSION} >> /root/.bashrc
#RUN yum update && yum install -y docker-engine-${DOCKER_VERSION}-1.el7.centos

# Install kubectl
ENV KUBE_VER=1.2.2
ENV KUBE_URL=https://storage.googleapis.com/kubernetes-release/release/v${KUBE_VER}/bin/linux/amd64/kubectl
RUN /bin/bash -l -c "wget --quiet ${KUBE_URL} \
                     -O /usr/local/bin/kubectl && \
                     chmod +x /usr/local/bin/kubectl"

# Install S3 Secrets
RUN /usr/bin/mkdir -p /opt/bin
RUN URL=https://github.com/UKHomeOffice/s3secrets/releases/download/v0.1.3/s3secrets_v0.1.3_linux_x86_64 OUTPUT_FILE=/opt/bin/s3secrets MD5SUM=ec5bc16e6686c365d2ca753d31d62fd5 /usr/bin/bash -c 'until [[ -x ${OUTPUT_FILE} ]] && [[ $(md5sum ${OUTPUT_FILE} | cut -f1 -d" ") == ${MD5SUM} ]]; do wget -q -O ${OUTPUT_FILE} ${URL} && chmod +x ${OUTPUT_FILE}; done'

ENV JENKINS_HOME /var/lib/jenkins

ADD jenkins.sh /srv/jenkins/jenkins.sh
ADD jenkins_backup.sh /srv/jenkins/jenkins_backup.sh

# User config / updates
# JENKINS_UC is needed to download plugins
ENV JENKINS_UC https://updates.jenkins.io
COPY plugins.sh /usr/local/bin/plugins.sh
COPY plugins.base.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.base.txt
COPY plugins.txt /usr/share/jenkins/ref/
RUN /usr/local/bin/plugins.sh /usr/share/jenkins/ref/plugins.txt

EXPOSE 8080
VOLUME /var/lib/jenkins
WORKDIR /var/lib/jenkins

ENTRYPOINT ["/srv/jenkins/jenkins.sh"]
