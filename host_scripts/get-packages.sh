export LFS=/mnt/lfs

mkdir -pv $LFS
mount -v -t ext4 /dev/sda8 $LFS

mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

# download acnd check the md5 checksum for the packages
wget http://www.linuxfromscratch.org/lfs/view/stable/wget-list
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
wget http://www.linuxfromscratch.org/lfs/view/stable/md5sums --directory-prefix=$LFS/sources
pushd $LFS/sources
md5sum -c md5sums
popd

# Create tools directory and sym link with /tools for generality across building tools and system
mkdir -v $LFS/tools
ln -sv $LFS/tools /

# create a group and user for unprevileged compilation
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs

passwd lfs
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources

su - lfs

cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

# non-login shell only reads .bashrc
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF

source ~/.bash_profile
