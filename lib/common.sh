#!/usr/bin/env bash
# shellcheck shell=bash
#
# lib/common.sh — AI Terminal Pult uchun umumiy yordamchi funksiyalar.
# Bu fayl mustaqil ishga tushirilmaydi; boshqa skriptlar `source` qiladi.
#
# Mazmuni:
#   • Rang konstantalari (terminal TTY bo'lganda)
#   • Log funksiyalari: log_info / log_warn / log_error / log_success
#   • die()  — xabar chiqarib, berilgan exit-code bilan to'xtaydi
#   • require_cmd() — kerakli buyruq mavjudligini tekshiradi

# --- Rang/animatsiya yoqilishini aniqlash --------------------------------
# Quyidagi tartibda hal qilinadi:
#   1) NO_COLOR o'rnatilgan bo'lsa            → o'chiq (standart hurmat)
#   2) FORCE_COLOR / CLICOLOR_FORCE bo'lsa    → MAJBURAN yoniq
#   3) stdout yoki stderr terminal (tty) bo'lsa → yoniq
#   4) Windows zamonaviy terminal belgilari   → yoniq (Windows Terminal/ConEmu/ANSICON)
#   5) aks holda                               → o'chiq (faylga/quvurga yozilmoqda)
if [[ -n "${NO_COLOR:-}" ]]; then
  UI_TTY=0
elif [[ -n "${FORCE_COLOR:-}" || -n "${CLICOLOR_FORCE:-}" ]]; then
  UI_TTY=1
elif [[ -t 1 || -t 2 ]]; then
  UI_TTY=1
elif [[ -n "${WT_SESSION:-}" || -n "${ANSICON:-}" || "${ConEmuANSI:-}" == "ON" || -n "${TERM_PROGRAM:-}" ]]; then
  UI_TTY=1
else
  UI_TTY=0
fi

if [[ "$UI_TTY" -eq 1 ]]; then
  C_RESET=$'\033[0m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_MAGENTA=$'\033[35m'
  C_CYAN=$'\033[36m'
  C_GRAY=$'\033[90m'
  C_DIM=$'\033[2m'
  C_BOLD=$'\033[1m'
  # 256-rangli urg'ular (banner/gradient uchun)
  C_G1=$'\033[38;5;51m'   # och feruza
  C_G2=$'\033[38;5;45m'
  C_G3=$'\033[38;5;39m'   # ko'k
  C_G4=$'\033[38;5;201m'  # pushti
  C_TITLE=$'\033[38;5;87m'
  # AD logosi uchun cyan→ko'k→pushti gradient (6 qator)
  C_LG1=$'\033[38;5;51m'
  C_LG2=$'\033[38;5;45m'
  C_LG3=$'\033[38;5;39m'
  C_LG4=$'\033[38;5;33m'
  C_LG5=$'\033[38;5;99m'
  C_LG6=$'\033[38;5;201m'
else
  C_RESET='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE='' C_MAGENTA='' C_CYAN=''
  C_GRAY='' C_DIM='' C_BOLD='' C_G1='' C_G2='' C_G3='' C_G4='' C_TITLE=''
  C_LG1='' C_LG2='' C_LG3='' C_LG4='' C_LG5='' C_LG6=''
fi

# Animatsiya: rang yoniq bo'lsa va aniq o'chirilmagan bo'lsa.
if [[ "$UI_TTY" -eq 1 && -z "${AI_NO_ANIM:-}" && -z "${CI:-}" ]]; then AI_ANIM=1; else AI_ANIM=0; fi
# Unicode (braille/box) qo'llab-quvvatlanadimi? Noma'lum bo'lsa — ha deb hisoblaymiz.
case "${LC_ALL:-${LC_CTYPE:-${LANG:-UTF-8}}}" in
  C|POSIX|*.iso*|*ISO8859*|*latin*|*LATIN*) UI_UTF8=0 ;;
  *)                                        UI_UTF8=1 ;;
esac

