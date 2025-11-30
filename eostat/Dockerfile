ARG BASE_IMAGE=inseefrlab/onyxia-jupyter-r-python-julia:r4.5.1-py3.13.8
FROM $BASE_IMAGE

LABEL maintainer="UN Global Platform <lovells@un.org>"
LABEL description="JupyterLab environment for Earth Observation Statistics (R, Python, geospatial stack)"

USER root

# Install additional system dependencies for geospatial packages
RUN apt-get update && apt-get install -y \
    git-lfs \
    libudunits2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libsqlite3-dev \
    && git lfs install \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy installation scripts
COPY --chmod=0755 scripts/ /opt/eostat/

# Copy R and Python package lists
COPY requirements-r.txt /tmp/
COPY requirements.txt /tmp/

# Install R packages
RUN Rscript /opt/eostat/install-r-packages.R && \
    rm /tmp/requirements-r.txt

# Install Python packages
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Ensure R kernel is available in JupyterLab
RUN R -e "if (!require('IRkernel', quietly = TRUE)) install.packages('IRkernel'); IRkernel::installspec(user = FALSE)"

# Set up init script for eostat sessions
COPY --chmod=0755 onyxia-eostat-init.sh /opt/
ENV EOSTAT_INIT_SCRIPT=/opt/onyxia-eostat-init.sh

# Fix permissions
RUN /opt/fix-user-permissions.sh

USER 1000

WORKDIR /home/jovyan

CMD ["/bin/bash"]
