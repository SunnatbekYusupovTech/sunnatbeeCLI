#!/usr/bin/env bash
#
# ai-selector.sh — Aidevix CLI'ning asosiy skripti (buyruq: `aidevix`).
#
# Vazifasi: config/agents.conf faylidan AI CLI agentlarini o'qiydi, ularni
# FZF interfeysi (yoki oddiy raqamli menyu) orqali ko'rsatadi va tanlangan
# agentni ishga tushiradi. Agar CLI o'rnatilmagan bo'lsa — ruxsat so'rab,
# o'zi o'rnatadi.
#
# Foydalanish:
#   aidevix              # interaktiv menyu
#   aidevix claude       # to'g'ridan-to'g'ri agentni nomi/binari bo'yicha ishga tushirish
#   aidevix --list       # agentlar ro'yxati + holati
#   aidevix --update     # o'rnatilgan agentlarni yangilash
#   aidevix --doctor     # muhitni tekshirish
#   aidevix --add        # interaktiv yangi agent qo'shish
#   aidevix --help       # yordam
#
# Exit kodlari:
#   0   — muvaffaqiyat (yoki foydalanuvchi bekor qildi)
#   1   — umumiy/konfiguratsiya xatosi
#   2   — noto'g'ri argument
#   127 — kerakli buyruq (fzf yoki tanlangan agent) topilmadi

set -Eeuo pipefail

# --- Loyiha ildizini aniqlash (symlink orqali chaqirilsa ham) -------------
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SCRIPT_SOURCE" ]]; do
  dir="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ "$SCRIPT_SOURCE" != /* ]] && SCRIPT_SOURCE="$dir/$SCRIPT_SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd -P "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
# Preview kabi qism-jarayonlar uchun skriptning to'liq yo'li.
SELF="$SCRIPT_DIR/$(basename "$SCRIPT_SOURCE")"

# Versiya — VERSION faylidan o'qiladi (bo'lmasa quyidagi zaxira qiymat).
AIDEVIX_VERSION="$(cat "$PROJECT_ROOT/VERSION" 2>/dev/null || echo "1.0.0")"

# Repo config — ASOSIY ro'yxat (git orqali doimo yangilanadi).
# Foydalanuvchi config — faqat o'zi qo'shgan QO'SHIMCHA agentlar.
# Birlashtirilganda repo ustun turadi (yangi agentlar/tuzatishlar darrov yetadi),
# foydalanuvchi faqat repo'da YO'Q nomlarni qo'shadi. Shu tufayli main'ga push
# qilingan o'zgarishlar avtomatik yangilanishdan keyin hammaga ko'rinadi.
REPO_CONFIG="$PROJECT_ROOT/config/agents.conf"
USER_CONFIG="$HOME/.config/ai-cli/agents.conf"

# Oxirgi tanlangan agentni eslab qolish uchun holat fayli.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ai-cli"
STATE_FILE="$STATE_DIR/last"
# Lokal ishlatish statistikasi: har agent necha marta ishga tushirilgani.
# FAQAT shu kompyuterda saqlanadi — hech qayoqqa yuborilmaydi. Format: "<son>\t<nom>".
STATS_FILE="$STATE_DIR/usage"
# Login/auth eslatmasi qaysi agentlar uchun allaqachon ko'rsatilganini saqlaydi.
SEEN_AUTH_FILE="$STATE_DIR/seen_auth"

# --- Global statistika (OPT-IN — standart o'CHIQ) -------------------------
# Foydalanuvchi YOQSAGINA (aidevix --stats on) ishlaydi. Yoqilganda: agent
# ishga tushganda FAQAT "agent nomi + hodisa turi" markaziy serverga yuboriladi
# (IP/ID/shaxsiy ma'lumot YO'Q) va global reyting menyuda ko'rsatiladi.
# Server: bepul, ochiq — qarang server/. URL'ni AIDEVIX_STATS_URL bilan o'zgartirish mumkin.
AIDEVIX_STATS_URL="${AIDEVIX_STATS_URL:-https://sunnatbeecli-production.up.railway.app}"
GLOBAL_OPTIN_FILE="$STATE_DIR/global_stats"          # "on"/"off" — opt-in holati
GLOBAL_CACHE="$STATE_DIR/global_stats_cache"         # /v1/stats JSON keshi
GLOBAL_STAMP="$STATE_DIR/global_stats_check"         # keshni yangilash throttle vaqti
GLOBAL_HINT_FILE="$STATE_DIR/global_stats_hint"      # bir martalik eslatma ko'rsatilganini belgilaydi

# --- npm yangilanish eslatmasi (notify) -----------------------------------
# npm orqali o'rnatilganlarda git auto_update ishlamaydi (`.git` yo'q). Shuning
# uchun npm registry'dan eng so'nggi versiyani FONDA tekshirib, yangisi chiqsa
# "npm update -g aidevix" buyrug'ini eslatamiz (majburlamaymiz).
NPM_PKG="aidevix"                                    # npm registry'dagi paket nomi
NPM_LATEST_CACHE="$STATE_DIR/npm_latest"             # eng so'nggi versiya keshi
NPM_CHECK_STAMP="$STATE_DIR/npm_check"               # tekshirishni throttle vaqti
NPM_NOTIFIED_FILE="$STATE_DIR/npm_notified"          # eslatilgan oxirgi versiya (takror eslatmaslik)

# Kategoriya ko'rsatilmagan agentlar uchun standart qiymat.
DEFAULT_CATEGORY="AI"

# --- Umumiy yordamchilarni yuklash ----------------------------------------
LIB="$PROJECT_ROOT/lib/common.sh"
if [[ ! -r "$LIB" ]]; then
  printf '[x] Kutubxona topilmadi: %s\n' "$LIB" >&2
  exit 1
fi
# shellcheck source=../lib/common.sh
source "$LIB"

# Vaqtinchalik fayllarni tozalash + kursorni tiklash.
TMPFILES=()
cleanup() {
  show_cursor
  local f
  for f in ${TMPFILES[@]+"${TMPFILES[@]}"}; do rm -f "$f" 2>/dev/null || true; done
}
trap cleanup EXIT
trap 'die 1 "$(t "Kutilmagan xato: %s (qator: %s)" "$BASH_COMMAND" "$LINENO")"' ERR

# --- Yordam matni ---------------------------------------------------------
usage() {
  if [[ "${AIDEVIX_LANG_RESOLVED:-uz}" == "en" ]]; then
    cat <<'EOF'
Aidevix CLI — manage your terminal AI CLI agents from a single menu.

USAGE:
  aidevix [OPTION | AGENT]

OPTIONS:
  (no argument)   Open the interactive menu (fzf if available, else numbered)
  AGENT           Launch an agent directly by name or binary
                  (e.g. `aidevix claude`, `aidevix gemini`)
  -l, --list      List agents and their status
  -f, --free      Open a menu of FREE agents only (🆓 / free tier)
  -t, --top       Open a menu of the most popular (top) agents only
  -u, --update    Update all installed agents
  -d, --doctor    Check the environment (node/npm/python/fzf, PATH, agents)
  -a, --add       Add a new agent interactively
  -s, --stats [on|off]
                  Global stats (opt-in): show status, or turn on/off.
                  When on, the menu shows "🔥 #rank". Only the agent name +
                  event type are sent (no personal data). Default: off.
  -v, --version   Show the Aidevix CLI version
  -h, --help      Show this help text

CONFIGURATION:
  Agents are read from the following file (first one found wins):
    1) $AI_PULT_CONFIG (environment variable)
    2) ~/.config/ai-cli/agents.conf
    3) <repo>/config/agents.conf

  Format (6 required + 2 optional fields):
    NAME|BINARY|COMMAND|INSTALL|DESC|CATEGORY|AUTH|URL
EOF
  else
    cat <<'EOF'
Aidevix CLI — terminaldagi AI CLI agentlarini bitta menyudan boshqaring.

FOYDALANISH:
  aidevix [TANLOV | AGENT]

TANLOVLAR:
  (argumentsiz)   Interaktiv menyuni ochadi (fzf bo'lsa fzf, bo'lmasa raqamli)
  AGENT           Agentni nomi yoki binari bo'yicha to'g'ridan-to'g'ri ishga tushiradi
                  (masalan: `aidevix claude`, `aidevix gemini`)
  -l, --list      Agentlar ro'yxati va holatini ko'rsatadi
  -f, --free      Faqat BEPUL agentlar menyusini ochadi (🆓 / bepul tier)
  -t, --top       Faqat eng mashhur (top) agentlar menyusini ochadi
  -u, --update    O'rnatilgan barcha agentlarni yangilaydi
  -d, --doctor    Muhitni tekshiradi (node/npm/python/fzf, PATH, agentlar)
  -a, --add       Interaktiv tarzda yangi agent qo'shadi
  -s, --stats [on|off]
                  Global statistika (opt-in): holatni ko'rsatadi yoki yoqadi/o'chiradi.
                  Yoqilganda menyuda "🔥 #reyting" ko'rinadi. Faqat agent nomi +
                  hodisa turi yuboriladi (shaxsiy ma'lumotsiz). Standart — o'chiq.
  -v, --version   Aidevix CLI versiyasini ko'rsatadi
  -h, --help      Ushbu yordam matnini ko'rsatadi

KONFIGURATSIYA:
  Agentlar quyidagi fayldan o'qiladi (birinchi topilgani ishlatiladi):
    1) $AI_PULT_CONFIG (muhit o'zgaruvchisi)
    2) ~/.config/ai-cli/agents.conf
    3) <repo>/config/agents.conf

  Format (6 majburiy + 2 ixtiyoriy maydon):
    NOM|BINARY|BUYRUQ|INSTALL|IZOH|KATEGORIYA|AUTH|URL
