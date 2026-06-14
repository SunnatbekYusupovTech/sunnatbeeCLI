#!/usr/bin/env bash
# tests/test_helper.bash — barcha .bats fayllar uchun umumiy yordamchilar.
#
# Yuklash: har bir test faylida `load test_helper`.

# --- Yo'llar --------------------------------------------------------------
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
PROJECT_ROOT="$(cd "$TESTS_DIR/.." >/dev/null 2>&1 && pwd)"
export TESTS_DIR PROJECT_ROOT
export SELECTOR="$PROJECT_ROOT/bin/ai-selector.sh"
export COMMON="$PROJECT_ROOT/lib/common.sh"
export FIXTURE_CONFIG="$TESTS_DIR/fixtures/agents.conf"

# --- Deterministik muhit --------------------------------------------------
# Rang, animatsiya va avto-yangilanishni o'chiramiz; HOME/state'ni har bir test
# uchun alohida vaqtinchalik papkaga olamiz — real foydalanuvchi fayllariga tegmaymiz.
setup_env() {
  export NO_COLOR=1            # ranglarni o'chiradi → chiqish deterministik
  export CI=1                  # animatsiya + auto_update'ni o'chiradi
  export AI_NO_ANIM=1
  export AIDEVIX_NO_AUTOUPDATE=1
  export LC_ALL=C              # UTF-8 logikasini deterministik qiladi
  export HOME="${BATS_TEST_TMPDIR:-/tmp}/home"
  export XDG_STATE_HOME="${BATS_TEST_TMPDIR:-/tmp}/state"
  export XDG_CONFIG_HOME="${BATS_TEST_TMPDIR:-/tmp}/config"
  mkdir -p "$HOME" "$XDG_STATE_HOME" "$XDG_CONFIG_HOME"
  # Test agentlaridagi kalitlar muhitda BO'LMASLIGI kerak (should_open_login_link).
  unset ALPHA_API_KEY ANTHROPIC_API_KEY OPENAI_API_KEY GEMINI_API_KEY 2>/dev/null || true
}

# load_selector — ai-selector.sh'ni source qiladi (funksiyalarni test qilish uchun).
# Skript `set -Eeuo pipefail` bilan keladi; testda errexit/nounset/ERR-tutqich
# halal qilmasligi uchun ularni o'chiramiz (funksiya `return 1` qilsa ham test
# yiqilmasligi kerak — bu kutilgan natija bo'lishi mumkin).
load_selector() {
  # shellcheck disable=SC1090
  source "$SELECTOR"
  set +eEu
  set +o pipefail
  trap - ERR
  trap - EXIT
}

# load_common — faqat lib/common.sh'ni source qiladi.
load_common() {
  # shellcheck disable=SC1090
  source "$COMMON"
  set +eEu
  set +o pipefail
  trap - ERR 2>/dev/null || true
}

# run_cli — ai-selector.sh'ni alohida jarayonda (qora-quti) ishga tushiradi.
run_cli() {
  run bash "$SELECTOR" "$@"
}
