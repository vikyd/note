# VSCode 自动补全 TDdesign Vue 3 的组件名、属性（含 pnpm 情况）

# 目的
想要：VSCode 写 Vue 组件时，能自动补全 [tdesign-vue-next](https://tdesign.tencent.com/vue-next/) 的组件名、组件属性。

> 其他 Vue UI 框架也适用



# 先上简要结论
不管是使用 npm，还是使用 [pnpm](https://pnpm.io/)，方式都一样：

## 需要

- 在 `tsconfig.json` 的 `compilerOptions.types` 添加 `"tdesign-vue-next/global"`（[JSON 片段示例](https://gist.github.com/vikyd/93c6fdf5cf0de8234dec5e1bd77d62b7)）
- 将 VSCode [Volar 插件](https://marketplace.visualstudio.com/items?itemName=Vue.volar) 中的 `Preferred Tag Name Case` 设置为 `kebab`
- 若不生效，可尝试 reload VSCode
- Over


## 无需

- `.npmrc`
- `tsconfig.json` 的 `include` 的 `"node_modules/tdesign-vue-next/global.d.ts"` 


> 更详细，可后面的小节。



# 常见问题
## 问题：不生效，未出现补全
问题：

- 没任何补全提示，没有出现候选组件列表，大写小写都没有


原因：

- 可能是没配置 `tsconfig.json`


解决：

- 确认 `tsconfig.json` 已配置完毕
- 尝试 reload VSCode
- 还不行，可尝试删除 `node_modules` 再重新下载依赖包，并 reload VSCode



## 问题：有出现补全，但大小写不是想要的
问题：

- 常见情况：以 `<t-button>` 组件为例，输入 `t` 或 `T`，候选列表出现 `TButton`，并未出现想要的 `<t-button>`
- 或反之，想要大写，但只出现小写的候选

原因：

- Volar 插件允许对候选组件名的大小写风格进行配置，可打开 VSCode 的 Settings 搜索 volar 看配置
  - `Preferred Tag Name Case`：组件名的大小写配置
  - ` Preferred Attr Name Case`：组件属性的大小写配置
  - 大小写风格名词说明：[camelCase、PascalCase、snake_case、kebab-case](https://betterprogramming.pub/string-case-styles-camel-pascal-snake-and-kebab-case-981407998841)
- 此外，VSCode 有多份 Settings，优先级不一样：
  - 本机用户级别（User）：最低优先级
  - 远程开发服务器（Remote）：优先级高于本机
  - 当前项目（Workspace）：最高优先级，位置 `项目根目录/.vscode/settings.json`

解决：

- 若想要组件名为小写加横杆（如 `<t-button>`，即 kebab 风格），则可将 Volar 的 `Preferred Tag Name Case` 设置为 `kebab`
  - 若是 `settings.json` ，则形如：
```json
{
  "volar.completion.preferredTagNameCase": "auto-kebab"
}
```
- 曾试过 `auto-kebab`，但有时一直补全为大写，规则未细究，暂不用
- 若想要首字母大写加驼峰的风格，则可配置值为 `pascal`


对于组件的属性名：

- 配置项 `Preferred Attr Name Case` 的 key 是 `volar.completion.preferredAttrNameCase`




## 问题：骤增 ts 报错
问题：

构建项目时，会报很多之前没报的错误，例如：
```
...
error TS2322: Type 'string | string[]' is not assignable to type 'MenuValue'.
...
error TS2322: Type 'string' is not assignable to type '"default" | "danger" | "warning" | "success" | "primary"'.
...
error TS2322: Type '{}' is not assignable to type 'TableSort'.
...
```


原因：

- `tsconfig.json` 配置 `"tdesign-vue-next/global"`
  - 没配置时：ts 不会去检查组件属性的类型匹配
  - 配置后：ts 会检查组件属性的类型匹配，发现了组件属性的不规范使用

解决：

- 没有捷径，只能逐个 fix
  - 因为这本身就是问题，之前能 build 通过，不代表运行的时候没有风险


## 问题：是否需配置 `tsconfig.json` 的 `include` ？
答：无需。

`tsconfig.json` 示例：

```json
{
  "include": [
    "node_modules/tdesign-vue-next/global.d.ts"
  ]
}
```


原因：

- 使用 [pnpm](https://pnpm.io/) 与 npm 不一样
- 使用 npm 时：
  - 有效：【`compilerOptions.types` 配置 `tdesign-vue-next/global`】
  - 有效：【`include` 配置 `node_modules/tdesign-vue-next/global.d.ts`】
  - 都能达到类似的效果，二选一即可
- 使用 [pnpm](https://pnpm.io/) 时：
  - 有效：【`compilerOptions.types` 配置 `tdesign-vue-next/global`】
  - 无效：【`include` 配置 `node_modules/tdesign-vue-next/global.d.ts`】 


## 问题：pnpm 时，【`include` 配置 `node_modules/tdesign-vue-next/global.d.ts`】为什么不生效？

原因：

- 可能是因为 pnpm 不允许引用间接依赖包，而 npm 允许（可对比看下两者的 node_modules 的直接子目录数）


解决：

- 建议使用：【`compilerOptions.types` 配置 `tdesign-vue-next/global`】
- 若非要生效，需在项目根目录新建文件 `.npmrc`，并且[内容为](https://blog.csdn.net/m0_52409770/article/details/127734886)：
```
public-hoist-pattern[]=@vue/runtime-core
```
- 然后重新执行 `pnpm install`，并 reload VSCode


疑问：

- 为什么需提升（hoist） [@vue/runtime-core](https://www.npmjs.com/package/@vue/runtime-core) 到 node_modules 中？

答：

- 观察文件 `node_modules/tdesign-vue-next/global.d.ts` 的内容：
```ts
declare module '@vue/runtime-core' {
  export interface GlobalComponents {
    TButton: typeof import('tdesign-vue-next')['Button'];
    // ...
  }
}
```
- 其中的 [declare module '@vue/runtime-core'](https://ts.xcatliu.com/basics/declaration-files.html#declare-module) 表示扩展 [@vue/runtime-core](https://www.npmjs.com/package/@vue/runtime-core) 模块的内容
- 所以需提升 [@vue/runtime-core](https://www.npmjs.com/package/@vue/runtime-core) 到 node_modules，也即 `.npmrc` 中的 `public-hoist-pattern[]=@vue/runtime-core`



# 小结
- 推荐：【`compilerOptions.types` 配置 `"tdesign-vue-next/global"`】
- 不推荐：【`include` 配置 `"node_modules/tdesign-vue-next/global.d.ts"`】
- 因 pnpm 默认不允许代码引用 `package.json` 没声明的依赖，所以需特殊处理
- 其他 UI 库在 VSCode 的自动补全，也类似



# 参考

- [pnpm 的 .npmrc 参考文档](https://pnpm.io/npmrc)
- [【类型提示】使用pnpm命令创建的vite项目无法在vscode中获得组件类型提示](https://blog.csdn.net/m0_52409770/article/details/127734886)
- [TDesign Vue 3 官网](https://tdesign.tencent.com/vue-next/)



