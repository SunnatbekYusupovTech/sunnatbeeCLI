@echo off
REM Aidevix CLI — Windows (cmd.exe / PowerShell) uchun wrapper.
REM Git Bash'ni PATH'dan yoki odatiy o'rnatish joylaridan topadi.
setlocal
set "AI_SH=%~dp0ai-selector.sh"

REM 1) PATH'dagi bash
for %%I in (bash.exe) do if not "%%~$PATH:I"=="" (
  bash "%AI_SH%" %*
  exit /b %errorlevel%
)

REM 2) Git for Windows odatiy joylari
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