EOF
  fi
}

# --- Ishlatiladigan konfiguratsiyani tanlash ------------------------------
# AI_PULT_CONFIG aniq berilgan bo'lsa — faqat o'sha (test/maxsus holatlar).
# Aks holda repo + foydalanuvchi qo'shimchalari birlashtiriladi (repo ustun).
resolve_config() {
  if [[ -n "${AI_PULT_CONFIG:-}" && -r "$AI_PULT_CONFIG" ]]; then
    printf '%s\n' "$AI_PULT_CONFIG"
    return 0
  fi
  build_merged_config
}

# build_merged_config — repo va foydalanuvchi configlarini birlashtirib,
# vaqtinchalik faylga yozadi va uning yo'lini qaytaradi. Repo agentlari ASOSIY;
# foydalanuvchi config faqat repo'da bo'lmagan NOMLARNI qo'shadi (o'z agentlari).
build_merged_config() {
  [[ -r "$REPO_CONFIG" || -r "$USER_CONFIG" ]] || \
    die 1 "$(t "Konfiguratsiya topilmadi. Tekshirildi: '%s', '%s'" "$REPO_CONFIG" "$USER_CONFIG")"

  local out; out="$(mktemp)"; TMPFILES+=("$out")
  local repo_names="" line nm

  if [[ -r "$REPO_CONFIG" ]]; then
    cat "$REPO_CONFIG" >>"$out"
    repo_names="$(grep -vE '^[[:space:]]*(#|$)' "$REPO_CONFIG" 2>/dev/null \
                  | cut -d'|' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  fi

  if [[ -r "$USER_CONFIG" && "$USER_CONFIG" != "$REPO_CONFIG" ]]; then
    printf '\n# --- Foydalanuvchi qo\047shgan agentlar ---\n' >>"$out"
    while IFS= read -r line || [[ -n "$line" ]]; do
      case "$line" in ''|\#*) continue ;; esac
      nm="$(printf '%s' "$line" | cut -d'|' -f1 | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
      # Repo'da shu nom bo'lmasagina qo'shamiz (repo ustun turadi).
      grep -qxF "$nm" <<<"$repo_names" || printf '%s\n' "$line" >>"$out"
    done <"$USER_CONFIG"
  fi

  printf '%s\n' "$out"
}

trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

# --- O'rnatish buyrug'i qaysi dasturga tayanishini aniqlash ----------------
# Masalan "npm install -g ..." → "npm". Bu dastur yo'q bo'lsa, oldindan
# sodda xabar berib, foydalanuvchini chalkash xatolardan asraymiz.
detect_install_tool() {
  local install="$1"
  if   [[ "$install" == *"npm "* ]];     then echo "npm"
  elif [[ "$install" == *"pip"* || "$install" == *"python3 "* ]]; then echo "python3"
  elif [[ "$install" == *"brew "* ]];    then echo "brew"
  elif [[ "$install" == *"curl "* ]];    then echo "curl"
  elif [[ "$install" == *"wget "* ]];    then echo "wget"
  else echo ""; fi
}

# --- Oxirgi tanlovni eslab qolish -----------------------------------------
read_last() { [[ -r "$STATE_FILE" ]] && cat "$STATE_FILE" 2>/dev/null || true; }
save_last() {
  mkdir -p "$STATE_DIR" 2>/dev/null || return 0
  printf '%s\n' "$1" >"$STATE_FILE" 2>/dev/null || true
}

# --- Lokal ishlatish statistikasi (faqat shu kompyuter) -------------------
# record_usage <nom> — agentning lokal sanog'ini +1 qiladi. Eng-yaxshi-harakat:
# har qanday xato bo'lsa ham agentni ishga tushirishga xalaqit bermaydi. awk
# bilan yoziladi (bash 3.2 mos — assotsiativ massiv ishlatilmaydi).
record_usage() {
  local name="$1"
  [[ -n "$name" ]] || return 0
  mkdir -p "$STATE_DIR" 2>/dev/null || return 0
  [[ -f "$STATS_FILE" ]] || : >"$STATS_FILE" 2>/dev/null || return 0
  local tmp; tmp="$(mktemp 2>/dev/null)" || return 0
  if awk -F'\t' -v n="$name" '
        BEGIN { OFS = "\t" }
        $2 == n { print ($1 + 1), $2; found = 1; next }
        NF      { print }
        END     { if (!found) print 1, n }
      ' "$STATS_FILE" >"$tmp" 2>/dev/null; then
    mv -f "$tmp" "$STATS_FILE" 2>/dev/null || rm -f "$tmp" 2>/dev/null
  else
    rm -f "$tmp" 2>/dev/null
  fi
  return 0
}

# read_usage <nom> — agentning lokal sanog'ini chiqaradi (yo'q bo'lsa 0).
read_usage() {
  local name="$1"
  [[ -r "$STATS_FILE" ]] || { printf '0'; return 0; }
  awk -F'\t' -v n="$name" '$2 == n { print $1 + 0; f = 1; exit } END { if (!f) print 0 }' \
    "$STATS_FILE" 2>/dev/null || printf '0'
}

# ===========================================================================
#  Global statistika (OPT-IN). Maxfiylik: yoqilgandagina, faqat agent nomi +
#  hodisa turi yuboriladi. CI'da yoki curl yo'q bo'lsa — hech narsa qilinmaydi.
# ===========================================================================

# global_stats_enabled — global statistika yoqilganmi? (0 = ha, 1 = yo'q)
# Tartib: AIDEVIX_GLOBAL_STATS env (1/0) ustun; aks holda opt-in fayli; std o'chiq.
global_stats_enabled() {
  case "${AIDEVIX_GLOBAL_STATS:-}" in
    1|on|true|yes) return 0 ;;
    0|off|false|no) return 1 ;;
  esac
  [[ -r "$GLOBAL_OPTIN_FILE" ]] && [[ "$(cat "$GLOBAL_OPTIN_FILE" 2>/dev/null)" == "on" ]]
}

# set_global_stats <on|off> — opt-in holatini saqlaydi.
set_global_stats() {
  mkdir -p "$STATE_DIR" 2>/dev/null || return 1
  printf '%s\n' "$1" >"$GLOBAL_OPTIN_FILE" 2>/dev/null || return 1
}

# stats_cmd [on|off] — `aidevix --stats` buyrug'i: holatni ko'rsatadi yoki o'zgartiradi.
stats_cmd() {
  local arg="${1:-}"
  case "$arg" in
    on)
      set_global_stats on
      panel "$(t '📊 Global statistika YOQILDI')" \
        "$(t 'Rahmat! Endi agent ishga tushganda FAQAT quyidagi yuboriladi:')" \
        "$(t '    • agent nomi (masalan "Claude Code")')" \
        "$(t '    • hodisa turi (install yoki launch)')" \
        "" \
        "$(t "❌ IP, foydalanuvchi nomi, kalit yoki boshqa shaxsiy ma'lumot YO'Q.")" \
        "$(t 'Bu hammaga "qaysi CLI eng mashhur"ligini ko'rsatishga yordam beradi.')" \
        "" \
        "$(t 'O'\''chirish: aidevix --stats off')"
      ;;
    off)
      set_global_stats off
      log_success "$(t 'Global statistika o'\''chirildi. Endi hech narsa yuborilmaydi.')"
      ;;
    ''|status)
      local state; state="$(t "o'chiq (opt-in)")"
      global_stats_enabled && state="$(t 'yoqilgan')"
      panel "$(t '📊 Global statistika — holat: %s' "$state")" \
        "$(t 'Server:   %s' "$AIDEVIX_STATS_URL")" \
        "$(t "Yuboriladi (yoqilganda): agent nomi + hodisa turi (shaxsiy ma'lumotsiz)")" \
        "" \
        "$(t 'Yoqish:   aidevix --stats on')" \
        "$(t 'O'\''chirish: aidevix --stats off')"
      ;;
    *)
      die 2 "$(t "Noma'lum: 'aidevix --stats %s'. Foydalanish: aidevix --stats [on|off]" "$arg")"
      ;;
  esac
}

# report_usage_global <nom> <install|launch> — hodisani serverga FONDA yuboradi.
# Eng-yaxshi-harakat: jim, qisqa timeout, hech qachon bloklamaydi/xato bermaydi.
report_usage_global() {
  local name="$1" type="${2:-launch}"
  global_stats_enabled || return 0
  [[ -n "${CI:-}" ]] && return 0
  command -v curl >/dev/null 2>&1 || return 0
  [[ -n "$name" ]] || return 0
  # Agent nomidagi " va \ ni JSON uchun ekranlaymiz (config nomlari odatda toza).
  local esc; esc="$(printf '%s' "$name" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')"
  # ( ... & ) — fonda detach: exec'dan keyin ham mustaqil tugaydi.
  ( curl -fsS -m 3 -X POST "$AIDEVIX_STATS_URL/v1/events" \
      -H 'content-type: application/json' \
      --data "{\"agent\":\"$esc\",\"type\":\"$type\"}" >/dev/null 2>&1 & ) 2>/dev/null
  return 0
}

