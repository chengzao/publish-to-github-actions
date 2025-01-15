# @chengzao/stylelint

[![NPM version](https://img.shields.io/npm/v/@chengzao/stylelint.svg?style=flat)](https://npmjs.org/package/@chengzao/stylelint)
[![NPM downloads](http://img.shields.io/npm/dm/@chengzao/stylelint.svg?style=flat)](https://npmjs.org/package/@chengzao/stylelint)

## Install

- yarn

```bash
yarn add stylelint @chengzao/stylelint
```

- npm

```bash
npm install stylelint @chengzao/stylelint
```

- pnpm

```bash
pnpm add stylelint @chengzao/stylelint stylelint-config-standard-scss stylelint-config-recess-order stylelint-config-recess-order stylelint-declaration-block-no-ignored-properties
```

## Use

- Project Root dir create `stylelint.config.js` file

```js
import { defaultConfig } from '@chengzao/stylelint';

export default defaultConfig({
  ignoreFiles: ['dist/**/*', 'node_modules/**/*', '.git/**/*'],
});
```

## Options

- Generator VScode `.vscode` Config file

```bash
npx chengzao-stylelint init
```
