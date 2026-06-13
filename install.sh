#!/usr/bin/env bash
#
# install.sh — Aidevix CLI'ni o'rnatish skripti.
#
# Nima qiladi:
#   1. Kerakli vositalarni (fzf) tekshiradi.
#   2. Foydalanuvchi shell konfiguratsiyasini (.bashrc / .zshrc) ZAXIRALAYDI.
#   3. `aidevix` buyrug'ini ~/.local/bin'ga symlink qilib joylaydi.
#   4. ~/.local/bin'ni PATH'ga qo'shadi (kerak bo'lsa).
#   5. Agentlar konfiguratsiyasini ~/.config/ai-cli'ga ko'chiradi.
#
# Xavfsizlik tamoyillari:
#   • set -Eeuo pipefail — har qanday xatoda darhol to'xtaydi.
#   • sudo TALAB QILMAYDI; faqat $HOME ichida ishlaydi.
#   • rc fayllarni o'zgartirishdan OLDIN zaxira oladi.
#   • Idempotent — qayta ishga tushirsa ham buzilmaydi.
#
# Exit kodlari: 0 — muvaffaqiyat, 1 — umumiy xato, 127 — kerakli vosita yo'q.

set -Eeuo pipefail

INSTALL_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [[ -r "$INSTALL_DIR/lib/common.sh" ]]; then
  # shellcheck source=lib/common.sh
  source "$INSTALL_DIR/lib/common.sh"
else
  log_info()    { printf '[i] %s\n' "$*" >&2; }
  log_warn()    { printf '[!] %s\n' "$*" >&2; }
  log_error()   { printf '[x] %s\n' "$*" >&2; }
  log_success() { printf '[✓] %s\n' "$*" >&2; }
  die() { local c="$1"; shift; log_error "$*"; exit "$c"; }
fi

on_install_error() {
  local line="$1"
  declare -f show_cursor >/dev/null 2>&1 && show_cursor
  if declare -f panel >/dev/null 2>&1; then
    panel "❌ O'rnatishda kutilmagan xatolik" \
      "O'rnatish $line-qatorda to'xtadi." \
      "" \
      "Quyidagilarni tekshiring:" \
      "  • 🌐 Internet ulanishi bormi?" \
      "  • 📁 \$HOME papkangizga yozish ruxsati bormi?" \
      "  • 🧩 \"git\", \"curl\", \"fzf\" o'rnatilganmi? (\"aidevix --doctor\")" \
      "" \
      "Muammo davom etsa, yuqoridagi xato matnini nusxalab yordam so'rang."
  fi
  exit 1
}
trap 'on_install_error "$LINENO"' ERR

readonly BIN_SRC="$INSTALL_DIR/bin/ai-selector.sh"
readonly CONFIG_SRC="$INSTALL_DIR/config/agents.conf"
readonly COMPLETION_SRC="$INSTALL_DIR/completions/aidevix.bash"
readonly USER_CONFIG_DIR="$HOME/.config/ai-cli"
readonly USER_CONFIG="$USER_CONFIG_DIR/agents.conf"
readonly BIN_DIR="$HOME/.local/bin"
readonly CMD_NAME="aidevix"
readonly CMD_LINK="$BIN_DIR/$CMD_NAME"
readonly MARK_BEGIN="# >>> ai-cli (boshlanish) >>>"
readonly MARK_END="# <<< ai-cli (oxir) <<<"

# --- fzf'ni avtomatik o'rnatish (chiroyli menyu UI uchun) -----------------
# fzf MAJBURIY emas, lekin u bilan menyu ancha chiroyli (izlanadigan, preview'li).
# Bu yerda fzf'ni paket-menejersiz, to'g'ridan-to'g'ri GitHub releases'dan
# ~/.local/bin'ga yuklab olamiz — sudo TALAB QILMAYDI. Muvaffaqiyatsiz bo'lsa
# paket-menejer bilan urinamiz; u ham bo'lmasa — shunchaki ogohlantiramiz
# (o'rnatish TO'XTAMAYDI, chunki raqamli menyu baribir ishlaydi).
readonly FZF_FALLBACK_TAG="v0.73.1"