# fetch_global_stats — /v1/stats keshini FONDA yangilaydi (throttled).
# Menyu keshni o'qiydi (darrov); bu funksiya keyingi safar uchun yangilaydi.
fetch_global_stats() {
  global_stats_enabled || return 0
  [[ -n "${CI:-}" ]] && return 0
  command -v curl >/dev/null 2>&1 || return 0
  local now interval last
  interval="${AIDEVIX_STATS_TTL:-10800}"
  now="$(date +%s 2>/dev/null || echo 0)"
  if [[ -r "$GLOBAL_STAMP" && -r "$GLOBAL_CACHE" ]]; then
    last="$(cat "$GLOBAL_STAMP" 2>/dev/null || echo 0)"; [[ "$last" =~ ^[0-9]+$ ]] || last=0
    (( now - last < interval )) && return 0
  fi
  mkdir -p "$STATE_DIR" 2>/dev/null || return 0
  ( curl -fsS -m 5 "$AIDEVIX_STATS_URL/v1/stats" -o "$GLOBAL_CACHE.tmp" 2>/dev/null \
      && mv -f "$GLOBAL_CACHE.tmp" "$GLOBAL_CACHE" 2>/dev/null \
      && printf '%s\n' "$now" >"$GLOBAL_STAMP" 2>/dev/null \
      || rm -f "$GLOBAL_CACHE.tmp" 2>/dev/null ) >/dev/null 2>&1 &
  return 0
}

# global_install_tsv — kesh JSON'idagi "install" reytingini "nom<TAB>rank<TAB>son"
# qatorlariga aylantiradi (rank = ro'yxatdagi tartib, server kamayish bo'yicha beradi).
global_install_tsv() {
  [[ -r "$GLOBAL_CACHE" ]] || return 0
  awk '
    {
      i = index($0, "\"install\":[")
      if (i == 0) next
      rest = substr($0, i + 11)          # "install":[ dan keyingi qism
      j = index(rest, "]")
      if (j == 0) next
      arr = substr(rest, 1, j - 1)
      n = 0
      while (match(arr, /"agent":"[^"]*","count":[0-9]+/)) {
        obj = substr(arr, RSTART, RLENGTH)
        arr = substr(arr, RSTART + RLENGTH)
        a = obj; sub(/^"agent":"/, "", a); sub(/","count":[0-9]+$/, "", a)
        c = obj; sub(/^.*"count":/, "", c)
        n++
        printf "%s\t%d\t%d\n", a, n, c
      }
    }
  ' "$GLOBAL_CACHE" 2>/dev/null || true
}

# maybe_global_hint — global statistika hali sozlanmagan bo'lsa, BIR MARTA
# yengil eslatma ko'rsatadi (majburlamaydi — opt-in). Faqat interaktiv holatda.
maybe_global_hint() {
  [[ -n "${AIDEVIX_GLOBAL_STATS:-}" ]] && return 0   # env orqali boshqarilmoqda
  global_stats_enabled && return 0                   # allaqachon yoqilgan
  [[ -e "$GLOBAL_OPTIN_FILE" ]] && return 0          # foydalanuvchi tanlagan (on/off)
  [[ -e "$GLOBAL_HINT_FILE" ]] && return 0           # eslatma ko'rsatilgan
  [[ -n "${CI:-}" ]] && return 0
  mkdir -p "$STATE_DIR" 2>/dev/null || return 0
  : >"$GLOBAL_HINT_FILE" 2>/dev/null || true
  panel "$(t '💡 Maslahat — global statistika (ixtiyoriy)')" \
    "$(t 'Qaysi AI CLI dunyoda eng mashhurligini menyuda ko'\''rmoqchimisiz?')" \
    "    aidevix --stats on" \
    "$(t "Yoqsangiz FAQAT agent nomi + hodisa turi yuboriladi (shaxsiy ma'lumotsiz).")" \
    "$(t 'Standart — o'\''CHIQ. Hozir hech narsa o'\''zgarmaydi; bu shunchaki eslatma.')"
}

# --- Birinchi ishga tushirishda login/auth yo'riqnomasi --------------------
# Agent AUTH maydoniga ega bo'lsa va u ilk bor ishga tushirilayotgan bo'lsa,
# foydalanuvchiga login/API kalit kerakligini SODDA tilda bir marta aytamiz.
# Kalitlarni biz saqlamaymiz — bu faqat ogohlantirish.
# should_open_login_link <auth> — login sahifasini brauzerda ochish KERAKMI?
#   Ha (0) — FAQAT agent "o'zingiz API kalit oling" (🔑) talab qilsa VA o'sha
#   kalit muhitda hali yo'q bo'lsa. Ya'ni agentni ishlatib bo'lmaydi → loginga
#   yo'naltiramiz.
#   Yo'q (1) — agar:
#     • agent brauzer orqali login (🌐), obuna (💳) yoki bepul (🆓) bo'lsa
#       (bularda agentning o'zi login qiladi yoki login shart emas), YOKI
#     • tegishli API kalit allaqachon o'rnatilgan bo'lsa (agent ishlab ketadi).
should_open_login_link() {
  local auth="$1"
  case "$auth" in
    *🌐*|*🆓*|*💳*) return 1 ;;   # agent o'zi hal qiladi / bepul
  esac
  [[ "$auth" == *🔑* ]] || return 1   # API kalit umuman talab qilinmaydi

  # Kalit allaqachon muhitda bormi? Bo'lsa — agent ishlaydi, link shart emas.
  local v vars common
  vars="$(printf '%s' "$auth" | grep -oE '[A-Z][A-Z0-9_]*(_API_KEY|_TOKEN|_KEY)' 2>/dev/null || true)"
  common="ANTHROPIC_API_KEY OPENAI_API_KEY GEMINI_API_KEY GOOGLE_API_KEY OPENROUTER_API_KEY GROQ_API_KEY DEEPSEEK_API_KEY MISTRAL_API_KEY"
  for v in $vars $common; do
    [[ -n "${!v:-}" ]] && return 1
  done
  return 0   # 🔑 kerak, lekin kalit yo'q → loginga yo'naltiramiz
}

maybe_show_auth_note() {
  local name="$1" auth="$2" url="${3:-}"
  [[ -n "$auth" || -n "$url" ]] || return 0
  if [[ -r "$SEEN_AUTH_FILE" ]] && grep -qxF "$name" "$SEEN_AUTH_FILE" 2>/dev/null; then
    return 0
  fi
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  printf '%s\n' "$name" >>"$SEEN_AUTH_FILE" 2>/dev/null || true

  if [[ -n "$url" ]] && should_open_login_link "$auth"; then
    # Login/registratsiya kerak — sahifani brauzerda ochamiz.
    panel "$(t "🔐 '%s' — login/kalit kerak" "$name")" \
      "$(t 'Bu agentni ishlatish uchun API kalit kerak:')" \
      "    $auth" \
      "" \
      "$(t '🌐 Kalit olish sahifasi brauzerda ochilmoqda:')" \
      "    $url" \
      "" \
      "$(t '👉 Kalitni oling va agent ko'\''rsatmasiga amal qiling. Aidevix kalitni')" \
      "$(t '   ko'\''rmaydi va saqlamaydi — u faqat sizning kompyuteringizda qoladi.')"
    open_url "$url"
    [[ "${AI_ANIM:-0}" -eq 1 ]] && sleep 0.8 || true
  elif [[ -n "$auth" ]]; then
    # Alohida loginga yo'naltirish SHART EMAS (kalit bor, agent o'zi login
    # qiladi, yoki bepul) — faqat qisqa eslatma beramiz, brauzer ochmaymiz.
    panel "$(t "🔐 '%s' — eslatma" "$name")" \
      "$(t 'Login talabi: %s' "$auth")" \
      "$(t '👉 Agar agent login so'\''rasa, ekrandagi ko'\''rsatmaga amal qiling.')"
    [[ "${AI_ANIM:-0}" -eq 1 ]] && sleep 0.4 || true
  fi
}

