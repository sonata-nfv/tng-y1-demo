docker pull sonatanfv/tng-wrk-advanced
docker run --rm -v tee:/workspace sonatanfv/tng-wrk-advanced ${workspace.absolutePath}/config.cfg
