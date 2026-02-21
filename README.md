# japanese-kana-kbd
Japanese flick keyboard for Sailfish OS / Sailfish OS 日本語フリックキーボード

Sailfish OS 向けの日本語フリック入力キーボードです。

## 概要

フィンランド発のスマートフォン OS である Sailfish OS でも日本語入力がやりたくて開発しています。

## 機能

- 12キー日本語フリック入力  
※他のキーボードが有効になっている場合、フリックがキーボードの切り替え(OS側の機能)と競合するため、他のキーボードを無効にする必要があります......
- ひらがな・カタカナ切り替え
- 辞書ベースの漢字変換（SKK-JISYO.L を利用）

## 開発状況

| 項目 | 状態 |
|------|------|
| フリック入力 | ✅ |
| カタカナ変換 | ✅ |
| 辞書変換 | ✅ (SKK辞書) |
| Anthy連携 | ✅ |

### 開発メモ

- 実機を所有しておらず、エミュレーターで開発しています。動作確認できる方いませんか...
- 2026-01-28: Anthy-unicode のビルドに成功。(Fedora パッケージから辞書データを流用)。~~連携方法は検討中です🤔~~
- 2026-02-08: Anthy との連携を一旦実現しました。Anthy を利用するには Sailfish 端末に Anthy-unicode を別途インストールする必要があります。
  (Anthy と連携できない場合は、従来通りの辞書ベースで動くはずです)  
  Anthy 連携済みの機能として連文節変換を実装しました。  
  機能していない左右の矢印キーを廃止して、絵文字一覧も実装しました。これは辞書ベースでも使えます。

## クレジット

- [SKK-JISYO.L](https://skk-dev.github.io/dict/) - 辞書データ
- [Anthy-unicode](https://github.com/fujiwarat/anthy-unicode) - 変換エンジン

## ライセンス

GPL-2.0-or-later

- 辞書データ (SKK-JISYO.L) は [SKK 辞書プロジェクト](https://skk-dev.github.io/dict/) より GPL で配布されています
