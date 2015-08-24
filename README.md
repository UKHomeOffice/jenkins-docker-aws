# DOCKER JENKINS
This folder contains the build for a docker image of jenkins with given plugins. Full documentation is given below about how this jenkins enables backing up and restoring of config from Amazon S3.

If you make updates to the jenkins docker image you will need to push these to docker hub and update the AWS cloud formation template to use the later version (../templates/cimngt.yaml).

To automatically build and push a new version to docker hub from this folder run:
$ ./build_and_push.sh <username>/<reponame>:<tag>
e.g.
./build_and_push.sh timgent/aws-jenkins:v0.5

# General jenkins-docker notes

Docker built image is hosted here: https://registry.hub.docker.com/u/state/jenkins/

Jenkins docker image. Jenkins configuration can be synced from AWS S3 bucket at
startup.

By default there is only one-way configuration sync, but you can set up a jenkins
job which syncs `${JENKINS_HOME}` to the same S3 bucket, so next time you start
this container you will have all your config loaded at startup time.

If `JENKINS_HOME_S3_BUCKET_NAME` is set, bucket config will be written out to
`/etc/jenkins-bucket-config`, which is used by
`/srv/jenkins/jenkins_backup.sh`. So you can just simply create a jenkins job
which runs the backup script.

The image is based on Fedora base image. It has docker, git, aws cli tools and
obviously Jenkins preinstall.

## Configuration

Configuration is done using environment variables.

Authentication to S3 bucket can be passed in via `AWS_SECRET_ACCESS_KEY` and
`AWS_ACCESS_KEY_ID` or EC2 instance IAM role.

- `JENKINS_HOME` Default: `/var/lib/jenkins`. If you decide to change this,
  make sure you run docker container with `-v <new_jenkins_home>` set
- `JENKINS_HOME_S3_BUCKET_NAME` Default: unset. If unset, config sync will not run
- `JAVA_OPTS` Default: unset.
- `JENKINS_OPTS` Default: unset. Any valid jenkins parameter is supported

## Running

```bash
docker run \
  -e AWS_SECRET_ACCESS_KEY=xxx \
  -e AWS_ACCESS_KEY_ID=xxx \
  -e JENKINS_HOME_S3_BUCKET_NAME=example-jenkinsconfig-us-east-1 \
  -p 8080:8080 state/jenkins
```
