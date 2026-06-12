cd /D %~dp0
mkdir llama
cd llama

curl -o llama.zip -L https://github.com/ggml-org/llama.cpp/releases/download/b9585/llama-b9585-bin-win-cuda-13.3-x64.zip
curl -o llama-dll.zip -L https://github.com/ggml-org/llama.cpp/releases/download/b9585/cudart-llama-bin-win-cuda-13.3-x64.zip
tar -xf llama.zip
tar -xf llama-dll.zip
del llama.zip
del llama-dll.zip

mkdir transformers
mkdir models

echo llama-server -c 131072 -m models\model.gguf -mm models\mmproj.gguf --tools all -rea off --reasoning-budget ^0> run.bat

git clone https://github.com/emiltervo/web-search-mcp --depth=1
cd web-search-mcp
uv sync
cd ..
(
echo cd web-search-mcp
echo uv run main.py
)> run-web-search-mcp.bat

uv venv -p 3.11
call .venv\Scripts\activate
uv pip install open-webui

hf download --local-dir transformers\cl-nagoya--ruri-v3-310m cl-nagoya/ruri-v3-310m
hf download --local-dir transformers\cl-nagoya--ruri-v3-reranker-310m cl-nagoya/ruri-v3-reranker-310m

(
echo start http://127.0.0.1:8081
echo start llama-server -c 131072 --no-ui --models-dir models --models-max 1 -rea off
echo set WEBUI_ADMIN_EMAIL=root@example.com
echo set WEBUI_ADMIN_PASSWORD=root
echo set ENABLE_OLLAMA_API=false
echo set OPENAI_API_BASE_URL=http://127.0.0.1:8080/v1
echo set RAG_EMBEDDING_MODEL=transformers\cl-nagoya--ruri-v3-310m
echo set RAG_TOP_K=12
echo set RAG_TOP_K_RERANKER=6
echo set ENABLE_RAG_HYBRID_SEARCH=true
echo set RAG_RERANKING_MODEL=transformers\cl-nagoya--ruri-v3-reranker-310m
echo call .venv\Scripts\activate
echo open-webui serve --host 127.0.0.1 --port 8081
)> run-open-webui.bat
