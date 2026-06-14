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
# Login/auth eslatmasi qaysi agentlar uchun allaqachon ko'rsatilganini saqlaydi.
SEEN_AUTH_FILE="$STATE_DIR/seen_auth"

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
trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

# --- Yordam matni ---------------------------------------------------------
usage() {
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
  -v, --version   Aidevix CLI versiyasini ko'rsatadi
  -h, --help      Ushbu yordam matnini ko'rsatadi

KONFIGURATSIYA:
  Agentlar quyidagi fayldan o'qiladi (birinchi topilgani ishlatiladi):
    1) $AI_PULT_CONFIG (muhit o'zgaruvchisi)
    2) ~/.config/ai-cli/agents.conf
    3) <repo>/config/agents.conf

  Format (6-maydon ixtiyoriy):
    NOM|BINARY|BUYRUQ|INSTALL|IZOH|KATEGORIYA
EOF
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
    die 1 "Konfiguratsiya topilmadi. Tekshirildi: '$REPO_CONFIG', '$USER_CONFIG'"

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
    panel "🔐 '$name' — login/kalit kerak" \
      "Bu agentni ishlatish uchun API kalit kerak:" \
      "    $auth" \
      "" \
      "🌐 Kalit olish sahifasi brauzerda ochilmoqda:" \
      "    $url" \
      "" \
      "👉 Kalitni oling va agent ko'rsatmasiga amal qiling. Aidevix kalitni" \
      "   ko'rmaydi va saqlamaydi — u faqat sizning kompyuteringizda qoladi."
    open_url "$url"
    [[ "${AI_ANIM:-0}" -eq 1 ]] && sleep 0.8 || true
  elif [[ -n "$auth" ]]; then
    # Alohida loginga yo'naltirish SHART EMAS (kalit bor, agent o'zi login
    # qiladi, yoki bepul) — faqat qisqa eslatma beramiz, brauzer ochmaymiz.
    panel "🔐 '$name' — eslatma" \
      "Login talabi: $auth" \
      "👉 Agar agent login so'rasa, ekrandagi ko'rsatmaga amal qiling."
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
      log_warn "Noto'g'ri qator o'tkazib yuborildi (#$lineno): $line"
      continue
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "$desc" "$binary" "$command" "$install" "$category" "$auth" "$url"
    found=1
  done <"$config"

  [[ "$found" -eq 1 ]] || die 1 "Konfiguratsiyada yaroqli agent topilmadi: $config"
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
      status="✓ o'rnatilgan"
    else
      status="✗ yo'q"
    fi
    # Maydon tartibi: status 7-, auth 8-, url 9- (preview/menu $7 status'ga tayanadi).
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$name" "$desc" "$binary" "$command" "$install" "$category" "$status" "$auth" "$url"
  done < <(parse_agents "$config" | tr '\t' '\037')
}

# --- --list rejimi --------------------------------------------------------
list_agents() {
  local config; config="$(resolve_config)"
  log_info "Konfiguratsiya: $config"
  printf '\n%s%-18s %-14s %-9s %-34s %s%s\n' "$C_BOLD" "AGENT" "HOLAT" "GURUH" "IZOH" "LOGIN" "$C_RESET"
  printf '%s\n' "------------------------------------------------------------------------------------------"
  local name desc binary command install category status auth url color
  while IFS=$'\037' read -r name desc binary command install category status auth url; do
    if [[ "$status" == *"✓"* ]]; then color="$C_GREEN"; else color="$C_RED"; fi
    printf '%-18s %b%-14s%b %-9s %-34s %s\n' "$name" "$color" "$status" "$C_RESET" "$category" "$desc" "$auth"
  done < <(build_rows "$config" | tr '\t' '\037')
}