# --- PATH'ni keng tarqalgan paket-menejer bin papkalari bilan boyitish -----
# AI CLI'lar odatda `npm -g`, `pip --user`, `cargo` orqali o'rnatiladi. Yangi
# kompyuterda bu papkalar PATH'da bo'lmasligi mumkin — natijada o'rnatilgan
# CLI topilmay, har safar qaytadan "o'rnatish" so'raladi. Bu funksiya o'sha
# papkalarni JORIY sessiya PATH'iga qo'shib, muammoni bartaraf etadi.
augment_tool_path() {
  local dirs=() d prefix userbase

  # Avval PATH'ni buzuq yozuvlardan TOZALAYMIZ. Git Bash'da Windows-shakl yo'l
  # (C:\Users\...) PATH'ga tushib qolsa, ":" ajratgich "C:" ni bo'lib, yagona
  # "C" harfi va "\Users\..." kabi buzuq bo'laklar hosil qiladi (bu ko'pincha
  # eski ~/.bashrc blokidan keladi). Ular npm shim'larini chalkashtirib,
  # "Cannot find module C:\Program Files\Git\Users\..." xatosini beradi.
  # Shu yozuvlarni olib tashlaymiz — qolgan to'g'ri (/c/...) yo'llar yetarli.
  local cleaned="" entry
  local _oldifs="$IFS"
  set -f
  IFS=':'
  for entry in $PATH; do
    case "$entry" in
      ''|[A-Za-z]|\\*) continue ;;   # bo'sh, yagona drive harfi ("C"), yoki "\..."
    esac
    cleaned="${cleaned:+$cleaned:}$entry"
  done
  IFS="$_oldifs"
  set +f
  [[ -n "$cleaned" ]] && PATH="$cleaned"

  if command -v npm >/dev/null 2>&1; then
    prefix="$(npm config get prefix 2>/dev/null || true)"
    if [[ -n "$prefix" && "$prefix" != "undefined" ]]; then
      # Unix'da binar $prefix/bin ichida, Windows'da $prefix ichida bo'ladi.
      dirs+=("$prefix/bin" "$prefix")
    fi
  fi
  if command -v python3 >/dev/null 2>&1; then
    userbase="$(python3 -m site --user-base 2>/dev/null || true)"
    [[ -n "$userbase" ]] && dirs+=("$userbase/bin" "$userbase/Scripts")
  fi
  dirs+=("$HOME/.local/bin" "$HOME/bin" "$HOME/.cargo/bin" "$HOME/AppData/Roaming/npm")

  for d in "${dirs[@]}"; do
    # Windows-shakldagi yo'l (masalan `C:\Users\...` — npm config get prefix
    # Git Bash'da shunday qaytaradi) PATH'ga to'g'ridan-to'g'ri qo'shilsa, ":"
    # ajratgich "C:" ni bo'lib yuboradi va `\Users\...` degan buzuq yozuv hosil
    # bo'ladi. Bu esa npm shim'larida yo'lni `C:\Program Files\Git\Users\...` ga
    # aylantirib, "Cannot find module" xatosini keltirib chiqaradi. Shu sababli
    # bunday yo'llarni avval POSIX shaklga (`/c/Users/...`) o'tkazamiz.
    case "$d" in
      [A-Za-z]:[\\/]*|*\\*)
        if command -v cygpath >/dev/null 2>&1; then
          d="$(cygpath -u "$d" 2>/dev/null || printf '%s' "$d")"
        fi
        ;;
    esac
    if [[ -d "$d" && ":$PATH:" != *":$d:"* ]]; then
      PATH="$d:$PATH"
    fi
  done
  export PATH
  hash -r 2>/dev/null || true
}

# --- Konfiguratsiyani o'qib, TAB bilan ajratilgan qatorlar chiqarish -------
# Chiqish formati: NAME\tDESC\tBINARY\tCOMMAND\tINSTALL\tCATEGORY
parse_agents() {
  local config="$1"
  local line name binary command install desc category auth url lineno=0 found=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    lineno=$((lineno + 1))
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*$ ]] && continue

    IFS='|' read -r name binary command install desc category auth url <<<"$line"
    name="$(trim "${name:-}")"
    binary="$(trim "${binary:-}")"
    command="$(trim "${command:-}")"
    install="$(trim "${install:-}")"
    desc="$(trim "${desc:-}")"
    category="$(trim "${category:-}")"
    auth="$(trim "${auth:-}")"
    url="$(trim "${url:-}")"
    [[ -z "$category" ]] && category="$DEFAULT_CATEGORY"

    if [[ -z "$name" || -z "$binary" || -z "$command" ]]; then
      log_warn "$(t "Noto'g'ri qator o'tkazib yuborildi (#%s): %s" "$lineno" "$line")"
      continue
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$desc" "$binary" "$command" "$install" "$category" "$auth" "$url"
    found=1
  done <"$config"

  [[ "$found" -eq 1 ]] || die 1 "$(t 'Konfiguratsiyada yaroqli agent topilmadi: %s' "$config")"
}

# --- Holat ustuni bilan to'ldirilgan qatorlar -----------------------------
# Chiqish formati: NAME\tDESC\tBINARY\tCOMMAND\tINSTALL\tCATEGORY\tSTATUS
build_rows() {
  local config="$1" name desc binary command install category auth url status
  # IFS=US (0x1f) — TAB whitespace bo'lgani uchun bo'sh maydonlarni "yutib" yuboradi
  # (masalan install bo'sh bo'lsa, keyingi maydonlar siljiydi). Shu sababli TAB'ni
  # non-whitespace ajratgich (\037)ga o'giramiz — bo'sh maydonlar saqlanadi.
  while IFS=$'\037' read -r name desc binary command install category auth url; do
    if command -v "$binary" >/dev/null 2>&1; then
      status="$(t "✓ o'rnatilgan")"
    else
      status="$(t '✗ yo'\''q')"
    fi
    # Maydon tartibi: status 7-, auth 8-, url 9- (preview/menu $7 status'ga tayanadi).
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$name" "$desc" "$binary" "$command" "$install" "$category" "$status" "$auth" "$url"
  done < <(parse_agents "$config" | tr '\t' '\037')
}

# --- --list rejimi --------------------------------------------------------
# Agentlar lokal ishlatish sanog'i bo'yicha KAMAYISH tartibida ko'rsatiladi
# (eng ko'p ishlatilgan tepada); "MARTA" ustuni shu sanoqni ko'rsatadi.
list_agents() {
  local config; config="$(resolve_config)"
  log_info "$(t 'Konfiguratsiya: %s' "$config")"
  local statsfile="$STATS_FILE"; [[ -r "$statsfile" ]] || statsfile=/dev/null
  printf '\n%s%-18s %-14s %-9s %-7s %-34s %s%s\n' "$C_BOLD" "$(t AGENT)" "$(t HOLAT)" "$(t GURUH)" "$(t MARTA)" "$(t IZOH)" "$(t LOGIN)" "$C_RESET"
  printf '%s\n' "-------------------------------------------------------------------------------------------------"
  local name desc binary command install category status auth url count color
  while IFS=$'\037' read -r name desc binary command install category status auth url count; do
    if [[ "$status" == *"✓"* ]]; then color="$C_GREEN"; else color="$C_RED"; fi
    printf '%-18s %b%-14s%b %-9s %-7s %-34s %s\n' "$name" "$color" "$status" "$C_RESET" "$category" "${count}×" "$desc" "$auth"
  done < <(
    build_rows "$config" | awk -F'\t' -v sf="$statsfile" '
      BEGIN { while ((getline line < sf) > 0) { m = split(line, a, "\t"); if (m >= 2) cnt[a[2]] = a[1] } }
      { c = cnt[$1] + 0; printf "%010d\t%06d\t%s\t%d\n", c, (++idx), $0, c }
    ' | sort -t"$(printf '\t')" -k1,1nr -k2,2n | cut -f3- | tr '\t' '\037'
  )
}

# --- Preview (fzf tomonidan qism-jarayon sifatida chaqiriladi) -------------
# fzf preview'ni TTY'siz ishga tushiradi, shuning uchun ranglarni bevosita
# ANSI kodlari bilan beramiz (fzf --ansi ularni to'g'ri ko'rsatadi).
preview_agent() {
  local name="$1" datafile="$2"
  [[ -r "$datafile" ]] || return 0
  awk -F'\t' -v n="$name" \
    -v l_inst="$(t 'o'\''rnatilgan')" -v l_noinst="$(t 'o'\''rnatilmagan')" \
    -v l_status="$(t 'Holat')" -v l_binary="$(t 'Binar')" -v l_cmd="$(t 'Buyruq')" \
    -v l_cat="$(t 'Kategoriya')" -v l_login="$(t 'Login')" -v l_url="$(t 'Havola')" \
    -v l_install="$(t 'O'\''rnatish:')" -v l_unset="$(t '(belgilanmagan)')" '
    BEGIN {
      ESC = sprintf("%c", 27)
      B   = ESC "[1m";      R = ESC "[0m"
      CY  = ESC "[38;5;87m"; GY = ESC "[90m"
      GRN = ESC "[32m";      RED = ESC "[31m";  MG = ESC "[38;5;213m"
    }
    $1 == n {
      # Holat belgisi
      if ($7 ~ /✓/) { badge = GRN "● " l_inst R }
      else          { badge = RED "○ " l_noinst R }

      print ""
      print "  " B CY $1 R
      print "  " GY "────────────────────────────" R
      print ""
      print "  " GY sprintf("%-10s", l_status) R badge
      print "  " GY sprintf("%-10s", l_binary) R $3
      print "  " GY sprintf("%-10s", l_cmd)    R MG $4 R
      print "  " GY sprintf("%-10s", l_cat)    R $6
      print "  " GY sprintf("%-10s", l_login)  R ($8 == "" ? GY "—" R : $8)
      if ($9 != "") print "  " GY sprintf("%-10s", l_url) R CY $9 R
      print ""
      print "  " GY l_install R
      print "    " ($5 == "" ? GY l_unset R : $5)
      print ""
      print "  " GY "────────────────────────────" R
      print "  " $2
      exit
    }' "$datafile"
}

