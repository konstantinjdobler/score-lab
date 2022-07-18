FROM nvidia/cuda:11.2.0-cudnn8-devel-centos8

WORKDIR /work

# Install mamba / conda and add to PATH
ENV CONDA_DIR /opt/conda
RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh" && bash Mambaforge-$(uname)-$(uname -m).sh -b -p /opt/conda
RUN rm Mambaforge-$(uname)-$(uname -m).sh
ENV PATH=$CONDA_DIR/bin:$PATH

# Create the environment:
RUN mamba create -y -n myenv python=3.9 

# Make RUN commands use the new environment:
SHELL ["mamba", "run", "--no-banner", "-n", "myenv", "/bin/bash", "-c"]

# Install packages. 
# Use the -c https://ftp.osuosl.org/pub/open-ce/current/ channel for packages that need to be compiled for ppc64le. 
# For more information, see https://github.com/open-ce/open-ce

# Basic pytorch needs. We need to use the open-ce channel to install a pytorch version compiled for ppc64le. This can take some time.
RUN mamba install -y -c https://ftp.osuosl.org/pub/open-ce/current/ -c conda-forge -c defaults pytorch torchvision cudatoolkit=11.2 

# Basic ML packages. tokenizers, pandas and numpy are provided compiled for ppc64le as-is in conda-forge
RUN mamba install -y -c conda-forge transformers datasets tqdm pip click pandas numpy tokenizers

# Anything else you want. This takes advantage of Docker Layer Caching, which means all previous steps are cached and need not be re-done everytime you make changes here.
# RUN mamba install -y -c conda-forge my-cool-package my-cool-package-2 

# Fix error on yum install
# https://stackoverflow.com/questions/70963985/error-failed-to-download-metadata-for-repo-appstream-cannot-prepare-internal
# RUN cd /etc/yum.repos.d/
# RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
# RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# # Install curl to download jemalloc
# RUN  yum install wget -y

# # jemalloc works only with the host system page size specified at compile time, so we need to sepcify --with-lg-page=16 (2^16 = 65536, which is the page size on the ac922 nodes)
# RUN wget -q https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 && \
#     tar jxf jemalloc-*.tar.bz2 && \
#     rm jemalloc-*.tar.bz2 && \
#     cd jemalloc-*  && \
#     ./configure --with-lg-page=16 && \
#     make && \
#     make install

# ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so 

# # Check if torch is correctly installed. This should not fail.
# RUN python -c "import tokenizers"

# RUN python -c "import torch"

# Prepare default warning message when no command is specified when the container is started.
COPY no_command_specified.py .
CMD ["python", "no_command_specified.py"]

# Prepend mamba run command to run the given CMD inside mamba environment.
# --no-banner option to suppress mamba banner. 
# --no-capture-output to work correctly for interactive containers
ENTRYPOINT ["mamba", "run", "--no-capture-output", "--no-banner", "-n", "myenv"]