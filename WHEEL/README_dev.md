## コンテナのバージョン指定方法
ユーザが選択するコンテナのバージョンは、`template/version.env` 内で定義されている配列 `APP_VERSIONS` で指定できます。

```
# APP_VERSIONS["version"]="containerURL sifFilePath"
APP_VERSIONS["latest(2026)"]="${WHEEL_PACKAGE_BASE_URL}/24932946275/wheel.sif ${WHEEL_SIFDIR}/wheel_24932946275.sif"
APP_VERSIONS["2025"]="${WHEEL_PACKAGE_BASE_URL}/23130393821/wheel.sif ${WHEEL_SIFDIR}/wheel_23130393821.sif"
APP_VERSIONS["2023"]="noURL ${WHEEL_SIFDIR}/wheel_debian10.13_x86_64.sif"
```

`APP_VERSIONS` のkeyがユーザが起動時のフォーム画面で選択するリストのラベルになります。
valueはスペース区切りで2つの値を指定してください。1つ目の値がgithubのリリースページに置かれているSIFファイルのURL,2つ目の値が OpenOnDemand のシステム内でのSIFファイルのパスです。


## コンテナファイルのダウンロード方法
`download_containers.sh` スクリプトを実行すると、`template/version.env` 内に定義されているSIFファイルを取得します。
ただし、URLがhttps://で始まっていないものや、既にダウンロード済のものは処理をスキップします。

ローカルでビルド済のSIFファイルを使う場合は、URLに `https://`で始まらないダミーの文字列を指定してください。

SIFファイルを再ダウンロードする場合は、既に存在するファイルを削除してからこのスクリプトを実行してください。
