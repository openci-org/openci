FROM node:22-bookworm-slim

RUN npm install --global firebase-tools@15.25.0 \
    && firebase setup:emulators:ui \
    && npm cache clean --force

WORKDIR /emulators
COPY firebase.json healthcheck.ts ./

ENV FIREBASE_CLI_DISABLE_UPDATE_CHECK=true
CMD ["firebase", "emulators:start", "--only", "auth", "--project", "demo-openci", "--config", "firebase.json"]
