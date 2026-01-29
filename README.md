# japanese-kana-kbd

Sailfish OS 向けの日本語フリック入力キーボードです。

## 概要

フィンランド発のスマートフォン OS である Sailfish OS でも日本語入力がやりたくて開発しています。

## 機能

- 12キー日本語フリック入力
- ひらがな・カタカナ切り替え
- 辞書ベースの漢字変換（SKK-JISYO.L を利用）

## 開発状況

| 項目 | 状態 |
|------|------|
| フリック入力 | ✅ |
| カタカナ変換 | ✅ |
| 辞書変換 | ✅ (SKK辞書) |
| Anthy連携 | 🚧 検討中 |

### 開発メモ

- 実機を所有しておらず、エミュレーターで開発しています。動作確認できる方いませんか...
- 2026-01-28: Anthy-unicode のビルドに成功。(Fedora パッケージから辞書データを流用)。連携方法は検討中です🤔

## クレジット

- [SKK-JISYO.L](https://skk-dev.github.io/dict/) - 辞書データ
- [Anthy-unicode](https://github.com/fujiwarat/anthy-unicode) - 変換エンジン（将来対応予定）

## ライセンス

GPL-2.0-or-later

- 辞書データ (SKK-JISYO.L) は [SKK 辞書プロジェクト](https://skk-dev.github.io/dict/) より GPL で配布されています
