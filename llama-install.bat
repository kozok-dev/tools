cd /D %~dp0
mkdir llama
cd llama

curl -o llama.zip -L https://github.com/ggml-org/llama.cpp/releases/download/b7964/llama-b7964-bin-win-cuda-13.1-x64.zip
curl -o llama-dll.zip -L https://github.com/ggml-org/llama.cpp/releases/download/b7964/cudart-llama-bin-win-cuda-13.1-x64.zip
tar -xf llama.zip
tar -xf llama-dll.zip
del llama.zip
del llama-dll.zip

mklink /D transformers ..\ComfyUI\transformers
mklink /D models ..\ComfyUI\models\llm

uv venv -p 3.11
call .venv\Scripts\activate
uv pip install open-webui

hf download --local-dir transformers\cl-nagoya--ruri-v3-310m cl-nagoya/ruri-v3-310m
hf download --local-dir transformers\cl-nagoya--ruri-v3-reranker-310m cl-nagoya/ruri-v3-reranker-310m

(
echo start http://127.0.0.1:8080
echo start llama-server -c 8192 --port 8081 --no-webui --models-max 1 --models-dir models
echo set WEBUI_ADMIN_EMAIL=root@example.com
echo set WEBUI_ADMIN_PASSWORD=root
echo set ENABLE_OLLAMA_API=false
echo set OPENAI_API_BASE_URL=http://127.0.0.1:8081/v1
echo set RAG_EMBEDDING_MODEL=transformers\cl-nagoya--ruri-v3-310m
echo set RAG_TOP_K=12
echo set RAG_TOP_K_RERANKER=6
echo set ENABLE_RAG_HYBRID_SEARCH=true
echo set RAG_RERANKING_MODEL=transformers\cl-nagoya--ruri-v3-reranker-310m
echo call .venv\Scripts\activate
echo open-webui serve --host 127.0.0.1
)> run.bat
