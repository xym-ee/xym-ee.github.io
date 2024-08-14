

test:
	hugo server --bind=0.0.0.0 --baseURL=http://10.0.0.22:1313 --buildDrafts --disableFastRender --gc --ignoreCache --noHTTPCache --forceSyncStatic -w

pub:
	hugo --baseURL="https://xym.work"


dir:
	mkdir -p layouts/partials/third_party_js





