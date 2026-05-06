@echo off
setlocal

set "SCRIPT=%USERPROFILE%\.codex\skills\.system\imagegen\scripts\image_gen.py"
set "INPUT=%~dp0CICC1003618_初赛_PPT图片生成_prompts.jsonl"
set "OUT_DIR=%~dp0PPT图片"

if not exist "%SCRIPT%" (
  echo Missing image generation script: %SCRIPT%
  exit /b 1
)

if "%OPENAI_API_KEY%"=="" (
  echo OPENAI_API_KEY is not set. Set it before running GPT Image 2 generation.
  exit /b 1
)

python "%SCRIPT%" generate-batch ^
  --model gpt-image-2 ^
  --input "%INPUT%" ^
  --out-dir "%OUT_DIR%" ^
  --size 1536x1024 ^
  --quality high ^
  --output-format png ^
  --concurrency 2

exit /b %ERRORLEVEL%
