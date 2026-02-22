import gc
import torch
import gradio as gr
from huggingface_hub import snapshot_download
from transformers import AutoProcessor, AutoModelForImageTextToText
from transformers import LightOnOcrProcessor, LightOnOcrForConditionalGeneration

active_processer = None
active_model = None
active_model_index = None
active_device = None

def run_lightonai__LightOnOCR_2_1B(image, model_index, device):
    load_model(LightOnOcrProcessor, LightOnOcrForConditionalGeneration, model_index, device)

    inputs = active_processer.apply_chat_template(
        [{
            "role": "user",
            "content": [
                {"type": "image", "image": image},
            ]
        }],
        add_generation_prompt=True,
        tokenize=True,
        return_tensors="pt",
        return_dict=True,
    ).to(active_model.device)

    outputs = active_model.generate(**inputs, max_new_tokens=1024)
    return active_processer.decode(outputs[0][inputs["input_ids"].shape[-1]:-1])

def run_PaddlePaddle__PaddleOCR_VL_1_5(image, model_index, device):
    load_model(AutoProcessor, AutoModelForImageTextToText, model_index, device)

    inputs = active_processer.apply_chat_template(
        [{
            "role": "user",
            "content": [
                {"type": "image", "image": image},
                {"type": "text", "text": "OCR:"},
            ],
        }],
        add_generation_prompt=True,
        tokenize=True,
        return_tensors="pt",
        return_dict=True,
    ).to(active_model.device)

    outputs = active_model.generate(**inputs, max_new_tokens=512)
    return active_processer.decode(outputs[0][inputs["input_ids"].shape[-1]:-1])

def run_zai_org__GLM_OCR(image, model_index, device):
    load_model(AutoProcessor, AutoModelForImageTextToText, model_index, device)

    inputs = active_processer.apply_chat_template(
        [{
            "role": "user",
            "content": [
                {"type": "image", "image": image},
                {"type": "text", "text": "Text Recognition:"},
            ],
        }],
        add_generation_prompt=True,
        tokenize=True,
        return_tensors="pt",
        return_dict=True,
    ).to(active_model.device)

    outputs = active_model.generate(**inputs, max_new_tokens=8192)
    return active_processer.decode(outputs[0][inputs["input_ids"].shape[-1]:-1])

MODELS = [
    {
        "name": "lightonai/LightOnOCR-2-1B",
        "path": "transformers\\lightonai--LightOnOCR-2-1B",
        "run": run_lightonai__LightOnOCR_2_1B,
    },
    {
        "name": "PaddlePaddle/PaddleOCR-VL-1.5",
        "path": "transformers\\PaddlePaddle--PaddleOCR-VL-1.5",
        "run": run_PaddlePaddle__PaddleOCR_VL_1_5,
    },
    {
        "name": "zai-org/GLM-OCR",
        "path": "transformers\\zai-org--GLM-OCR",
        "run": run_zai_org__GLM_OCR,
    },
]

# モデル読み込み
def load_model(tf_processor, tf_model, model_index, device):
    global active_processer, active_model, active_model_index, active_device

    if active_model_index == model_index and active_device == device:
        return
    active_model_index = model_index
    active_device = device

    if active_processer is not None:
        del active_processer
        del active_model
        gc.collect()
        torch.cuda.empty_cache()

    model = MODELS[model_index]
    for i in range(2):
        try:
            active_processer = tf_processor.from_pretrained(model["path"])
            active_model = tf_model.from_pretrained(
                pretrained_model_name_or_path=model["path"],
                device_map=device,
            )
            break
        except:
            snapshot_download(repo_id=model["name"], local_dir=model["path"])

# 実行
def run(image, model_index, device):
    if image is None:
        raise gr.Error("画像は必須です。")
    return MODELS[model_index]['run'](image, model_index, device)

# gradioによるHTML生成
with gr.Blocks(title="AI-OCRテスト") as demo:
    gr.Markdown("# AI-OCRテスト")

    with gr.Row():
        with gr.Column():
            image = gr.Image(height=500, type="pil", label="画像")

            with gr.Row():
                model = gr.Dropdown(choices=[(v["name"], k) for k, v in enumerate(MODELS)], label="モデル")
                device = gr.Radio(choices=["auto", "cpu"], value="auto", label="デバイス", interactive=True)

            with gr.Row():
                btn_clear = gr.Button(value="クリア")
                btn_run = gr.Button(value="テキスト抽出", variant="primary")

        output = gr.Textbox(lines=15, label="結果", buttons=["copy"])

    btn_run.click(fn=run, inputs=[image, model, device], outputs=output)
    btn_clear.click(fn=lambda: (None, None), outputs=[image, output])

demo.launch()