# --- Log funksiyalari (barchasi stderr'ga yozadi) -------------------------
log_info()    { printf '%s[i]%s %s\n'  "$C_BLUE"   "$C_RESET" "$*" >&2; }
log_warn()    { printf '%s[!]%s %s\n'  "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_error()   { printf '%s[x]%s %s\n'  "$C_RED"    "$C_RESET" "$*" >&2; }
log_success() { printf '%s[✓]%s %s\n'  "$C_GREEN"  "$C_RESET" "$*" >&2; }

# die <exit_code> <message...>
#   Xato xabarini chiqaradi va skriptni berilgan exit-code bilan to'xtatadi.
die() {
  local code="$1"; shift
  log_error "$*"
  exit "$code"
}

# require_cmd <command> [installation_hint]
#   Buyruq PATH'da mavjudligini tekshiradi; yo'q bo'lsa die() qiladi.
require_cmd() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    if [[ -n "$hint" ]]; then
      die 127 "'$cmd' topilmadi. O'rnatish uchun: $hint"
    else
      die 127 "'$cmd' topilmadi. Iltimos, uni o'rnatib, qaytadan urinib ko'ring."
    fi
  fi
}

# --- Sodda, tushunarli xabarlar (yangi va yosh foydalanuvchilar uchun) -----

# panel <SARLAVHA> [QATOR...]
#   Diqqatni tortadigan, ramkali xabar chiqaradi. Har bir QATOR — alohida
#   qator. Maqsad: xatoni hatto tajribasiz odam ham tushunsin.
panel() {
  local title="$1"; shift
  printf '\n%s%s┌─ %s%s\n' "${C_YELLOW}" "${C_BOLD}" "$title" "${C_RESET}" >&2
  local line
  for line in "$@"; do
    printf '%s│%s %s\n' "${C_YELLOW}" "${C_RESET}" "$line" >&2
  done
  printf '%s└────────────────────────────────────────%s\n\n' "${C_YELLOW}" "${C_RESET}" >&2
}

# tool_hint <tool>
#   Berilgan dasturni qanday o'rnatishni ODDIY tilda tushuntiradi.
tool_hint() {
  case "$1" in
    npm|node|nodejs)
      printf '%s' "Node.js kerak (npm u bilan birga keladi). https://nodejs.org saytiga kiring, katta yashil \"LTS\" tugmasini bosib yuklab oling, o'rnating va terminalni qayta oching." ;;
    python3|python|pip|pip3)
      printf '%s' "Python 3 kerak. https://www.python.org/downloads saytidan yuklab oling. Windows'da o'rnatishda \"Add Python to PATH\" katagiga belgi qo'yishni unutmang." ;;
    curl)
      printf '%s' "curl kerak. Ubuntu/Debian: \"sudo apt install curl\" · macOS: oldindan bor · Windows: Git Bash bilan birga keladi." ;;
    wget)
      printf '%s' "wget kerak. Ubuntu/Debian: \"sudo apt install wget\"." ;;
    git)
      printf '%s' "git kerak. https://git-scm.com/downloads saytidan yuklab olib o'rnating." ;;
    fzf)
      printf '%s' "fzf kerak. macOS: \"brew install fzf\" · Ubuntu: \"sudo apt install fzf\" · Windows: \"winget install fzf\"." ;;
    bash)
      printf '%s' "bash kerak. Windows'da Git for Windows o'rnating: https://git-scm.com/download/win" ;;
    brew)
      printf '%s' "Homebrew kerak. https://brew.sh saytidagi buyruqni terminalga nusxalang." ;;
    *)
      printf '%s' "'$1' nomli dastur kerak, lekin u topilmadi. Internetdan \"$1 install\" deb qidirib o'rnating." ;;
  esac
}

# ===========================================================================
#  CHIROYLI UI: banner, gorizontal chiziq, spinner, animatsiyalar
#  Barchasi STDERR'ga yozadi — stdout'ni (qaytariladigan qiymatlarni) buzmaydi.
# ===========================================================================

# show_cursor — kursorni qaytaradi (spinner yoki Ctrl+C'dan keyin).
show_cursor() { [[ "${UI_TTY:-0}" -eq 1 ]] && printf '\033[?25h' >&2 || true; }

