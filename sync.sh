#!/bin/bash
set -euo pipefail

# このスクリプトは接続されたビデオカメラデバイスを検出し、
# デバイスが「pink」か「white」かを識別し、
# 既存の「pink」または「white」フォルダをクリーンアップして、
# デバイスから対応するフォルダにビデオクリップを抽出します。

SERIAL_WHITE="6D6C904DF4D9"
SERIAL_PINK="6CD0502F3121"

ICON_PINK="🐷"
ICON_WHITE="🐻‍❄️"

function get_device_info_by_serial() {
    serial=${1}
    info=$(system_profiler SPUSBDataType | awk -v RS='' "/Serial Number: $serial/")
    echo "$info"
}

function copy_video_clips() {
    local device_color=$1
    local source_path=$2
    local target_folder=$3

    # カラーコードの設定
    if [[ "$device_color" == "PINK" ]]; then
        COLOR="\033[95m"  # ピンク
        ICON="🐷"
    else
        COLOR="\033[97m"  # 白
        ICON="🐻‍❄️"
    fi
    RESET="\033[0m"
    GREEN="\033[92m"
    YELLOW="\033[93m"
    RED="\033[91m"
    CYAN="\033[96m"

    if [[ -d "$source_path" ]]; then
        echo -e "${COLOR}${ICON} [$device_color]${RESET} 📹 デバイスを検出しました！ ${CYAN}$source_path${RESET}"

        if [[ -d "$target_folder" ]]; then
            echo -e "${COLOR}${ICON} [$device_color]${RESET} 🧹 既存フォルダ ${YELLOW}$target_folder${RESET} をクリーンアップ中..."
            rm -rf "${target_folder:?}/"*
            echo -e "${COLOR}${ICON} [$device_color]${RESET} ✨ クリーンアップ完了！"
        fi

        mkdir -p "$target_folder"

        # Use rsync for better progress display and error handling
        echo -e "${COLOR}${ICON} [$device_color]${RESET} 🚀 ファイル転送を開始します..."
        if command -v rsync &> /dev/null; then
            rsync -av --progress "$source_path/" "$target_folder/"
            count=$(find "$target_folder" -type f | wc -l | tr -d ' ')
        else
            # Fallback to cp if rsync not available
            count=0
            for f in "$source_path"/*; do
                if [[ -f "$f" ]]; then
                    bn=$(basename "$f")
                    printf "  📄 コピー中: ${CYAN}$bn${RESET}"
                    if cp "$f" "$target_folder/"; then
                        printf " ${GREEN}✓ 成功！${RESET}\n"
                        count=$((count + 1))
                    else
                        printf " ${RED}✗ 失敗...${RESET}\n"
                    fi
                fi
            done
        fi
        echo -e "${COLOR}${ICON} [$device_color]${RESET} 🎉 転送完了！ 合計 ${GREEN}$count${RESET} ファイルをコピーしました！"
        return 0
    else
        echo -e "${COLOR}${ICON} [$device_color]${RESET} ${RED}❌ ソースパスが見つかりません: $source_path${RESET}"
        return 1
    fi
}

function show_help() {
    BLUE="\033[94m"
    GREEN="\033[92m"
    YELLOW="\033[93m"
    CYAN="\033[96m"
    MAGENTA="\033[95m"
    RESET="\033[0m"
    BOLD="\033[1m"

    echo -e "${CYAN}${BOLD}🎬 ビデオ同期ツール v1.0 🎬${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo
    echo -e "${BOLD}使用方法:${RESET}"
    echo -e "  $0 [オプション]"
    echo
    echo -e "${BOLD}オプション:${RESET}"
    echo -e "  -h, --help    このヘルプを表示"
    echo
    echo -e "${BOLD}説明:${RESET}"
    echo -e "  このスクリプトは接続されたビデオカメラデバイスを自動検出し、"
    echo -e "  ビデオファイルをローカルフォルダに同期します。"
    echo
    echo -e "${BOLD}対応デバイス:${RESET}"
    echo -e "  ${MAGENTA}🐷 PINK:${RESET}  $SERIAL_PINK"
    echo -e "  ${CYAN}🐻‍❄️ WHITE:${RESET} $SERIAL_WHITE"
    echo
    echo -e "${BOLD}動作:${RESET}"
    echo -e "  1. 接続されたUSBデバイスをスキャン"
    echo -e "  2. 対応デバイスのビデオファイルを検出"
    echo -e "  3. ${YELLOW}pink${RESET} または ${YELLOW}white${RESET} フォルダに同期"
    echo -e "  4. デバイスを安全に取り出し"
    echo
    echo -e "${BOLD}注意:${RESET}"
    echo -e "  • 既存のフォルダ内容はクリーンアップされます"
    echo -e "  • ファイル転送中はデバイスを取り外さないでください"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

function main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo -e "\033[91m❌ 不明なオプション: $1\033[0m"
                echo -e "ヘルプを表示するには: $0 --help"
                exit 1
                ;;
        esac
        shift
    done

    BLUE="\033[94m"
    GREEN="\033[92m"
    YELLOW="\033[93m"
    RED="\033[91m"
    MAGENTA="\033[95m"
    CYAN="\033[96m"
    RESET="\033[0m"
    BOLD="\033[1m"

    echo -e "${CYAN}${BOLD}🎬 ビデオ同期ツール v1.0 🎬${RESET}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "🔍 デバイスを検索中..."

    pink_info=$(get_device_info_by_serial "$SERIAL_PINK")
    white_info=$(get_device_info_by_serial "$SERIAL_WHITE")

    devices_found=0

    # Check and process both devices independently
    if [[ -n "$pink_info" ]]; then
        echo -e "${MAGENTA}${ICON_PINK} PINKデバイスを発見！${RESET}"
        if copy_video_clips "PINK" "/Volumes/Untitled/AVCHD/BDMV/STREAM" "pink"; then
            devices_found=$((devices_found + 1))
        fi
    fi

    if [[ -n "$white_info" ]]; then
        echo -e "${CYAN}${ICON_WHITE} WHITEデバイスを発見！${RESET}"
        if copy_video_clips "WHITE" "/Volumes/Untitled/AVCHD/BDMV/STREAM" "white"; then
            devices_found=$((devices_found + 1))
        fi
    fi

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    if [[ $devices_found -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  サポートされているデバイスが検出されませんでした${RESET}"
        echo -e "   ${YELLOW}探索対象:${RESET}"
        echo -e "   ${MAGENTA}${ICON_PINK} PINK:${RESET} $SERIAL_PINK"
        echo -e "   ${CYAN}${ICON_WHITE} WHITE:${RESET} $SERIAL_WHITE"
    else
        echo -e "${GREEN}✅ ${devices_found}台のデバイスを処理しました！${RESET}"
        echo -e "💿 デバイスの取り出しを試みます..."
        eject_device
    fi
    echo -e "${CYAN}${BOLD}👋 ありがとうございました！${RESET}"
}

function eject_device() {
    local ejected=0
    GREEN="\033[92m"
    YELLOW="\033[93m"
    RED="\033[91m"
    CYAN="\033[96m"
    RESET="\033[0m"

    # Try to eject each volume, continue even if one fails
    for volume in "/Volumes/Untitled" "/Volumes/PMHOME"; do
        if [[ -d "$volume" ]]; then
            echo -e "💿 ${CYAN}$volume${RESET} を取り出しています..."
            if diskutil eject "$volume" 2>/dev/null; then
                echo -e "  ${GREEN}✅ $volume の取り出しに成功しました！${RESET}"
                ejected=$((ejected + 1))
            else
                echo -e "  ${YELLOW}⚠️  $volume の取り出しに失敗しました（使用中の可能性があります）${RESET}"
            fi
        fi
    done

    if [[ $ejected -eq 0 ]]; then
        echo -e "${RED}⚠️  警告: ボリュームを取り出せませんでした。手動で取り出す必要があります。${RESET}"
        return 1
    fi
    return 0
}

main "$@"
