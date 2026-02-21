# Anthy Unicode ビルド＆インストールガイド for Sailfish OS

このガイドでは、Sailfish OS 向けに Anthy Unicode 入力エンジンをビルドしてインストールする手順を説明します。

> ⚠️ **注意**: この手順は開発時のターミナルやスレッドの記録、おぼろげな記憶をもとに作成しています。
> 環境によって異なる場合があります。問題があれば Issue で教えてください。

## 作業環境

このガイドでは以下の3つの環境を使い分けます：

| 環境 | 説明 | プロンプト例 |
|-----|------|-------------|
| **Build Engine** | Sailfish SDK 内の仮想マシン。`mb2` コマンドでクロスコンパイル | `[mersdk@SailfishSDK ~]$` |
| **Windows (PowerShell)** | `scp` でファイル転送に使用 | `PS C:\Users\...>` |
| **実機 (SSH)** | `ssh defaultuser@<IP>` で接続。`devel-su` で root 権限取得 | `[defaultuser@XqAU ~]$` |

### Build Engine への接続

Sailfish IDE から、または直接 SSH で接続：

```bash
ssh -p 2222 mersdk@localhost
```

### 実機への接続

デバイスと同じネットワークに接続し、SSH で接続：

```bash
ssh defaultuser@192.168.x.x
```
> Sailfish 端末の本体設定 → Developer tools → Developer mode をオンにして、SSH するための Remote connection のパスワード設定などを行ってください。
> 頑張れば USB 経由で SSH 接続ができるようになるようです。

## 前提条件

- **Sailfish SDK** がインストールされていること
- **対象デバイス**: aarch64 アーキテクチャ（Xperia 10 III など）
- **Sailfish OS バージョン**: 5.0.0.62EA 以降

## 概要

Anthy を動作させるには、以下の3つのコンポーネントが必要です：

| コンポーネント | 説明 |
|---------------|------|
| **anthy-unicode** | かな漢字変換エンジン本体（C ライブラリ） |
| **anthy-qml-plugin** | QML から Anthy を呼び出すためのブリッジ |
| **辞書ファイル** | Fedora 由来の anthy.dic（形態素解析用） |

---

## 1. anthy-unicode のビルド

### 1.1 ソースコードの取得

```bash
cd /home/mersdk
git clone https://github.com/fujiwarat/anthy-unicode.git build
cd build
```

### 1.2 configure の実行

```bash
./autogen.sh
./configure --prefix=/usr --libdir=/usr/lib64
```

### 1.3 aarch64 向けビルド

**重要**: i486 ビルドでは `mkdepgraph` が segfault を起こすため、**aarch64 または armv7hl** でビルドする必要があります。

```bash
mb2 -t SailfishOS-5.0.0.62EA-aarch64 build
```

成功すると `RPMS/anthy-unicode-1.0.0-1.aarch64.rpm` が生成されます。

### 1.4 実機へのインストール

```bash
# RPM を実機に転送
scp RPMS/anthy-unicode-*.rpm defaultuser@<デバイスIP>:~/

# 実機でインストール
ssh defaultuser@<デバイスIP>
devel-su rpm -i --nodeps anthy-unicode-*.rpm
```

---

## 2. Fedora 辞書ファイルの取得と置き換え

**重要**: ソースからビルドした辞書では形態素解析が正しく動作しません。Fedora 由来の辞書ファイルを使用する必要があります。

### 2.1 Fedora パッケージのダウンロード

