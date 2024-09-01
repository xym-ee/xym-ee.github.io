

server_all:
	sudo hugo server --bind=0.0.0.0 -p 80 --baseURL=http://10.0.0.22 --buildDrafts --disableFastRender --gc --ignoreCache --noHTTPCache --forceSyncStatic -w

server_nodraft:
	sudo hugo server --bind=0.0.0.0 -p 80 --baseURL=http://10.0.0.22 --disableFastRender --gc --ignoreCache --noHTTPCache --forceSyncStatic -w

clean:
	rm -rf ./public

