import json, os, shutil, sys, tempfile
from safetensors.torch import safe_open, load_file, save_file

if len(sys.argv) < 2:
    print("error: specify a file as an argument")
    sys.exit()

for path in sys.argv[1:]:
    try:
        # metadata取得
        with safe_open(path, "pt") as f:
            metadata = f.metadata()

        # 既にmetadataなしの場合は何もしない
        if not metadata:
            print(f"ignore: {path}")
            continue

        # metadataの書き出し
        with open(os.path.splitext(path)[0] + ".txt", "a", encoding="utf-8") as f:
            json.dump(metadata, f, indent=2, ensure_ascii=False)

        # metadataなしで上書き
        f, tmp_path = tempfile.mkstemp()
        os.close(f)
        save_file(load_file(path), tmp_path)
        shutil.move(tmp_path, path)

        print(f"done: {path}")
    except Exception as e:
        print(f"error: {path} {e}")