# Platforma (os) va arxitekturani fzf release nomlariga moslab aniqlaydi.
detect_os_arch() {
  local os="" arch="" s m
  s="$(uname -s 2>/dev/null || echo unknown)"
  m="$(uname -m 2>/dev/null || echo unknown)"
  case "$s" in
    Linux*)               os="linux" ;;
    Darwin*)              os="darwin" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
  esac
  case "$m" in
    x86_64|amd64)  arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    armv7l)        arch="armv7" ;;
  esac
  printf '%s %s\n' "$os" "$arch"
}

# GitHub API'dan eng so'nggi fzf tegini oladi; bo'lmasa — fallback teg.
fzf_latest_tag() {
  local tag=""
  if command -v curl >/dev/null 2>&1; then
    tag="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest 2>/dev/null \
           | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || true)"
  elif command -v wget >/dev/null 2>&1; then
    tag="$(wget -qO- https://api.github.com/repos/junegunn/fzf/releases/latest 2>/dev/null \
           | grep -m1 '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || true)"
  fi
  [[ -n "$tag" ]] || tag="$FZF_FALLBACK_TAG"
  printf '%s\n' "$tag"
}

download_to() {
  local url="$1" out="$2"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$out"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$out" "$url"
  else
    return 1
  fi
}

# fzf binarini GitHub releases'dan ~/.local/bin'ga yuklab oladi. 0 — muvaffaqiyat.
install_fzf_binary() {
  local os arch tag ver ext url tmp
  read -r os arch < <(detect_os_arch)
  [[ -n "$os" && -n "$arch" ]] || { log_warn "fzf: platforma aniqlanmadi ($(uname -sm 2>/dev/null))."; return 1; }

  tag="$(fzf_latest_tag)"; ver="${tag#v}"
  if [[ "$os" == "windows" ]]; then ext="zip"; else ext="tar.gz"; fi
  url="https://github.com/junegunn/fzf/releases/download/${tag}/fzf-${ver}-${os}_${arch}.${ext}"

  mkdir -p "$BIN_DIR"
  tmp="$(mktemp -d)"
  log_info "fzf yuklab olinmoqda: ${tag} (${os}_${arch})"
  if ! download_to "$url" "$tmp/fzf.$ext"; then
    rm -rf "$tmp"; log_warn "fzf yuklab bo'lmadi: $url"; return 1
  fi

  if [[ "$ext" == "tar.gz" ]]; then
    if ! tar -xzf "$tmp/fzf.$ext" -C "$tmp" fzf 2>/dev/null; then
      rm -rf "$tmp"; log_warn "fzf arxivdan chiqarib bo'lmadi."; return 1
    fi
    mv -f "$tmp/fzf" "$BIN_DIR/fzf" && chmod +x "$BIN_DIR/fzf"
  else
    # Windows zip — unzip yoki Windows tar.exe (bsdtar) bilan ochamiz.
    if command -v unzip >/dev/null 2>&1; then
      unzip -o -q "$tmp/fzf.$ext" -d "$tmp" 2>/dev/null || true
    elif [[ -x /c/Windows/System32/tar.exe ]]; then
      ( cd "$tmp" && /c/Windows/System32/tar.exe -xf "fzf.$ext" ) 2>/dev/null || true
    else
      tar -xf "$tmp/fzf.$ext" -C "$tmp" 2>/dev/null || true
    fi
    if [[ -f "$tmp/fzf.exe" ]]; then
      mv -f "$tmp/fzf.exe" "$BIN_DIR/fzf.exe"
    else
      rm -rf "$tmp"; log_warn "fzf arxivdan chiqarib bo'lmadi (unzip kerak bo'lishi mumkin)."; return 1
    fi
  fi
  rm -rf "$tmp"
  hash -r 2>/dev/null || true
  return 0
}