[Fedora Packages](https://packages.fedoraproject.org/) から `anthy-unicode` パッケージをダウンロード：

```
anthy-unicode-1.0.0.20240502-10.fc42.aarch64.rpm（または最新版）
```

### 2.2 辞書ファイルの抽出

```bash
# rpm2cpio または 7-Zip を使用して展開
rpm2cpio anthy-unicode-*.rpm | cpio -idmv

# anthy.dic を取得
# 場所: ./usr/share/anthy-unicode/anthy.dic
```

### 2.3 実機の辞書を置き換え

```bash
# 辞書ファイルを実機に転送
scp anthy.dic defaultuser@<デバイスIP>:~/

# 実機で置き換え
ssh defaultuser@<デバイスIP>
devel-su cp ~/anthy.dic /usr/share/anthy-unicode/anthy.dic
```

### 2.4 動作確認

```bash
echo "きょうはいいてんきです" | anthy-morphological-analyzer-unicode
```

正しく動作していれば、以下のような出力が得られます：

```
segments: 3
indep_word hash=31845050 features=4,22,34,1082 #T 今日 きょう
dep_word hash=199158 は
indep_word hash=52223642 features=11,24,109,580 #RT 良い いい
indep_word hash=36007187 features=5,25,222,543,1167 #T 天気 てんき
dep_word hash=19504715 です
eos  features=1,116
```

すべて `unknown` と表示される場合は、辞書ファイルが正しく配置されていません。

---

## 3. anthy-qml-plugin のビルド

### 3.1 SDK ターゲットにヘッダーとライブラリを配置

SDK でビルドするには、Anthy のヘッダーファイルとライブラリが必要です。

#### ヘッダーファイル

Fedora の `anthy-unicode-devel` パッケージからヘッダーを取得：

```bash
# Fedora devel パッケージをダウンロード
# anthy-unicode-devel-1.0.0.20240502-10.fc42.aarch64.rpm

# 展開してヘッダーを SDK ターゲットにコピー
sudo mkdir -p /srv/mer/targets/SailfishOS-5.0.0.62EA-aarch64/usr/include/anthy-unicode-1.0/anthy
sudo cp <展開先>/usr/include/anthy-unicode-1.0/anthy/*.h /srv/mer/targets/SailfishOS-5.0.0.62EA-aarch64/usr/include/anthy-unicode-1.0/anthy/
```

#### ライブラリファイル

anthy-unicode ビルド時に生成されたライブラリを SDK ターゲットにコピー：

```bash
sudo cp /home/mersdk/build/src-main/.libs/libanthy-unicode.so* /srv/mer/targets/SailfishOS-5.0.0.62EA-aarch64/usr/lib64/
sudo cp /home/mersdk/build/src-diclib/.libs/libanthydic-unicode.so* /srv/mer/targets/SailfishOS-5.0.0.62EA-aarch64/usr/lib64/
sudo cp /home/mersdk/build/src-util/.libs/libanthyinput-unicode.so* /srv/mer/targets/SailfishOS-5.0.0.62EA-aarch64/usr/lib64/

# シンボリックリンク作成
cd /srv/mer/targets/SailfishOS-5.0.0.62EA-aarch64/usr/lib64/
sudo ln -sf libanthy-unicode.so.0.1.0 libanthy-unicode.so
sudo ln -sf libanthydic-unicode.so.0.1.0 libanthydic-unicode.so
sudo ln -sf libanthyinput-unicode.so.0.0.0 libanthyinput-unicode.so
```

### 3.2 プラグインのビルド

```bash
cd /home/mersdk
git clone https://github.com/inugamine/anthy-qml-plugin.git
cd anthy-qml-plugin
mb2 -t SailfishOS-5.0.0.62EA-aarch64 build
```

### 3.3 実機へのインストール

```bash
scp RPMS/anthy-qml-plugin-*.rpm defaultuser@<デバイスIP>:~/

ssh defaultuser@<デバイスIP>
devel-su rpm -i --nodeps anthy-qml-plugin-*.rpm
```

---

## 4. キーボードからの利用

### QML での使用例

```qml
import jp.anthy 1.0

AnthyEngine {
    id: anthy
    Component.onCompleted: {
        console.log("Anthy initialized")
    }
}

// 変換
function convert(hiragana) {
    if (anthy.convert(hiragana)) {
        var candidates = anthy.getCandidates(0)
        console.log("Candidates:", candidates)
    }
}
```

### AnthyEngine API

| メソッド | 説明 |
|---------|------|
| `convert(hiragana)` | ひらがなを変換（戻り値: bool） |
| `getCandidates(segmentIndex)` | 指定文節の候補一覧を取得 |
| `selectCandidate(segmentIndex, candidateIndex)` | 候補を選択 |
| `commit()` | 変換を確定 |
| `reset()` | 変換状態をリセット |

| プロパティ | 説明 |
|-----------|------|
| `segments` | 変換結果の文節リスト |

---

## トラブルシューティング

### 「unknown」ばかり表示される

辞書ファイルが正しくインストールされていません。Fedora 由来の `anthy.dic` を `/usr/share/anthy-unicode/` に配置してください。

### QML プラグインが読み込めない

```bash
# プラグインが正しくインストールされているか確認
ls -la /usr/lib64/qt5/qml/jp/anthy/

# 依存ライブラリが揃っているか確認
ldd /usr/lib64/qt5/qml/jp/anthy/libanthyplugin.so
```

### i486 ビルドで segfault

`mkdepgraph` ツールが i486 で実行時に segfault を起こす既知の問題です。aarch64 または armv7hl でビルドしてください。

---

## ライセンス

- **anthy-unicode**: LGPL-2.1
- **anthy-qml-plugin**: GPL-3.0（または MIT、プロジェクトによる）

## 参考リンク

- [anthy-unicode GitHub](https://github.com/fujiwarat/anthy-unicode)
- [Fedora anthy-unicode Package](https://packages.fedoraproject.org/pkgs/anthy-unicode/anthy-unicode/)
- [Sailfish SDK Documentation](https://docs.sailfishos.org/)
