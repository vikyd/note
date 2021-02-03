# Defining Go Modules

原文：https://research.swtch.com/vgo-module

作者：[Russ Cox](https://swtch.com/~rsc/)

翻译时间：2020-01-17

# 定义 Go 语言的模块（Module）

（[Go 与版本管理](https://research.swtch.com/vgo)，第 6 部分）

发表时间：2018-02-22 周四 [PDF](https://research.swtch.com/vgo-module.pdf)

# 目录

<!--ts-->
   * [Defining Go Modules](#defining-go-modules)
   * [定义 Go 语言的模块（Module）](#定义-go-语言的模块module)
   * [目录](#目录)
   * [正文](#正文)
   * [为 release 添加版本](#为-release-添加版本)
   * [go.mod 文件](#gomod-文件)
   * [从代码库到模块](#从代码库到模块)
      * [多模块的代码库](#多模块的代码库)
      * [废弃的版本](#废弃的版本)
      * [发布](#发布)
      * [代码托管网站](#代码托管网站)
   * [模块打包](#模块打包)
   * [模块下载协议](#模块下载协议)
   * [模块代理服务](#模块代理服务)
   * [vendor 模式的终结](#vendor-模式的终结)
   * [下一步？](#下一步)


<!--te-->

# 正文

正如前面 [综述文章](https://github.com/vikyd/note/blob/master/go_and_versioning/go_add_package_versioning.md) 所说的，一个 Go 模块（module）表示一系列包组成的一个版本单元，其中包含一个 go.mod 文件，用于指定所依赖的其他模块。趁此迁移到模块机制之际，正好可让我们回首看看原来的 go 命令是如何管理源码的，里面涉及很多细节问题，可借此机会进行修复。此时此刻，`go get` 命令已经快 10 岁了。我们需要确保新的模块机制能满足接下来 10 年的需求。

具体来说：

- 我们希望更多开发者用 tag 方式来发布他们的包，而不是让用户从一堆 commit 中随便挑一个。用 tag 标记出明确的 release，可让别人清楚的知道哪些版本是可用的，哪些是未开发完的。但还是允许用户直接获取指定 commit 的源码，尽管不太方便。
- 我们希望在下载源码时摆脱对版本控制工具的依赖，如 bzr、fossil、git、hg、svn 等等。因为依赖版本控制工具会导致生态系统碎片化，例如：使用 Bazaar、Fossil 开发的包，没安装或不想安装这些工具的用户就使用不了。这些版本控制工具也会带来 [严重的](https://golang.org/issue/22131) [安全](https://www.mercurial-scm.org/wiki/WhatsNew/Archive#Mercurial_3.2.3_.282014-12-18.29) [问题](https://git-blame.blogspot.com/2014/12/git-1856-195-205-214-and-221-and.html)。我们希望能摆脱这些安全问题的困扰。
- 我们希望同一个代码仓库中允许包含多个模块，而且允许里面的每个模块分别拥有独立的版本号。尽管大部分开发者喜欢一个仓库对应一个模块，但对于大型项目来说，单一仓库包含多个模块会方便不少。例如，我们喜欢将 `golang.org/x/text` 放到一个单一的仓库中，但同时也需要将一些实验性新包与已发布的包分开进行版本管理。
- 我们希望个人或公司都能轻松对 `go get` 下载的内容进行缓存代理，无论是出于可用性考虑（通过本地副本保证明天使用的包与今天的一致），还是安全性考虑（在公司内使用前先进行安全检查）。
- 我们希望在未来能创建一个供 Go 社区公用的模块代理服务，类似于 Rust、Node 和其他语言的包管理服务。同时，此方案也应设计成：代理不在线时依然不影响用户工作。
- 我们希望消除 vendor 目录机制。vendor 机制是为可复现构建、可用性而诞生的，但现在我们已有更好的机制。可复现构建应被适当的版本管理替代，可用性应被代理的缓存替代。

本文将介绍 vgo 设计中的这几个要点。本文不是最终的设计：我们将会在发现错误时进行修正。

# 为 release 添加版本

抽象出明确的边界可使项目更具规模。最初，Go 的包可被外部任意包 import。后来，我们在 Go 1.4 引入 [`internal` 目录约定](https://golang.org/s/go14internal)，解决了内部包被误用的问题。因为有些开发者的程序包含多个包，但不是每个包都供给外部用户使用，引入 `internal` 机制后无需再担心此问题。

Go 社区中，对于代码仓库的 commit，同样有类似的可见性问题。今天，用户很经常通过 commit（通常是 Git 的 commit hash）来区分包的版本。然而在开发者眼里，不是每个 commit 都适合用户使用的。我们需要改变 Go 开源社区的预期，建立这样的规范：作者应以 tag 发布版本，且用户应优先使用这些 tag 版本。

从 Git 历史的 commit 中选取源码，变为从 tag 版本选取源码，有些人认为这不一定合理。但我不这么认为，因为难的是如何改变常态，我们只需让常态变得更好就行：让包作者更易去打 tag 版本，让用户更易去使用这些版本。

现在，作者们分享代码的最常见方式是在代码托管网站中分享，特别是 Github。对于 Github 上的代码，所有的包作者都应打 tag，并以这个 tag 发布版本。我们也计划提供一个工具（可能叫 `go release`）来自动对比不同版本之间在类型层面的 API 兼容性，从而在类型系统中提前发现一些不经意引入的破坏性修改。包作者可据此发布为次要版本（因添加了新 API 或修改了很多代码），或是仅发布为补丁版本。

对用户而言，vgo 本身完全基于 tag 版本。但是，我们知道从旧习惯转变为新习惯不容易，或者有时一直维护旧项目而非新起项目。这时需要特殊情况特殊处理，所以也应允许使用指定 commit 的版本。vgo 已支持使用指定 commit 版本，但优先让用户使用基于 tag 的版本。

特殊情况下，vgo 可识别这种特别的伪版本号 `v0.0.0-yyyymmddhhmmss-commit`，此版本号代表特定的 commit 记录，里面包含了一个 Git 的短哈希值、commit 的时间（UTC）。此形式是有效的语义版本号，代表着 v0.0.0 的预发布版本。例如，Gopkg.toml 中的一个片段：

```toml
[[projects]]
  name = "google.golang.org/appengine"
  packages = [
    "internal",
    "internal/base",
    "internal/datastore",
    "internal/log",
    "internal/remote_api",
    "internal/urlfetch",
    "urlfetch"
  ]
  revision = "150dc57a1b433e64154302bdc40b6bb8aefa313a"
  version = "v1.0.0"

[[projects]]
  branch = "master"
  name = "github.com/google/go-github"
  packages = ["github"]
  revision = "922ceac0585d40f97d283d921f872fc50480e06e"
correspond to these go.mod lines:

require (
	"google.golang.org/appengine" v1.0.0
	"github.com/google/go-github" v0.0.0-20180116225909-922ceac0585d
)
```

选择这样的伪版本形式后，就可基于标准的 semver 优先规则，根据 commit 时间对两个伪版本进行比较，因为字符串的大小比较刚好可代表时间的大小比较。此形式还可让 vgo 优先选择基于 tag 的版本而非伪版本，因为尽管 v0.0.1 是很旧的版本，但在 semver 优先规则中，它依然比 v0.0.0 的任意预发布伪版本更新（注意：此方式与 dep 添加新依赖到项目中的动作一致）。而且，伪版本号从视觉上也不太好看：在 go.mod 中和 `vgo list -m` 的输出中，这些伪版本看起来都不会太顺眼。所有这些特性，都是为了鼓励作者和用户优先选择基于 tag 的版本。伪版本有点像之前的 `import "unsafe"` 那样，以不太顺眼的方式来提醒开发者优先编写安全的代码。

# go.mod 文件

一个模块版本由源码树组成。go.mod 文件描述了当前模块的名称，也指明了当前目录就是项目的根目录。当 vgo 进入一个目录时，会从当前目录开始寻找 go.mod 文件，若无再往上级目录找，如此类推，直到找到 go.mod 文件，并将 go.mod 所在目录认定为项目根目录。

go.mod 文件格式是基于行的，并用 `//` 表示注释。每行开头包含一个指令，每个指令都是一个单词（module、require、exclude、replace，详细可见 [最小版本选择](https://github.com/vikyd/note/blob/master/go_and_versioning/minimal_version_selection.md)），指令的后面是参数：

```
module "my/thing"
require "other/thing" v1.0.2
require "new/thing" v2.3.4
exclude "old/thing" v1.2.3
replace "bad/thing" v1.4.5 => "good/thing" v1.4.5
```

可将相同指令的行用小括号来表示（类似 Go 的 import 语法）：

```
require (
	"new/thing" v2.3.4
	"old/thing" v1.2.3
)
```

我希望 go.mod 文件能够：

1. 清晰、简单
2. 便于人们阅读、控制、对比
3. 便于类似 vgo 的程序对其进行读取、修改、回写，并保持原有的注释和结构
4. 未来有有限的增长空间

我曾调研过 JSON、TOML、XML、YAML，但它们都无法同时兼有上述 4 个特点。例如，Gopkg.toml 中至少需 3 行才能描述 1 个需求，导致难以简化、排序和对比。为此我在 Go 程序语法的基础上设计了一个很简单的格式，但也希望不要因语法过于接近 Go 代码语法反而导致疑惑。我采用了一个现成的、对于注释友好的解释器。

最终集成到 go 命令时，可能 go.mod 的语法会被修改为更标准的文件格式。但为了兼容性，我们将依然会提供读取今天 go.mod 文件格式的功能，就像 vgo 也能读取这些文件中的需求信息一样：

- GLOCKFILE
- Godeps/Godeps.json
- Gopkg.lock
- dependencies.tsv
- glide.lock
- vendor.conf
- vendor.yml
- vendor/manifest
- vendor/vendor.json

# 从代码库到模块

开发者通常会使用版本控制工具，所以 vgo 也应与版本控制工具配合得更好，例如，不应再让开发者手动去为模块打包文件。所以，vgo 应能根据一些基础的、不突兀的约定来直接从版本控制仓库中导出模块包。

首先，创建一个仓库，并为一个 commit 打个语义版本格式的 tag。如 v0.1.0，开头的 `v` 是必须的，跟随其后的 3 个数字也是必须的。尽管 vgo 在命令行中接受类似 v0.1 的简单版本号，但为了避免歧义，代码仓库的 tag 依然必须使用完整的 v0.1.0。发布一个语义版本只需打一个 tag。若不使用 vgo 时，则也能使用 commit 版本，此时 go.mod 文件不是必须的。创建新的 tag 就表示创建了一个新的模块版本，很简单。

当开发者开发到 v2 版本时，若遵循基于语义的 import 版本管理，则 `/v2/` 应被追加到 import 路径的模块路径之后，如：`my/thing/v2/sub/pkg`。正如 [之前文章所说的](https://github.com/vikyd/note/blob/master/go_and_versioning/semantic_import_versioning.md)，此约定能带来一些好处，但同时也与现有工具有些不协调。因此，当一个模块的源码仓库的 v2 或更新的 tag 中没包含 go.mod 文件或 go.mod 中没有声明模块路径时（如 `module "my/thing/v2"`），vgo 不会将这些 tag 当成新的版本。仅在使用此方式声明时，vgo 才会认为作者使用了基于语义的 import 版本管理来命名模块中的包。这对于包含多个包的模块来说尤其重要，因为模块中的 import 路径必须包含 `/v2/` 来避免与 v1 模块的歧义。

我们希望大部分开发者都优先遵循通用的 `主版本分支` 约定，每个不同的主版本在不同的代码分支中进行开发。此时，v2 分支的根目录中应存在一个包含 v2 声明的 go.mod 文件，类似：

![](https://research.swtch.com/gitmod-1.png)

上图大致说明了目前大部分开发者的开发方式。图中，tag v1.0.0 指向了一个比 vgo 更早出现的 commit 记录，此 commit 并无 go.mod 文件，但不无大碍。在 tag v1.0.1 中，作者添加了 go.mod 文件，并在其中声明了 `module "my/thing"`。此后，作者 fork 出一个新的 v2 开发分支。除了 v2 模块内容本身的变化外（如 `bar` 被替换为 `quux`），还需将 go.mod 文件中的声明修改为 `module "my/thing/v2"`，之后若继续新建分支也如此类推。实际上，vgo 并不会感知分支的存在，vgo 只关心 tag 以及 tag 对应的 commit 中的 go.mod 文件。再次强调一下，对于 v2 及更新版本来说，go.mod 文件是必须的，否则 vgo 将无法根据 go.mod 中的声明来区分 import 的语义版本，如：`my/thing/v2/foo/quux` 和 `my/thing/foo/quux`。

作为候选功能，vgo 还支持 `子目录的主版本` 的约定，即 v1 以后（不含 v1）的版本源码可以放在项目的某个子目录中进行：

![](https://research.swtch.com/gitmod-2.png)

此时，应通过复制到一个子目录中来创建 v2.0.0，而非 fork 整个源码树。而且，go.mod 也必须更新为 `"my/thing/v2"`。此后，tag v1.x.x 将表示 commit 中根目录中除 `v2/` 外的文件；而 tag v2.x.x 将仅表示 commit 中的 `v2/` 子目录内的文件。而且，即使 v1.x.x 和 v2.x.x 指向同一个 commit，也没问题，因为各自指向了不同的目录树。

vgo 会同时支持两种约定，我们预计开发者会根据自己的需求来选择一种约定。注意，对于比 v2 更新的主版本来说，主版本号作为子目录的方式可能适用于 `go get` 的用户，便于他们平滑的过渡。而对于使用 dep 或其他 vendor 工具的用户来说，他们可选择任意一种约定。当然，我们会保证 dep 能同时支持这两种约定方式。

## 多模块的代码库

对于开发者来说，有时若能在一个源码仓库中同时维护多个模块会比较方便。我们也希望 vgo 能支持此特性。一般来说，开发者、团队、项目、公司对于源码控制的使用方式差异极大，我们认为不能对所有开发者强制要求 `一个仓库只能对应一个模块`，这是不现实的。保留一些灵活性，可让 vgo 随源码控制方式的不一样而适配出各自的最佳实践。

在基于主版本号子目录的约定方式中，`v2/` 目录中包含了名为 `"my/thing/v2"` 的模块。若对此进行扩展，子目录的名称可以不止是主版本号，也应可以是其他自然的名字。例如，可添加一个名为 `blue/` 的子目录，以及文件 `blue/go.mod`，此文件中包含模块名称 `"my/thing/blue"`。此时，对应的 tag 名应为类似 `blue/v1.x.x` 的形式。类似的，tag `blue/v2.x.x` 将指向 `blue/v2/` 子目录。因 `blue/go.mod` 文件的存在，外层模块 `my/thing` 将会排除 `blue/` 目录。

在 Go 的项目中，我们想通过此约定方式，来让类似 `golang.org/x/text` 的仓库支持定义多个互相独立的模块。这样，我们就可既保留源码控制工具原始使用方式的便利，又可在不同时间将不同的子树升级到 v1。

## 废弃的版本

作者有时也需要指明哪些版本已被废弃，不应再被用户使用。vgo 原型中暂未实现此功能，但作者可在代码托管网站上指定废弃版本，具体方式为：在 v1.0.0 所指向的 commit 上再添加一个名为 `v1.0.0+deprecated` 的 tag，即可认为 v1.0.0 已被废弃。此时不应删除原有的 tag（如 v1.0.0），因为会破坏某些构建。在 `vgo list -m -u` 中应高亮显示被废弃的模块版本（显示我的模块以及相关的更新信息），以提示用户应对此模块进行更新。

由于程序在运行期间可获取他们的模块列表和版本，所以一个程序可配置为在运行废弃的模块版本时，根据指定权限检查自己的模块版本，并以某种形式自行报告。虽然具体细节未确定，但当开发者和相关工具都以同样的方式理解版本概念时，这种情况就是典型的应用例子。

## 发布

对于一个源码仓库来说，开发者需要将其以某种形式发布出来，才能让 vgo 用户去使用此源码。一般情况下，我们会提供一个命令，让作者可通过任意静态 web server，将他们的源码仓库转换为 vgo 能使用的文件树。类似于目前的 `go get`，vgo 期望能从响应的 html 中找到一个 `<meta>` 标签，标签中包含模块名称对应具体文件树的信息。例如，想找到模块 `swtch.com/testmod` 对应的文件树，vgo 命令内部会这样做：

```sh
$ curl -sSL 'https://swtch.com/testmod?go-get=1'
<!DOCTYPE html>
<meta name="go-import" content="swtch.com/testmod mod https://storage.googleapis.com/gomodules/rsc">
Nothing to see here.
$
```

从上述响应中可知，server 类型为 `mod`（译注：若是 `curl -sSL 'https://github.com/gin-gonic/gin?go-get=1' | grep go-import` 可看到此时返回的是 `git` 类型），表示可从 `https://storage.googleapis.com/gomodules/rsc` 这个基础路径中获取模块的文件树（译注：即非通过 git 方式获取，而是通过 HTTP GET 方式获取）。此例子中，`storage.googleapis.com/gomodules/rsc` 里的相关文件包括：

- [.../swtch.com/testmod/@v/list](https://storage.googleapis.com/gomodules/rsc/swtch.com/testmod/@v/list)
- [.../swtch.com/testmod/@v/v1.0.0.info](https://storage.googleapis.com/gomodules/rsc/swtch.com/testmod/@v/v1.0.0.info)
- [.../swtch.com/testmod/@v/v1.0.0.mod](https://storage.googleapis.com/gomodules/rsc/swtch.com/testmod/@v/v1.0.0.mod)
- [.../swtch.com/testmod/@v/v1.0.0.zip](https://storage.googleapis.com/gomodules/rsc/swtch.com/testmod/@v/v1.0.0.zip)

上述 URL 中的具体含义将在本文后面的 `模块下载协议` 中详述。

## 代码托管网站

代码托管网站承载了大量的开发工作，我们也希望 vgo 与代码托管网站适配时能尽量平滑。使用 vgo 时，开发者无需将模块发布在代码托管网站之外的地方，vgo 会通过代码托管网站提供的 HTTP 接口，直接从中读取相关信息。一般来说，直接下载源码包会比从源码仓库 checkout 快得多。举个实际的例子，在一个笔记本中，连上千兆网络，从 GitHub 以 zip 包方式下载 [CockroachDB 的源码树](https://github.com/cockroachdb/cockroach) 耗时约 10 秒，而 `git clone` 则需 4 分钟。网站只需提供某种形式的下载包，并能通过 HTTP GET 下载即可。例如，[Gerrit](https://www.gerritcodereview.com/) 只提供基于 gzip 编码的 tar 包下载，而 vgo 可将其下载后转换为标准的 zip 格式。

vgo 的初版原型仅提供对 GitHub 和 Gerrit（Go 项目用到）的支持，在正式整合到 Go 工具链之前，会增加对 Bitbucket 以及其他主流代码托管网站的支持。

在适配到模块机制时，避免对原有的开源活动影响过多，vgo 将采用了以下策略：

- 对代码仓库增加一些轻量的约定规则，符合开发者当前的主要习惯
- 提供对主流代码托管网站的支持
- 还有就是在仓库中增加一个 go.mod 文件

一些公司之前利用旧版的 `go get` 直接使用 git 或其他源码控制工具来获取内网模块的源码。使用 vgo 后，可以编写一个符合 vgo 规则的模块代理服务来转发内网模块，以获得类似外面开源代码托管网站的模块代理体验（译注：即也可以通过简单的 HTTP GET 即可获取内网模块，而无需依赖 git 等工具）。

# 模块打包

从代码仓库打包为一个模块包会有一些复杂，因为开发者使用源码控制的方式各异。但最终的目标都是将这些复杂度简化为一个通用的、单一格式的 Go 模块包，以供 Go 模块服务使用或供其他代码服务使用（如 godoc.org 或其他代码检查工具）。

vgo 原型中的模块包标准格式是一个 zip 包，zip 包中所有的路径都以目录路径和版本号开始。例如，通过执行 `vgo get` 获得 `rsc.io/quote` 的 v1.5.2 版本后，可在本地的 vgo 缓存目录中找到此 zip 包，下面是 zip 包中的内容：

```sh
 unzip -l $GOPATH/src/v/cache/rsc.io/quote/@v/v1.5.2.zip
     1479  00-00-1980 00:00   rsc.io/quote@v1.5.2/LICENSE
      131  00-00-1980 00:00   rsc.io/quote@v1.5.2/README.md
      240  00-00-1980 00:00   rsc.io/quote@v1.5.2/buggy/buggy_test.go
       55  00-00-1980 00:00   rsc.io/quote@v1.5.2/go.mod
      793  00-00-1980 00:00   rsc.io/quote@v1.5.2/quote.go
      917  00-00-1980 00:00   rsc.io/quote@v1.5.2/quote_test.go
$
```

我选择 zip 格式的原因包括：

- 格式定义明确
- 受到广泛支持
- 可按需扩展
- 可对 zip 包中任一文件随机访问

大家可能会想到为什么不采用 tar 格式，原因也很简单，因为 tar 不能满足上述全部特点。

# 模块下载协议

无论是下载模块元数据信息，还是下载模块源码本身，vgo 原型都只使用 HTTP GET 操作。这里的一个关键设计点是：让静态服务器也能提供模块下载服务，所以 URL 中不能包含查询参数（query parameters）。

如前所述，自定义的域名可为托管在其他网站的模块指定一个基础 URL。目前的 vgo 模块托管服务都必须支持这 4 个请求（但与 vgo 的其他功能类似，也可能会有些修改）：

- GET `baseURL/module/@v/list`：获取已知的版本列表，一个版本一行
- GET `baseURL/module/@v/version.info`：获取关于该版本的元数据信息，JSON 格式
- GET `baseURL/module/@v/version.mod`：获取该版本的 go.mod 文件
- GET `baseURL/module/@v/version.zip`：获取该版本的模块源码包

JSON 格式的 `version.info` 文件结构可能会发生变化，但目前它长这样：

```go
type RevInfo struct {
	Version string    // version string
	Name    string    // complete ID in underlying repository
	Short   string    // shortened ID, for use in pseudo-version
	Time    time.Time // commit time
}
```

`vgo list -m -u` 命令会根据此结构中的 `Time` 字段显示每个可更新版本的 commit 时间。

一个通用的模块托管服务可选对非 semver 版本的 `version.info` 请求进行响应。其 vgo 命令类似：

```sh
vgo get my/thing/v2@1459def
```

此命令将获取 `1459def.info`，然后根据 `Time` 和 `Short` 字段组成一个伪版本号。

还有 2 种更非必选的请求形式：

- GET `baseURL/module/@t/yyyymmddhhmmss`：返回 `.info` 结尾的 JSON 内容，表示在指定时间之前的最新版本
- GET `baseURL/module/@t/yyyymmddhhmmss/branch`：返回同样的内容，但只会在指定分支中搜索 commit

上述可选响应可让 vgo 支持没打过 tag 的 commit。若 vgo 在添加一个新模块时找不到任何打过 tag 的 commit，则 vgo 会使用上面的第 1 种形式的请求来查找截至当前时间的最新 commit。在更新一个模块时，若依然没有任何打过 tag 的 commit，则也采用类似的动作。而基于分支的请求形式，则是供 gopkg.in 内部场景使用。这些形式还可在命令行中使用：

```sh
vgo get my/thing/v2@2018-02-01T15:34:45
vgo get my/thing/v2@2018-02-01T15:34:45@branch
```

也许提供这样的模块获取方式是不恰当的，但目前这些方式都存在于 vgo 原型中，所以我也在这里提一下。

# 模块代理服务

不管是个人还是公司，可能都会因以下理由而优先通过模块代理服务来下载 Go 模块：

- 下载快
- 高可用（译注：因为可缓存模块包，即使模块源码已删除，也依然可使用该模块）
- 更安全（译注：可避免泄露模块使用偏好等）
- 许可证
- 或其他原因

有了前面 2 个小节所介绍的 Go 模块格式和标准的下载协议后，可顺其自然创建一个模块代理服务。若已设置环境变量 `$GOPROXY`，则 vgo 会从此环境变量指定的基础 URL 中获取所有的模块，而非直接从模块所在的源码网站获取。为便于 debug，`$GOPROXY` 还可以 `file:///` 开头指向本地文件树。

我们打算写一个基本的代理服务，此服务可基于 vgo 自身的本地缓存来提供服务，并仅在需要新模块时再从外面下载。在多个计算机之间共享这样的模块代理服务可有助于减少对模块原始来源的重复下载。而更重要的是，即使模块原始来源在未来某天突然消失了，用户依然可以从模块代理服务的缓存中继续获取到该模块。模块代理服务还可用于限制用户不要下载新的模块，例如，服务管理员可使用白名单机制约束可下载的模块。对于公司环境来说，代理服务的上述 2 种模式可能会很常用。

也许有一天，可建立一个全球通用的模块代理分布式集群，作为 `go get` 默认使用的代理，从而为全球开发者提供快速下载体验，以及模块缓存服务。但目前这一设想暂未实现，现在我们的目标优先着重于：让 `go get` 在即使没有集中式代理服务的情况下，也能正常工作。

# vendor 模式的终结

vendor 目录主要有 2 个优点：

1. 保证可复现的构建：在 `go build` 时能精确使用指定版本的依赖包内容
2. 保证依赖包一直可用：即使源码网站中依赖包已被删除，本地也依然能使用这些依赖包

vendor 目录也有一些缺点：

1. 难以管理维护
2. 让源码仓库变得臃肿

而由于 vgo 的出现，vendor 机制变得有些多余，原因包括：

1. 在 `vgo build` 时，go.mod 文件已能精确指明所需使用的依赖包版本
2. 模块代理服务可提供模块缓存功能，即模块来源被删也依旧能用

vendor 目前存在的唯一理由可能只剩下：平滑过渡到新的版本机制。

每次构建一个模块时，vgo（或未来的 go 命令）将完全忽略 vendor 目录中的依赖包，而且 vendor 目录也不会被放在模块 zip 包中。为了让作者在迁移到 vgo 和 go.mod 的时候依然能支持未迁移到 vgo 的用户，vgo 提供了一个 `vgo vendor` 命令，供用户按需生成 vendor 目录，复现基于 vgo 的构建。

# 下一步？

本文所提到的细节可能会在未来有些修改，但当前版本的 go.mod 文件肯定会被未来的工具支持。请开始以下行动吧：

- 为你的包打上 release tag
- 添加 go.mod 到你的项目中

本系列接下来的文章将会详细介绍 go 工具命令行的变化细节。
