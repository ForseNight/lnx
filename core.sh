DISK="/dev/sda"

parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 301MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary ext4 301MiB 100%

mkfs.fat -F32 ${DISK}1
mkfs.ext4 -F ${DISK}2

mount ${DISK}2 /mnt
mkdir /mnt/boot
mount ${DISK}1 /mnt/boot

pacstrap /mnt base linux linux-firmware networkmanager plasma-desktop plasma-meta kde-system-meta sddm

genfstab -U /mnt >> /mnt/etc/fstab

cat << EOF > /mnt/chroot.sh
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
sed -i 's/#ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo LANG=ru_RU.UTF-8 > /etc/locale.conf
echo arch > /etc/hostname
cat << H > /etc/hosts
127.0.0.1 localhost
::1 localhost
127.0.1.1 arch
H
systemctl enable NetworkManager
systemctl enable sddm
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
echo root:123 | chpasswd
EOF

chmod +x /mnt/chroot.sh
arch-chroot /mnt /chroot.sh
rm /mnt/chroot.sh
reboot
