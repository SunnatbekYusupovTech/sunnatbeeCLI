#!/usr/bin/env bash
#
# install.sh — AI CLI Pult'ni o'rnatish skripti.
#
# Nima qiladi:
#   1. Kerakli vositalarni (fzf) tekshiradi.
#   2. Foydalanuvchi shell konfiguratsiyasini (.bashrc / .zshrc) ZAXIRALAYDI.
#   3. `ai` buyrug'ini ~/.local/bin'ga symlink qilib joylaydi.
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
      "  • 🧩 \"git\", \"curl\", \"fzf\" o'rnatilganmi? (\"ai --doctor\")" \
      "" \
      "Muammo davom etsa, yuqoridagi xato matnini nusxalab yordam so'rang."
  fi
  exit 1
}
trap 'on_install_error "$LINENO"' ERR

readonly BIN_SRC="$INSTALL_DIR/bin/ai-selector.sh"
readonly CONFIG_SRC="$INSTALL_DIR/config/agents.conf"
readonly COMPLETION_SRC="$INSTALL_DIR/completions/ai.bash"
readonly USER_CONFIG_DIR="$HOME/.config/ai-cli"
readonly USER_CONFIG="$USER_CONFIG_DIR/agents.conf"
readonly BIN_DIR="$HOME/.local/bin"
readonly CMD_NAME="ai"
readonly CMD_LINK="$BIN_DIR/$CMD_NAME"
readonly MARK_BEGIN="# >>> ai-cli (boshlanish) >>>"
readonly MARK_END="# <<< ai-cli (oxir) <<<"

# --- 1) Kerakli vositalar -------------------------------------------------
check_prerequisites() {
  log_info "Kerakli vositalar tekshirilmoqda..."
  [[ -r "$BIN_SRC" ]]    || die 1 "Asosiy skript topilmadi: $BIN_SRC"
  [[ -r "$CONFIG_SRC" ]] || die 1 "Konfiguratsiya topilmadi: $CONFIG_SRC"

  # fzf MAJBURIY emas — bo'lmasa `ai` oddiy raqamli menyuga o'tadi. Shu sababli
  # uni ogohlantirish sifatida ko'rsatamiz, o'rnatishni to'xtatmaymiz.
  if ! command -v fzf >/dev/null 2>&1; then
    if declare -f panel >/dev/null 2>&1; then
      panel "ℹ️  \"fzf\" topilmadi — ixtiyoriy, lekin tavsiya etiladi" \
        "fzf — terminalda ro'yxatdan oson tanlash uchun kichik dastur." \
        "U bo'lmasa ham \"ai\" ishlaydi (oddiy raqamli menyu bilan)." \
        "Chiroyli, izlanadigan menyu uchun keyinroq o'rnatib qo'ying:" \
        "" \
        "👉 $(tool_hint fzf)"
    else
      log_warn "fzf topilmadi (ixtiyoriy). O'rnatish: https://github.com/junegunn/fzf#installation"
    fi
  else
    log_success "fzf topildi: $(command -v fzf)"
  fi
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

# --- 3) `ai` buyrug'ini wrapper sifatida joylash --------------------------
# Symlink o'rniga kichik wrapper yozamiz: u barcha platformalarda bir xil
# ishlaydi (Windows'da symlink huquqi talab qilinmaydi) va asl skriptga
# to'g'ridan-to'g'ri yo'l ko'rsatadi — shu sababli lib/common.sh doimo topiladi.
install_command() {
  chmod +x "$BIN_SRC"
  mkdir -p "$BIN_DIR"
  cat >"$CMD_LINK" <<EOF
#!/usr/bin/env bash
# AI CLI Pult — avtomatik yaratilgan wrapper. Qo'lda tahrirlamang.
exec bash "$BIN_SRC" "\$@"
EOF
  chmod +x "$CMD_LINK"
  log_success "'$CMD_NAME' buyrug'i o'rnatildi: $CMD_LINK -> $BIN_SRC"

  # Windows (cmd.exe / PowerShell) uchun wrapper'lar — `ai` to'g'ridan-to'g'ri
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
    # `ai` avtomatik to'ldirish (bash va zsh).
    printf '%s\n' 'if [ -n "${ZSH_VERSION:-}" ]; then autoload -U +X bashcompinit 2>/dev/null && bashcompinit 2>/dev/null; fi'
    printf '[ -r "%s" ] && . "%s"\n' "$COMPLETION_SRC" "$COMPLETION_SRC"
    printf '%s\n' "$MARK_END"
  } >>"$rc"
  log_success "PATH va completion yozuvlari qo'shildi: $rc"
}

main() {
  if declare -f banner >/dev/null 2>&1; then
    banner "AI CLI PULT" "o'rnatish boshlanmoqda"
  else
    printf '\n%s🤖 AI CLI Pult — o\047rnatish%s\n\n' "${C_BOLD:-}" "${C_RESET:-}"
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
  printf '    %s%sai%s\n\n'     "${C_BOLD:-}" "${C_CYAN:-}" "${C_RESET:-}"
}

main "$@"
