FROM fpco/stack-build

WORKDIR /build

COPY . /build

RUN stack install
