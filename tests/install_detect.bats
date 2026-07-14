#!/usr/bin/env bats
# install_detect.bats — "o'rnatilgan agent har safar qayta o'rnatish so'raydi"
# muammosi uchun tuzatishlar regressiya testlari:
#   • locate_binary / record_bin_dir — binar PATH'dan tashqarida bo'lsa ham
#     topiladi, papkasi doimiy keshga yoziladi (BIN_DIR_CACHE);
#   • augment_tool_path — keshdagi papkalarni keyingi sessiyada PATH'ga qo'shadi;
#   • resolve_install_cmd — Windows'da python3 Store-stub bo'lsa python'ga o'tadi;
#   • maybe_autoupdate_agent — curl/wget o'rnatuvchilar endi avtomatik qayta
#     ishga tushirilmaydi (har 3 soatda to'liq installer yuklab olinardi).

load test_helper

setup() {
  setup_env
  load_selector
}

# --- resolve_install_cmd ---------------------------------------------------
@test "resolve_install_cmd: python bo'lmagan buyruq o'zgarmaydi" {
  run resolve_install_cmd "npm install -g demo@latest"
  [ "$output" = "npm install -g demo@latest" ]
}

@test "resolve_install_cmd: ishlaydigan python3 tegilmaydi" {
  local fb="$BATS_TEST_TMPDIR/fb1"; mkdir -p "$fb"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$fb/python3"; chmod +x "$fb/python3"
  PATH="$fb:$PATH"
  run resolve_install_cmd "python3 -m pip install --user --upgrade demo"
  [ "$output" = "python3 -m pip install --user --upgrade demo" ]
}

@test "resolve_install_cmd: buzuq python3 (Store stub) → python'ga almashadi" {
  local fb="$BATS_TEST_TMPDIR/fb2"; mkdir -p "$fb"
  printf '#!/usr/bin/env bash\nexit 9\n' >"$fb/python3"; chmod +x "$fb/python3"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$fb/python";  chmod +x "$fb/python"
  PATH="$fb:$PATH"
  run resolve_install_cmd "python3 -m pip install --user --upgrade demo"
  [ "$output" = "python -m pip install --user --upgrade demo" ]
}

# --- detect_install_tool: python varianti ----------------------------------
@test "detect_install_tool: 'python -m pip' buyrug'i uchun python qaytaradi" {
  run detect_install_tool "python -m pip install --user demo"
  [ "$output" = "python" ]
}

# --- record_bin_dir / locate_binary ----------------------------------------
@test "record_bin_dir: papkani keshga bir marta yozadi (takrorsiz)" {
  mkdir -p "$HOME/tooldir"
  record_bin_dir "$HOME/tooldir"
  record_bin_dir "$HOME/tooldir"
  run grep -cxF "$HOME/tooldir" "$BIN_DIR_CACHE"
  [ "$output" = "1" ]
}

@test "locate_binary: ~/.<binary>/bin dan topadi, PATH'ga qo'shadi va keshlaydi" {
  mkdir -p "$HOME/.zeta/bin"
  printf '#!/usr/bin/env bash\necho zeta\n' >"$HOME/.zeta/bin/zeta"
  chmod +x "$HOME/.zeta/bin/zeta"
  run command -v zeta
  [ "$status" -ne 0 ]                       # oldin PATH'da yo'q
  locate_binary zeta
  run command -v zeta
  [ "$status" -eq 0 ]                       # endi topiladi
  grep -qxF "$HOME/.zeta/bin" "$BIN_DIR_CACHE"
}

@test "locate_binary: hech qayerda topilmasa 1 qaytaradi" {
  run locate_binary "definitely-not-real-xyz"
  [ "$status" -ne 0 ]
}

@test "augment_tool_path: keshdagi papkalar keyingi sessiyada PATH'ga qo'shiladi" {
  mkdir -p "$HOME/custombin" "$(dirname "$BIN_DIR_CACHE")"
  printf '%s\n' "$HOME/custombin" >"$BIN_DIR_CACHE"
  augment_tool_path
  [[ ":$PATH:" == *":$HOME/custombin:"* ]]
}

# --- ensure_installed: topilgan binar uchun qayta o'rnatish so'ralmaydi ----
@test "ensure_installed: binar ma'lum papkada bo'lsa qayta o'rnatish SO'RALMAYDI" {
  mkdir -p "$HOME/.ybin/bin"
  printf '#!/usr/bin/env bash\n' >"$HOME/.ybin/bin/ybin"
  chmod +x "$HOME/.ybin/bin/ybin"
  run ensure_installed "Ybin Agent" "ybin" "npm install -g ybin@latest"
  [ "$status" -eq 0 ]
  [[ "$output" != *"o'rnatilsinmi"* ]]      # o'rnatish prompti chiqmagan
}

# --- maybe_autoupdate_agent: curl/wget chiqarildi ---------------------------
@test "maybe_autoupdate_agent: curl o'rnatuvchini avtomatik QAYTA ishga tushirmaydi" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  RAN_LOG="$BATS_TEST_TMPDIR/ran.log"; : >"$RAN_LOG"
  spin_run() { printf 'RAN:%s\n' "$2" >>"$RAN_LOG"; return 0; }
  augment_tool_path() { :; }
  run maybe_autoupdate_agent "Curly" "bash" 'bash -c "$(curl -fsSL https://example.com/i.sh)"'
  [ "$status" -eq 0 ]
  run grep -c "RAN:" "$RAN_LOG"
  [ "$output" = "0" ]
}
