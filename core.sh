#!/bin/bash

### ===== НАСТРОЙКИ =====
DISK="/dev/sda"
HOSTNAME="arch"
LOCALE="ru_RU.UTF-8"
KEYMAP="ru"
TIMEZONE="Europe/Moscow"

### ===== ПРОВЕРКА =====
echo "!!! ВНИМАНИЕ: СЕЙЧАС БУДЕТ СТЁРТ ДИСК $DISK !!!"
read -p "Нажми Enter чтобы продолжить..."

### ===== РАЗМЕТКА ДИСКА =====
echo "[+] Создание GPT и разделов..."
parted -s $DISK mklabel gpt
parted -s $DISK mkpart ESP fat32 1MiB 301MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary ext4 301MiB 100%

EFI="${DISK}1"
ROOT="${DISK}2"

### ===== ФОРМАТИРОВАНИЕ =====
echo "[+] Форматирование..."
mkfs.fat -F32 $EFI
mkfs.ext4 -F $ROOT

### ===== МОНТИРОВАНИЕ =====
echo "[+] Монтирование..."
mount $ROOT /mnt
mkdir /mnt/boot
mount $EFI /mnt/boot

### ===== УСТАНОВКА СИСТЕМЫ =====
echo "[+] Установка Arch Linux + KDE..."
pacstrap /mnt base linux linux-firmware nano networkmanager \
    plasma sddm konsole

### ===== FSTAB =====
genfstab -U /mnt >> /mnt/etc/fstab

### ===== CHROOT-СКРИПТ =====
cat << EOF > /mnt/chroot-setup.sh
#!/bin/bash

echo "[CHROOT] Настройка системы..."

# Часовой пояс
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Локали
sed -i "s/#$LOCALE UTF-8/$LOCALE UTF-8/" /etc/locale.gen
sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

# hostname
echo "$HOSTNAME" > /etc/hostname

# hosts
cat << HOSTS > /etc/hosts
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME
HOSTS

# Сеть
systemctl enable NetworkManager

# SDDM
systemctl enable sddm

# Установка grub
pacman -S --noconfirm grub efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

echo "[CHROOT] Установи пароль root:"
passwd

EOF

chmod +x /mnt/chroot-setup.sh

### ===== ЗАПУСК CHROOT СКРИПТА =====
arch-chroot /mnt /chroot-setup.sh
rm /mnt/chroot-setup.sh

echo "[+] Установка завершена! Перезагружаюсь..."
sleep 3
reboot
