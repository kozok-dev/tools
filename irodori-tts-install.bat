cd /D %~dp0
git clone https://github.com/Aratako/Irodori-TTS --depth=1
cd Irodori-TTS

mkdir transformers

call :replace pyproject.toml \s*"""silentcipher.*
call :replace gradio_app.py Aratako/Irodori-TTS-500M-v3 transformers\\Aratako--Irodori-TTS-500M-v3\\model.safetensors
call :replace gradio_app_voicedesign.py Aratako/Irodori-TTS-600M-v3-VoiceDesign transformers\\Aratako--Irodori-TTS-600M-v3-VoiceDesign\\model.safetensors
call :replace irodori_tts\inference_runtime.py "repo_id=model_cfg.text_tokenizer_repo" "repo_id=""transformers\\llm-jp--llm-jp-3-150m""""
call :replace irodori_tts\inference_runtime.py "repo_id=model_cfg.caption_tokenizer_repo_resolved" "repo_id=""transformers\\llm-jp--llm-jp-3-150m""""
call :replace irodori_tts\inference_runtime.py "repo_id=key.codec_repo" "repo_id=""transformers\\Aratako--Semantic-DACVAE-Japanese-32dim\\weights.pth""""

uv sync --extra cu128

uvx hf download --local-dir transformers\Aratako--Irodori-TTS-500M-v2 Aratako/Irodori-TTS-500M-v2 --include *.safetensors
uvx hf download --local-dir transformers\Aratako--Irodori-TTS-500M-v3 Aratako/Irodori-TTS-500M-v3 --include *.safetensors
uvx hf download --local-dir transformers\Aratako--Irodori-TTS-600M-v3-VoiceDesign Aratako/Irodori-TTS-600M-v3-VoiceDesign --include *.safetensors
uvx hf download --local-dir transformers\Aratako--Semantic-DACVAE-Japanese-32dim Aratako/Semantic-DACVAE-Japanese-32dim --include *.pth
uvx hf download --local-dir transformers\llm-jp--llm-jp-3-150m llm-jp/llm-jp-3-150m --include special_tokens_map.json tokenizer*

echo uv run --no-sync gradio_app.py> run.bat
echo uv run --no-sync gradio_app_voicedesign.py> run-voicedesign.bat

exit /B

:replace
powershell -Command "[IO.File]::WriteAllText('%~1', ([IO.File]::ReadAllText('%~1') -replace '%~2', '%~3'))"
exit /B
