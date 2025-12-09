cfdisk /dev/sda
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
pacstrap /mnt base linux linux-firmware networkmanager nano plasma kde-applications sddm
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
nano /etc/locale.gen
locale-gen
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
echo arch > /etc/hostname
systemctl enable NetworkManager
systemctl enable sddm
pacman -S grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
passwd
exit
reboot