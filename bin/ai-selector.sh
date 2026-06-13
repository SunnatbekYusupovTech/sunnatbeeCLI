#!/usr/bin/env bash
#
# ai-selector.sh — AI Terminal Pult'ning asosiy skripti.
#
# Vazifasi: config/agents.conf faylidan AI CLI agentlarini o'qiydi, ularni
# FZF interfeysi orqali ko'rsatadi va tanlangan agentni ishga tushiradi.
#
# Foydalanish:
#   ai-selector.sh            # interaktiv FZF menyusi
#   ai-selector.sh --list     # agentlar ro'yxatini chop etadi
#   ai-selector.sh --help     # yordam
#
# Exit kodlari:
#   0   — muvaffaqiyat (yoki foydalanuvchi tanlovni bekor qildi)
#   1   — umumiy/konfiguratsiya xatosi
#   2   — noto'g'ri argument
#   127 — kerakli buyruq (fzf yoki tanlangan agent) topilmadi

set -Eeuo pipefail

# --- Loyiha ildizini va kerakli fayllarni aniqlash ------------------------
# Skript joylashgan haqiqiy katalog (symlink orqali chaqirilsa ham to'g'ri).
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_SOURCE" ]]; do
  dir="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ "$SCRIPT_SOURCE" != /* ]] && SCRIPT_SOURCE="$dir/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -P "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"

# Foydalanuvchi konfiguratsiyasini ustun qo'yamiz, bo'lmasa repodagisini.
USER_CONFIG="${AI_PULT_CONFIG:-$HOME/.config/ai-terminal-pult/agents.conf}"
REPO_CONFIG="$PROJECT_ROOT/config/agents.conf"

# --- Umumiy yordamchilarni yuklash ----------------------------------------
LIB="$PROJECT_ROOT/lib/common.sh"
if [[ ! -r "$LIB" ]]; then
  printf '[x] Kutubxona topilmadi yoki o\047qib bo\047lmadi: %s\n' "$LIB" >&2
  exit 1
fi
# shellcheck source=../lib/common.sh
source "$LIB"

# --- Xatolik tutqichi (qaysi qatorda yiqilganini ko'rsatadi) --------------
trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

# --- Yordam matni ---------------------------------------------------------
usage() {
  cat <<'EOF'
AI Terminal Pult — terminaldagi AI CLI agentlarini bitta menyudan boshqaring.

FOYDALANISH:
  ai-selector [TANLOV]

TANLOVLAR:
  (argumentsiz)   Interaktiv FZF menyusini ochadi
  -l, --list      Mavjud agentlar ro'yxatini chop etadi
  -h, --help      Ushbu yordam matnini ko'rsatadi

KONFIGURATSIYA:
  Agentlar quyidagi fayldan o'qiladi (birinchi topilgani ishlatiladi):
    1) $AI_PULT_CONFIG (muhit o'zgaruvchisi)
    2) ~/.config/ai-terminal-pult/agents.conf
    3) <repo>/config/agents.conf

  Yangi agent qo'shish uchun faylga quyidagi formatda qator yozing:
    NOM|BINARY|BUYRUQ|IZOH
EOF
}

# --- Ishlatiladigan konfiguratsiya faylini tanlash ------------------------
resolve_config() {
  if [[ -r "$USER_CONFIG" ]]; then
    printf '%s\n' "$USER_CONFIG"
  elif [[ -r "$REPO_CONFIG" ]]; then
    printf '%s\n' "$REPO_CONFIG"
  else
    die 1 "Konfiguratsiya fayli topilmadi. Tekshirildi: '$USER_CONFIG' va '$REPO_CONFIG'"
  fi
}

# --- Konfiguratsiyani o'qib, FZF uchun qatorlar tayyorlash ----------------
# Har bir yaroqli qatorni "NOM\tIZOH\tBINARY\tBUYRUQ" ko'rinishida chiqaradi.
# (Tab bilan ajratamiz, chunki nom/izohda probel bo'lishi mumkin.)
parse_agents() {
  local config="$1"
  local line name binary command desc lineno=0 found=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    # Izoh va bo'sh qatorlarni o'tkazib yuborish
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue

    IFS='|' read -r name binary command desc <<<"$line"
    # Bo'shliqlarni qirqish
    name="$(printf '%s' "${name:-}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    binary="$(printf '%s' "${binary:-}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    command="$(printf '%s' "${command:-}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    desc="$(printf '%s' "${desc:-}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    if [[ -z "$name" || -z "$binary" || -z "$command" ]]; then
      log_warn "Konfiguratsiyada noto'g'ri qator o'tkazib yuborildi (#$lineno): $line"
      continue
    fi
    printf '%s\t%s\t%s\t%s\n' "$name" "$desc" "$binary" "$command"
    found=1
  done <"$config"

  [[ "$found" -eq 1 ]] || die 1 "Konfiguratsiyada birorta yaroqli agent topilmadi: $config"
}