# open_url <url> — havolani standart brauzerda ochadi (platformaga qarab).
#   Eng yaxshi-harakat: xato bo'lsa ham jim qaytadi (havola baribir chop etiladi).
open_url() {
  local url="$1" os
  [[ -n "$url" ]] || return 0
  os="$(uname -s 2>/dev/null || echo unknown)"
  case "$os" in
    MINGW*|MSYS*|CYGWIN*)
      # Windows / Git Bash — explorer URL'ni standart brauzerda ochadi.
      # MSYS2_ARG_CONV_EXCL='*' — MSYS "https://" ni yo'lga aylantirmasin.
      if command -v explorer.exe >/dev/null 2>&1; then
        MSYS2_ARG_CONV_EXCL='*' explorer.exe "$url" >/dev/null 2>&1 &
      elif command -v powershell >/dev/null 2>&1; then
        powershell -NoProfile -Command "Start-Process '$url'" >/dev/null 2>&1 &
      fi
      ;;
    Darwin*)
      command -v open >/dev/null 2>&1 && open "$url" >/dev/null 2>&1 &
      ;;
    *)
      command -v xdg-open >/dev/null 2>&1 && xdg-open "$url" >/dev/null 2>&1 &
      ;;
  esac
  return 0
}

# hr [eni] — gorizontal chiziq satrini QAYTARADI (chop etmaydi).
hr() {
  local w="${1:-46}" ch i s=''
  if [[ "${UI_UTF8:-1}" -eq 1 ]]; then ch='━'; else ch='-'; fi
  for ((i = 0; i < w; i++)); do s+="$ch"; done
  printf '%s' "$s"
}

