FROM node:20-slim
WORKDIR /usr/app
ENTRYPOINT /bin/bash
RUN apt-get update \
 && apt-get install -y openssl bash curl git

# Install remixd (sharing files from host to remix editor)
RUN npm install -g @remix-project/remixd \
 && sed -i s/127.0.0.1/0.0.0.0/g /usr/local/lib/node_modules/@remix-project/remixd/src/websocket.js

# Install foundry
RUN curl -L https://foundry.paradigm.xyz | bash \
 && export PATH="$PATH:/root/.foundry/bin" \
 && foundryup

