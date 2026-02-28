#!/usr/bin/env bash
# Source this file to set up IndicNLP environment
_MYNLP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export INDIC_RESOURCES_PATH="${_MYNLP_DIR}/lib/indic_nlp_resources"
export PYTHONPATH="${PYTHONPATH:-}:${_MYNLP_DIR}/lib/indic_nlp_library"