# banner [sarlavha] [kichik-sarlavha]
#   Aidevix CLI brendi: AD monogrammasi (gradient) + harfma-harf animatsiya.
#   TTY bo'lmasa — oddiy matn. assets/log.jpg dagi "AD" logosining ASCII shakli.
banner() {
  local title="${1:-Aidevix CLI}" subtitle="${2:-barcha AI agentlar — bitta pultda}"
  if [[ "${UI_TTY:-0}" -ne 1 ]]; then
    printf '\n  %s\n  %s\n\n' "$title" "$subtitle" >&2
    return 0
  fi

  printf '\n' >&2

  # --- AD logosi (assets/log.jpg ASCII shakli) ---------------------------
  if [[ "${UI_UTF8:-1}" -eq 1 ]]; then
    local -a logo=(
'    █████╗ ██████╗ '
'   ██╔══██╗██╔══██╗'
'   ███████║██║  ██║'
'   ██╔══██║██║  ██║'
'   ██║  ██║██████╔╝'
'   ╚═╝  ╚═╝╚═════╝ '
    )
    local -a grad=("$C_LG1" "$C_LG2" "$C_LG3" "$C_LG4" "$C_LG5" "$C_LG6")
    local k
    for k in "${!logo[@]}"; do
      printf '%s%s%s%s\n' "$C_BOLD" "${grad[k]}" "${logo[k]}" "$C_RESET" >&2
      [[ "${AI_ANIM:-0}" -eq 1 ]] && sleep 0.045 || true
    done
  else
    printf '%s    /\\  ___ %s\n' "$C_G1" "$C_RESET" >&2
    printf '%s   /__\\ |  |%s\n' "$C_G3" "$C_RESET" >&2
    printf '%s        |__|%s\n' "$C_G4" "$C_RESET" >&2
  fi

  # --- Sarlavha — harfma-harf "yozilish" animatsiyasi --------------------
  printf '\n  %s✦  ' "$C_BOLD" >&2
  if [[ "${AI_ANIM:-0}" -eq 1 ]]; then
    local j
    for ((j = 0; j < ${#title}; j++)); do
      printf '%s%s' "$C_TITLE" "${title:j:1}" >&2
      sleep 0.03
    done
    printf '%s\n' "$C_RESET" >&2
  else
    printf '%s%s%s\n' "$C_TITLE" "$title" "$C_RESET" >&2
  fi

  printf '  %s%s%s\n' "$C_GRAY" "$subtitle" "$C_RESET" >&2

  local s1 s2
  s1="$(hr 18)"; s2="$(hr 18)"
  printf '  %s%s%s%s%s\n\n' "$C_G1" "$s1" "$C_G4" "$s2" "$C_RESET" >&2
}

# SPIN_LOG — oxirgi spin_run chiqishi shu faylda saqlanadi (xatoni ko'rsatish uchun).
SPIN_LOG=""

# spin_run <xabar> <bash-buyrug'i-satri>
#   Buyruqni ishga tushiradi, yonida aylanuvchi spinner + o'tgan vaqtni
#   ko'rsatadi. TTY/animatsiya bo'lmasa — oddiy bajaradi (chiqish ko'rinadi).
#   Chiqishni tugagach SPIN_LOG'ga saqlaydi. Buyruq exit-kodini qaytaradi.
spin_run() {
  local msg="$1" cmd="$2"
  SPIN_LOG="$(mktemp)"

  if [[ "${AI_ANIM:-0}" -ne 1 ]]; then
    printf '%s▸%s %s ...\n' "$C_CYAN" "$C_RESET" "$msg" >&2
    bash -c "$cmd" 2>&1 | tee "$SPIN_LOG" >&2
    return "${PIPESTATUS[0]}"
  fi

  # Spinner ramkalari + progress-bar belgilarini Unicode/ASCII'ga moslaymiz.
  local frames comet trail1 trail2 dimc
  if [[ "${UI_UTF8:-1}" -eq 1 ]]; then
    frames=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    comet='█'; trail1='▓'; trail2='▒'; dimc='░'
  else
    frames=('|' '/' '-' '\')
    comet='#'; trail1='='; trail2='-'; dimc='.'
  fi
  local n=${#frames[@]} barw=22

  bash -c "$cmd" >"$SPIN_LOG" 2>&1 &
  local pid=$! i=0 start=$SECONDS el
  printf '\033[?25l' >&2
  while kill -0 "$pid" 2>/dev/null; do
    el=$((SECONDS - start))
    # Indeterminat "komet": chap-o'ngga sakraydi, orqasida gradientli iz qoldiradi.
    local period=$(( (barw - 1) * 2 )); (( period < 1 )) && period=1
    local pos=$(( i % period )); (( pos >= barw )) && pos=$(( period - pos ))
    local bar="" k dist
    for ((k = 0; k < barw; k++)); do
      dist=$(( k - pos )); (( dist < 0 )) && dist=$(( -dist ))
      if   (( dist == 0 )); then bar+="${C_G1}${comet}"
      elif (( dist == 1 )); then bar+="${C_G3}${trail1}"
      elif (( dist == 2 )); then bar+="${C_G4}${trail2}"
      else                        bar+="${C_GRAY}${dimc}"
      fi
    done
    printf '\r %s%s%s %s%s%s  %s%s  %s%2ss%s\033[K' \
      "$C_CYAN" "${frames[i % n]}" "$C_RESET" \
      "$C_BOLD" "$msg" "$C_RESET" \
      "$bar" "$C_RESET" \
      "$C_GRAY" "$el" "$C_RESET" >&2
    i=$((i + 1))
    sleep 0.08
  done
  local rc=0; wait "$pid" || rc=$?
  printf '\033[?25h' >&2
  el=$((SECONDS - start))

  # Yakuniy holat — to'liq to'ldirilgan bar (yashil/qizil).
  local fullbar="" k
  for ((k = 0; k < barw; k++)); do fullbar+="$comet"; done
  if [[ "$rc" -eq 0 ]]; then
    printf '\r %s✓%s %s  %s%s%s  %s(%ss)%s\033[K\n' \
      "$C_GREEN" "$C_RESET" "$msg" "$C_GREEN" "$fullbar" "$C_RESET" "$C_GRAY" "$el" "$C_RESET" >&2
  else
    printf '\r %s✗%s %s  %s%s%s  %s(%ss)%s\033[K\n' \
      "$C_RED" "$C_RESET" "$msg" "$C_RED" "$fullbar" "$C_RESET" "$C_GRAY" "$el" "$C_RESET" >&2
  fi
  return "$rc"
}

# ui_launch <nom> — agentni ishga tushirishdan oldingi qisqa chiroyli ishora.
ui_launch() {
  local name="$1"
  printf '\n  %s%s🚀 Ishga tushirilmoqda%s  %s%s%s\n\n' \
    "$C_BOLD" "$C_G3" "$C_RESET" "$C_TITLE" "$name" "$C_RESET" >&2
  [[ "${AI_ANIM:-0}" -eq 1 ]] && sleep 0.3 || true
}
