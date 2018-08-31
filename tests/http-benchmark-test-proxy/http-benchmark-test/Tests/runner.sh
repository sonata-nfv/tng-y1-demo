docker pull sonatanfv/tng-wrk
docker run --rm -v tee:/workspace sonatanfv/tng-wrk ${workspace.absolutePath}/config.cfg
