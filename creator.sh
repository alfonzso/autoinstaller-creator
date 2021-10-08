ISO_NAME=ubuntu-20.04.3-live-server-amd64
# https://releases.ubuntu.com/20.04/ubuntu-20.04.2-live-server-amd64.iso

WORKDIR=$(pwd)/workspace

[[ ! -d $WORKDIR ]] && mkdir $WORKDIR

# cp default.config.yaml $WORKDIR
cp k8s.config.yaml     $WORKDIR

docker rm -f autoinstaller || true
docker run -d --rm --name autoinstaller -v $WORKDIR:$WORKDIR alpine sh -c 'tail -f /dev/null'
sleep 3

docker exec -it autoinstaller sh -c "
apk add --update p7zip syslinux xorriso bash wget
"

docker exec -it autoinstaller bash -c "
cd $WORKDIR
rm -rf iso || true
sleep 5

set -ex

# mkdir cubic/ || true
# cd cubic

[[ ! -f ${ISO_NAME}.iso ]] && wget https://releases.ubuntu.com/20.04/${ISO_NAME}.iso

mkdir -p iso/nocloud
7z x ${ISO_NAME}.iso -oiso
touch iso/nocloud/meta-data

# cp default.config.yaml iso/nocloud/user-data
cp k8s.config.yaml       iso/nocloud/user-data

rm -rf 'iso/[BOOT]/'
sed -i 's|---|fsck.mode=skip autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg
sed -i 's|---|fsck.mode=skip autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' iso/isolinux/txt.cfg

# md5sum iso/README.diskdefines > iso/md5sum.txt
# sed -i 's|iso/|./|g' iso/md5sum.txt

cd iso
find -type f -print0 |  xargs -0 md5sum | grep -v isolinux/boot.cat |  tee md5sum.txt
cd ..

xorriso -as mkisofs -r \
  -V Ubuntu\ custom\ amd64 \
  -o ${ISO_NAME}-$(date +'%F--%H-%M-%S').iso \
  -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin  \
  iso/boot iso

"
docker rm -f autoinstaller || true

# apk add --update p7zip syslinux xorriso
# mkdir -p iso/nocloud
# 7z x ${ISO_NAME}.iso -oiso
# touch iso/nocloud/meta-data

# cat > iso/nocloud/user-data << 'EOF'
# #cloud-config
# autoinstall:
#   version: 1
#   identity:
#     hostname: ubuntu-server
#     # password is ubuntu
#     password: "$6$exDY1mhS4KUYCE/2$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46P0"
#     username: ubuntu
# EOF

# rm -rf 'iso/[BOOT]/'
# sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg
# sed -i 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' iso/isolinux/txt.cfg

# md5sum iso/README.diskdefines > iso/md5sum.txt
# sed -i 's|iso/|./|g' iso/md5sum.txt

# xorriso -as mkisofs -r \
#   -V Ubuntu\ custom\ amd64 \
#   -o ${ISO_NAME}-$(date +'%F--%H-%M-%S').iso \
#   -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
#   -boot-load-size 4 -boot-info-table \
#   -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
#   -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
#   -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin  \
#   iso/boot iso
