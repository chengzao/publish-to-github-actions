#!/bin/bash

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

# 3. 在 ~/.zshrc 里添加动态读取逻辑（如果没有就追加）
if ! grep -q "GITHUB_PACKAGES_NPM_TOKEN" ~/.zshrc; then
  cat <<'EOF' >> ~/.zshrc
# Load GitHub Packages token from macOS Keychain
export NPM_TOKEN="$(security find-generic-password -a "$USER" -s GITHUB_PACKAGES_NPM_TOKEN -w 2>/dev/null)"
EOF
  echo "✅ 已在 ~/.zshrc 添加动态加载 NPM_TOKEN"
else
  echo "ℹ️  ~/.zshrc 已经有相关配置，跳过追加"
fi

# 4. 配置全局 ~/.npmrc（如果没有就写入）
if ! grep -q "@yolotechnology:registry" ~/.npmrc 2>/dev/null; then
  cat <<'EOF' >> ~/.npmrc
@yolotechnology:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=\${NPM_TOKEN}
EOF
  echo "✅ 已写入 ~/.npmrc"
else
  echo "ℹ️  ~/.npmrc 已经有相关配置，跳过追加"
fi

# 5. 让 ~/.zshrc 立即生效
source ~/.zshrc

# 6. 验证环境变量是否可用
echo "🔍 检查 NPM_TOKEN:"
echo $NPM_TOKEN

# 7. 验证 npm 是否能正确登录
echo "🔍 验证 npm whoami:"
npm whoami --registry=https://npm.pkg.github.com || echo "⚠️ 登录失败，请检查 token 权限（需要 read:packages）"
