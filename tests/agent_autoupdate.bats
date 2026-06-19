#!/usr/bin/env bats
# agent_autoupdate.bats — o'rnatilgan agentni eng so'nggi versiyaga avtomatik
# yangilash (maybe_autoupdate_agent) mantig'i + agents.conf "latest" validatsiyasi.
#
# Tarmoqqa yoki haqiqiy o'rnatuvchiga chiqmaydi: spin_run/augment_tool_path
# stub qilinadi, binar sifatida hamisha mavjud "bash" ishlatiladi.

load test_helper

setup() {
  setup_env
  load_selector
  # Haqiqiy o'rnatish/yangilashni chaqirmaymiz — spin_run'ni stub qilamiz.
  RAN_LOG="$BATS_TEST_TMPDIR/ran"
  : >"$RAN_LOG"
  spin_run() { printf 'RAN:%s\n' "$2" >>"$RAN_LOG"; return 0; }
  augment_tool_path() { :; }
}

# safe nom: "Demo Agent" → "Demo_Agent" stamp fayli
stamp_for() { printf '%s/%s' "$AGENT_UPDATE_DIR" "$(printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '_')"; }

# --- env qo'riqchilari -----------------------------------------------------
@test "maybe_autoupdate_agent: AIDEVIX_NO_AUTOUPDATE bo'lsa hech narsa qilmaydi" {
  export AIDEVIX_NO_AUTOUPDATE=1
  run maybe_autoupdate_agent "Demo Agent" "bash" "npm install -g demo@latest"
  [ "$status" -eq 0 ]
  [ ! -s "$RAN_LOG" ]
  [ ! -e "$(stamp_for "Demo Agent")" ]
}

@test "maybe_autoupdate_agent: CI bo'lsa hech narsa qilmaydi" {
  unset AIDEVIX_NO_AUTOUPDATE
  export CI=1
  run maybe_autoupdate_agent "Demo Agent" "bash" "npm install -g demo@latest"
  [ "$status" -eq 0 ]
  [ ! -s "$RAN_LOG" ]
}

# --- o'rnatilmagan / bo'sh install -----------------------------------------
@test "maybe_autoupdate_agent: binar o'rnatilmagan bo'lsa o'tkazib yuboradi" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  run maybe_autoupdate_agent "Demo Agent" "definitely_missing_xyz_123" "npm install -g demo@latest"
  [ "$status" -eq 0 ]
  [ ! -s "$RAN_LOG" ]
  [ ! -e "$(stamp_for "Demo Agent")" ]
}

@test "maybe_autoupdate_agent: install bo'sh bo'lsa o'tkazib yuboradi" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  run maybe_autoupdate_agent "Demo Agent" "bash" ""
  [ "$status" -eq 0 ]
  [ ! -s "$RAN_LOG" ]
}

# --- faqat "latest"ga olib keladigan o'rnatuvchilar ------------------------
@test "maybe_autoupdate_agent: @latest/--upgrade'siz install o'tkazib yuboriladi" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  run maybe_autoupdate_agent "Brewy" "bash" "brew install gh"
  [ "$status" -eq 0 ]
  [ ! -s "$RAN_LOG" ]
  [ ! -e "$(stamp_for "Brewy")" ]
}

# --- throttle --------------------------------------------------------------
@test "maybe_autoupdate_agent: yangi stamp bo'lsa yangilamaydi (throttle)" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  mkdir -p "$AGENT_UPDATE_DIR"
  printf '%s\n' "$(date +%s)" >"$(stamp_for "Demo Agent")"
  run maybe_autoupdate_agent "Demo Agent" "bash" "npm install -g demo@latest"
  [ "$status" -eq 0 ]
  [ ! -s "$RAN_LOG" ]
}

# --- haqiqiy yangilash yo'li -----------------------------------------------
@test "maybe_autoupdate_agent: eskirgan/yangi stamp'da yangilaydi va stamp yozadi" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  maybe_autoupdate_agent "Demo Agent" "bash" "npm install -g demo@latest"
  [ -s "$RAN_LOG" ]
  grep -q "RAN:npm install -g demo@latest" "$RAN_LOG"
  [ -e "$(stamp_for "Demo Agent")" ]
}

@test "maybe_autoupdate_agent: eski stamp (interval o'tgan) → yangilaydi" {
  unset AIDEVIX_NO_AUTOUPDATE CI
  export AIDEVIX_UPDATE_INTERVAL=1
  mkdir -p "$AGENT_UPDATE_DIR"
  printf '%s\n' "1" >"$(stamp_for "Demo Agent")"   # 1970 — juda eski
  maybe_autoupdate_agent "Demo Agent" "bash" "pip install --upgrade demo"
  grep -q "RAN:pip install --upgrade demo" "$RAN_LOG"
}

# --- agents.conf "latest" validatsiyasi ------------------------------------
@test "agents.conf: barcha 'npm install' qatorlari @latest ishlatadi" {
  run bash -c '
    fail=0
    while IFS= read -r line; do
      case "$line" in \#*|"") continue ;; esac
      inst="$(printf "%s" "$line" | cut -d"|" -f4)"
      case "$inst" in
        *"npm install"*) case "$inst" in *@latest*) : ;; *) echo "NO-LATEST: $inst"; fail=1 ;; esac ;;
      esac
    done < "'"$PROJECT_ROOT"'/config/agents.conf"
    exit $fail
  '
  [ "$status" -eq 0 ]
}

@test "agents.conf: barcha 'pip install' qatorlari --upgrade ishlatadi" {
  run bash -c '
    fail=0
    while IFS= read -r line; do
      case "$line" in \#*|"") continue ;; esac
      inst="$(printf "%s" "$line" | cut -d"|" -f4)"
      case "$inst" in
        *"pip install"*) case "$inst" in *--upgrade*) : ;; *) echo "NO-UPGRADE: $inst"; fail=1 ;; esac ;;
      esac
    done < "'"$PROJECT_ROOT"'/config/agents.conf"
    exit $fail
  '
  [ "$status" -eq 0 ]
}
