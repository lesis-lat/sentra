FROM perl:5.42-slim

COPY . /usr/src/sentra
WORKDIR /usr/src/sentra

RUN apt-get update && apt-get install -y --no-install-recommends \
    cpanminus \
    libssl-dev \
    libexpat1-dev \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN cpanm --installdeps .

ENTRYPOINT [ "perl", "./sentra.pl" ]
