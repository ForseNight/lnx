#!/bin/bash
set -e

DISK="/dev/sda"
EFI="${DISK}1"
ROOT="${DISK}2"

cfdisk "$DISK"

mkfs.fat -F32 "$EFI"
mkfs.ext4 "$ROOT"

mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

pacstrap /mnt base linux linux-firmware networkmanager plasma sddm

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash -c "
set -e
ln -sf /usr/share/zoneinfo/Europe/Moscow /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
sed -i 's/#ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen
locale-gen
echo 'LANG=ru_RU.UTF-8' > /etc/locale.conf
echo 'arch' > /etc/hostname
systemctl enable NetworkManager
systemctl enable sddm
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
passwd
"

reboot