# --- Menyu qatorlarini qurish (eng ko'p ishlatilgan yuqorida) --------------
# Chiqish formati: KO'RINISH\tNAME  (NAME — qidirish uchun yashirin maydon).
# Qatorlar LOKAL ishlatish sanog'i bo'yicha KAMAYISH tartibida; teng bo'lsa
# config tartibi saqlanadi. Har agent yonida "· N×" (lokal) va — global
# statistika yoqilgan bo'lsa — "🔥 #rank · count" (global) belgisi ko'rinadi.
#   build_menu <rows> [lokal-stats-fayl] [global-tsv-fayl]
build_menu() {
  local rows="$1" statsfile="${2:-}" globalfile="${3:-}"
  [[ -n "$statsfile" && -r "$statsfile" ]] || statsfile=/dev/null
  [[ -n "$globalfile" && -r "$globalfile" ]] || globalfile=/dev/null
  awk -F'\t' -v sf="$statsfile" -v gf="$globalfile" \
            -v g="${C_GREEN:-}" -v r="${C_RED:-}" -v z="${C_RESET:-}" \
            -v t="${C_TITLE:-}" -v gy="${C_GRAY:-}" -v b="${C_BOLD:-}" -v mg="${C_MAGENTA:-}" '
    function human(x) {
      if (x >= 1000000) return sprintf("%.1fM", x / 1000000)
      if (x >= 1000)    return sprintf("%.1fk", x / 1000)
      return x ""
    }
    BEGIN {
      # Lokal statistika: nom -> son.
      while ((getline line < sf) > 0) {
        m = split(line, a, "\t")
        if (m >= 2) cnt[a[2]] = a[1]
      }
      # Global statistika (ixtiyoriy): nom -> rank, son.
      while ((getline gline < gf) > 0) {
        m = split(gline, gp, "\t")
        if (m >= 3) { grank[gp[1]] = gp[2]; gcnt[gp[1]] = gp[3] }
      }
    }
    {
      name=$1; desc=$2; status=$7; auth=$8;
      if (status ~ /✓/) { icon = g "✓" z } else { icon = r "✗" z }
      badge = "";
      if (index(auth, "🆓"))      badge = "🆓";
      else if (index(auth, "🌐")) badge = "🌐";
      else if (index(auth, "🔑")) badge = "🔑";
      else if (index(auth, "💳")) badge = "💳";
      c = cnt[name] + 0;
      use = (c > 0) ? sprintf("  %s·%d×%s", gy, c, z) : "";
      gbadge = (name in grank) ? sprintf("  %s🔥#%d·%s%s", mg, grank[name], human(gcnt[name] + 0), z) : "";
      disp = sprintf("%s  %s%s%-16s%s %s%s%s  %s%s%s", icon, b, t, name, z, gy, desc, z, badge, use, gbadge)
      # Tartiblash kalitlari: 1) lokal sanoq (kamayish), 2) config indeksi (barqaror).
      printf "%010d\t%06d\t%s\t%s\n", c, (++idx), disp, name
    }
  ' <<<"$rows" | sort -t"$(printf '\t')" -k1,1nr -k2,2n | cut -f3-
}

# --- fzf orqali tanlash ---------------------------------------------------
select_with_fzf() {
  local menu="$1" datafile="$2" selection rc
  selection="$(
    printf '%s\n' "$menu" \
      | fzf --ansi \
            --delimiter='\t' \
            --with-nth=1 \
            --prompt="$(t '  qidirish › ')" \
            --pointer='▶' \
            --marker='✓' \
            --height=~90% \
            --layout=reverse \
            --border=rounded \
            --border-label=' ✦ Aidevix CLI ' \
            --border-label-pos=3 \
            --margin=1,2 \
            --padding=1 \
            --info=inline \
            --color='fg:-1,bg:-1,hl:51,fg+:231,bg+:236,hl+:87,info:245,prompt:213,pointer:213,marker:84,header:245,border:60,label:87' \
            --header="$(t '↑/↓ tanlang · yozib qidiring · ENTER ishga tushirish · ESC bekor')" \
            --preview "bash \"$SELF\" __preview {2} \"$datafile\"" \
            --preview-window='right,52%,wrap,border-left' \
            --preview-label=' tafsilot '
  )" || {
    rc=$?
    if [[ "$rc" -eq 130 ]]; then log_info "$(t 'Bekor qilindi.')"; exit 0; fi
    die "$rc" "$(t 'fzf kutilmagan kod bilan to'\''xtadi: %s' "$rc")"
  }
  [[ -z "$selection" ]] && { log_info "$(t 'Hech narsa tanlanmadi.')"; exit 0; }
  # Yashirin NAME maydoni — TAB'dan keyingi qism.
  printf '%s' "$selection" | sed 's/.*\t//'
}

# --- fzf bo'lmaganda oddiy raqamli menyu ----------------------------------
select_with_numbers() {
  local menu="$1"
  local -a displays=() names=()
  local disp nm
  while IFS=$'\t' read -r disp nm; do
    [[ -z "$nm" ]] && continue
    displays+=("$disp"); names+=("$nm")
  done <<<"$menu"

  [[ "${#names[@]}" -gt 0 ]] || die 1 "$(t 'Menyu uchun agent topilmadi.')"

  log_warn "$(t "fzf topilmadi — oddiy menyu ishlatilmoqda (yaxshiroq tajriba uchun fzf o'rnating).")"
  printf '\n%s%s%s\n' "${C_BOLD:-}" "$(t 'AI CLI tanlang:')" "${C_RESET:-}" >&2
  local i
  for i in "${!names[@]}"; do
    printf '%b%3d)%b %b\n' "${C_BLUE:-}" "$((i + 1))" "${C_RESET:-}" "${displays[$i]}" >&2
  done
  printf '%s\n' "----------------------------------------" >&2

  local choice="" prompt; prompt="$(t 'Raqam kiriting (1-%s, ESC=bekor) › ' "${#names[@]}")"
  trap - ERR
  if { : >/dev/tty; } 2>/dev/null; then
    printf '%s' "$prompt" >/dev/tty
    IFS= read -r choice </dev/tty || choice=""
  else
    printf '%s' "$prompt" >&2
    IFS= read -r choice || choice=""
  fi
  trap 'die 1 "$(t "Kutilmagan xato: %s (qator: %s)" "$BASH_COMMAND" "$LINENO")"' ERR

  [[ -z "$choice" ]] && { log_info "$(t 'Bekor qilindi.')"; exit 0; }
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#names[@]} )); then
    die 2 "$(t "Noto'g'ri tanlov: '%s'." "$choice")"
  fi
  printf '%s' "${names[$((choice - 1))]}"
}

# --- Interaktiv menyu -----------------------------------------------------
run_menu() {
  local filter="${1:-}"
  case "$filter" in
    free) banner "Aidevix CLI" "$(t '🆓 bepul agentlar — login/kalitsiz yoki bepul tier')" ;;
    top)  banner "Aidevix CLI" "$(t '⭐ eng mashhur agentlar — vibecoding uchun')" ;;
    *)    banner ;;
  esac

  local config; config="$(resolve_config)"
  local rows; rows="$(build_rows "$config")"

  # --free / --top filtrlari (agar so'ralgan bo'lsa).
  case "$filter" in
    free)
      rows="$(awk -F'\t' '$8 ~ /🆓/ || tolower($8) ~ /bepul|free/' <<<"$rows")"
      [[ -n "$rows" ]] || { log_info "$(t 'Bepul agent topilmadi.')"; exit 0; }
      ;;
    top)
      rows="$(awk -F'\t' -v tops="|claude|codex|gemini|copilot|cursor-agent|aider|opencode|qwen|codebuff|freebuff|" \
              'index(tops, "|" $3 "|") > 0' <<<"$rows")"
      [[ -n "$rows" ]] || { log_info "$(t 'Top agent topilmadi.')"; exit 0; }
      ;;
  esac

  # Global statistika (opt-in): keshni fonda yangilab qo'yamiz (keyingi safar
  # uchun) va joriy keshdan reytingni menyuga qo'shamiz. Bir martalik eslatma.
  maybe_global_hint
  fetch_global_stats
  local globalfile=""
  if global_stats_enabled; then
    globalfile="$(mktemp)"; TMPFILES+=("$globalfile")
    global_install_tsv >"$globalfile" 2>/dev/null || true
  fi

  local menu; menu="$(build_menu "$rows" "$STATS_FILE" "$globalfile")"

  local name
  if command -v fzf >/dev/null 2>&1; then
    local datafile; datafile="$(mktemp)"; TMPFILES+=("$datafile")
    printf '%s\n' "$rows" >"$datafile"
    name="$(select_with_fzf "$menu" "$datafile")"
  else
    name="$(select_with_numbers "$menu")"
  fi

  launch_selected "$rows" "$name"
}

# --- Tanlangan agentni ishga tushirish ------------------------------------
launch_selected() {
  local rows="$1" name="$2"
  local row binary command install auth url
  row="$(awk -F'\t' -v n="$name" '$1 == n { print; exit }' <<<"$rows")"
  [[ -n "$row" ]] || die 1 "$(t 'Tanlangan agent topilmadi: %s' "$name")"

  binary="$(printf '%s'  "$row" | cut -f3)"
  command="$(printf '%s' "$row" | cut -f4)"
  install="$(printf '%s' "$row" | cut -f5)"
  auth="$(printf '%s'    "$row" | cut -f8)"
  url="$(printf '%s'     "$row" | cut -f9)"

  save_last "$name"
  ensure_installed "$name" "$binary" "$install"
  maybe_show_auth_note "$name" "$auth" "$url"
  # Statistika: faqat haqiqatan ishga tushganda (o'rnatish muvaffaqiyatli,
  # bekor qilinmagan). Lokal — har doim; global — faqat opt-in yoqilgan bo'lsa.
  record_usage "$name"
  report_usage_global "$name" "launch"
  launch_agent "$name" "$binary" "$command"
}

