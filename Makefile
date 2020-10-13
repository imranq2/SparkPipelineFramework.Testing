LANG=en_US.utf-8

export LANG

BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
VERSION=$(shell cat VERSION)
VENV_NAME=venv
GIT_HASH=${CIRCLE_SHA1}
SPARK_VER=3.0.1
HADOOP_VER=3.2
PACKAGES_FOLDER=venv/lib/python3.6/site-packages
SPF_BASE=${PACKAGES_FOLDER}

include spark_pipeline_framework_testing/Makefile.spark
include spark_pipeline_framework_testing/Makefile.docker
include spark_pipeline_framework_testing/Makefile.python

.PHONY:devsetup
devsetup:venv
	source $(VENV_NAME)/bin/activate && \
    pip install --upgrade pip && \
    pip install --upgrade -r requirements.txt && \
    pip install --upgrade -r requirements-test.txt && \
    pre-commit install && \
    python setup.py install

.PHONY:checks
checks:venv
	source $(VENV_NAME)/bin/activate && \
    pip install --upgrade -r requirements.txt && \
    flake8 spark_pipeline_framework_testing && \
    mypy spark_pipeline_framework_testing --strict && \
    flake8 tests && \
    mypy tests

.PHONY:update
update:
	source $(VENV_NAME)/bin/activate && \
	pip install --upgrade -r requirements.txt && \
	pip install --upgrade -r requirements-test.txt

.PHONY:build
build:venv
	source $(VENV_NAME)/bin/activate && \
    pip install --upgrade pip && \
    pip install --upgrade -r requirements.txt && \
    python setup.py install && \
    rm -r dist/ && \
    python3 setup.py sdist bdist_wheel

.PHONY:testpackage
testpackage:venv build
	source $(VENV_NAME)/bin/activate && \
	python3 -m twine upload -u __token__ --repository testpypi dist/*
# password can be set in TWINE_PASSWORD. https://twine.readthedocs.io/en/latest/

.PHONY:package
package:venv build
	source $(VENV_NAME)/bin/activate && \
	python3 -m twine upload -u __token__ --repository pypi dist/*
# password can be set in TWINE_PASSWORD. https://twine.readthedocs.io/en/latest/

.PHONY:tests
tests:
	source $(VENV_NAME)/bin/activate && \
    pip install --upgrade -r requirements.txt && \
	pip install --upgrade -r requirements-test.txt && \
	pytest tests

.PHONY:init
init: installspark docker up devsetup proxies tests

.PHONY:proxies
proxies:
	source ${VENV_NAME}/bin/activate && \
	python3 ${PACKAGES_FOLDER}/spark_pipeline_framework/proxy_generator/generate_proxies.py