# --- Preview (fzf tomonidan qism-jarayon sifatida chaqiriladi) -------------
# fzf preview'ni TTY'siz ishga tushiradi, shuning uchun ranglarni bevosita
# ANSI kodlari bilan beramiz (fzf --ansi ularni to'g'ri ko'rsatadi).
preview_agent() {
  local name="$1" datafile="$2"
  [[ -r "$datafile" ]] || return 0
  awk -F'\t' -v n="$name" '
    BEGIN {
      ESC = sprintf("%c", 27)
      B   = ESC "[1m";      R = ESC "[0m"
      CY  = ESC "[38;5;87m"; GY = ESC "[90m"
      GRN = ESC "[32m";      RED = ESC "[31m";  MG = ESC "[38;5;213m"
    }
    $1 == n {
      # Holat belgisi
      if ($7 ~ /✓/) { badge = GRN "● o\47rnatilgan" R }
      else          { badge = RED "○ o\47rnatilmagan" R }

      print ""
      print "  " B CY $1 R
      print "  " GY "────────────────────────────" R
      print ""
      print "  " GY "Holat     " R badge
      print "  " GY "Binar     " R $3
      print "  " GY "Buyruq    " R MG $4 R
      print "  " GY "Kategoriya" R $6
      print "  " GY "Login     " R ($8 == "" ? GY "—" R : $8)
      if ($9 != "") print "  " GY "Havola    " R CY $9 R
      print ""
      print "  " GY "O\47rnatish:" R
      print "    " ($5 == "" ? GY "(belgilanmagan)" R : $5)
      print ""
      print "  " GY "────────────────────────────" R
      print "  " $2
      exit
    }' "$datafile"
}

# --- Menyu qatorlarini qurish (oxirgi tanlov yuqorida) ---------------------
# Chiqish formati: KO'RINISH\tNAME  (NAME — qidirish uchun yashirin maydon)
build_menu() {
  local rows="$1" last="$2"
  awk -F'\t' -v last="$last" -v g="${C_GREEN:-}" -v r="${C_RED:-}" -v z="${C_RESET:-}" \
            -v t="${C_TITLE:-}" -v gy="${C_GRAY:-}" -v b="${C_BOLD:-}" '
    {
      name=$1; desc=$2; status=$7; auth=$8;
      if (status ~ /✓/) { icon = g "✓" z } else { icon = r "✗" z }
      badge = "";
      if (index(auth, "🆓"))      badge = "🆓";
      else if (index(auth, "🌐")) badge = "🌐";
      else if (index(auth, "🔑")) badge = "🔑";
      else if (index(auth, "💳")) badge = "💳";
      disp = sprintf("%s  %s%s%-16s%s %s%s%s  %s", icon, b, t, name, z, gy, desc, z, badge)
      line = disp "\t" name
      if (name == last && last != "") { first = line }
      else { rest[++n] = line }
    }
    END {
      if (first != "") print first
      for (i = 1; i <= n; i++) print rest[i]
    }
  ' <<<"$rows"
}

# --- fzf orqali tanlash ---------------------------------------------------
select_with_fzf() {
  local menu="$1" datafile="$2" selection rc
  selection="$(
    printf '%s\n' "$menu" \
      | fzf --ansi \
            --delimiter='\t' \
            --with-nth=1 \
            --prompt='  qidirish › ' \
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
            --header='↑/↓ tanlang · yozib qidiring · ENTER ishga tushirish · ESC bekor' \
            --preview "bash \"$SELF\" __preview {2} \"$datafile\"" \
            --preview-window='right,52%,wrap,border-left' \
            --preview-label=' tafsilot '
  )" || {
    rc=$?
    if [[ "$rc" -eq 130 ]]; then log_info "Bekor qilindi."; exit 0; fi
    die "$rc" "fzf kutilmagan kod bilan to'xtadi: $rc"
  }
  [[ -z "$selection" ]] && { log_info "Hech narsa tanlanmadi."; exit 0; }
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

  [[ "${#names[@]}" -gt 0 ]] || die 1 "Menyu uchun agent topilmadi."

  log_warn "fzf topilmadi — oddiy menyu ishlatilmoqda (yaxshiroq tajriba uchun fzf o'rnating)."
  printf '\n%sAI CLI tanlang:%s\n' "${C_BOLD:-}" "${C_RESET:-}" >&2
  local i
  for i in "${!names[@]}"; do
    printf '%b%3d)%b %b\n' "${C_BLUE:-}" "$((i + 1))" "${C_RESET:-}" "${displays[$i]}" >&2
  done
  printf '%s\n' "----------------------------------------" >&2

  local choice="" prompt="Raqam kiriting (1-${#names[@]}, ESC=bekor) › "
  trap - ERR
  if { : >/dev/tty; } 2>/dev/null; then
    printf '%s' "$prompt" >/dev/tty
    IFS= read -r choice </dev/tty || choice=""
  else
    printf '%s' "$prompt" >&2
    IFS= read -r choice || choice=""
  fi
  trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

  [[ -z "$choice" ]] && { log_info "Bekor qilindi."; exit 0; }
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#names[@]} )); then
    die 2 "Noto'g'ri tanlov: '$choice'."
  fi
  printf '%s' "${names[$((choice - 1))]}"
}

