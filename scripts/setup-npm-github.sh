#!/usr/bin/env bash

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

# 2. 存入 macOS Keychain
security add-generic-password -a "$USER" -s GITHUB_PACKAGES_NPM_TOKEN -w "$GITHUB_TOKEN" -U
echo "✅ Token 已保存到 Keychain"

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
  source "$RC_FILE"
fi

# 4. 配置全局 ~/.npmrc（如果没有就写入）
if ! grep -q "@yolotechnology:registry" ~/.npmrc 2>/dev/null; then
  cat <<'EOF' >> ~/.npmrc
@yolotechnology:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${NPM_TOKEN}
EOF
  echo "✅ 已写入 ~/.npmrc"
else
  echo "ℹ️  ~/.npmrc 已经有相关配置，跳过追加"
fi

# 5. 验证环境变量是否可用
echo "🔍 检查 NPM_TOKEN:"
echo $NPM_TOKEN

# 6. 验证 npm 是否能正确登录
echo "🔍 验证 npm whoami:"
npm whoami --registry=https://npm.pkg.github.com || echo "⚠️ 登录失败，请检查 token 权限（需要 read:packages）"
