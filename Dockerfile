FROM alpine:latest

####
# pre-installation
####

USER root

ENV HOME /home
ENV APP_DIR $HOME/docker/app

# http://pkg-shadow.alioth.debian.org/features.php
ENV TEMPORARY_DEPENDENCIES='shadow'
RUN apk update && apk --no-cache add ${TEMPORARY_DEPENDENCIES}
# add user as per: https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/#user
RUN groupadd -r docker && useradd --no-log-init -r -g docker docker
RUN chown -R docker $HOME

###
# nodejs installation
###

RUN apk --no-cache add \
    nodejs-current \
    nodejs-current-npm \
    # clean up obsolete files
    && rm -rf /tmp/* /root/.npm


####
# post-installation
####

# clean no longer needed dependencies
RUN apk del ${TEMPORARY_DEPENDENCIES}


####
# user and content management
####

# create dedicated directory
RUN mkdir -p $APP_DIR
RUN mkdir -p $APP_DIR/tests_output/screenshots
RUN chown -R docker $APP_DIR

COPY --chown=docker:docker scripts/entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# copy package.json to image
COPY --chown=docker:docker package.json $APP_DIR
# switch to docker user to ensure correct permissions for npm dependencies
USER docker

WORKDIR $APP_DIR

RUN npm install --ignore-scripts --unsafe-perm --loglevel warn

# add rest of repo to image (doing this after installing npm dependencies
# makes for a faster development workflow because only a change to package.json
# will force docker to rebuild the "npm install" layer above)
COPY --chown=docker:docker . $APP_HOME

ENTRYPOINT ["/entrypoint.sh"]