# --- Interaktiv menyu -----------------------------------------------------
run_menu() {
  local filter="${1:-}"
  case "$filter" in
    free) banner "Aidevix CLI" "🆓 bepul agentlar — login/kalitsiz yoki bepul tier" ;;
    top)  banner "Aidevix CLI" "⭐ eng mashhur agentlar — vibecoding uchun" ;;
    *)    banner ;;
  esac

  local config; config="$(resolve_config)"
  local rows; rows="$(build_rows "$config")"

  # --free / --top filtrlari (agar so'ralgan bo'lsa).
  case "$filter" in
    free)
      rows="$(awk -F'\t' '$8 ~ /🆓/ || tolower($8) ~ /bepul|free/' <<<"$rows")"
      [[ -n "$rows" ]] || { log_info "Bepul agent topilmadi."; exit 0; }
      ;;
    top)
      rows="$(awk -F'\t' -v tops="|claude|codex|gemini|copilot|cursor-agent|aider|opencode|qwen|" \
              'index(tops, "|" $3 "|") > 0' <<<"$rows")"
      [[ -n "$rows" ]] || { log_info "Top agent topilmadi."; exit 0; }
      ;;
  esac

  local last; last="$(read_last)"
  local menu; menu="$(build_menu "$rows" "$last")"

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
  [[ -n "$row" ]] || die 1 "Tanlangan agent topilmadi: $name"

  binary="$(printf '%s'  "$row" | cut -f3)"
  command="$(printf '%s' "$row" | cut -f4)"
  install="$(printf '%s' "$row" | cut -f5)"
  auth="$(printf '%s'    "$row" | cut -f8)"
  url="$(printf '%s'     "$row" | cut -f9)"

  save_last "$name"
  ensure_installed "$name" "$binary" "$install"
  maybe_show_auth_note "$name" "$auth" "$url"
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
  [[ -n "$name" ]] || die 2 "Mos agent topilmadi: '$query'. Ro'yxat uchun: aidevix --list"

  launch_selected "$rows" "$name"
}

