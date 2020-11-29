#!/bin/bash
set -ex

IMAGE=akeylimepie/php-fpm

COMPOSER_VERSION=2.0.7
XDEBUG_VERSION=3.0.0

DOCKERFILE_TEMPLATE=$(<./template.dockerfile)
DOCKERFILE_PROD=$(<./environments/prod.dockerfile)
DOCKERFILE_DEV=$(<./environments/dev.dockerfile)

TAGS=()

function build() {
  PHP_VERSION=$1

  if [[ $1 =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)(RC[1-9]+)?$ ]]; then
    MAJOR=${BASH_REMATCH[1]}
    MINOR=${BASH_REMATCH[2]}
    PATCH=${BASH_REMATCH[3]}
    RC=${BASH_REMATCH[4]}
  else
    exit 1
  fi

  case $2 in
  dev)
    DOCKERFILE="${DOCKERFILE_TEMPLATE//%%ENVIRONMENT%%/$DOCKERFILE_DEV}"
    ENV_MARK="-dev"
    ;;
  prod)
    DOCKERFILE="${DOCKERFILE_TEMPLATE//%%ENVIRONMENT%%/$DOCKERFILE_PROD}"
    ENV_MARK=""
    ;;
  esac

  TAG_LATEST="${MAJOR}.${MINOR}${RC}-latest${ENV_MARK}"

  echo "$DOCKERFILE" | docker build \
    --build-arg PHP_VERSION="$PHP_VERSION" \
    --build-arg COMPOSER_VERSION="$COMPOSER_VERSION" \
    --build-arg XDEBUG_VERSION="$XDEBUG_VERSION" \
    -t $IMAGE:"$TAG_LATEST" -f- .

  TAG_SPECIAL="${MAJOR}.${MINOR}.${PATCH}${RC}${ENV_MARK}"
  tag "$TAG_LATEST" "$TAG_SPECIAL"

  TAGS+=("$TAG_LATEST")
  TAGS+=("$TAG_SPECIAL")
}

function tag() {
  docker tag $IMAGE:"$1" $IMAGE:"$2"
}

function readme() {
  PROD_BUILDS=()
  DEV_BUILDS=()

  for TAG in "${TAGS[@]}"; do
    docker push $IMAGE:"$TAG"

    if [[ $TAG =~ \-dev$ ]]; then
      DEV_BUILDS+=("$TAG")
    else
      PROD_BUILDS+=("$TAG")
    fi
  done

  TAGS_TABLE=""

  for i in "${!PROD_BUILDS[@]}"; do
    TAGS_TABLE+="| ${PROD_BUILDS[$i]} | ${DEV_BUILDS[$i]} |"
    TAGS_TABLE+=$'\n'
  done

  README_TEMPLATE=$(<./README.template.md)
  README_TEMPLATE="${README_TEMPLATE//%%COMPOSER_VERSION%%/$COMPOSER_VERSION}"
  README_TEMPLATE="${README_TEMPLATE//%%XDEBUG_VERSION%%/$XDEBUG_VERSION}"

  echo "${README_TEMPLATE//%%TAGS_TABLE%%/$TAGS_TABLE}" >./README.md
}

PHP_VERSIONS=(
  8.0.0RC5
  7.4.12
  7.3.24
)

for PHP_VERSION in "${PHP_VERSIONS[@]}"; do
  build "$PHP_VERSION" prod
  build "$PHP_VERSION" dev
done

readme