# fzf bor-yo'qligini tekshirib, bo'lmasa avtomatik o'rnatadi. Hech qachon
# o'rnatishni to'xtatmaydi (har doim 0 qaytaradi).
_ensure_fzf() {
  if command -v fzf >/dev/null 2>&1; then
    log_success "fzf topildi: $(command -v fzf)"
    return 0
  fi

  log_info "fzf topilmadi — chiroyli menyu uchun avtomatik o'rnatamiz..."

  # 1) To'g'ridan-to'g'ri binar (sudo talab qilmaydi, eng universal).
  if install_fzf_binary && { command -v fzf >/dev/null 2>&1 || [[ -x "$BIN_DIR/fzf" || -x "$BIN_DIR/fzf.exe" ]]; }; then
    log_success "fzf o'rnatildi: $BIN_DIR"
    return 0
  fi

  # 2) Paket-menejer bilan urinib ko'ramiz.
  if command -v brew >/dev/null 2>&1; then
    log_info "fzf brew orqali o'rnatilmoqda..."
    brew install fzf >/dev/null 2>&1 && command -v fzf >/dev/null 2>&1 && { log_success "fzf o'rnatildi (brew)."; return 0; }
  fi
  if command -v winget >/dev/null 2>&1; then
    log_info "fzf winget orqali o'rnatilmoqda..."
    winget install --id=junegunn.fzf -e --accept-source-agreements --accept-package-agreements >/dev/null 2>&1 \
      && { log_success "fzf o'rnatildi (winget). Terminalni qayta oching."; return 0; }
  fi

  # 3) Hammasi muvaffaqiyatsiz — ogohlantiramiz (xato emas).
  if declare -f panel >/dev/null 2>&1; then
    panel "ℹ️  fzf avtomatik o'rnatilmadi — muammo emas" \
      "Chiroyli, izlanadigan menyu uchun fzf tavsiya etiladi, lekin u bo'lmasa" \
      "ham \"aidevix\" oddiy raqamli menyu bilan bemalol ishlayveradi." \
      "" \
      "👉 Keyinroq qo'lda o'rnatishingiz mumkin: $(tool_hint fzf)"
  else
    log_warn "fzf avtomatik o'rnatilmadi (ixtiyoriy). Qo'lda: $(tool_hint fzf 2>/dev/null || echo 'https://github.com/junegunn/fzf')"
  fi
  return 0
}

# set -e ostida ichki buyruqlar xatosi o'rnatishni to'xtatmasligi uchun
# ERR tutqichini vaqtincha o'chirib chaqiramiz (fzf — ixtiyoriy bosqich).
ensure_fzf() {
  trap - ERR
  set +e
  _ensure_fzf
  set -Eeuo pipefail
  trap 'on_install_error "$LINENO"' ERR
}

# --- 1) Kerakli vositalar -------------------------------------------------
check_prerequisites() {
  log_info "Kerakli vositalar tekshirilmoqda..."
  [[ -r "$BIN_SRC" ]]    || die 1 "Asosiy skript topilmadi: $BIN_SRC"
  [[ -r "$CONFIG_SRC" ]] || die 1 "Konfiguratsiya topilmadi: $CONFIG_SRC"

  # fzf'ni avtomatik o'rnatamiz (chiroyli menyu UI uchun). Ixtiyoriy bosqich —
  # muvaffaqiyatsiz bo'lsa ham o'rnatish davom etadi (raqamli menyu ishlaydi).
  ensure_fzf
}

detect_shell_rc() {
  local shell_name; shell_name="$(basename "${SHELL:-/bin/bash}")"
  case "$shell_name" in
    zsh)  printf '%s\n' "$HOME/.zshrc" ;;
    bash) printf '%s\n' "$HOME/.bashrc" ;;
    *)    printf '%s\n' "$HOME/.profile" ;;
  esac
}

