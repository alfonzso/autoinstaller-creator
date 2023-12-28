set -eu

: "${UID:?=> not set or empty}"
: "${GID:?=> not set or empty}"
: "${WORKDIR:?=> not set or empty}"
: "${SERVER_PATH:?=> not set or empty}"
: "${ISO_NAME:?=> not set or empty}"

usermod -u $UID creator 2> /dev/null 1>&2 || true
usermod -g $GID creator 2> /dev/null 1>&2 || true

cd $WORKDIR
rm -rf iso || true
rm -rf BOOT || true

[[ ! -f ${ISO_NAME}.iso ]] && wget $SERVER_PATH

mkdir -p iso/nocloud
7z x ${ISO_NAME}.iso -oiso
touch iso/nocloud/meta-data

cp k8s.config.yaml iso/nocloud/user-data

mv 'iso/[BOOT]/' 'BOOT'
sed -i 's|---|fsck.mode=skip autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg

sed -i 's|set timeout=.*$|set timeout=5|g' iso/boot/grub/grub.cfg


xorriso -as mkisofs -r \
  -V Ubuntu\ custom\ amd64 \
  -o ${ISO_NAME}-$(date +'%F--%H-%M-%S').iso \
  --grub2-mbr BOOT/1-Boot-NoEmul.img \
  -partition_offset 16 \
  --mbr-force-bootable \
  -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b BOOT/2-Boot-NoEmul.img \
  -appended_part_as_gpt \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  -c '/boot.catalog' \
  -b '/boot/grub/i386-pc/eltorito.img' \
  -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
  -eltorito-alt-boot \
  -e '--interval:appended_partition_2:::' \
  -no-emul-boot \
  iso/boot iso
