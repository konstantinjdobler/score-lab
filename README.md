# score-lab

## Setup for nodes with `ppc64le` (Power-PC) processor architecture
On nodes that use the `ppc64le` processor architecture instead of the "standard" `x86_64`, any *compiled* package or tool will need to be recompiled for the new architecture. For Machine Learning workloads, this mostly concerns `conda` and packages with a compiled backend like `pytorch` or `tensorflow`. 

Compiling from source is tricky and can take a **very** long time, but luckily there are a few tricks to make things easier using specific open-source `conda` channels which ship pre-compiled versions for `ppc64le`. To enable a seamless experience across processor architecures, we need to take the following steps:

1. Install the correct conda **distribution** (not just creating a new environment) for the processor architecture
2. Edit your `.bashrc` so that the correct conda distribution is loaded depending on the current architecture
3. Create environments and install your packages

### 1. Installing conda
For `ppc64le`, we need to use [mambaforge](https://github.com/conda-forge/miniforge#mambaforge), which is a fork of the regular `conda` command and works exactly the same, except that you use `mamba` instead of `conda`. As a bonus, it is also *much* faster than `conda`.  For `x86_64`, we can use whatever `conda` distribution we prefer, or even `pip`. For simplicity, I recommend to use `mambaforge` as well.

<details><summary>More about mamba and conda</summary>
<p>
	
If you *really* want to, you can probably get away without using `mamba`, if you do it is still recommended to use [miniforge](https://github.com/conda-forge/miniforge#miniforge3) (same repo as mambaforge) instead of other `conda` distributions because it is optimized for `ppc64le`. Specifically for `pytorch`, using `mamba` makes the installation much easier (and also much faster). 
	
If you use `mamba`, you can still use `conda` to issue the same commands. I.e. if you suspect some bug in `mamba` is causing an install to fail you can also try `conda install ...`. At your own risk (as in this might or might not casue issues), you can also choose to use  `mamba` *only* for the install commands (which is where `mamba` makes a lot of improvements) and keep using `conda` for the rest.
	
</p>
</details>

1. Log into a node that uses the `ppc64le` architecture
	> 🚨 Never do development or installations on the `summon` node. You can use `salloc -A <account> --mem 5G` to quickly spawn a jobshell. 
3. Download the [mambaforge installation script](https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-ppc64le.sh) for `ppc64le` from the [mambaforge GitHub](https://github.com/conda-forge/miniforge#mambaforge) into your home directory (`/hpi/fs00/home/<username>/`)
4. Install conda with `bash Mambaforge-Linux-ppc64le.sh`. I recommend to add a prefix to the install location, e.g. `/hpi/fs00/home/<username>/ppc-mambaforge` instead of `/hpi/fs00/home/<username>/mambaforge`. **Important**: when asked whether to automatically do `conda init`, **decline**. We will do this manually.
5. If you have no environment setup for `x86_64` or want to follow this guide exactly (**recommended**), repeat steps 1.-3. with with the [installation script](https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh) for `x86_64` and a **different** prefix, e.g. `x86-`.

### 2. Editing the `.bashrc`
We need to manually intialize the correct `conda` distribution depending on the processor architecture. Paste the following snippet at the bottom of your `.bashrc`. You need to replace <username> with your username and adjust the install locations if you deviated from the guide.

<details><summary>Snippet</summary>
<p>
  
```bash
arch=$(uname -i)
if [[ $arch == x86_64* ]]; then
  # echo "Executing x86 (${arch}) Architecture specific part "

  # >>> conda initialize >>>
  # !! Contents within this block are managed by 'conda init' !!
  __conda_setup="$('/hpi/fs00/home/<username>/x86-mambaforge/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  else
      if [ -f "/hpi/fs00/home/<username>/x86-mambaforge/etc/profile.d/conda.sh" ]; then
	  . "/hpi/fs00/home/<username>/x86-mambaforge/etc/profile.d/conda.sh"
      else
	  export PATH="/hpi/fs00/home/<username>/x86-mambaforge/bin:$PATH"
      fi
  fi
  unset __conda_setup
  # <<< conda initialize <<<
	
elif [[ $arch == ppc* ]]; then  
  # echo "Executing POWER (${arch}) Architecture specific part "

  # >>> conda initialize >>>
  # !! Contents within this block are managed by 'conda init' !!
  __conda_setup="$('/hpi/fs00/home/<username>/ppc-mambaforge/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
      eval "$__conda_setup"
  else
      if [ -f "/hpi/fs00/home/<username>/ppc-mambaforge/etc/profile.d/conda.sh" ]; then
          . "/hpi/fs00/home/<username>/ppc-mambaforge/etc/profile.d/conda.sh"
      else
          export PATH="/hpi/fs00/home/<username>/ppc-mambaforge/bin:$PATH"
      fi
  fi
  unset __conda_setup
  # <<< conda initialize <<<

fi
```
</p>
</details>  
  
You can uncomment the `echo` lines to verify that the snippet is working correctly. Beware that output in the `.bashrc` can cause issues for tools like `rsync` or `sftp`, so make sure to comment them out again after you are done.
> :bulb: Reload the `.bashrc` with `source ~/.bashrc` for the changes to take effect (or close the terminal and connect again).
  
### 3. Creating environments and installing packages 
For `x86_64`, you can continue as you are used to. For `ppc64le` please follow this guide.
1. (logged into a `ppc64le` node) Create a new environment and activate it. Supported Python versions are `3.7`, `3.8` and `3.9` (April 2022). **Important**: the names for environments on `x86_64` and `ppc64le` **must not** be the same.
	```bash
	mamba create -n <cool env name> python=3.8
	```
2. To install packages with a compiled backend, use the https://ftp.osuosl.org/pub/open-ce/current/ channel. You can inspect available packages compiled for `ppc64le` and their versions [here.](https://ftp.osuosl.org/pub/open-ce/current/)
	```bash
	mamba install tensorflow -c https://ftp.osuosl.org/pub/open-ce/current/
	```
	> :bulb: To always try to use this channel, run `conda config --prepend channels https://ftp.osuosl.org/pub/open-ce/current/`.

	<details><summary>Important for PyTorch</summary>
	<p>

	PyTorch is a bit tricky. We need to add the `defaults` channel to provide some minor dependencies. The following command was tested and works (April 2022). Just to be safe, install `pytorch` as the first package before any others.
		
	```bash
	mamba install pytorch -c https://ftp.osuosl.org/pub/open-ce/current/ -c defaults
	```	

	</p>
	</details>	

	<details><summary>Troubleshooting</summary>
	<p>

	- There can always be version conflicts or other errrors even with the pre-compiled packages from open-ce. If you have any issues, try Google or the [open-ce GitHub](https://github.com/open-ce/open-ce) for a solution.	
	- In general, try to install the "biggest" packages (like `pytorch`) first and one-by-one.
	- Try adding the `-v` flag to a conda command to get verbose output.
	- If certain packages are not found, try adding channels such as `-c defaults`, `-c anaconda` or `-c conda-forge`


	</p>
	</details>
  
3. To install other packages, you can install them regularly with `mamba install`. I recommend to install pytorch first to avoid version conflicts.
  
To automatically activate the correct `conda` environment on login, paste the following after the previous snippet we pasted into `.bashrc`:
  
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
  
🍾 Once you're done, give yourself a pad on the back and enjoy your dev environment! 🍾
