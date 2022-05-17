FROM nvidia/cuda:11.2.1-devel-centos8

WORKDIR /work

ENV CONDA_DIR /opt/conda
RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh" && bash Mambaforge-$(uname)-$(uname -m).sh -b -p /opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH
# Create the environment:
COPY environment.yml .
RUN mamba create -n myenv python=3.9

# Make RUN commands use the new environment:
SHELL ["mamba", "run", "-n", "myenv", "/bin/bash", "-c"]

# Demonstrate the environment is activated:
RUN echo "Make sure torch is installed:"
RUN mamba install -c https://ftp.osuosl.org/pub/open-ce/current/ cudatoolkit=11.2
RUN mamba install -c https://ftp.osuosl.org/pub/open-ce/current/ pytorch

RUN python -c "import torch"

# Prepare default warning message when no command is specified when the container is started
COPY no_command_specified.py .
CMD ["python", "no_command_specified.py"]

# Prepend mamba run command to run the given CMD inside mamaba environment.
# --no-banner option to suppress mamba banner. 
# --no-capture-output to work correctly for interactive containers
ENTRYPOINT ["mamba", "run", "--no-capture-output", "--no-banner", "-n", "myenv"]