cd /D %~dp0
git clone https://github.com/hiroki-abe-58/Qwen3-TTS-JP --depth=1
cd Qwen3-TTS-JP

mklink /D transformers ..\ComfyUI\transformers

uv venv -p 3.13
call .venv\Scripts\activate
uv pip install -U "torch<2.10" torchaudio --torch-backend cu128
uv pip install -e .
uv pip install faster-whisper

hf download --local-dir transformers\Qwen--Qwen3-TTS-12Hz-1.7B-VoiceDesign Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign
hf download --local-dir transformers\Qwen--Qwen3-TTS-12Hz-1.7B-CustomVoice Qwen/Qwen3-TTS-12Hz-1.7B-CustomVoice
hf download --local-dir transformers\Qwen--Qwen3-TTS-12Hz-1.7B-Base Qwen/Qwen3-TTS-12Hz-1.7B-Base
hf download --local-dir transformers\Systran--faster-whisper-large-v3 Systran/faster-whisper-large-v3

(
echo call .venv\Scripts\activate
echo qwen-tts-demo transformers\Qwen--Qwen3-TTS-12Hz-1.7B-VoiceDesign --ip 127.0.0.1 --no-flash-attn
)> run-voice-design.bat
(
echo call .venv\Scripts\activate
echo qwen-tts-demo transformers\Qwen--Qwen3-TTS-12Hz-1.7B-CustomVoice --ip 127.0.0.1 --no-flash-attn
)> run-custom-voice.bat
(
echo call .venv\Scripts\activate
echo qwen-tts-demo transformers\Qwen--Qwen3-TTS-12Hz-1.7B-Base --ip 127.0.0.1 --no-flash-attn
)> run-base.bat

curl -o ffmpeg.zip -L https://github.com/GyanD/codexffmpeg/releases/download/2026-01-22-git-4561fc5e48/ffmpeg-2026-01-22-git-4561fc5e48-essentials_build.zip
tar -xf ffmpeg.zip
cd ffmpeg-2026-01-22-git-4561fc5e48-essentials_build\bin
move /Y *.exe ..\..\.venv\Scripts
cd ..\..
rmdir /S /Q ffmpeg-2026-01-22-git-4561fc5e48-essentials_build
del ffmpeg.zip

rem qwen_tts\cli\demo.py
rem   "large-v3",
rem + "transformers\\Systran--faster-whisper-large-v3",
rem - value="small",
rem + value="transformers\\Systran--faster-whisper-large-v3",
rem - value="small",
rem + value="transformers\\Systran--faster-whisper-large-v3",
