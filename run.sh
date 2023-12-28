export UBU_VERSION=22.04.3
export ISO_NAME=ubuntu-$UBU_VERSION-live-server-amd64
export SERVER_PATH=http://releases.ubuntu.com/releases/jammy/$ISO_NAME.iso
################################ https://releases.ubuntu.com/20.04/ubuntu-20.04.2-live-server-amd64.iso
################################ https://releases.ubuntu.com/22.04.2/ubuntu-22.04.2-live-server-amd64.iso
################################ http://releases.ubuntu.com/releases/jammy/ubuntu-22.04.3-live-server-amd64.iso

export WORKDIR=$(pwd)/workspace

[[ ! -d $WORKDIR ]] && mkdir $WORKDIR

cp k8s.config.yaml $WORKDIR

docker build -t alp-iso-creator .

docker rm -f autoinstaller || true
# docker run -it -e UID=$(id -u) -e GID=$(id -g) --rm --name autoinstaller -v $WORKDIR:$WORKDIR alp-iso-creator bash -s < creator.sh
docker run -i -e WORKDIR -e SERVER_PATH -e ISO_NAME -e UID=$(id -u) -e GID=$(id -g) --rm --name autoinstaller -v $WORKDIR:$WORKDIR alp-iso-creator bash -s < creator.sh

