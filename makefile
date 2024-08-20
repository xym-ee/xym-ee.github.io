

server_all:
	hugo server --bind=0.0.0.0 --baseURL=http://10.0.0.22:1313 --buildDrafts --disableFastRender --gc --ignoreCache --noHTTPCache --forceSyncStatic -w

server_nodraft:
	hugo server --bind=0.0.0.0 --baseURL=http://10.0.0.22:1313 --disableFastRender --gc --ignoreCache --noHTTPCache --forceSyncStatic -w