# --- CLI mavjudligini ta'minlash (kerak bo'lsa avtomatik o'rnatish) -------
ensure_installed() {
  local name="$1" binary="$2" install="$3"

  command -v "$binary" >/dev/null 2>&1 && return 0

  log_warn "Agent topilmadi: '$name' (kerakli buyruq: '$binary')."
  if [[ -z "$install" ]]; then
    die 127 "Avtomatik o'rnatish buyrug'i belgilanmagan. Iltimos, '$name'ni qo'lda o'rnating."
  fi

  log_info "O'rnatish buyrug'i: $install"
  local ans="" prompt="❓ '$name' hozir o'rnatilsinmi? [y/N] "
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
  trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

  if [[ ! "$ans" =~ ^[Yy]$ ]]; then
    die 127 "Bekor qilindi. '$name'ni qo'lda o'rnatish uchun: $install"
  fi

  # O'rnatishdan OLDIN: kerakli dastur (npm/python3/curl...) bormi? Yo'q bo'lsa
  # foydalanuvchiga nima yetishmayotganini SODDA tilda aytamiz.
  local tool; tool="$(detect_install_tool "$install")"
  if [[ -n "$tool" ]] && ! command -v "$tool" >/dev/null 2>&1; then
    panel "❌ '$name' o'rnatilmadi — avval bitta dastur kerak" \
      "'$name'ni o'rnatish uchun kompyuteringizda \"$tool\" bo'lishi shart," \
      "lekin u topilmadi." \
      "" \
      "👉 $(tool_hint "$tool")" \
      "" \
      "Shuni o'rnatib, terminalni qayta oching va yana \"aidevix\" deb yozing."
    die 127 "'$tool' topilmadi — '$name' o'rnatilmadi."
  fi

  # ERR tutqichini vaqtincha o'chirib, o'rnatish xatosini o'zimiz ushlaymiz.
  trap - ERR
  if ! spin_run "📦 '$name' o'rnatilmoqda" "$install"; then
    local tail_lines="" log_text=""
    if [[ -r "${SPIN_LOG:-}" ]]; then
      tail_lines="$(tail -n 6 "$SPIN_LOG" 2>/dev/null || true)"
      log_text="$(cat "$SPIN_LOG" 2>/dev/null || true)"
    fi
    trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

    # O'rnatuvchi "bu OS qo'llab-quvvatlanmaydi" desa — adashtiruvchi (internet/
    # sudo/curl) sabablar o'rniga halol, aniq xabar beramiz.
    if printf '%s' "$log_text" | grep -qiE 'unsupported (operating system|os|platform|architecture)|not supported|no (prebuilt|pre-built|binary)|MINGW|MSYS|windows is not'; then
      panel "🚫 '$name' bu operatsion tizimda qo'llab-quvvatlanmaydi" \
        "'$name' o'rnatuvchisi sizning tizimingizni (Windows / Git Bash —" \
        "MINGW64) qo'llab-quvvatlamasligini aytdi. Bu — internet yoki ruxsat" \
        "muammosi EMAS; shunchaki bu agentning Windows uchun o'rnatuvchisi yo'q." \
        "" \
        "👉 Variantlar:" \
        "  • Boshqa agentni tanlang (masalan Claude Code, Gemini, Aider — ular" \
        "    Windows'da ishlaydi)." \
        "  • Yoki '$name'ni WSL (Windows Subsystem for Linux) ichida ishlating." \
        "  • Agent rasmiy sahifasida Windows uchun yo'l bor-yo'qligini tekshiring."
      if [[ -n "$tail_lines" ]]; then
        printf '%s  Xato tafsiloti (oxirgi qatorlar):%s\n' "$C_GRAY" "$C_RESET" >&2
        printf '%s\n' "$tail_lines" | sed 's/^/    /' >&2
        printf '\n' >&2
      fi
      rm -f "${SPIN_LOG:-}" 2>/dev/null || true
      die 127 "'$name' bu OS'da qo'llab-quvvatlanmaydi."
    fi

    panel "❌ '$name' o'rnatishda xatolik yuz berdi" \
      "Quyidagi buyruq muvaffaqiyatsiz tugadi:" \
      "    $install" \
      "" \
      "Ko'pincha sabab quyidagilardan biri bo'ladi:" \
      "  1) 🌐 Internet yo'q yoki sekin — Wi-Fi/ulanishni tekshiring." \
      "  2) 🔒 Ruxsat yetarli emas — buyruqni \"sudo\" bilan sinab ko'ring." \
      "  3) 📦 \"${tool:-dastur}\" eski — uni yangilab, qaytadan urinib ko'ring." \
      "" \
      "👉 Aniq sababni ko'rish uchun yuqoridagi buyruqni terminalga o'zingiz" \
      "   nusxalab ishga tushiring — xato matni to'liq ko'rinadi."
    if [[ -n "$tail_lines" ]]; then
      printf '%s  Xato tafsiloti (oxirgi qatorlar):%s\n' "$C_GRAY" "$C_RESET" >&2
      printf '%s\n' "$tail_lines" | sed 's/^/    /' >&2
      printf '\n' >&2
    fi
    rm -f "${SPIN_LOG:-}" 2>/dev/null || true
    die 1 "O'rnatish muvaffaqiyatsiz tugadi: $name."
  fi
  rm -f "${SPIN_LOG:-}" 2>/dev/null || true
  trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR

  # O'rnatish yangi bin papkasi yaratgan bo'lishi mumkin — PATH'ni qayta
  # boyitamiz va hash'ni tozalaymiz, shunda binar joriy sessiyada ko'rinadi.
  augment_tool_path

  if ! command -v "$binary" >/dev/null 2>&1; then
    panel "⚠️  '$name' o'rnatildi, lekin hali ishga tushmadi" \
      "Dastur o'rnatildi, biroq tizim \"$binary\" buyrug'ini hali topa olmayapti." \
      "Bu odatda \"PATH\" sozlamasi yangilanmagani uchun bo'ladi." \
      "" \
      "👉 Yechimi oson: terminalni butunlay yopib, qaytadan oching," \
      "   so'ng yana \"aidevix\" deb yozing — endi ishlaydi." \
      "" \
      "Agar shunda ham yordam bermasa: \"aidevix --doctor\" buyrug'i muammoni ko'rsatadi."
    die 127 "'$binary' hali PATH'da ko'rinmayapti — terminalni qayta oching."
  fi
  log_success "O'rnatildi: $name"
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
  log_info "Konfiguratsiya: $config"
  local rows; rows="$(build_rows "$config")"
  local name desc binary command install category status auth url
  local checked=0 ok=0 fail=0

  while IFS=$'\037' read -r name desc binary command install category status auth url; do
    command -v "$binary" >/dev/null 2>&1 || continue
    checked=$((checked + 1))
    if [[ -z "$install" ]]; then
      log_warn "$name: o'rnatish buyrug'i yo'q — o'tkazib yuborildi."
      continue
    fi
    trap - ERR
    if spin_run "🔄 $name yangilanmoqda" "$install"; then
      ok=$((ok + 1))
    else
      fail=$((fail + 1))
    fi
    rm -f "${SPIN_LOG:-}" 2>/dev/null || true
    trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR
  done < <(printf '%s\n' "$rows" | tr '\t' '\037')

  if [[ "$checked" -eq 0 ]]; then
    log_warn "O'rnatilgan agent topilmadi — yangilash uchun avval agent o'rnating."
  else
    log_success "Yangilash tugadi: $ok ta muvaffaqiyatli, $fail ta xato (jami $checked)."
  fi
}

