UBU_VERSION=22.04.2
ISO_NAME=ubuntu-$UBU_VERSION-live-server-amd64
SERVER_PATH=https://releases.ubuntu.com/$UBU_VERSION/$ISO_NAME.iso
# https://releases.ubuntu.com/20.04/ubuntu-20.04.2-live-server-amd64.iso
# https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso

WORKDIR=$(pwd)/workspace

[[ ! -d $WORKDIR ]] && mkdir $WORKDIR

# cp default.config.yaml $WORKDIR
cp k8s.config.yaml $WORKDIR

# create a dummy alpine iso creator image
docker build -t alp-iso-creator .

docker rm -f autoinstaller || true
docker run -it -e UID=$(id -u) -e GID=$(id -g) --rm --name autoinstaller -v $WORKDIR:$WORKDIR alp-iso-creator bash -c "
set -e
usermod -u $UID creator 2>/dev/null 1>&2 || true
usermod -g $GID creator 2>/dev/null 1>&2 || true

cd $WORKDIR
rm -rf iso || true

[[ ! -f ${ISO_NAME}.iso ]] && wget $SERVER_PATH

mkdir -p iso/nocloud
7z x ${ISO_NAME}.iso -oiso
touch iso/nocloud/meta-data

# cp default.config.yaml iso/nocloud/user-data
cp k8s.config.yaml       iso/nocloud/user-data

mv 'iso/[BOOT]/' 'BOOT'
sed -i 's|---|fsck.mode=skip autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg
# sed -i 's|---|fsck.mode=skip autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' iso/isolinux/txt.cfg

# md5sum iso/README.diskdefines > iso/md5sum.txt
# sed -i 's|iso/|./|g' iso/md5sum.txt

# cd iso
# find -type f -print0 |  xargs -0 md5sum | grep -v isolinux/boot.cat |  tee md5sum.txt
# cd ..

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

"
