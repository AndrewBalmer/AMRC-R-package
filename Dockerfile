FROM rocker/r-ver:4.5.0

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV AMRC_PACKAGE_LOAD_MODE=installed
ENV STREAMLIT_SERVER_HEADLESS=true
ENV STREAMLIT_BROWSER_GATHER_USAGE_STATS=false

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    build-essential \
    gfortran \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    zlib1g-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libgit2-dev \
    ghostscript \
    qpdf \
    zip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY DESCRIPTION NAMESPACE /app/
COPY R /app/R
COPY man /app/man
COPY inst /app/inst
COPY streamlit_app /app/streamlit_app

RUN Rscript -e 'install.packages(c("remotes", "pak"), repos = "https://cloud.r-project.org")'
RUN Rscript -e 'pak::pak(c("local::.", "jsonlite", "ggExtra", "knitr", "rmarkdown", "lme4"))'

RUN pip3 install --no-cache-dir -r /app/streamlit_app/requirements.txt

EXPOSE 8501

CMD ["streamlit", "run", "streamlit_app/app.py", "--server.address=0.0.0.0", "--server.port=8501"]
