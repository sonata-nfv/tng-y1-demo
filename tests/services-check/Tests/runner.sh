docker pull sonatanfv/tng-probe-services-check
docker run --rm -v tee:/workspace sonatanfv/tng-probe-services-check ${workspace.absolutePath}/config.cfg
