#!/usr/bin/env bash

# 设置严格模式，提高脚本健壮性
set -euo pipefail

# 捕获中断信号，提供更好的用户体验
trap 'echo -e "\n❌ 脚本被中断"; exit 1' INT TERM

# 1. 控制台输入 GitHub Token（不会显示在屏幕上）
echo -e "\033[33m⚠️  控制台不会显示输入的 GitHub Token，请勿将 Token 泄露给别人\033[0m"
echo -en "\033[32m🔒 请输入 GitHub Token 后回车: \033[0m"
read -s GITHUB_TOKEN
echo

# 检查是否为空
if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ GitHub Token 不能为空"
  exit 1
fi

# 输入 GitHub 组织名，如果无输入则默认为 yolotechnology
echo -en "\033[32m🏢 请输入 GitHub 组织名, 可选填 (默认为 yolotechnology): \033[0m"
read GITHUB_ORG_NAME
if [ -z "$GITHUB_ORG_NAME" ]; then
  GITHUB_ORG_NAME="yolotechnology"
fi

# 2. 存入 macOS Keychain
if security add-generic-password -a "$USER" -s GITHUB_PACKAGES_NPM_TOKEN -w "$GITHUB_TOKEN" -U; then
  echo "✅ Token 已保存到 Keychain"
else
  echo "❌ 保存 Token 到 Keychain 失败, 请检查权限"
  exit 1
fi

# 3. 在对应 shell 配置文件里添加动态读取逻辑（如果没有就追加）
CURRENT_SHELL=$(basename "$SHELL")

case "$CURRENT_SHELL" in
  zsh)
    RC_FILE="$HOME/.zshrc"
    ;;
  bash)
    # macOS 上 bash 默认可能用 ~/.bash_profile
    if [ -f "$HOME/.bashrc" ]; then
      RC_FILE="$HOME/.bashrc"
    else
      RC_FILE="$HOME/.bash_profile"
    fi
    ;;
  *)
    echo "⚠️ 检测到未适配的 shell: $CURRENT_SHELL"
    echo "👉 将仅在当前会话里设置 NPM_TOKEN，不会写入配置文件"
    export NPM_TOKEN="$(security find-generic-password -a "$USER" -s GITHUB_PACKAGES_NPM_TOKEN -w 2>/dev/null)"
    RC_FILE=""
    ;;
esac

if [ -z "$RC_FILE" ]; then
  echo "❌ 检测到未适配的 shell，无法写入配置文件，终止脚本"
  exit 1
fi

if [ -n "$RC_FILE" ]; then
  # 如果配置文件不存在就创建
  if [ ! -f "$RC_FILE" ]; then
    mkdir -p "$(dirname "$RC_FILE")"
    touch "$RC_FILE"
    echo "ℹ️ 未找到 $RC_FILE，已自动创建"
  fi

  if ! grep -q "GITHUB_PACKAGES_NPM_TOKEN" "$RC_FILE"; then
    cat <<'EOF' >> "$RC_FILE"
# Load GitHub Packages token from macOS Keychain
export NPM_TOKEN="$(security find-generic-password -a "$USER" -s GITHUB_PACKAGES_NPM_TOKEN -w 2>/dev/null)"
EOF
    echo "✅ 已在 $RC_FILE 添加动态加载 NPM_TOKEN"
  else
    echo "ℹ️ $RC_FILE 已经有相关配置，跳过追加"
  fi
  # source "$RC_FILE"
fi

# 4. 配置全局 ~/.npmrc（如果没有就写入）
if ! grep -q "@${GITHUB_ORG_NAME}:registry" ~/.npmrc 2>/dev/null; then
  cat <<EOF >> ~/.npmrc
@${GITHUB_ORG_NAME}:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${NPM_TOKEN}
EOF
  echo "✅ 已写入 ~/.npmrc"
else
  echo "ℹ️  ~/.npmrc 已经有相关配置，跳过追加"
fi

# 5. 验证环境变量是否可用
echo "🔍 检查 NPM_TOKEN:"
if [ -n "$NPM_TOKEN" ]; then
  echo "🔍 NPM_TOKEN 已成功加载（长度：${#NPM_TOKEN}）"
else
  echo "❌ NPM_TOKEN 未正确加载"
fi

# 6. 验证 npm 是否能正确登录
echo "🔍 验证 npm whoami:"
if GITHUB_PKG_NAME=$(npm whoami --registry=https://npm.pkg.github.com 2>/dev/null); then
  echo "✅ npm 登录验证成功，用户名: $GITHUB_PKG_NAME"
else
  echo "❌ 登录验证失败，请检查 token 权限（需要 read:packages）"
  exit 1
fi