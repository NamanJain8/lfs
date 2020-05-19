# copy kernel image
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.5.3-lfs-9.1

# copy map file for debugging
cp -iv System.map /boot/System.map-5.5.3

# copy config file for future reference
cp -iv .config /boot/config-5.5.3

# install docs
install -d /usr/share/doc/linux-5.5.3
cp -r Documentation/* /usr/share/doc/linux-5.5.3

