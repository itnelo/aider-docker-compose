#!/usr/bin/env sh
set -eu

MODEL_NAME="${AIDER_OLLAMA_PROVIDER}/${AIDER_OLLAMA_MODEL}"
SETTINGS_PATH="${HOME}/.aider.model.settings.yml"

mkdir -p "${HOME}"

# Empty string in .env must not override Aider built-in defaults (unset = variable not set).
case "${AIDER_COMMIT_PROMPT:-}" in '') unset AIDER_COMMIT_PROMPT ;; esac
case "${AIDER_CHAT_LANGUAGE:-}" in '') unset AIDER_CHAT_LANGUAGE ;; esac
case "${AIDER_COMMIT_LANGUAGE:-}" in '') unset AIDER_COMMIT_LANGUAGE ;; esac
case "${AIDER_LINT_CMD:-}" in '') unset AIDER_LINT_CMD ;; esac

yaml_escape_string() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

write_kv_if_set() {
  key="$1"
  val="$2"
  if [ -n "$val" ]; then
    printf '    %s: %s\n' "$key" "$val" >> "$SETTINGS_PATH"
  fi
}

rm -f "$SETTINGS_PATH"

{
  echo "- name: \"$(yaml_escape_string "$MODEL_NAME")\""
  echo "  extra_params:"
} > "$SETTINGS_PATH"

write_kv_if_set "num_ctx" "${AIDER_OLLAMA_NUM_CTX:-}"
write_kv_if_set "num_predict" "${AIDER_OLLAMA_NUM_PREDICT:-}"
write_kv_if_set "temperature" "${AIDER_OLLAMA_TEMPERATURE:-}"
write_kv_if_set "top_p" "${AIDER_OLLAMA_TOP_P:-}"
write_kv_if_set "top_k" "${AIDER_OLLAMA_TOP_K:-}"
write_kv_if_set "repeat_penalty" "${AIDER_OLLAMA_REPEAT_PENALTY:-}"
write_kv_if_set "seed" "${AIDER_OLLAMA_SEED:-}"
if [ -n "${AIDER_OLLAMA_KEEP_ALIVE:-}" ]; then
  write_kv_if_set "keep_alive" "\"$(yaml_escape_string "${AIDER_OLLAMA_KEEP_ALIVE}")\""
fi

echo "Generated ${SETTINGS_PATH} for ${MODEL_NAME}"

if [ "$#" -eq 0 ]; then
  exec /venv/bin/aider --help
fi

# Expand AIDER_LINT_CMD into multiple --lint-cmd flags (one env key for compose).
# Options:
#   (a) one rule:  AIDER_LINT_CMD='php: php -l'
#   (b) several rules separated by ';;' (must not appear inside a command):
#       AIDER_LINT_CMD='php: php -l;;javascript: npx eslint --max-warnings=0'
#   (c) multiline value (YAML | block in compose): one 'lang: command' per line.
if [ -n "${AIDER_LINT_CMD:-}" ]; then
  _cmd=${AIDER_LINT_CMD}
  _nl=$(printf '\n')
  case "${_cmd}" in
    *"${_nl}"*)
      OLDIFS=${IFS}
      IFS=${_nl}
      for _piece in ${_cmd}; do
        IFS=${OLDIFS}
        _piece=$(printf '%s' "${_piece}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        case "${_piece}" in '') continue ;; esac
        set -- --lint-cmd "${_piece}" "$@"
      done
      IFS=${OLDIFS}
      ;;
    *';;'*)
      _rest=${_cmd}
      while [ -n "${_rest}" ]; do
        case "${_rest}" in
          *';;'*) _piece=${_rest%%;;*}; _rest=${_rest#*;;} ;;
          *) _piece=${_rest}; _rest= ;;
        esac
        _piece=$(printf '%s' "${_piece}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        case "${_piece}" in '') continue ;; esac
        set -- --lint-cmd "${_piece}" "$@"
      done
      ;;
    *)
      set -- --lint-cmd "${_cmd}" "$@"
      ;;
  esac
fi

exec /venv/bin/aider "$@"
