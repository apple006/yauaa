#!/bin/bash

[ -f "httpdlog-pigloader-2.7-udf.jar" ] || wget http://repo1.maven.org/maven2/nl/basjes/parse/httpdlog/httpdlog-pigloader/2.7/httpdlog-pigloader-2.7-udf.jar
rsync ../../udfs/dissector/target/yauaa-logparser-*-udf.jar yauaa-logparser.jar

if [ "${USER}" = "" ]; then
  USER=$(id -un)
fi

PROJECTNAME=examples
CONTAINER_NAME=${PROJECTNAME}-${USER}-$$

docker build -t ${PROJECTNAME} docker

if [ "$(uname -s)" == "Linux" ]; then
  USER_NAME=${SUDO_USER:=${USER}}
  USER_ID=$(id -u ${USER_NAME})
  GROUP_ID=$(id -g ${USER_NAME})
else # boot2docker uid and gid
  USER_NAME=${USER}
  USER_ID=1000
  GROUP_ID=50
fi

docker build -t ${PROJECTNAME}-${USER_NAME} - <<UserSpecificDocker
FROM ${PROJECTNAME}
RUN groupadd -g ${GROUP_ID} ${USER_NAME} || true
RUN useradd -g ${GROUP_ID} -u ${USER_ID} -k /root -m ${USER_NAME}
ENV HOME /home/${USER_NAME}
UserSpecificDocker

docker run --rm=true -t -i                                    \
           -u ${USER_NAME}                                    \
           -v ${PWD}:/home/${USER_NAME}/${PROJECTNAME}        \
           -w /home/${USER}/${PROJECTNAME}                    \
           --name "${CONTAINER_NAME}"                         \
           ${PROJECTNAME}-${USER_NAME}                  \
           pig -x local TopOperatingSystems.pig


exit 0
