.PHONY: build lint images
build:
	python3 scripts/build.py

lint: build
	python3 scripts/check.py

images:
	bash scripts/render-images.sh