# --- Muhit tashxisi (doctor) ----------------------------------------------
doctor() {
  banner "Aidevix — Tashxis" "muhitingizni tekshiramiz"

  local tool
  printf '%sVositalar:%s\n' "${C_BOLD:-}" "${C_RESET:-}"
  for tool in bash fzf node npm python3 curl git; do
    if command -v "$tool" >/dev/null 2>&1; then
      printf '  %b✓%b %-8s %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$tool" "$(command -v "$tool")"
    else
      printf '  %b✗%b %-8s topilmadi\n' "${C_RED:-}" "${C_RESET:-}" "$tool"
    fi
  done

  printf '\n%sPATH tekshiruvi:%s\n' "${C_BOLD:-}" "${C_RESET:-}"
  if command -v npm >/dev/null 2>&1; then
    local prefix bindir
    prefix="$(npm config get prefix 2>/dev/null || true)"
    printf '  npm prefix: %s\n' "${prefix:-(aniqlanmadi)}"
    for bindir in "$prefix/bin" "$prefix"; do
      [[ -d "$bindir" ]] || continue
      if [[ ":$PATH:" == *":$bindir:"* ]]; then
        printf '  %b✓%b PATH ichida: %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$bindir"
      else
        printf '  %b✗%b PATH da YO''Q: %s  (aidevix uni o'\''zi qo'\''shadi)\n' "${C_YELLOW:-}" "${C_RESET:-}" "$bindir"
      fi
    done
  else
    printf '  %b!%b npm topilmadi — npm orqali o'\''rnatiladigan agentlar ishlamaydi.\n' "${C_YELLOW:-}" "${C_RESET:-}"
  fi
  if [[ -d "$HOME/.local/bin" ]]; then
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
      printf '  %b✓%b PATH ichida: %s\n' "${C_GREEN:-}" "${C_RESET:-}" "$HOME/.local/bin"
    else
      printf '  %b✗%b PATH da YO''Q: %s\n' "${C_YELLOW:-}" "${C_RESET:-}" "$HOME/.local/bin"
    fi
  fi

  printf '\n%sAgentlar holati:%s\n' "${C_BOLD:-}" "${C_RESET:-}"
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
  trap 'die 1 "Kutilmagan xato: $BASH_COMMAND (qator: $LINENO)"' ERR
  printf -v "$__var" '%s' "$__val"
}

