# 记一次 monaco editor 不能编辑的 Bug
写本文，是不想下次碰到类似问题依然花费那么多时间。

- 开始关注：2021-11-04
- 修复时间：2021-11-08



# 目录
[TOC]


# 起因
有一个页面，有多个 monaco-editor 实例，偶现有些 editor 不可编辑，键盘敲什么内容都不会改变，影响较大。

但明明该 monaco 实例从未设置过 `readOnly`。



# 复现方式
若有 monaco 实例在隐藏时（如 CSS `display: none`）执行过格式化（如 `myEditor.getAction("editor.action.formatDocument").run()`），会导致此页面后续新创建的 monaco 实例不能编辑。

当前版本：
- monaco-editor：`0.19.3`
- monaco-editor-webpack-plugin": `1.9.1`



# Bug 原因
未最终确认。

但猜测是低版本 monaco 的 bug，因为升级高版本 monaco 后 bug 消失了



# 解决
## Step1 使用新版本的 monaco-editor
简短：使用新版本的 [monaco-editor](https://github.com/microsoft/monaco-editor)，及其对应的 [monaco-editor-webpack-plugin](https://github.com/microsoft/monaco-editor/tree/main/monaco-editor-webpack-plugin#version-matrix) 。

> 当前最新版本：monaco-editor `0.30.0` 对应 monaco-editor-webpack-plugin `6.0.0` 

详细：
- 原来：项目使用了 [monaco-editor-vue](https://github.com/FE-Mars/monaco-editor-vue) 而非直接使用 [monaco-editor](https://github.com/microsoft/monaco-editor)
- 问题：monaco-editor-vue 依赖的 monaco-editor 版本较老，而 monaco-editor-vue 对 monaco-editor 的依赖是在 package.json 的 `dependencies` 中，导致项目无法修改 monaco-editor-vue 所依赖的 monaco-editor 版本
- 解决：需将 monaco-editor-vue 的 package.json 的 `dependencies` 中的 monaco-editor 放到 `peerDependencies` 中
  - 为快速生效，基于 monaco-editor-vue 新建了一个 npm 库：[monaco-editor-vue-fixed](https://github.com/vikyd/monaco-editor-vue-fixed)，直接用这个库，而不用 monaco-editor-vue
  - 参考：[为什么需要 peerDependencies ？](https://nodejs.org/en/blog/npm/peer-dependencies/)


## Step2 适配新版 monaco-editor 配置
目前，需适配的配置只发现 1 项：
- 定义 monaco-editor 新 theme 时（[defineTheme](https://microsoft.github.io/monaco-editor/api/modules/monaco.editor.html#definetheme)），需增加 `colors`  选项（值为空也可以）
  - 否则报错：`undefined (reading 'editor.foreground')`


## Step3 使用新版本的 monaco-vim
项目使用了 [monaco-vim](https://github.com/brijeshb42/monaco-vim) 提供 Vim 编辑模式。

- 原来：使用 monaco-editor `0.19.3` + [monaco-vim `0.1.10`](https://github.com/brijeshb42/monaco-vim) 没问题
- 问题：当 monaco-editor 升级到最新的 `0.30.0`，monaco-vim 维持 `0.1.10` 时，会报错：`Uncaught Error: monaco is not defined`
  - 原因：[cm_adapter.js#L154](https://github.com/brijeshb42/monaco-vim/blob/0.0.10/src/cm_adapter.js#L154) 此行引用了全局变量 `monaco`，但已无此全局变量
- 解决：将 monaco-vim 升级的当前最新版 [`0.1.19`](https://www.npmjs.com/package/monaco-vim)



# Fix 过程
- 前提01：页面有 2 个 monaco 以上实例，其中 1 个 readOnly 用于展示结果，其他的实例用于编辑代码
- 前提02：[readOnly 的 monaco 不能格式化](https://github.com/Microsoft/monaco-editor/issues/978)，需先解除 readOnly、格式化、再次 readOnly 才行
- 最开始问题偶现，不是必现，没能重现，时间问题暂时搁置
- 怀疑 localStorage（后简称 LS）问题
  - LS 大小满了？
    - 清空 LS 该份数据，问题消失。但[检查](https://stackoverflow.com/a/15720835/2752670) LS 使用共不超 1MB，估计无关。
  - LS 数据内容有问题 ？
    - 发现有个 monaco 实例内容与 LS 有关，但问题依然偶现
- 怀疑 Tabs 组件隐藏了 monaco 导致问题
  - 怀疑无法编辑的 monaco 实例隐藏导致问题
  - 怀疑 readOnly monaco 实例隐藏导致问题
  - 确认 Tabs 组件的隐藏方式是 CSS 的 `display: none`
  - 多次重复试验，得出结论：与 readOnly 的格式化 action 有关，但不确定与 updateOptions 是否有关
- 于是另建最简 monaco demo 项目
  - 验证到底是格式化还是 updateOptions，还是二者同时导致的问题
  - 最简 demo 仅 2 个 monaco 实例（简称 A、B 实例，其中 A 是 readOnly）
  - 多种组合尝试：`A、B 两个实例` × `是否使用 Tabs 组件、是否 display: none` × `是否 updateOptions` × `是否执行格式化 action` × `格式化的形式` × `执行其他 action 是否能复现问题（如 editor.action.fontZoomIn）` 
  - 格式化可能形式：
    - 正确：`editor.getAction("editor.action.formatDocument").run()`
      - 在 `.run.then(()=>{})` 中 `updateOptions` 是否有影响
    - 不正确：`editor.trigger(‘anyString’, 'editor.action.formatDocument')`
      - 因为无返回 Promise
    - 不正确：`editor.getAction('editor.action.format').run()`
      - getAction 返回 null
  - 多次实验后，得出结论：
    - 格式化 `editor.getAction("editor.action.formatDocument").run()`、`editor.trigger(‘anyString’, 'editor.action.formatDocument')` 都有效，但前者返回 Promise 可方便后续再次 readOnly
    - 问题与 `updateOptions` 无关
    - 问题与是否 readOnly 无关
    - 问题仅与格式化 `editor.getAction("editor.action.formatDocument").run()` 有关
    - 总之，复现问题的充分必要条件：
      - A `display: none` 时
      - A 执行 `editor.getAction("editor.action.formatDocument").run()`，之后创建的新 monaco 实例，都会变成不能编辑
- 知道问题的精确复现方法后，开始寻找解决方案
  - 把 `updateOptions` 放在 `setTimeout` ？
  - 把 `formatDocument` 放在 `setTimeout` ？
  - 尝试其他 action（`editor.action.fontZoomIn`） 是否复现（此 action 不会复现）
  - 多次尝试未果
- 尝试不使用 monaco-editor 的格式化功能
  - 改用其他 Js 库实现格式化功能
  - 但简单找了下，未找到体积小、又能格式化 Js、Html、XML 的库，于是打消了此念头
  - 剩下只想到升级 monaco-editor 相关版本看能否解决问题
- 尝试升级 monaco-editor 版本
  - 早之前尝试过 monaco-editor 版本，失败，时间问题未细看，搁置
  - 这次下定决心升级
  - 项目中直接升级 [monaco-editor](https://github.com/microsoft/monaco-editor)：`npm install monaco-editor`，及其匹配的 `npm install -D monaco-editor-webpack-plugin`
    - 可得：项目 `package.json` 的 monaco-editor 已是最新版本
    - 误以为：此时项目已经使用了最新版的 monaco-editor（实际不是）
    - 因为：项目直接依赖的是 [monaco-editor-vue](https://github.com/FE-Mars/monaco-editor-vue)，而非 monaco-editor
      - 而 monaco-editor-vue 对 monaco-editor 的依赖是在 package.json 的 dependencies 中，导致项目无法修改 monaco-editor-vue 所依赖的 monaco-editor 版本
    - 解决：需将 monaco-editor-vue 的 package.json 的 dependencies 中的 monaco-editor 放到 `peerDependencies` 中
      - 为快速生效，基于 monaco-editor-vue 新建了一个 npm 库：[monaco-editor-vue-fixed](https://github.com/vikyd/monaco-editor-vue-fixed)，直接用这个库，而不用 monaco-editor-vue
  - 在使用 peerDependencies 前，发现 `editor.getAction("editor.action.formatDocument")` 返回 `null`，导致无法执行 `run()`
    - 曾一度以为是 monaco-editor 新版本的 bug
    - 原因：新版本生效的只是 `monaco-editor-webpack-plugin` 而非 `monaco-editor`
- 刚升级 monaco-editor，解决了最开始的不能编辑问题，但出现了其他问题
  - 第一反应：是不是新版本的 monaco-editor 有其他 bug ?
  - 目前，需适配的配置只发现 1 项：
    - 定义 monaco-editor 新 theme 时（[defineTheme](https://microsoft.github.io/monaco-editor/api/modules/monaco.editor.html#definetheme)），需增加 `colors`  选项
    - 否则报错：`undefined (reading 'editor.foreground')`
    - 可在 [官网](https://microsoft.github.io/monaco-editor/playground.html#customizing-the-appearence-exposed-colors) 复现此问题
- monaco-editor 的 Vim 模式库 [monaco-vim](https://github.com/brijeshb42/monaco-vim) 是否有问题？
  - 问题：当 monaco-editor 升级到最新的 `0.30.0`，monaco-vim 维持 `0.1.10` 时，会报错：`Uncaught Error: monaco is not defined`
    - 原因：[cm_adapter.js#L154](https://github.com/brijeshb42/monaco-vim/blob/0.0.10/src/cm_adapter.js#L154) 此行引用了全局变量 `monaco`，但已无此全局变量
  - 解决：将 monaco-vim 升级的当前最新版 [`0.1.19`](https://www.npmjs.com/package/monaco-vim)
- Over。到此，问题基本解决。



# GET
- package.json 的 [`peerDependencies`](https://nodejs.org/en/blog/npm/peer-dependencies/) 
  - 用途：让依赖库的子依赖版本以项目的依赖版本为准
  - 例如：A 依赖 B，B 依赖 C `1.0.0`，若想通过 A 的 package.json 让 B 依赖 C 的 `1.5.0`，则需 B 将对 C 的依赖放在 B 的 package.json 的 `peerDependencies`，而非 `dependencies`



# 小结
- 为什么一开始没想到升级 monaco-editor 版本？
  - 因为没细究 npm 嵌套依赖版本，对 peerDependencies 不熟悉
  - 需对 npm 的版本管理机制更熟悉
- 基于最简 Demo 复现问题，可行


