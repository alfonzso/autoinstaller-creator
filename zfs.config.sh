cat <<"EOF">> /etc/hdparm.conf
write_cache = on
EOF

cat <<"EOF"> /etc/modprobe.d/zfs.conf
options zfs zfs_arc_max=6442450944
EOF

systemctl enable zfs.target zfs-import.service zfs-mount.service zfs-import-cache.service
zpool create storage mirror ata-WDC_WD20EFZX-68AWUN0_WD-WX12DB0DPS74 ata-WDC_WD20EFZX-68AWUN0_WD-WX22DB0AD5AP
zpool set cachefile=/etc/zfs/zpool.cache storage
zfs set mountpoint=/mnt/storage storage
zfs set compress=lz4 storage
zpool add storage log ata-Samsung_SSD_840_PRO_Series_S1ANNSAF414709B-part4
zpool add storage cache ata-Samsung_SSD_840_PRO_Series_S1ANNSAF414709B-part5

cat <<"EOF">> /etc/modules
ipmi_si
acpi_ipmi
EOF