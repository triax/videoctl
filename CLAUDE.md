# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

接続されたビデオカメラデバイスを自動検出し、シリアル番号で識別して、ビデオクリップをローカルフォルダに同期するビデオカメラ同期ツール（videoctl）です。ファイル変更時刻（mtime）に基づく自動リネーム機能付き。

## コアアーキテクチャ

### 主要コンポーネント

- **video**: 全機能を含む単一のbashスクリプト（実行ファイル）
- **pink/**: PINKデバイス用ビデオの保存先ディレクトリ (シリアル: 6CD0502F3121)
- **white/**: WHITEデバイス用ビデオの保存先ディレクトリ (シリアル: 6D6C904DF4D9)
- **.claude/commands/fix.md**: カスタムスラッシュコマンド `/fix` の定義

### 主要関数

- `get_device_info_by_serial()`: system_profilerを使用してシリアル番号でUSBデバイスを検出
- `check_file_naming()`: ファイル名がmtimeの順序で正しく命名されているかチェック（video:21）
- `rename_files_by_date()`: ファイルをmtimeでソートし%05d形式でリネーム (00000.MTS, 00001.MTS等)（video:105）
- `copy_video_clips()`: デバイス検出、rsync/cpフォールバックでのファイルコピー、リネーム確認を処理（video:183）
- `eject_device()`: 同期後にマウントされたボリュームを安全に取り出し（video:393）

### デバイス設定

このツールは2つの特定のビデオカメラデバイスを認識します：
- PINKデバイス: シリアル `6CD0502F3121`, アイコン 🐷
- WHITEデバイス: シリアル `6D6C904DF4D9`, アイコン 🐻‍❄️

両デバイスは `/Volumes/Untitled/AVCHD/BDMV/STREAM` としてマウントされ、.MTSビデオファイルが含まれることを想定。

## よく使うコマンド

### 基本的な使用法
```bash
# フル同期プロセスを実行（デバイス検出とファイルコピー）
./video

# ヘルプ表示
./video --help

# ファイル名が正しい順序かチェック
./video check pink
./video check white

# 既存ディレクトリ内のファイルをmtime順でリネーム
./video rename pink
./video rename white
./video rename /path/to/directory
```

### カスタムスラッシュコマンド
```bash
# Claude Code内で使用可能
/fix    # pink/whiteを自動チェック＆リネーム（リネーム後の再チェック含む）
```

### 開発用コマンド
```bash
# スクリプトを実行可能にする（必要に応じて）
chmod +x video

# コピーせずにデバイス検出をテスト
system_profiler SPUSBDataType | grep -A 20 "6CD0502F3121\|6D6C904DF4D9"
```

## 重要な仕様

### ファイル名規則
ファイルはmtime（modification time）に基づいて昇順で自動リネームされます：
- 元のファイル名: `00001.MTS`, `00023.MTS`, `00045.MTS`
- リネーム後: `00000.MTS`, `00001.MTS`, `00002.MTS` (mtimeでソート済み)

### mtimeの保持
`mv`コマンドでリネームする際、**mtimeは保持されます**。これにより：
- リネーム後も時系列の整合性が保たれる
- 再度`./video check`を実行しても正しい順序と判定される
- 何度でも安全にチェック＆リネームを繰り返せる

### ユーザー確認プロンプト
- ファイルコピー後のリネーム実行前にユーザー確認 (`y + Enter`)
- 既存フォルダのクリーンアップ前にユーザー確認

## コミットメッセージスタイル

確立されたパターンに従って日本語プレフィックスを使用：
- `機能追加:` 新機能の場合
- `改善:` 改善の場合
- `リファクタ:` リファクタリングの場合
- `修正:` バグ修正の場合
- `ドキュメント追加:` ドキュメント追加の場合