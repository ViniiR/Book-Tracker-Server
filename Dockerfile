FROM nixos/nix:2.28.5 AS builder
WORKDIR /app

COPY . .
RUN nix \
    --extra-experimental-features "nix-command flakes" \
    build

EXPOSE 5001
CMD [ "result/bin/server" ]
