#!/usr/bin/env bats
# completion.bats — `aidevix` bash/zsh avtomatik to'ldirilishi uchun testlar.
#
# Asosiy regressiya: completion AGENT NOMLARINI ham taklif qilishi kerak.
# Avval u faqat foydalanuvchi configini o'qiyotgan edi; o'rnatuvchi esa uni
# bo'sh yaratadi (asosiy ro'yxat repo config'da) — natijada `aidevix <TAB>`
# faqat flag'larni ko'rsatardi. Endi repo config ham hisobga olinadi.

load test_helper

export COMPLETION="$PROJECT_ROOT/completions/aidevix.bash"

setup() {
  setup_env
}

# complete_for — completion'ni alohida bash jarayonida ishga tushirib,
# COMPREPLY'ni bo'sh-bilan-ajratilgan satr sifatida chiqaradi.
#   complete_for <joriy-so'z> [AI_PULT_CONFIG qiymati]
complete_for() {
  local cur="$1" pultcfg="${2:-}"
  AI_PULT_CONFIG="$pultcfg" bash -c '
    source "'"$COMPLETION"'"
    COMP_WORDS=(aidevix "'"$1"'"); COMP_CWORD=1
    _ai_complete
    printf "%s\n" "${COMPREPLY[*]}"
  ' _ "$cur"
}

@test "completion: bo'sh foydalanuvchi config bilan ham repo agentlarini taklif qiladi" {
  # O'rnatuvchi yaratadigan bo'sh (faqat izohli) foydalanuvchi config.
  mkdir -p "$HOME/.config/ai-cli"
  printf '# faqat izohlar\n' > "$HOME/.config/ai-cli/agents.conf"

  run complete_for ""
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude"* ]]
  [[ "$output" == *"gemini"* ]]
}

@test "completion: flag'larni doimo taklif qiladi" {
  run complete_for "--"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--list"* ]]
  [[ "$output" == *"--doctor"* ]]
}

@test "completion: prefiks bo'yicha filtrlaydi (cl → claude, cline)" {
  run complete_for "cl"
  [ "$status" -eq 0 ]
  [[ "$output" == *"claude"* ]]
}

@test "completion: AI_PULT_CONFIG berilsa faqat o'sha configdan nom oladi" {
  run complete_for "" "$FIXTURE_CONFIG"
  [ "$status" -eq 0 ]
  # Fixture binarlari ko'rinadi...
  [[ "$output" == *"charliebin"* ]]
  [[ "$output" == *"nibin"* ]]
  # ...repo agentlari esa YO'Q (faqat ko'rsatilgan config ishlatiladi).
  [[ "$output" != *"gemini"* ]]
}

@test "completion: birinchidan keyingi argument to'ldirilmaydi" {
  output="$(AI_PULT_CONFIG="" bash -c '
    source "'"$COMPLETION"'"
    COMP_WORDS=(aidevix claude ""); COMP_CWORD=2
    _ai_complete
    printf "%s\n" "${COMPREPLY[*]}"
  ')"
  [ -z "$output" ]
}