add_agent() {
  printf '\n%s➕ Yangi agent qo'\''shish%s\n\n' "${C_BOLD:-}" "${C_RESET:-}"
  local name binary command install desc category auth url
  prompt_tty "Nom (masalan: My Agent)        : " name
  prompt_tty "Binary (PATH'dagi buyruq nomi) : " binary
  prompt_tty "Ishga tushirish buyrug'i       : " command
  prompt_tty "O'rnatish buyrug'i (ixtiyoriy) : " install
  prompt_tty "Izoh (ixtiyoriy)               : " desc
  prompt_tty "Kategoriya (ixtiyoriy)         : " category
  prompt_tty "Login/kalit izohi (ixtiyoriy)  : " auth
  prompt_tty "Login/hujjat havolasi (ixtiyoriy): " url

  name="$(trim "$name")"; binary="$(trim "$binary")"; command="$(trim "$command")"
  install="$(trim "$install")"; desc="$(trim "$desc")"; category="$(trim "$category")"
  auth="$(trim "$auth")"; url="$(trim "$url")"
  [[ -z "$command" ]] && command="$binary"
  [[ -z "$category" ]] && category="$DEFAULT_CATEGORY"

  if [[ -z "$name" || -z "$binary" ]]; then
    die 2 "Nom va Binary majburiy. Bekor qilindi."
  fi
  if [[ "$name$binary$command$install$desc$category$auth$url" == *"|"* ]]; then
    die 2 "Maydonlar ichida '|' belgisi bo'lmasligi kerak. Bekor qilindi."
  fi

  # Foydalanuvchi configi — faqat QO'SHIMCHA agentlar (repo nusxalanmaydi, shunda
  # repo yangilanganda yangi agentlar avtomatik ko'rinadi). Bo'lmasa yaratamiz.
  mkdir -p "$(dirname "$USER_CONFIG")"
  if [[ ! -e "$USER_CONFIG" ]]; then
    printf '# Aidevix CLI — foydalanuvchi qo\047shgan agentlar\n# Format: NOM|BINARY|BUYRUQ|INSTALL|IZOH|KATEGORIYA|AUTH|URL\n\n' >"$USER_CONFIG"
  fi
  printf '%s|%s|%s|%s|%s|%s|%s|%s\n' \
    "$name" "$binary" "$command" "$install" "$desc" "$category" "$auth" "$url" >>"$USER_CONFIG"
  log_success "Qo'shildi: $name  →  $USER_CONFIG"
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

  printf '\n  %s%s🔄 Aidevix CLI — yangi versiya topildi, yangilanmoqda...%s\n' \
    "${C_BOLD:-}" "${C_TITLE:-}" "${C_RESET:-}" >&2
  local subj
  subj="$("${g[@]}" log --no-merges --pretty='format:    • %s' "HEAD..FETCH_HEAD" 2>/dev/null | head -4 || true)"
  if [[ -n "$subj" ]]; then
    printf '  %sYangi o\047zgarishlar:%s\n' "${C_GRAY:-}" "${C_RESET:-}" >&2
    printf '%s\n' "$subj" >&2
  fi

  if "${g[@]}" reset --hard --quiet FETCH_HEAD 2>/dev/null; then
    printf '  %s✓ Yangilandi!%s Yangi imkoniyatlar tayyor.\n\n' "${C_GREEN:-}" "${C_RESET:-}" >&2
    # Skript ham yangilangan bo'lishi mumkin — yangi versiyani qayta ishga tushiramiz.
    trap - ERR
    cleanup 2>/dev/null || true
    exec bash "$SELF" "$@"
  fi
  printf '  %s! Avtomatik yangilab bo\047lmadi%s — keyinroq qayta urinadi.\n\n' \
    "${C_YELLOW:-}" "${C_RESET:-}" >&2
  return 0
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
    -h|--help|-v|--version) : ;;
    *)                      auto_update "$@" ;;
  esac

  case "${1:-}" in
    -h|--help)     usage ;;
    -v|--version)  printf 'Aidevix CLI %s\n' "$AIDEVIX_VERSION" ;;
    -l|--list)     list_agents ;;
    -u|--update)   update_agents ;;
    -d|--doctor)   doctor ;;
    -a|--add)      add_agent ;;
    -f|--free)     run_menu free ;;
    -t|--top)      run_menu top ;;
    "")            run_menu ;;
    -*)            log_error "Noma'lum tanlov: $1"; echo; usage; exit 2 ;;
    *)             quick_launch "$1" ;;
  esac
}

main "$@"
