ARG BASE_IMAGE=inseefrlab/onyxia-rstudio-r
FROM $BASE_IMAGE

LABEL maintainer="UN Global Platform <lovells@un.org>"
LABEL description="RStudio environment for Earth Observation Statistics (R, geospatial stack)"

USER root

# Install additional system dependencies for geospatial packages
# Note: Base image already includes GDAL, GEOS, PROJ from rocker geospatial stack
RUN apt-get update && apt-get install -y \
    git-lfs \
    libudunits2-dev \
    && git lfs install \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy installation scripts
COPY --chmod=0755 scripts/ /opt/eostat/

# Copy R package list
COPY requirements-r.txt /tmp/

# Install R packages
RUN Rscript /opt/eostat/install-r-packages.R && \
    rm /tmp/requirements-r.txt

# Set up init script for eostat sessions
COPY --chmod=0755 onyxia-eostat-init.sh /opt/
ENV EOSTAT_INIT_SCRIPT=/opt/onyxia-eostat-init.sh

# Fix permissions
RUN /opt/fix-user-permissions.sh

EXPOSE 8787

CMD ["/init"]
