docker pull sonatanfv/tng-probe-ping
docker run --rm -v tee:/workspace sonatanfv/tng-probe-ping ${workspace.absolutePath}/config.cfg