# --- 2) rc faylni zaxiralash ----------------------------------------------
backup_file() {
  local target="$1"
  [[ -e "$target" ]] || { log_info "Zaxira shart emas (fayl yo'q): $target"; return 0; }
  local ts backup
  ts="$(date +%Y%m%d-%H%M%S)"
  backup="${target}.aicli-backup-${ts}"
  cp -p -- "$target" "$backup"
  log_success "Zaxira yaratildi: $backup"
}

# --- 3) `aidevix` buyrug'ini wrapper sifatida joylash ---------------------
# Symlink o'rniga kichik wrapper yozamiz: u barcha platformalarda bir xil
# ishlaydi (Windows'da symlink huquqi talab qilinmaydi) va asl skriptga
# to'g'ridan-to'g'ri yo'l ko'rsatadi — shu sababli lib/common.sh doimo topiladi.
install_command() {
  chmod +x "$BIN_SRC"
  mkdir -p "$BIN_DIR"
  cat >"$CMD_LINK" <<EOF
#!/usr/bin/env bash
# Aidevix CLI — avtomatik yaratilgan wrapper. Qo'lda tahrirlamang.
exec bash "$BIN_SRC" "\$@"
EOF
  chmod +x "$CMD_LINK"
  log_success "'$CMD_NAME' buyrug'i o'rnatildi: $CMD_LINK -> $BIN_SRC"

  # Windows (cmd.exe / PowerShell) uchun wrapper'lar — `aidevix` to'g'ridan-to'g'ri
  # shu qobiqlardan ham ishlasin. Git Bash'ni PATH'dan yoki odatiy o'rnatish
  # joylaridan topadi (PATH'da bo'lmasa ham). cmd fayli CRLF bilan yoziladi.
  {
    printf '%s\n' "@echo off"
    printf '%s\n' "setlocal"
    printf '%s\n' "set \"AI_SH=$BIN_SRC\""
    cat <<'CMDEOF'
for %%I in (bash.exe) do if not "%%~$PATH:I"=="" (
  bash "%AI_SH%" %*
  exit /b %errorlevel%
)
for %%P in (
  "%ProgramFiles%\Git\bin\bash.exe"
  "%ProgramFiles(x86)%\Git\bin\bash.exe"
  "%LocalAppData%\Programs\Git\bin\bash.exe"
) do if exist "%%~P" (
  "%%~P" "%AI_SH%" %*
  exit /b %errorlevel%
)
echo [x] bash topilmadi. Git for Windows o'rnating: https://git-scm.com/download/win
exit /b 127
CMDEOF
  } | sed 's/\r$//; s/$/\r/' >"$BIN_DIR/$CMD_NAME.cmd"

  {
    printf '%s\n' "\$script = '$BIN_SRC'"
    cat <<'PS1EOF'
$ErrorActionPreference = 'Stop'
$bash = (Get-Command bash -ErrorAction SilentlyContinue).Source
if (-not $bash) {
  foreach ($p in @(
    "$env:ProgramFiles\Git\bin\bash.exe",
    "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
  )) {
    if (Test-Path $p) { $bash = $p; break }
  }
}
if (-not $bash) {
  Write-Error "bash topilmadi. Git for Windows o'rnating: https://git-scm.com/download/win"
  exit 127
}
& $bash $script @args
exit $LASTEXITCODE
PS1EOF
  } >"$BIN_DIR/$CMD_NAME.ps1"
  log_success "Windows wrapper'lar o'rnatildi: $CMD_NAME.cmd, $CMD_NAME.ps1"
}

