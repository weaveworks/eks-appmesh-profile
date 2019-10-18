#!/usr/bin/env bash

set -o errexit

HR=$1
IGNORE_VALUES=$2

usage() {
  echo "$(basename $0) </path/to/helmrelease>"
}

if test ! -f "${HR}"; then
  echo "\"${HR}\" file not found!"
  usage
  exit 1
fi

function download {
  CHART_REPO=$(yq r ${1} spec.chart.repository)
  CHART_NAME=$(yq r ${1} spec.chart.name)
  CHART_VERSION=$(yq r ${1} spec.chart.version)
  CHART_TAR="${2}/${CHART_NAME}-${CHART_VERSION}.tgz"
  URL=$(echo ${CHART_REPO} | sed "s/^\///;s/\/$//")
  curl -s ${URL}/${CHART_NAME}-${CHART_VERSION}.tgz > ${CHART_TAR}
  echo ${CHART_TAR}
}

function clone {
  ORIGIN=$(git rev-parse --show-toplevel)
  GIT_REPO=$(yq r ${1} spec.chart.git)
  GIT_REF=$(yq r ${1} spec.chart.ref)
  CHART_PATH=$(yq r ${1} spec.chart.path)
  cd ${2}
  git init -q
  git remote add origin ${GIT_REPO}
  git fetch -q origin
  git checkout -q ${GIT_REF}
  cd ${ORIGIN}
  echo ${2}/${CHART_PATH}
}

function validate {
  TMPDIR=$(mktemp -d)
  CHART_PATH=$(yq r ${HR} spec.chart.path)

  if [ "${CHART_PATH}" == "null" ]; then
    echo "Downloading to ${TMPDIR}"
    CHART_TAR=$(download ${HR} ${TMPDIR}| tail -n1)
  else
    echo "Cloning to ${TMPDIR}"
    CHART_TAR=$(clone ${HR} ${TMPDIR}| tail -n1)
  fi

  HR_NAME=$(yq r ${HR} metadata.name)
  HR_NAMESPACE=$(yq r ${HR} metadata.namespace)

  echo "Extracting values to ${TMPDIR}/${HR_NAME}.values.yaml"
  if [ ${IGNORE_VALUES} ]; then
    echo "" > ${TMPDIR}/${HR_NAME}.values.yaml
  else
    yq r ${HR} spec.values > ${TMPDIR}/${HR_NAME}.values.yaml
  fi

  echo "Writing Helm release to ${TMPDIR}/${HR_NAME}.release.yaml"
  helm template ${CHART_TAR} \
  --name ${HR_NAME} \
  --namespace ${HR_NAMESPACE} \
  -f ${TMPDIR}/${HR_NAME}.values.yaml > ${TMPDIR}/${HR_NAME}.release.yaml

  echo "Validating Helm release ${HR_NAME}.${HR_NAMESPACE}"
  kubeval --strict --ignore-missing-schemas ${TMPDIR}/${HR_NAME}.release.yaml
}

validate