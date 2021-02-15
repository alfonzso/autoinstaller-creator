ISO_NAME=ubuntu-20.04.1-live-server-amd64
WORKDIR=/tmp/cubic/

cd ${WORKDIR}
wget "https://releases.ubuntu.com/20.04/${ISO_NAME}.iso"

docker run -it --rm --name autoinstaller -v $(pwd):$(pwd) alpine sh -c " cd $(pwd) && sh "

apk add --update p7zip syslinux xorriso
mkdir -p iso/nocloud
7z x ${ISO_NAME}.iso -oiso
touch iso/nocloud/meta-data

cat > iso/nocloud/user-data << 'EOF'
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: ubuntu-server
    # password is ubuntu
    password: "$6$exDY1mhS4KUYCE/2$zmn9ToZwTKLhCw.b4/b.ZRTIZM30JZ4QrOQ2aOXJ8yk96xpcCof0kxKwuX1kqLG/ygbJ1f8wxED22bTL4F46P0"
    username: ubuntu
EOF

rm -rf 'iso/[BOOT]/'
sed -i 's|---|autoinstall ds=nocloud\\\;s=/cdrom/nocloud/ ---|g' iso/boot/grub/grub.cfg
sed -i 's|---|autoinstall ds=nocloud;s=/cdrom/nocloud/ ---|g' iso/isolinux/txt.cfg

md5sum iso/README.diskdefines > iso/md5sum.txt
sed -i 's|iso/|./|g' iso/md5sum.txt

xorriso -as mkisofs -r \
  -V Ubuntu\ custom\ amd64 \
  -o ${ISO_NAME}-$(date +'%F--%H-%M-%S').iso \
  -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -eltorito-alt-boot -e boot/grub/efi.img -no-emul-boot \
  -isohybrid-gpt-basdat -isohybrid-apm-hfsplus \
  -isohybrid-mbr /usr/share/syslinux/isohdpfx.bin  \
  iso/boot iso