# --- Tezkor ishga tushirish: `aidevix <nom-yoki-binary>` ------------------
quick_launch() {
  local query="$1"
  local config; config="$(resolve_config)"
  local rows; rows="$(build_rows "$config")"

  local name
  # 1) Nom yoki binar bo'yicha aniq moslik (katta-kichik harf farqsiz).
  name="$(awk -F'\t' -v q="$query" 'BEGIN{ql=tolower(q)}
            tolower($1)==ql || tolower($3)==ql { print $1; exit }' <<<"$rows")"
  # 2) Bo'lmasa — qisman moslik.
  if [[ -z "$name" ]]; then
    name="$(awk -F'\t' -v q="$query" 'BEGIN{ql=tolower(q)}
              index(tolower($1),ql) || index(tolower($3),ql) { print $1; exit }' <<<"$rows")"
  fi
  [[ -n "$name" ]] || die 2 "$(t "Mos agent topilmadi: '%s'. Ro'yxat uchun: aidevix --list" "$query")"

  launch_selected "$rows" "$name"
}

# --- CLI mavjudligini ta'minlash (kerak bo'lsa avtomatik o'rnatish) -------
ensure_installed() {
  local name="$1" binary="$2" install="$3"

  command -v "$binary" >/dev/null 2>&1 && return 0

  log_warn "$(t "Agent topilmadi: '%s' (kerakli buyruq: '%s')." "$name" "$binary")"
  if [[ -z "$install" ]]; then
    die 127 "$(t "Avtomatik o'rnatish buyrug'i belgilanmagan. Iltimos, '%s'ni qo'lda o'rnating." "$name")"
  fi

  log_info "$(t "O'rnatish buyrug'i: %s" "$install")"
  local ans="" prompt; prompt="$(t "❓ '%s' hozir o'rnatilsinmi? [y/N] " "$name")"
  # Javobni avval /dev/tty'dan o'qishga urinamiz (fzf stdin'ni band qilgan
  # bo'lishi mumkin), bo'lmasa oddiy stdin'ga qaytamiz. Device xatosi ERR
  # tutqichini ishga tushirmasligi uchun tutqichni vaqtincha o'chiramiz.
  trap - ERR
  if { : >/dev/tty; } 2>/dev/null; then
    printf '%s' "$prompt" >/dev/tty
    IFS= read -r ans </dev/tty || ans=""
  else
    printf '%s' "$prompt" >&2
    IFS= read -r ans || ans=""
  fi
  trap 'die 1 "$(t "Kutilmagan xato: %s (qator: %s)" "$BASH_COMMAND" "$LINENO")"' ERR

  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    die 127 "$(t "Bekor qilindi. '%s'ni qo'lda o'rnatish uchun: %s" "$name" "$install")"
  fi

  # O'rnatishdan OLDIN: kerakli dastur (npm/python3/curl...) bormi? Yo'q bo'lsa
  # foydalanuvchiga nima yetishmayotganini SODDA tilda aytamiz.
  local tool; tool="$(detect_install_tool "$install")"
  if [[ -n "$tool" ]] && ! command -v "$tool" >/dev/null 2>&1; then
    panel "$(t "❌ '%s' o'rnatilmadi — avval bitta dastur kerak" "$name")" \
      "$(t "'%s'ni o'rnatish uchun kompyuteringizda \"%s\" bo'lishi shart," "$name" "$tool")" \
      "$(t 'lekin u topilmadi.')" \
      "" \
      "👉 $(tool_hint "$tool")" \
      "" \
      "$(t 'Shuni o'\''rnatib, terminalni qayta oching va yana "aidevix" deb yozing.')"
    die 127 "$(t "'%s' topilmadi — '%s' o'rnatilmadi." "$tool" "$name")"
  fi

  # ERR tutqichini vaqtincha o'chirib, o'rnatish xatosini o'zimiz ushlaymiz.
  trap - ERR
  if ! spin_run "$(t "📦 '%s' o'rnatilmoqda" "$name")" "$install"; then
    local tail_lines="" log_text=""
    if [[ -r "${SPIN_LOG:-}" ]]; then
      tail_lines="$(tail -n 6 "$SPIN_LOG" 2>/dev/null || true)"
      log_text="$(cat "$SPIN_LOG" 2>/dev/null || true)"
    fi
    trap 'die 1 "$(t "Kutilmagan xato: %s (qator: %s)" "$BASH_COMMAND" "$LINENO")"' ERR

    # O'rnatuvchi "bu OS qo'llab-quvvatlanmaydi" desa — adashtiruvchi (internet/
    # sudo/curl) sabablar o'rniga halol, aniq xabar beramiz.
    if printf '%s' "$log_text" | grep -qiE 'unsupported (operating system|os|platform|architecture)|not supported|no (prebuilt|pre-built|binary)|MINGW|MSYS|windows is not'; then
      panel "$(t "🚫 '%s' bu operatsion tizimda qo'llab-quvvatlanmaydi" "$name")" \
        "$(t "'%s' o'rnatuvchisi sizning tizimingizni (Windows / Git Bash —" "$name")" \
        "$(t 'MINGW64) qo'\''llab-quvvatlamasligini aytdi. Bu — internet yoki ruxsat')" \
        "$(t "muammosi EMAS; shunchaki bu agentning Windows uchun o'rnatuvchisi yo'q.")" \
        "" \
        "$(t '👉 Variantlar:')" \
        "$(t '  • Boshqa agentni tanlang (masalan Claude Code, Gemini, Aider — ular')" \
        "$(t "    Windows'da ishlaydi).")" \
        "$(t "  • Yoki '%s'ni WSL (Windows Subsystem for Linux) ichida ishlating." "$name")" \
        "$(t '  • Agent rasmiy sahifasida Windows uchun yo'\''l bor-yo'\''qligini tekshiring.')"
      if [[ -n "$tail_lines" ]]; then
        printf '%s  %s%s\n' "$C_GRAY" "$(t 'Xato tafsiloti (oxirgi qatorlar):')" "$C_RESET" >&2
        printf '%s\n' "$tail_lines" | sed 's/^/    /' >&2
        printf '\n' >&2
      fi
      rm -f "${SPIN_LOG:-}" 2>/dev/null || true
      die 127 "$(t "'%s' bu OS'da qo'llab-quvvatlanmaydi." "$name")"
    fi

    panel "$(t "❌ '%s' o'rnatishda xatolik yuz berdi" "$name")" \
      "$(t 'Quyidagi buyruq muvaffaqiyatsiz tugadi:')" \
      "    $install" \
      "" \
      "$(t "Ko'pincha sabab quyidagilardan biri bo'ladi:")" \
      "$(t '  1) 🌐 Internet yo'\''q yoki sekin — Wi-Fi/ulanishni tekshiring.')" \
      "$(t '  2) 🔒 Ruxsat yetarli emas — buyruqni "sudo" bilan sinab ko'\''ring.')" \
      "$(t '  3) 📦 "%s" eski — uni yangilab, qaytadan urinib ko'\''ring.' "${tool:-$(t dastur)}")" \
      "" \
      "$(t '👉 Aniq sababni ko'\''rish uchun yuqoridagi buyruqni terminalga o'\''zingiz')" \
      "$(t '   nusxalab ishga tushiring — xato matni to'\''liq ko'\''rinadi.')"
    if [[ -n "$tail_lines" ]]; then
      printf '%s  %s%s\n' "$C_GRAY" "$(t 'Xato tafsiloti (oxirgi qatorlar):')" "$C_RESET" >&2
      printf '%s\n' "$tail_lines" | sed 's/^/    /' >&2
      printf '\n' >&2
    fi
    rm -f "${SPIN_LOG:-}" 2>/dev/null || true
    die 1 "$(t "O'rnatish muvaffaqiyatsiz tugadi: %s." "$name")"
  fi
  rm -f "${SPIN_LOG:-}" 2>/dev/null || true
  trap 'die 1 "$(t "Kutilmagan xato: %s (qator: %s)" "$BASH_COMMAND" "$LINENO")"' ERR

  # O'rnatish yangi bin papkasi yaratgan bo'lishi mumkin — PATH'ni qayta
  # boyitamiz va hash'ni tozalaymiz, shunda binar joriy sessiyada ko'rinadi.
  augment_tool_path

  if ! command -v "$binary" >/dev/null 2>&1; then
    panel "$(t "⚠️  '%s' o'rnatildi, lekin hali ishga tushmadi" "$name")" \
      "$(t 'Dastur o'\''rnatildi, biroq tizim "%s" buyrug'\''ini hali topa olmayapti.' "$binary")" \
      "$(t 'Bu odatda "PATH" sozlamasi yangilanmagani uchun bo'\''ladi.')" \
      "" \
      "$(t '👉 Yechimi oson: terminalni butunlay yopib, qaytadan oching,')" \
      "$(t '   so'\''ng yana "aidevix" deb yozing — endi ishlaydi.')" \
      "" \
      "$(t 'Agar shunda ham yordam bermasa: "aidevix --doctor" buyrug'\''i muammoni ko'\''rsatadi.')"
    die 127 "$(t "'%s' hali PATH'da ko'rinmayapti — terminalni qayta oching." "$binary")"
  fi
  log_success "$(t "O'rnatildi: %s" "$name")"
  report_usage_global "$name" "install"
}