# --- --list rejimi --------------------------------------------------------
list_agents() {
  local config; config="$(resolve_config)"
  log_info "Konfiguratsiya: $config"
  printf '\n%s%-22s %-9s %s%s\n' "$C_BOLD" "AGENT" "HOLAT" "IZOH" "$C_RESET"
  printf '%s\n' "------------------------------------------------------------"
  local name desc binary command status
  while IFS=$'\t' read -r name desc binary command; do
    if command -v "$binary" >/dev/null 2>&1; then
      status="${C_GREEN}o'rnatilgan${C_RESET}"
    else
      status="${C_RED}yo'q${C_RESET}      "
    fi
    printf '%-22s %b %s\n' "$name" "$status" "$desc"
  done < <(parse_agents "$config")
}

# --- Asosiy interaktiv rejim ----------------------------------------------
run_menu() {
  require_cmd fzf "https://github.com/junegunn/fzf#installation"

  local config; config="$(resolve_config)"

  # FZF'ga faqat ko'rinadigan ustunlarni beramiz (NOM + IZOH),
  # asl ma'lumotni esa keyin nom bo'yicha qayta topamiz.
  local agents selection name
  agents="$(parse_agents "$config")"

  selection="$(
    printf '%s\n' "$agents" \
      | awk -F'\t' '{ printf "%-22s  %s\n", $1, $2 }' \
      | fzf --ansi \
            --prompt='🤖 AI agent tanlang › ' \
            --height=60% \
            --reverse \
            --border=rounded \
            --header='ENTER — ishga tushirish · ESC — bekor qilish'
  )" || {
    # fzf 130 (ESC) qaytarsa — bu xato emas, foydalanuvchi bekor qildi.
    local rc=$?
    if [[ "$rc" -eq 130 ]]; then
      log_info "Bekor qilindi."
      exit 0
    fi
    die "$rc" "fzf kutilmagan kod bilan to'xtadi: $rc"
  }

  [[ -z "$selection" ]] && { log_info "Hech narsa tanlanmadi."; exit 0; }

  # Tanlangan nomni tozalab, asl qatordan binary/command'ni topamiz.
  name="$(printf '%s' "$selection" | sed -e 's/[[:space:]][[:space:]].*$//' -e 's/[[:space:]]*$//')"

  local row binary command
  row="$(printf '%s\n' "$agents" | awk -F'\t' -v n="$name" '$1 == n { print; exit }')"
  [[ -n "$row" ]] || die 1 "Tanlangan agent topilmadi: $name"

  binary="$(printf '%s' "$row" | cut -f3)"
  command="$(printf '%s' "$row" | cut -f4)"

  launch_agent "$name" "$binary" "$command"
}

# --- Agentni ishga tushirish (mavjudligini tekshirib) ---------------------
launch_agent() {
  local name="$1" binary="$2" command="$3"

  if ! command -v "$binary" >/dev/null 2>&1; then
    log_error "Agent topilmadi: '$name' (kerakli buyruq: '$binary')."
    log_error "Iltimos, uni o'rnatib oling va qaytadan urinib ko'ring."
    exit 127
  fi

  log_success "Ishga tushirilmoqda: $name  ➜  $command"
  # ERR tutqichini o'chiramiz — agent o'z exit-code'ini o'zi qaytarsin.
  trap - ERR
  # Buyruqni so'zlarga ajratib ishga tushiramiz (argumentlarni qo'llab-quvvatlash uchun).
  # shellcheck disable=SC2086
  exec $command
}

# --- Argumentlarni qayta ishlash ------------------------------------------
main() {
  case "${1:-}" in
    -h|--help)  usage ;;
    -l|--list)  list_agents ;;
    "")         run_menu ;;
    *)          log_error "Noma'lum tanlov: $1"; echo; usage; exit 2 ;;
  esac
}

main "$@"
