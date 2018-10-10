docker pull sonatanfv/tng-wrk-advanced
docker run --rm --network host -v tee:/workspace sonatanfv/tng-wrk-advanced ${workspace.absolutePath}/config.cfg
