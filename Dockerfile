FROM registry.access.redhat.com/ubi9/nodejs-18:latest AS build
USER root
RUN command -v yarn || npm i -g yarn

ADD . /usr/src/app
WORKDIR /usr/src/app
RUN yarn install && yarn build

FROM registry.access.redhat.com/ubi9/nginx-120:latest

COPY --from=build /usr/src/app/dist /usr/share/nginx/html
USER 1001

ENTRYPOINT ["nginx", "-g", "daemon off;"]