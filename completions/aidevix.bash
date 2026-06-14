# bash/zsh uchun `aidevix` buyrug'i avtomatik to'ldirilishi.
#
# Yoqish:
#   • bash: ushbu faylni ~/.bashrc dan `source` qiling.
#   • zsh : ~/.zshrc da `autoload -U +X bashcompinit && bashcompinit` dan
#           keyin ushbu faylni `source` qiling.
# install.sh buni avtomatik bajaradi.

_ai_complete() {
  local cur flags names cfg
  cur="${COMP_WORDS[COMP_CWORD]}"
  flags="--list --free --top --update --doctor --add --version --help -l -f -t -u -d -a -v -h"

  # Faqat birinchi argument to'ldiriladi (qolganlari agentga uzatiladi).
  if [[ "$COMP_CWORD" -ne 1 ]]; then
    return 0
  fi

  # Konfiguratsiyadan agent binarlarini o'qiymiz.
  if [[ -n "${AI_PULT_CONFIG:-}" && -r "$AI_PULT_CONFIG" ]]; then
    cfg="$AI_PULT_CONFIG"
  elif [[ -r "$HOME/.config/ai-cli/agents.conf" ]]; then
    cfg="$HOME/.config/ai-cli/agents.conf"
  fi

  names=""
  if [[ -n "${cfg:-}" ]]; then
    names="$(grep -vE '^[[:space:]]*(#|$)' "$cfg" 2>/dev/null \
             | cut -d'|' -f2 | tr -d ' ' | tr '\n' ' ')"
  fi

  # shellcheck disable=SC2207
  COMPREPLY=( $(compgen -W "$flags $names" -- "$cur") )
}

complete -F _ai_complete aidevix
