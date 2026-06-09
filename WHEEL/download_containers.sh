#!/usr/bin/env bash
set -euo pipefail

# 1. 外部データファイルの読み込み
if [ -f "template/version.env" ]; then
    source template/version.env
else
    echo "ERROR: version.env file not found." >&2
    exit 1
fi

# 2. 連想配列のすべてのキー（バージョン）をループ処理
# ${!APP_VERSIONS[@]} で登録されている全てのキー（"latest" "2024" など）を取得できます
for VER in "${!APP_VERSIONS[@]}"; do
    echo "=========================================="
    echo "Processing Version: ${VER}"
    echo "=========================================="

    # データの展開
    read -r CONTAINER_URL SIF_FILE_PATH <<< "${APP_VERSIONS[$VER]}"

    # CONTAINER_URLが「https://」で始まっていなければスキップ
    if [[ $CONTAINER_URL != https://* ]]; then
        echo "Skipping: CONTAINER_URL is not HTTPS ($CONTAINER_URL)"
        continue
    fi

    # 保存先ディレクトリの作成（存在しない場合）
    TARGET_DIR=$(dirname "${SIF_FILE_PATH}")
    if [ ! -d "${TARGET_DIR}" ]; then
        echo "Creating directory: ${TARGET_DIR}"
        mkdir -p "${TARGET_DIR}"
    fi

    # ファイルの存在チェックと wget ダウンロード
    if [ -f "${SIF_FILE_PATH}" ]; then
        echo "[INFO] SIF file already exists: ${SIF_FILE_PATH}"
    else
        echo "[INFO] SIF file not found. Downloading from ${CONTAINER_URL}..."
        
        if wget -q --show-progress -O "${SIF_FILE_PATH}" "${CONTAINER_URL}"; then
            echo "[SUCCESS] Download completed: ${SIF_FILE_PATH}"
        else
            echo "[ERROR] Failed to download SIF file for version ${VER}." >&2
        fi
    fi
    echo ""
done

echo "All processes completed!"