# --- Agentni ishga tushirish ----------------------------------------------
launch_agent() {
  local name="$1" binary="$2" command="$3"
  ui_launch "$name"
  trap - ERR
  cleanup
  # shellcheck disable=SC2086
  exec $command
}

# --- O'rnatilgan agentlarni yangilash -------------------------------------
update_agents() {
  local config; config="$(resolve_config)"
  log_info "$(t 'Konfiguratsiya: %s' "$config")"
  local rows; rows="$(build_rows "$config")"
  local name desc binary command install category status auth url
  local checked=0 ok=0 fail=0

  while IFS=$'\037' read -r name desc binary command install category status auth url; do
    command -v "$binary" >/dev/null 2>&1 || continue
    checked=$((checked + 1))
    if [[ -z "$install" ]]; then
      log_warn "$(t "%s: o'rnatish buyrug'i yo'q — o'tkazib yuborildi." "$name")"
      continue
    fi
    trap - ERR
    if spin_run "$(t '🔄 %s yangilanmoqda' "$name")" "$install"; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1))
    fi
    rm -f "${SPIN_LOG:-}" 2>/dev/null || true
    trap 'die 1 "$(t "Kutilmagan xato: %s (qator: %s)" "$BASH_COMMAND" "$LINENO")"' ERR
  done < <(printf '%s\n' "$rows" | tr '\t' '\037')

  if [[ "$checked" -eq 0 ]]; then
    log_warn "$(t "O'rnatilgan agent topilmadi — yangilash uchun avval agent o'rnating.")"
  else
    log_success "$(t 'Yangilash tugadi: %s ta muvaffaqiyatli, %s ta xato (jami %s).' "$ok" "$fail" "$checked")"
  fi
}

# --- Muhit tashxisi (doctor) ----------------------------------------------
doctor() {
  banner "$(t 'Aidevix — Tashxis')" "$(t 'muhitingizni tekshiramiz')"

  local tool
  printf '%s%s%s\n' "${C_BOLD:-}" "$(t 'Vositalar:')" "${C_RESET:-}"
  for tool in bash fzf node npm python3 curl git; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '  %b✓%b %-8s %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$tool" "$(command -v "$tool")"
    else
      printf '  %b✗%b %-8s %s\n' "${C_RED:-}" "${C_RESET:-}" "$tool" "$(t 'topilmadi')"
    fi
  done

  printf '\n%s%s%s\n' "${C_BOLD:-}" "$(t 'PATH tekshiruvi:')" "${C_RESET:-}"
  if command -v npm >/dev/null 2>&1; then
    local prefix bindir
    prefix="$(npm config get prefix 2>/dev/null || true)"
    printf '  npm prefix: %s\n' "${prefix:-$(t '(aniqlanmadi)')}"
    for bindir in "$prefix/bin" "$prefix"; do
      [[ -d "$bindir" ]] || continue
      if [[ ":$PATH:" == *":$bindir:"* ]]; then
        printf '  %b✓%b %s %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$(t 'PATH ichida:')" "$bindir"
      else
        printf '  %b✗%b %s\n' "${C_YELLOW:-}" "${C_RESET:-}" "$(t "PATH da YO'Q: %s  (aidevix uni o'zi qo'shadi)" "$bindir")"
      fi
    done
  else
    printf '  %b!%b %s\n' "${C_YELLOW:-}" "${C_RESET:-}" "$(t "npm topilmadi — npm orqali o'rnatiladigan agentlar ishlamaydi.")"
  fi
  if [[ -d "$HOME/.local/bin" ]]; then
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
      printf '  %b✓%b %s %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$(t 'PATH ichida:')" "$HOME/.local/bin"
    else
      printf '  %b✗%b %s %s\n' "${C_YELLOW:-}" "${C_RESET:-}" "$(t "PATH da YO'Q:")" "$HOME/.local/bin"
    fi
  fi

  printf '\n%s%s%s\n' "${C_BOLD:-}" "$(t 'Global statistika:')" "${C_RESET:-}"
  if global_stats_enabled; then
    printf '  %b✓%b %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$(t 'yoqilgan — server: %s' "$AIDEVIX_STATS_URL")"
    if [[ -r "$GLOBAL_CACHE" ]]; then
      printf '  %b✓%b %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$(t 'kesh mavjud: %s' "$GLOBAL_CACHE")"
    else
      printf '  %b!%b %s\n' "${C_YELLOW:-}" "${C_RESET:-}" "$(t "kesh hali yo'q (keyingi menyuda yangilanadi)")"
    fi
  else
    printf '  %b•%b %s\n' "${C_GRAY:-}" "${C_RESET:-}" "$(t "o'chiq (opt-in). Yoqish: aidevix --stats on")"
  fi

  printf '\n%s%s%s\n' "${C_BOLD:-}" "$(t 'Agentlar holati:')" "${C_RESET:-}"
  list_agents
}

# --- Interaktiv yangi agent qo'shish --------------------------------------
prompt_tty() {
  # prompt_tty <savol> <o'zgaruvchi-nomi>
  local q="$1" __var="$2" __val=""
  trap - ERR
  if { : >/dev/tty; } 2>/dev/null; then
    printf '%s' "$q" >/dev/tty
    IFS= read -r __val </dev/tty || __val=""
  else
    printf '%s' "$q" >&2
    IFS= read -r __val || __val=""
  fi
  trap 'die 1 "$(t "Kutilmagan xato: %s (qator: %s)" "$BASH_COMMAND" "$LINENO")"' ERR
  printf -v "$__var" '%s' "$__val"
}

add_agent() {
  printf '\n%s%s%s\n\n' "${C_BOLD:-}" "$(t '➕ Yangi agent qo'\''shish')" "${C_RESET:-}"
  local name binary command install desc category auth url
  prompt_tty "$(t 'Nom (masalan: My Agent)        : ')" name
  prompt_tty "$(t "Binary (PATH'dagi buyruq nomi) : ")" binary
  prompt_tty "$(t "Ishga tushirish buyrug'i       : ")" command
  prompt_tty "$(t "O'rnatish buyrug'i (ixtiyoriy) : ")" install
  prompt_tty "$(t 'Izoh (ixtiyoriy)               : ')" desc
  prompt_tty "$(t 'Kategoriya (ixtiyoriy)         : ')" category
  prompt_tty "$(t 'Login/kalit izohi (ixtiyoriy)  : ')" auth
  prompt_tty "$(t 'Login/hujjat havolasi (ixtiyoriy): ')" url

  name="$(trim "$name")"; binary="$(trim "$binary")"; command="$(trim "$command")"
  install="$(trim "$install")"; desc="$(trim "$desc")"; category="$(trim "$category")"
  auth="$(trim "$auth")"; url="$(trim "$url")"
  [[ -z "$command" ]] && command="$binary"
  [[ -z "$category" ]] && category="$DEFAULT_CATEGORY"

  if [[ -z "$name" || -z "$binary" ]]; then
    die 2 "$(t 'Nom va Binary majburiy. Bekor qilindi.')"
  fi
  if [[ "$name$binary$command$install$desc$category$auth$url" == *"|"* ]]; then
    die 2 "$(t "Maydonlar ichida '|' belgisi bo'lmasligi kerak. Bekor qilindi.")"
  fi

  # Foydalanuvchi configi — faqat QO'SHIMCHA agentlar (repo nusxalanmaydi, shunda
  # repo yangilanganda yangi agentlar avtomatik ko'rinadi). Bo'lmasa yaratamiz.
  mkdir -p "$(dirname "$USER_CONFIG")"
  if [[ ! -e "$USER_CONFIG" ]]; then
    printf '# Aidevix CLI — foydalanuvchi qo\047shgan agentlar\n# Format: NOM|BINARY|BUYRUQ|INSTALL|IZOH|KATEGORIYA|AUTH|URL\n\n' >"$USER_CONFIG"
  fi
  printf '%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$name" "$binary" "$command" "$install" "$desc" "$category" "$auth" "$url" >>"$USER_CONFIG"
  log_success "$(t "Qo'shildi: %s  →  %s" "$name" "$USER_CONFIG")"
}

# --- Avtomatik yangilanish (git orqali) -----------------------------------
# main'ga push qilingan o'zgarishlarni foydalanuvchilarga AVTOMATIK yetkazadi:
# remote'da yangi commit bo'lsa, jim yuklab oladi, qisqa xabar beradi va yangi
# versiyani qayta ishga tushiradi. Throttled (standart 3 soat).
# O'chirish: AIDEVIX_NO_AUTOUPDATE=1 · Oraliq: AIDEVIX_UPDATE_INTERVAL (sekund).
auto_update() {
  [[ -n "${AIDEVIX_NO_AUTOUPDATE:-}" || -n "${CI:-}" ]] && return 0
  [[ -d "$PROJECT_ROOT/.git" ]] || return 0
  command -v git >/dev/null 2>&1 || return 0

  local stamp="$STATE_DIR/last_update_check" now interval last
  interval="${AIDEVIX_UPDATE_INTERVAL:-10800}"
  now="$(date +%s 2>/dev/null || echo 0)"
  if [[ -r "$stamp" ]]; then
    last="$(cat "$stamp" 2>/dev/null || echo 0)"; [[ "$last" =~ ^[0-9]+$ ]] || last=0
    (( now - last < interval )) && return 0
  fi
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  printf '%s\n' "$now" >"$stamp" 2>/dev/null || true

  # http.schannelCheckRevoke=false — Windows git'dagi sertifikat-otzыv (revocation)
  # xatosini oldini oladi (CRYPT_E_NO_REVOCATION_CHECK).
  local g=(git -c http.schannelCheckRevoke=false -C "$PROJECT_ROOT")
  local branch; branch="$("${g[@]}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  [[ -z "$branch" || "$branch" == "HEAD" ]] && branch=main

  # Lokal commit qilinmagan o'zgarishlar bo'lsa — ularni clobbering qilmaslik
  # uchun avtomatik yangilanishni o'tkazib yuboramiz (xavfsizlik).
  [[ -n "$("${g[@]}" status --porcelain 2>/dev/null)" ]] && return 0

  # FETCH_HEAD — `git fetch origin <branch>` uni har doim yozadi (tracking ref
  # sozlamasidan qat'i nazar), shuning uchun ishonchli.
  "${g[@]}" fetch --quiet --depth 1 origin "$branch" 2>/dev/null || return 0
  local local_sha remote_sha
  local_sha="$("${g[@]}" rev-parse HEAD 2>/dev/null || true)"
  remote_sha="$("${g[@]}" rev-parse FETCH_HEAD 2>/dev/null || true)"
  [[ -n "$local_sha" && -n "$remote_sha" && "$local_sha" != "$remote_sha" ]] || return 0

  printf '\n  %s%s%s%s\n' \
    "${C_BOLD:-}" "${C_TITLE:-}" "$(t '🔄 Aidevix CLI — yangi versiya topildi, yangilanmoqda...')" "${C_RESET:-}" >&2
  local subj
  subj="$("${g[@]}" log --no-merges --pretty='format:    • %s' "HEAD..FETCH_HEAD" 2>/dev/null | head -4 || true)"
  if [[ -n "$subj" ]]; then
    printf '  %s%s%s\n' "${C_GRAY:-}" "$(t "Yangi o'zgarishlar:")" "${C_RESET:-}" >&2
    printf '%s\n' "$subj" >&2
  fi

  if "${g[@]}" reset --hard --quiet FETCH_HEAD 2>/dev/null; then
    printf '  %s%s%s %s\n\n' "${C_GREEN:-}" "$(t '✓ Yangilandi!')" "${C_RESET:-}" "$(t 'Yangi imkoniyatlar tayyor.')" >&2
    # Skript ham yangilangan bo'lishi mumkin — yangi versiyani qayta ishga tushiramiz.
    trap - ERR
    cleanup 2>/dev/null || true
    exec bash "$SELF" "$@"
  fi
  printf '  %s%s%s\n\n' \
    "${C_YELLOW:-}" "$(t "! Avtomatik yangilab bo'lmadi — keyinroq qayta urinadi.")" "${C_RESET:-}" >&2
  return 0
}

# is_npm_install — paket npm (global) node_modules ichidan ishlayaptimi?
# Faqat shunda "npm update" maslahati to'g'ri bo'ladi (git/brew/scoop emas).
is_npm_install() {
  case "$PROJECT_ROOT" in
    */node_modules/*|*/node_modules) return 0 ;;
    *)                               return 1 ;;
  esac
}

