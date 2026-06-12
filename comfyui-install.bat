cd /D %~dp0
setlocal enabledelayedexpansion

git clone https://github.com/Comfy-Org/ComfyUI --depth=1
cd ComfyUI

uv venv -p 3.13
call .venv\Scripts\activate
uv pip install torch torchvision torchaudio --torch-backend cu130
uv pip install triton-windows
uv pip install https://github.com/woct0rdho/SageAttention/releases/download/v2.2.0-windows.post4/sageattention-2.2.0+cu130torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl
uv pip install -r requirements.txt

call :hard_link %APPDATA%\uv\python\cpython-3.13.11-windows-x86_64-none\include .venv\Scripts\include
call :hard_link %APPDATA%\uv\python\cpython-3.13.11-windows-x86_64-none\libs .venv\Scripts\libs
rmdir /Q /S %USERPROFILE%\.triton\cache
rmdir /Q /S %TEMP%\torchinductor_%USERNAME%

cd custom_nodes
git clone https://github.com/Comfy-Org/ComfyUI-Manager --depth=1
git clone https://github.com/huchukato/ComfyUI-Upscaler-TensorRT-Auto --depth=1
git clone https://github.com/huchukato/ComfyUI-RIFE-TensorRT-Auto --depth=1
cd ..
python -m ensurepip
uv pip install tensorrt==10.15.1.29
uv pip install -r custom_nodes\ComfyUI-Upscaler-TensorRT-Auto\requirements.txt
uv pip install -r custom_nodes\ComfyUI-Upscaler-TensorRT-Auto\requirements_cu13.txt
uv pip install -r custom_nodes\ComfyUI-RIFE-TensorRT-Auto\requirements.txt
uv pip install -r custom_nodes\ComfyUI-RIFE-TensorRT-Auto\requirements_cu13.txt

mkdir .venv\Lib\x64\vc17
powershell -Command "Start-Process cmd '/C cd """%CD%\.venv\Lib\x64\vc17""" & mklink /D bin ..\..\site-packages\torch\lib' -Verb RunAs"

echo .venv\Scripts\python main.py --auto-launch --fast fp16_accumulation cublas_ops autotune --use-sage-attention> run.bat

exit /B

:hard_link
@echo off
for /R %1 %%F in (*) do (
  set TARGET=%%F
  set TARGET=%2!TARGET:%1=!
  mkdir !TARGET!\..>nul 2>&1
  mklink /H !TARGET! %%F>nul 2>&1
)
@echo on & exit /B