# --- 4) Foydalanuvchi konfiguratsiyasi ------------------------------------
install_user_config() {
  mkdir -p "$USER_CONFIG_DIR"
  if [[ -e "$USER_CONFIG" ]]; then
    log_info "Mavjud konfiguratsiya saqlanib qoldi: $USER_CONFIG"
  else
    cp -- "$CONFIG_SRC" "$USER_CONFIG"
    log_success "Konfiguratsiya o'rnatildi: $USER_CONFIG"
  fi
}

# --- 5) rc'ga PATH bloki (idempotent) -------------------------------------
install_shell_block() {
  local rc="$1"
  touch "$rc"
  if grep -qF "$MARK_BEGIN" "$rc" 2>/dev/null; then
    log_info "Mavjud ai-cli bloki yangilanmoqda: $rc"
    local tmp; tmp="$(mktemp)"
    sed "/${MARK_BEGIN//\//\\/}/,/${MARK_END//\//\\/}/d" "$rc" >"$tmp"
    mv -- "$tmp" "$rc"
  fi
  {
    printf '\n%s\n' "$MARK_BEGIN"
    printf '%s\n' 'export PATH="$HOME/.local/bin:$PATH"'
    # npm global bin papkasini PATH'ga qo'shamiz — yangi terminalda ham
    # npm orqali o'rnatilgan AI CLI'lar topilishi uchun.
    printf '%s\n' 'if command -v npm >/dev/null 2>&1; then'
    printf '%s\n' '  __ai_npm_prefix="$(npm config get prefix 2>/dev/null)"'
    printf '%s\n' '  if [ -n "$__ai_npm_prefix" ] && [ "$__ai_npm_prefix" != "undefined" ]; then'
    printf '%s\n' '    case ":$PATH:" in *":$__ai_npm_prefix/bin:"*) ;; *) export PATH="$__ai_npm_prefix/bin:$PATH" ;; esac'
    printf '%s\n' '    case ":$PATH:" in *":$__ai_npm_prefix:"*) ;; *) export PATH="$__ai_npm_prefix:$PATH" ;; esac'
    printf '%s\n' '  fi'
    printf '%s\n' '  unset __ai_npm_prefix'
    printf '%s\n' 'fi'
    # `aidevix` avtomatik to'ldirish (bash va zsh).
    printf '%s\n' 'if [ -n "${ZSH_VERSION:-}" ]; then autoload -U +X bashcompinit 2>/dev/null && bashcompinit 2>/dev/null; fi'
    printf '[ -r "%s" ] && . "%s"\n' "$COMPLETION_SRC" "$COMPLETION_SRC"
    printf '%s\n' "$MARK_END"
  } >>"$rc"
  log_success "PATH va completion yozuvlari qo'shildi: $rc"
}

main() {
  if declare -f banner >/dev/null 2>&1; then
    banner "Aidevix CLI" "o'rnatish boshlanmoqda"
  else
    printf '\n%s✦ Aidevix CLI — o\047rnatish%s\n\n' "${C_BOLD:-}" "${C_RESET:-}"
  fi

  check_prerequisites
  local rc; rc="$(detect_shell_rc)"
  log_info "Aniqlangan shell konfiguratsiyasi: $rc"

  backup_file "$rc"
  install_command
  install_user_config
  install_shell_block "$rc"

  printf '\n'
  if declare -f hr >/dev/null 2>&1; then
    printf '  %s%s%s\n' "${C_GREEN:-}" "$(hr 46)" "${C_RESET:-}"
  fi
  log_success "O'rnatish muvaffaqiyatli tugadi! 🎉"
  printf '\n  %sKeyingi qadam%s — terminalni qayta oching, yoki:\n' "${C_BOLD:-}" "${C_RESET:-}"
  printf '    %ssource %s%s\n'  "${C_CYAN:-}" "$rc" "${C_RESET:-}"
  printf '\n  So\047ngra menyuni oching:\n'
  printf '    %s%saidevix%s\n\n'     "${C_BOLD:-}" "${C_CYAN:-}" "${C_RESET:-}"
}

main "$@"