# version_gt <a> <b> — semver a, b dan KATTAmi? (a>b → 0/true). Tashqi dasturga
# tayanmaydi: nuqta bilan ajratib, maydonma-maydon sonli taqqoslaydi. Raqam
# bo'lmagan qism (masalan "-beta") 0 deb olinadi — yetarli darajada ehtiyotkor.
version_gt() {
  local a="$1" b="$2"
  [[ "$a" == "$b" ]] && return 1
  local IFS=.
  # Nuqta bo'yicha ataylab bo'lib olamiz (semver maydonlari).
  # shellcheck disable=SC2206
  local -a A=($a) B=($b)
  local i max=${#A[@]}
  (( ${#B[@]} > max )) && max=${#B[@]}
  for (( i=0; i<max; i++ )); do
    local x="${A[i]:-0}" y="${B[i]:-0}"
    [[ "$x" =~ ^[0-9]+$ ]] || x=0
    [[ "$y" =~ ^[0-9]+$ ]] || y=0
    (( 10#$x > 10#$y )) && return 0
    (( 10#$x < 10#$y )) && return 1
  done
  return 1
}

# fetch_npm_latest — npm registry'dan eng so'nggi versiyani FONDA keshlaydi
# (throttled, std 3 soat). Bloklamaydi: joriy ishga tushish eski keshni o'qiydi.
fetch_npm_latest() {
  [[ -n "${CI:-}" ]] && return 0
  command -v curl >/dev/null 2>&1 || return 0
  local now interval last
  interval="${AIDEVIX_UPDATE_INTERVAL:-10800}"
  now="$(date +%s 2>/dev/null || echo 0)"
  if [[ -r "$NPM_CHECK_STAMP" && -r "$NPM_LATEST_CACHE" ]]; then
    last="$(cat "$NPM_CHECK_STAMP" 2>/dev/null || echo 0)"; [[ "$last" =~ ^[0-9]+$ ]] || last=0
    (( now - last < interval )) && return 0
  fi
  mkdir -p "$STATE_DIR" 2>/dev/null || return 0
  # dist-tags endpoint'i kichik: {"latest":"X.Y.Z", ...}. sed bilan ajratamiz.
  ( curl -fsS -m 5 "https://registry.npmjs.org/-/package/$NPM_PKG/dist-tags" 2>/dev/null \
      | sed -n 's/.*"latest":"\([0-9][0-9A-Za-z.\-]*\)".*/\1/p' >"$NPM_LATEST_CACHE.tmp" 2>/dev/null \
      && [[ -s "$NPM_LATEST_CACHE.tmp" ]] \
      && mv -f "$NPM_LATEST_CACHE.tmp" "$NPM_LATEST_CACHE" 2>/dev/null \
      && printf '%s\n' "$now" >"$NPM_CHECK_STAMP" 2>/dev/null \
      || rm -f "$NPM_LATEST_CACHE.tmp" 2>/dev/null ) >/dev/null 2>&1 &
  return 0
}

# maybe_npm_update_hint — npm o'rnatishda yangi versiya bo'lsa, BIR MARTA (har
# yangi versiya uchun) yangilash buyrug'ini eslatadi. Jim, majburlamaydi.
# O'chirish: AIDEVIX_NO_AUTOUPDATE=1 (yoki CI).
maybe_npm_update_hint() {
  [[ -n "${AIDEVIX_NO_AUTOUPDATE:-}" || -n "${CI:-}" ]] && return 0
  is_npm_install || return 0
  fetch_npm_latest                       # keyingi safar uchun fonda yangilaydi
  [[ -r "$NPM_LATEST_CACHE" ]] || return 0
  local latest; latest="$(cat "$NPM_LATEST_CACHE" 2>/dev/null || true)"
  [[ "$latest" =~ ^[0-9]+\.[0-9]+ ]] || return 0
  version_gt "$latest" "$AIDEVIX_VERSION" || return 0
  # Shu versiya allaqachon eslatilgan bo'lsa — qayta bezovta qilmaymiz.
  local notified=""
  [[ -r "$NPM_NOTIFIED_FILE" ]] && notified="$(cat "$NPM_NOTIFIED_FILE" 2>/dev/null || true)"
  [[ "$notified" == "$latest" ]] && return 0
  mkdir -p "$STATE_DIR" 2>/dev/null || true
  printf '%s\n' "$latest" >"$NPM_NOTIFIED_FILE" 2>/dev/null || true
  panel "$(t '🔄 Aidevix yangi versiya bor (%s → %s)' "$AIDEVIX_VERSION" "$latest")" \
    "$(t 'Yangilash uchun terminalga yozing:')" \
    "    npm update -g $NPM_PKG" \
    "$(t "Eslatmani o'chirish: AIDEVIX_NO_AUTOUPDATE=1")"
}

# --- Argumentlar ----------------------------------------------------------
main() {
  # Preview qism-jarayoni — augment va boshqa og'ir ishlardan oldin.
  if [[ "${1:-}" == "__preview" ]]; then
    preview_agent "${2:-}" "${3:-}"
    exit 0
  fi

  augment_tool_path

  # Avtomatik yangilanish — tez/meta buyruqlar uchun o'tkazib yuboramiz.
  case "${1:-}" in
    -h|--help|-v|--version|-s|--stats) : ;;
    *)                                 auto_update "$@"; maybe_npm_update_hint ;;
  esac

  case "${1:-}" in
    -h|--help)     usage ;;
    -v|--version)  printf 'Aidevix CLI %s\n' "$AIDEVIX_VERSION" ;;
    -l|--list)     list_agents ;;
    -u|--update)   update_agents ;;
    -d|--doctor)   doctor ;;
    -a|--add)      add_agent ;;
    -s|--stats)    stats_cmd "${2:-}" ;;
    -f|--free)     run_menu free ;;
    -t|--top)      run_menu top ;;
    "")            run_menu ;;
    -*)            log_error "$(t "Noma'lum tanlov: %s" "$1")"; echo; usage; exit 2 ;;
    *)             quick_launch "$1" ;;
  esac
}

# Skript to'g'ridan-to'g'ri ishga tushirilganda main()'ni chaqiramiz. `source`
# qilinganda (masalan bats testlarida) chaqirmaymiz — shunda alohida funksiyalarni
# (trim, parse_agents, ...) izolyatsiyada test qilish mumkin bo'ladi.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
