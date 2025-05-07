sudo dnf install epel-release 
sudo dnf upgrade
sudo reboot


sudo dnf config-manager --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel9/$(uname -i)/cuda-rhel9.repo
sudo dnf install kernel-headers-$(uname -r) kernel-devel-$(uname -r) tar bzip2 make automake gcc gcc-c++ pciutils elfutils-libelf-devel libglvnd-opengl libglvnd-glx libglvnd-devel acpid pkgconfig dkms
sudo dnf module install nvidia-driver:latest-dkms
echo "blacklist nouveau" | sudo tee /etc/modprobe.d/blacklist-nouveau.conf
echo 'omit_drivers+=" nouveau "' | sudo tee /etc/dracut.conf.d/blacklist-nouveau.conf
sudo dracut --regenerate-all --force
sudo depmod -a


sudo mokutil --import /var/lib/dkms/mok.pub
sudo reboot


nvidia-smi


cp ~/kernel/rpmbuild/BUILD/kernel-4.18.0-425.19.2.el8_7/linux-4.18.0-425.19.2.el8.`uname -m`/configs/kernel-4.18.0-`uname -m`.config ~/lustre-release/lustre/kernel_patches/kernel_configs/kernel-4.18.0-4.18-rhel8.10-`uname -m`.config


cd ~/lustre-release/lustre/kernel_patches/series && \
for patch in $(<"4.18-rhel8.10.series"); do \
     patch_file="$HOME/lustre-release/lustre/kernel_patches/patches/${patch}"; \
     cat "${patch_file}" >> "$HOME/lustre-kernel-`uname -m`-lustre.patch"; \
done

echo '# x86_64' > ~/kernel/rpmbuild/SOURCES/kernel-`uname -m`.config
cat ~/lustre-release/lustre/kernel_patches/kernel_configs/kernel-4.18.0-4.18-rhel8.10-`uname -m`.config >> ~/kernel/rpmbuild/SOURCES/kernel-`uname -m`.config

