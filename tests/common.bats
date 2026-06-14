#!/usr/bin/env bats
# common.bats — lib/common.sh yordamchi funksiyalari uchun testlar.

load test_helper

# `run -127` kabi flaglar uchun (BW02 ogohlantirishini ham bartaraf etadi).
bats_require_minimum_version 1.5.0

setup() {
  setup_env
  load_common
}

# --- die ------------------------------------------------------------------
@test "die: berilgan exit-code bilan to'xtaydi va xabar beradi" {
  run bash -c 'source "'"$COMMON"'"; die 3 "portlash"'
  [ "$status" -eq 3 ]
  [[ "$output" == *"portlash"* ]]
}

# --- require_cmd ----------------------------------------------------------
@test "require_cmd: mavjud buyruq uchun muvaffaqiyat (exit 0)" {
  run bash -c 'source "'"$COMMON"'"; require_cmd bash'
  [ "$status" -eq 0 ]
}

@test "require_cmd: mavjud bo'lmagan buyruq uchun die (exit 127)" {
  run -127 bash -c 'source "'"$COMMON"'"; require_cmd mavjud-emas-xyz123'
  [[ "$output" == *"topilmadi"* ]]
}

@test "require_cmd: ko'rsatma (hint) berilsa xabarda ko'rinadi" {
  run -127 bash -c 'source "'"$COMMON"'"; require_cmd mavjud-emas-xyz123 "npm install -g foo"'
  [[ "$output" == *"npm install -g foo"* ]]
}

# --- hr -------------------------------------------------------------------
@test "hr: so'ralgan uzunlikda chiziq qaytaradi (ASCII rejim)" {
  # LC_ALL=C → UI_UTF8=0 → '-' ishlatiladi (1 bayt = 1 belgi).
  run bash -c 'export LC_ALL=C; source "'"$COMMON"'"; hr 7'
  [ "$status" -eq 0 ]
  [ "${#output}" -eq 7 ]
  [ "$output" = "-------" ]
}

# --- tool_hint ------------------------------------------------------------
@test "tool_hint: npm uchun Node.js'ni tavsiya qiladi" {
  run tool_hint npm
  [[ "$output" == *"Node.js"* ]]
}

@test "tool_hint: noma'lum dastur uchun nomni qaytaradi" {
  run tool_hint zibberish-tool
  [[ "$output" == *"zibberish-tool"* ]]
}

# --- panel ----------------------------------------------------------------
@test "panel: sarlavha va qatorlarni chiqaradi" {
  run bash -c 'source "'"$COMMON"'"; panel "Sarlavha" "birinchi qator" "ikkinchi qator"'
  [ "$status" -eq 0 ]
  [[ "$output" == *"Sarlavha"* ]]
  [[ "$output" == *"birinchi qator"* ]]
  [[ "$output" == *"ikkinchi qator"* ]]
}
