# Linux from scratch

Curious on understanding the details for the Linux system, I decided to build on the Linux system from Scratch. It was an amazing experience with learning. I got to understand the packages that one needs for the basic Linux and their importance. While setting up a network for the laptop, I learned a lot about the things involved in making your PC connect to the internet. This blog is basically the summary of what we do for building the LFS system. This is just an overview and not the complete guide, one should follow the online LFS book for that. 

With lots of Linux distros out there like Ubuntu, CentOS, Arch Linux, etc.; one requires having a Linux system as a host system as it provides the necessary tools like compiler, shell to be used during the first phase of Linux build. I used Ubuntu 18.04 LTS, already installed as a host system.


## Preparing the host system:

The next step is to prepare the host system to the build. Check the necessary programs if they exist on the host system (use version-check.sh). Create a partition for the LFS system (I used fdisk utility), create a file system on that partition(ext4), mount the created LFS file system (use /etc/fstab to mount it on boot). To make sure the paths defined are correct, you need to have $LFS environment variable set across the users (root as well as chrooted root included). It's better to have it included in .bashrc and .bash_profile to load it automatically. Note that the shell corresponds to the one in /etc/passwd.

Having set up the environment and build tools on the host system, download the packages/patches listed in the wget-list needed for the basic build of LFS. Verify the md5sum for security. Create user lfs and chroot to the new lfs in a clean environment. Having a clean environment ensures any contamination from the host environment to creep in. Create necessary files/directories and set up permissions.


## Building the Temporary System:

Now, we will construct a temporary system for building LFS. First, we install binutils which provides a linker, an assembler, and other tools for handling object files. This is necessary as GCC and Glibc perform many tests which help it decide the config features to enable/disable. Install the GCC, and then the Linux API headers. These allow the standard C library (Glibc) to interface with features that the Linux kernel will provide. Build Glibc and then the second pass for binutils and GCC. This removes the dependency from the host system completely and now on the core toolchain is self-contained and self-hosted. Now we build the other packages using the above toolchain. We change the ownership of $LFS/tools again back to root because of the vulnerability of that ownership to be misused by another user with the same UID as of lfs user(exist on the host system) on the LFS system.

### Detour: Static vs Dynamic Libraries

Building and installing of static libraries are generally discouraged. This is because for each program one needs to compile the package with static library and hence are for different packages using the same library load it in memory for themselves. But for the dynamic library, only one copy is loaded at runtime and used by multiple programs. Moreover, for any change/bug fix in the static library, one needs to recompile the package which is detrimental. The packages to be updated and the correct procedure may not be known.

Static libraries were traditionally used and few older systems only allow that. In the past, essential programs like shell used static libraries to provide minimal recovery system in case dynamic libraries got corrupted. But now we can use live CD/USB for the purpose. Though, the static libraries exclusively built for some package can be statically linked.


## Building the LFS System:

For building LFS, we will be using shared libraries wherever possible and remove the static libraries manually or by passing a flag to configuration files. First, we will prepare the virtual file system. Create device nodes to be used by udevd (create-init-dev-nodes.sh), mount the virtual filesystems (mount_script), and enter the chroot environment (chroot_script).

We will start building with Glibc as this is self-sufficient as said earlier. Then we will build the other packages. You may observe that we are installing the packages already installed in the temporary system. This is because we don't want to pollute the final system with tools and also due to circular dependencies.

After installing the packages, we may clean up the unnecessary temporary files and strip the libraries to remove debug information. This significantly reduces system size. Now, enter chroot with new PATH variable because from now onwards, we won't be needing /tools (can be deleted).

### Detour: SystemV vs SystemD

System V (Sys V) is one of the first and traditional init systems for the UNIX/Linux operating system. Init is the first process started by the kernel during system boot and is a parent process for everything. Over the years, several alternative init systems have been released to address design limitations in stable versions such as launchd, Service Management, systems, and Upstart. But the systemd has been adopted by many large Linux distributions over the traditional SysVinit manager.

If you are using systemctl to manage things (like systemctl restart sshd), then you are on SystemD, else if you are doing /etc/init.d/sshd start then you are on SystemV. Red Hat Enterprise, CentOS, Fedora, Debian/Ubuntu/Mint uses SysD while Gentoo, Alpine, LFS uses SysV.

#### PS: I was actually trying the SystemD way and was lost in that for some time.


## Configuring the System:

System V is the classic boot process that has been used in Unix and Unix-like systems such as Linux since about 1983. It consists of a small program, init, that sets up basic programs such as login (via getty) and runs a script. This script, usually named rc (aka. run commands), controls the execution of a set of additional scripts that perform the tasks required to initialize the system.

### Overview of Device and Module Handling: 
Traditionally, Linux used a static device creation method, where thousands of nodes were created each corresponding to the possible devices. This was inefficient and was succeeded by devfs which dynamically created nodes on detection. But this had problems in naming policy and handling concurrency.
Later, a new virtual file system sysfs came to be. The job of sysfs is to export a view of the system's hardware configuration to userspace processes. Drivers that have been compiled into the kernel directly register their objects with a sysfs (devtmpfs internally) as they are detected by the kernel. For drivers compiled as modules, this registration will happen when the module is loaded (we installed wifi drivers this way). Device nodes permissions, groups, naming can be changed in internal database entry maintained by udevd (installed by eudev package) via rules.d files in various directories. Also, when you plug in the new USB device, a uevent is created and handled by udevd. Traditional device naming scheme may assign eth0 and eth1 to any of the network card (in case device has 2 network cards) on the basis of which one was detected earlier, to avoid this we follow a scheme based on Firmware data or physical properties like MAC Address/bus/slot. After generating the initial rules, add the custom rules as desired.
Which interfaces to keep up and which down, depends on the content of /etc/sysconfig in SysV. Create ifconfig.enp2s0 file (for ethernet) if you want to follow the new naming system. For DNS resolution, create /etc/resolv.conf and add the DNS resolver (you can use Google's public DNS server 8.8.8.8). Create /etc/hostname and /etc/hosts files. A hostname is set as the system name on bootup, while hosts are used when connected to a network by some programs (valid hosts file is necessary). Then we create the initialization file (/etc/inittab), set up clock parameters for clock(/etc/sysconfig/clock). Then, we need to set up the keyboard mapping. I skipped that because my keyboard was US. Create optional rc.site file and customize system parameters.
Setup bash startup files (/etc/profile), proper setting of variable results in smooth functioning. In LFS, we set only LANG option. Set up default global (/etc/inputrc) config file for Readline library which provides editing capabilities for the user entering the terminal. Some other terminal-based programs may use curses library. Create /etc/shells file which enables cash(change shell) program to determine valid shells.


## Making LFS Bootable:
Create a file systems table in /etc/fstab. This information is used while mounting and executing some programs. Now, we will build the kernel. Like any generic build process, it involves configuration, compilation, and installation.

Clean the environment using make mrproper.Use make menuconfig for configuring the kernel. This will lead you to TUI application for configuration. Compile the kernel using make and run make modules_install. Copy the kernel image to /boot using copy-kernel.sh. Now update the grub. 