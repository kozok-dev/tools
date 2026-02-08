cd /D %~dp0
setlocal enabledelayedexpansion

git clone https://github.com/Comfy-Org/ComfyUI --depth=1
cd ComfyUI

uv venv -p 3.13
call .venv\Scripts\activate
uv pip install "torch<2.10" torchvision torchaudio --torch-backend cu130
uv pip install "triton-windows<3.6"
uv pip install https://github.com/woct0rdho/SageAttention/releases/download/v2.2.0-windows.post4/sageattention-2.2.0+cu130torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl
uv pip install -r requirements.txt
.venv\Scripts\python -m ensurepip

call :hard_link %APPDATA%\uv\python\cpython-3.13.11-windows-x86_64-none\include .venv\Scripts\include
call :hard_link %APPDATA%\uv\python\cpython-3.13.11-windows-x86_64-none\libs .venv\Scripts\libs
rmdir /Q /S %USERPROFILE%\.triton\cache
rmdir /Q /S %TEMP%\torchinductor_%USERNAME%

echo .venv\Scripts\python main.py --auto-launch --fast fp16_accumulation cublas_ops autotune --use-sage-attention> run.bat

cd custom_nodes
git clone https://github.com/Comfy-Org/ComfyUI-Manager --depth=1

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

rem "FETCH ComfyRegistry Data: x/x" will be displayed, so wait until "[ComfyUI-Manager] All startup tasks have been completed." is displayed
rem After the first run of run.bat, set use_uv = True in user\__manager\config.ini
rem Launch ComfyUI and install the following custom nodes:
rem - ComfyUI-WanVideoWrapper [1.3.9]
rem - ComfyUI-Crystools
rem - ComfyUI-WD14-Tagger
rem - ComfyUI_essentials [nightly]
rem Install any additional custom nodes required by each workflow
