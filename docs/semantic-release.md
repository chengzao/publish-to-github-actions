# CI/CD Semantic Release

- [release.yml](../yml/semantic-release.yml)

## 在项目中准备

- 目录

```bash
.
├── packages/
│   ├── web/           # 前端项目
│   ├── api/           # Node.js 后端
│   ├── cli/           # 命令行工具
│   └── shared/        # 共享工具库
├── .github/workflows/release.yml
├── .releaserc.json
├── package.json
└── CHANGELOG.md       # 根 changelog（汇总）
```

- 安装依赖

```bash
npm install --save-dev semantic-release \
  semantic-release-monorepo \
  @semantic-release/git \
  @semantic-release/github \
  @semantic-release/changelog \
  @semantic-release/commit-analyzer \
  @semantic-release/release-notes-generator
```

- 根目录创建 `.releaserc.json` 文件

```json
{
  "branches": [
    "main",
    {
      "name": "staging",
      "prerelease": true
    }
  ],
  "plugins": [
    [
      "semantic-release-monorepo",
      {
        "branches": ["main", "staging"]
      }
    ],
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/changelog",
      {
        "changelogFile": "CHANGELOG.md"
      }
    ],
    [
      "@semantic-release/git",
      {
        "assets": ["CHANGELOG.md", "package.json"],
        "message": "chore(release): ${nextRelease.version} [skip ci]"
      }
    ],
    [
      "@semantic-release/github",
      {
        "assets": [
          {
            "path": "dist/**",
            "label": "Build Output"
          }
        ]
      }
    ]
  ]
}
```

- 子目录`packages/web/.releaserc.json`

```json
{
  "tagFormat": "web@${version}",
  "plugins": [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    [
      "@semantic-release/changelog",
      {
        "changelogFile": "CHANGELOG.md"
      }
    ],
    [
      "@semantic-release/git",
      {
        "assets": ["CHANGELOG.md", "package.json"],
        "message": "chore(release): web ${nextRelease.version} [skip ci]"
      }
    ],
    [
      "@semantic-release/github",
      {
        "assets": [
          {
            "path": "dist/**",
            "label": "Web Build"
          }
        ]
      }
    ]
  ]
}
```


## Commit Message 规范

```bash
feat(web): 新增登录界面
fix(api): 修复 token 校验问题
docs(shared): 更新接口文档
refactor(cli): 优化命令执行逻辑
```