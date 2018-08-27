docker pull sonatanfv/tng-vnv-probe-ports
docker run --rm -v tee:/workspace sonatanfv/tng-probe-ports ${workspace.absolutePath}/config.cfg
