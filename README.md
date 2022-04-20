# score-lab

## Setup for nodes with `ppc64le` (Power-PC) processor architecture
On nodes that use the `ppc64le` processor architecture instead of the "standard" `x86_64`, any *compiled* package or tool will need to be recompiled for the new architecture. For Machine Learning workloads, this mostly concerns `conda` and packages with a compiled backend like `pytorch`. Compiling from source is tricky and can take a **very** long time, but luckily there are a few tricks to make things easier. To enable a seamless experience across processor arhcitecures, we need to take the following steps:

1. Install the correct conda **version** (not just crearing a new environment) for the processor architecture
2. Edit your `.bashrc` so that the correct conda version is loaded depending on the current architecture
3. Create environments and install your packages

### 1. Installing conda
For `ppc64le`, we need to use [miniforge](https://github.com/conda-forge/miniforge), which is a fork of the regular `conda` command and works exactly the same. For `x86_64`, we can use whatever `conda` distribution we prefer, or even `pip`. For simplicity, I recommend use `miniforge` as well.

1. Log into a node that uses the `ppc64le` architecture
2. Download the [installation script](https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-ppc64le.sh) for `ppc64le` from the miniforge GitHub into your home directory (`/hpi/fs00/home/<username>/`)
3. Install conda with `bash Miniforge3-Linux-ppc64le.sh`. I recommend to add a prefix to the install location, e.g. `/hpi/fs00/home/<username>/ppc-miniforge3` instead of `/hpi/fs00/home/<username>/miniforge3`. **Important**: when asked whether to automatically do `conda init`, **decline**. We will do this manually.
4. If you have no environment setup for `x86_64` or want to follow this guide exactly (**recommended**), repeat steps 1.-3. with with the [installation script](https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh) for `x86_64` and a **different** prefix, e.g. `x64-`.

### 2. Editing the `.bashrc`
We need to manually intialize the correct `conda` distribution depending on the processor architecture. Paste the following snippet at the bottom of your `.bashrc`. You need to replace <username> with your username and adjust the install locations for `conda` if you deviated from the guide.

<details><summary>Snippet</summary>
<p>
  
```bash
arch=$(uname -i)
if [[ $arch == x86_64* ]]; then
  # echo "Executing X64 (${arch}) Architecture specific part "

  # >>> conda initialize >>>
  # !! Contents within this block are managed by 'conda init' !!
  __conda_setup="$('/hpi/fs00/home/<username>/x64-miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  else
      if [ -f "/hpi/fs00/home/<username>/x64-miniforge3/etc/profile.d/conda.sh" ]; then
	  . "/hpi/fs00/home/<username>/x64-miniforge3/etc/profile.d/conda.sh"
      else
	  export PATH="/hpi/fs00/home/<username>/x64-miniforge3/bin:$PATH"
      fi
  fi
  unset __conda_setup
  # <<< conda initialize <<<
	
elif [[ $arch == ppc* ]]; then  
  # echo "Executing POWER (${arch}) Architecture specific part "

  # >>> conda initialize >>>
  # !! Contents within this block are managed by 'conda init' !!
  __conda_setup="$('/hpi/fs00/home/<username>/ppc-miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  else
      if [ -f "/hpi/fs00/home/<username>/ppc-miniforge3/etc/profile.d/conda.sh" ]; then
          . "/hpi/fs00/home/<username>/ppc-miniforge3/etc/profile.d/conda.sh"
      else
          export PATH="/hpi/fs00/home/<username>/ppc-miniforge3/bin:$PATH"
      fi
  fi
  unset __conda_setup
  # <<< conda initialize <<<

fi
```
</p>
</details>  
  
You can uncomment the `echo` lines to verify that the snippet is working correctly. Beware that output in the `.bashrc` can cause issues for tools like `rsync` or `sftp`, so make sure to comment them out again after you are done.
> :bulb: Reload the `.bashrc` with `source ~/.bashrc`.
  
### 3. Creating environments and installing packages 
For `x86_64`, you can continue as you are used to. For `ppc64le` please follow this guide.
1. (logged into a `ppc64le` node) Create a new environment and activate it. Supported Python versions are `3.8` and `3.9` (April 2022). **Important**: the names for environments on `x86_64` and `ppc64le` **must not** be the same.
2. To install packages with a compiled backend, use the https://ftp.osuosl.org/pub/open-ce/current/ channel. You can inspect available packages compiled for `ppc64le` and their versions [here.](https://ftp.osuosl.org/pub/open-ce/current/)
  ```bash
  conda install -c https://ftp.osuosl.org/pub/open-ce/current/ pytorch
  ```
> :bulb: To always try to use this channel, run `conda config --prepend channels https://ftp.osuosl.org/pub/open-ce/current/`.
There can always be version conflicts or other errrors even with the pre-compiled packages from open-ce. If you have any issues, try Google or the [open-ce GitHub](https://github.com/open-ce/open-ce) for a solution.

  
3. To install other packages, you can install them regularly with `conda install`. I recommend to install pytorch first to avoid version conflicts.
  
To automatically activate the correct `conda` environment on login, paste the following after the previous snippet:
  
<details><summary>Snippet</summary>
<p>
  
```bash
if [[ $arch == x86_64* ]]; then
  conda activate <x86_64 environment name>
else
  conda activate <ppc64le environment name>
fi
```
  
</p>
</details>
  
Now you are done and can enjoy your setup!
