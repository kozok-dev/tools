cd /D %~dp0
git clone https://github.com/hiroki-abe-58/Qwen3-TTS-JP --depth=1
cd Qwen3-TTS-JP

mkdir transformers

uv venv -p 3.13
call .venv\Scripts\activate
uv pip install torch torchaudio --torch-backend cu130
uv pip install -e .
uv pip install faster-whisper
uv pip install https://huggingface.co/ussoewwin/Flash-Attention-2_for_Windows/resolve/main/flash_attn-2.9.1+cu132torch2.12.0cxx11abiTRUE-cp313-cp313-win_amd64.whl

powershell -Command "Start-Process cmd '/C cd """%CD%\.venv\Lib\site-packages\torch\lib""" & mklink cublas64_12.dll cublas64_13.dll' -Verb RunAs"

hf download --local-dir transformers\Qwen--Qwen3-TTS-12Hz-1.7B-VoiceDesign Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign
hf download --local-dir transformers\Qwen--Qwen3-TTS-12Hz-1.7B-CustomVoice Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice
hf download --local-dir transformers\Qwen--Qwen3-TTS-12Hz-1.7B-Base Qwen/Qwen3-TTS-12Hz-1.7B-Base
hf download --local-dir transformers\Systran--faster-whisper-large-v3 Systran/faster-whisper-large-v3

(
echo call .venv\Scripts\activate
echo qwen-tts-demo transformers\Qwen--Qwen3-TTS-12Hz-1.7B-VoiceDesign --ip 127.0.0.1
)> run-voice-design.bat
(
echo call .venv\Scripts\activate
echo qwen-tts-demo transformers\Qwen--Qwen3-TTS-12Hz-1.7B-CustomVoice --ip 127.0.0.1
)> run-custom-voice.bat
(
echo call .venv\Scripts\activate
echo qwen-tts-demo transformers\Qwen--Qwen3-TTS-12Hz-1.7B-Base --ip 127.0.0.1
)> run-base.bat

curl -o ffmpeg.zip -L https://github.com/GyanD/codexffmpeg/releases/download/2026-06-01-git-bf608f16fd/ffmpeg-2026-06-01-git-bf608f16fd-essentials_build.zip
tar -xf ffmpeg.zip
cd ffmpeg-2026-06-01-git-bf608f16fd-essentials_build\bin
move /Y *.exe ..\..\.venv\Scripts
cd ..\..
rmdir /S /Q ffmpeg-2026-06-01-git-bf608f16fd-essentials_build
del ffmpeg.zip

call :replace qwen_tts\ui\components\voice_clone_tab.py large-v3 transformers\\Systran--faster-whisper-large-v3
call :replace qwen_tts\ui\components\voice_clone_tab.py "value=""small""" "value="""transformers\\Systran--faster-whisper-large-v3"""

exit /B

:replace
powershell -Command "[IO.File]::WriteAllText('%~1', ([IO.File]::ReadAllText('%~1') -replace '%~2', '%~3'))"
exit /B
