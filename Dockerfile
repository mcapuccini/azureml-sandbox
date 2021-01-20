# Base image
FROM continuumio/miniconda3:4.9.2

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Non-root user with sudo access
ARG USERNAME=default
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Conda
ARG CONDA_ENV_NAME=default

# Configure apt
RUN apt-get update \
  && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
  #
  # apt deps
  && apt-get install -y sudo curl \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/* \
  #
  # Install docker binary
  && curl -L https://download.docker.com/linux/static/stable/x86_64/docker-19.03.9.tgz | tar xvz docker/docker \
  && cp docker/docker /usr/local/bin \
  && rm -R docker \
  #
  # Create a non-root user to use if preferred
  && groupadd --gid $USER_GID $USERNAME \
  && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

# Create conda environment with deps
RUN conda create -n $CONDA_ENV_NAME -c conda-forge \
  python=3.6.2 \
  pip=20.2.4 \
  ipykernel=5.3.4 \
  #
  # Pip deps
  && conda run -n $CONDA_ENV_NAME pip install --disable-pip-version-check --no-cache-dir \
  matplotlib==3.3.3 \
  click==7.1.2 \
  jupytext==1.9.1 \
  nbformat==5.0.8 \
  papermill==2.2.2 \
  yapf==0.30.0 \
  pylint==2.6.0 \
  nbconvert==5.6.1 \
  #
  # Add Jupyter kernel
  && conda run -n $CONDA_ENV_NAME python -m ipykernel install --name $CONDA_ENV_NAME

# Init conda for non-root user
USER $USERNAME
RUN conda init bash \
  && conda config --set auto_activate_base false \
  && echo "conda activate default" >> ~/.bashrc

# Set working directory
WORKDIR /home/$USERNAME

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog