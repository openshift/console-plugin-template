FROM registry.access.redhat.com/ubi9/nodejs-22:latest AS build
USER root

ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1

ADD . /usr/src/app
WORKDIR /usr/src/app

RUN LOCAL_YARN="node $(awk '/yarnPath:/{print $2}' .yarnrc.yml)" && \
    $LOCAL_YARN install --immutable && $LOCAL_YARN build

FROM registry.access.redhat.com/ubi9/nginx-120:latest

COPY --from=build /usr/src/app/dist /usr/share/nginx/html
USER 1001

ENTRYPOINT ["nginx", "-g", "daemon off;"]
