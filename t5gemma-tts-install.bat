cd /D %~dp0
git clone https://github.com/robustonian/T5Gemma-TTS --depth=1
cd T5Gemma-TTS

mklink /D transformers ..\ComfyUI\transformers

uv venv -p 3.13
call .venv\Scripts\activate
uv pip install numba llvmlite
uv pip install -r requirements.txt
uv pip install -U "torch<2.10" torchaudio --torch-backend cu130

set /P HF_TOKEN=Hugging Face token:
if not "%HF_TOKEN%" == "" (
  hf auth login --token %HF_TOKEN%
  set HF_TOKEN=
  hf download --local-dir transformers\Aratako--T5Gemma-TTS-2b-2b Aratako/T5Gemma-TTS-2b-2b --include *.json *.py *.safetensors
  hf download --local-dir transformers\google--t5gemma-2b-2b-ul2 google/t5gemma-2b-2b-ul2 --include special_tokens_map.json tokenizer.*
  hf auth logout
)
hf download --local-dir transformers\NandemoGHS--Anime-XCodec2-44.1kHz-v2 NandemoGHS/Anime-XCodec2-44.1kHz-v2 --include *.json *.safetensors
hf download --local-dir transformers\openai--whisper-large-v3-turbo openai/whisper-large-v3-turbo
hf download --local-dir transformers\facebook--w2v-bert-2.0 facebook/w2v-bert-2.0 --exclude *.pt

(
echo start http://127.0.0.1:7860
echo .venv\Scripts\python inference_gradio.py --model_dir transformers\Aratako--T5Gemma-TTS-2b-2b --xcodec2_model_name transformers\NandemoGHS--Anime-XCodec2-44.1kHz-v2
)>run.bat

rem inference_tts_utils.py
rem - model_name = "openai/whisper-large-v3-turbo"
rem + model_name = "transformers\\openai--whisper-large-v3-turbo"

rem .venv\Lib\site-packages\xcodec2\modeling_xcodec2.py
rem - "facebook/w2v-bert-2.0",
rem + "transformers\\facebook--w2v-bert-2.0",
rem - feature_extractor = AutoFeatureExtractor.from_pretrained("facebook/w2v-bert-2.0")
rem + feature_extractor = AutoFeatureExtractor.from_pretrained("transformers\\facebook--w2v-bert-2.0")

rem data\tokenizer.py
rem - ckpt_path = hf_hub_download(repo_id=model_id, filename="model.safetensors")
rem + ckpt_path = model_id + "\\model.safetensors"

rem transformers\Aratako--T5Gemma-TTS-2b-2b\config.json
rem - "t5gemma_model_name": "google/t5gemma-2b-2b-ul2",
rem + "t5gemma_model_name": "transformers\\google--t5gemma-2b-2b-ul2",
rem - "text_tokenizer_name": "google/t5gemma-2b-2b-ul2",
rem + "text_tokenizer_name": "transformers\\google--t5gemma-2b-2b-ul2",
