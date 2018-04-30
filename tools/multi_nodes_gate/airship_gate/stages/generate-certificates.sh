#!/usr/bin/env bash

set -e

source "${GATE_UTILS}"

IS_UPDATE=0
DO_EXCLUDE=0
EXCLUDE_PATTERNS=()

while getopts "ux:" opt; do
    case "${opt}" in
        u)
            IS_UPDATE=1
            ;;
        x)
            DO_EXCLUDE=1
            EXCLUDE_PATTERNS+=("${OPTARG}")
            ;;
        *)
            echo "Unknown option"
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

DESIGN_FILES=($(find "${DEFINITION_DEPOT}" -name '*.yaml' | xargs -n 1 basename | xargs -n 1 printf "/tmp/design/%s\n"))
GATE_FILES=($(find "${GATE_DEPOT}" -name '*.yaml' | xargs -n 1 basename | xargs -n 1 printf "/tmp/gate/%s\n"))
mkdir -p "${CERT_DEPOT}"
chmod 777 "${CERT_DEPOT}"

log Generating certificates
docker run --rm -t \
    -w /tmp \
    -v "${DEFINITION_DEPOT}:/tmp/design" \
    -v "${GATE_DEPOT}:/tmp/gate" \
    -v "${CERT_DEPOT}:/certs" \
    -e "PROMENADE_DEBUG=${PROMENADE_DEBUG}" \
    "${IMAGE_PROMENADE_CLI}" \
        promenade \
            generate-certs \
                -o /certs \
                "${DESIGN_FILES[@]}" "${GATE_FILES[@]}"
