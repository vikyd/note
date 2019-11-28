# Semantic Import Versioning
原文：https://research.swtch.com/vgo-import

作者：[Russ Cox](https://swtch.com/~rsc/)

翻译时间：2019-11-28

# 基于语义的 import 版本化
（[Go 与版本](https://research.swtch.com/vgo)，第 3 部分）

发表时间：2018-02-21 周三 [PDF](https://research.swtch.com/vgo-repro.pdf)


# 正文
你是如何在现有的包中进行不兼容修改的？在任何包管理系统中，这都一个很根本的挑战，且是一个很根本的抉择。其选择会决定一个包管理系统的好用与否。（虽然同时也决定了包管理系统自身实现的复杂度，但还是用户体验更重要）

为回答这个问题，本文首先介绍一下 Go 语言的 `import 兼容性规则`：

> 如果一个旧包与新包共用相同的 import 路径，那么新包必须向后兼容旧包。

我们从 Go 刚开始的时候就主张这个原则，只是我们从未为其正式命名或给出如此直接的声明。

import 的兼容性规则极大简化了使用同一个包的不兼容版本的体验。若每个不同的版本分别拥有不同的 import 路径的话，预期中的 import 语句就没有歧义。这样一来，开发人员以及相关工具都可以更易理解 Go 的程序。

开发者现在都期望使用语义版本来描述包的版本，所以也我们采用了此模式。具体来说就是，一个名为 `my/thing` 的模块使用 `my/thing` 作为导入路径时，表示 v0 版本。在不兼容时期，通常预计会有破坏性修改，此时很多功能不保证兼容，而到了 v1 版本，即第一个稳定的大版本，也依然使用 `my/thing`。但发展到 v2 时，我们不使用原来稳定版本的表示方式 `my/thing`，而是使用一个新的名称：`my/thing/v2`。


![](https://research.swtch.com/impver@2x.png)

我将此称为 `基于语义的 import 版本化（semantic import versioning）`，也即：既使用语义版本，同时也遵循 import 的兼容性规则。

一年前，我也曾坚定的认为将版本放到 import 路径中是一件很丑陋、恶心、没必要的事。但过去这一年，我逐渐开始理解这样做居然可以极大的让系统变得更清晰、更简单。在本文，我想告诉你我的想法是如何发生改变的。



# 一个关于依赖包的故事
具体问题具体分析，下面将会讲一个故事，这个故事虽然是虚构的，但也是从真实问题而来。当 `dep` 发布后，有个写了一个 OAuth2 包的 Google 团队跑过来问我：如何才能改善使用同一个包的不兼容版本的情况，因为他们一直很想要那样的功能。我越想越发现这个问题并非想象中那么简单，至少在没有基于语义的 import 版本化的情况下不简单。

## 序言
从包管理工具的角度来看，有代码作者和代码用户这两种角色。假设 Alice、Anna、Amy 是不同代码包的作者。

- Alice 在 Google 工作，并写了一个 OAuth2 的包
- Amy 在微软工作，并写了一个 Azure 客户端的包
- Anna 在亚马逊工作，并写了一个 AWS 客户端的包
- Ugo 是这些包的用户，他正在开发云端应用 Unity，这个软件用到了上述 3 个包以及一些其他的包

作为作者，Alice、Anna、Amy 都需要在写完代码后发布新的版本。每个发布版本都列明了其所需的所有依赖包的具体版本。

作为用户，Ugo 需要利用其他包来构建他的 Unity 软件；他需要精确控制每个构建所需的依赖包版本；他还想按需更新依赖包到新的版本。

这 4 位朋友可能还想在包管理工具中使用更多功能，如发现新的包、测试、可移植性、自动诊断等等，但这些与本故事无关，暂且不提。

正如故事开始所说的，Ugo 的 Unity 构建依赖大概长这样：

![](https://research.swtch.com/deps-a1-short2.png)


## 第一章
每个人都是分别独立写代码的。

在 Google，Alice 正忙于为 OAuth2 新设计一个更简单、更易用的 API。这个新的 API 依然能做旧包所做的所有事，但 API 的数量减少了一半。她将这个新包发布为 OAuth2 r2。（`r` 表示修订。可以看到，这个修订版本号除了作为序号，并不能代表任何其他含义：也就是说，这不是语义的版本）

在微软，Amy 正享受着自己的长假，她的团队决定在她休假结束之前暂时不做与 OAuth2 r2 相关的任何修改。因此 Azure 的包会继续使用 OAuth2 r1。

在亚马逊，Anna 发现 OAuth2 r2 能帮她减少 AWS r1 中大量的丑陋代码，因此她将 AWS 修改为使用 OAuth2 r2。她在此过程中顺便修复了一些错误，并最终发布为 AWS r2。

Ugo 收到关于 Azure 的相关 bug 报告，并已找到 Azure 客户端库中的错误。Amy 在休假之前已经在 Azure r2 中修复了该 bug。Ugo 在自己的 Unity 中跑了一下测试用例，也确认 Azure 的旧包确实有问题，于是用包管理工具将 Azure 升级到 r2 版本。

更新后，Ugo 的构建如下所示：

![](https://research.swtch.com/deps-a1.5.png)

Ugo 再次跑了下新的测试用例和旧的测试用例，确认都能成功。然后，他锁定了 Azure 的版本，并发布了新版的 Unity。


## 第二章
有一天，亚马逊推出了他们的新产品 Amazon Zeta Functions。为此，Anna 在 AWS 包中添加了对 Zeta 的支持，并发布为 AWS r3。

当 Ugo 听到亚马逊发布了 Zeta，他写了一些测试程序，对运行效果非常兴奋，以至于连午饭都不吃就开始更新他的 Unity。这次的更新与上次不同。Ugo 想使用最新版的 Azure r2、AWS r3、Zeta 来构建 Unity。但问题来了，Azure r2 需要 OAuth2 r1（不是 r2），而 AWS r3 需要 OAuth2 r2（不是 r1）。这不就是经典的钻石依赖吗？但 Ugo 并不想关心背后如何，他的目的只有构建 Unity。

问题在于，他们几个人都没有做错什么。Alice 写了一个更好的 OAuth2 包。Amy 修复了 Azure 的 bug 后去休假了。Anna 认为 AWS 应使用新的 OAuth2（可理解为是内部实现的细节），并增加了对 Zeta 的支持。Ugo 纯粹是想用最新版的 Azure 和 AWS 包来构建他的 Unity。很难说这是谁的锅，若一定要说是谁错了，可能就是包管理工具的错了。我们一直认为 Ugo 的 Unity 中只能允许一个 OAuth2 的版本，可能这就是问题的根源。或许包管理工具应在同一个构建中允许同一个包的多个不同版本，下面这个例子尝试解释这样做的必要性。

Ugo 被这个问题卡住了，所以他去 StackOverflow 搜索解决方案。经过一番搜索，Ugo 发现包管理工具支持一个名为 `-fmultiverse` 的 flag，允许支持多版本。所以 Ugo 的程序构建会变成这样：

![](https://research.swtch.com/deps-a2-short@2x.png)

Ugo 试了一下，发现还是不行。经过一番摸索后，Ugo 发现 Azure 和 AWS 都使用了一个名为 Moauth 的 OAuth2 中间件。这个中间件可简化 OAuth2 的部分处理逻辑。但 Moauth 并不是一个完整的独立 API，用户依然需要直接 import OAuth2，然后使用 Moauth 来简化其中的部分 API 调用。Moauth 所涉及的部分在 OAuth2 r1 和 r2 都是一样的，所以 Moauth r1（目前只有这个版本）对两者都兼容。Azure r2 和 AWS r3 都使用了 Moauth r1。若只单独使用 Azure r2 或 AWS r3 是没问题的。但此时 Ugo 的 Unity 构建实际会变成下图：

![](https://research.swtch.com/deps-a3-short@2x.png)

Unity 同时需要 OAuth2 的两个不同版本，但此时 Moauth 应 import 哪个版本的 OAuth2 呢？

为了让构建成功，貌似我们需要区分 Moauth 的两个版本：一个 import OAuth2 r1，供 Azure 使用；一个 import OAuth2 r2，供 AWS 使用。Ugo 再次去 StackOverflow 搜索，发现包管理工具还支持另一个名为 `-fclone` 的 flag。用了这个 flag 后，Ugo 的程序构建又变成下图这样：

![](https://research.swtch.com/deps-a4-short@2x.png)

尽管 Ugo 还是觉得会有更多潜在的坑，但这个构建确实成功了，也能跑通测试用例了。Ugo 想了下，还是先回家吃晚饭吧（译注：也即这个坑就这么耗费了 Ugo 一个下午）。


## 第三章
Amy 休假结束后回到微软。她决定 Azure 包继续使用 OAuth2 r1 一段时间。但同时也发现将 Moauth 的 token 直接传到 Azure API 中可让用户使用更方便，于是她将此功能添加到 Azure 包中，保持向后兼容，并发布为 Azure r3。另一边，亚马逊的 Anna 也很喜欢基于 Moauth 的 API，于是也添加类似的 API 到 AWS 包中，并发布为 AWS r4。

Ugo 发现了上述两个更新，为了使用基于 Moauth 的 API，他同时将 Azure、AWS 两个包更新到最新版本。这次他又搞了一个下午。首先，他只更新 Azure 和 AWS，但不修改 Unity，此时构建成功！

Ugo 很高兴，于是继续修改 Unity 代码以使用基于 Moauth 的 Azure API，此时构建也成功了。Ugo 继续修改 Unity 使用基于 Moauth 的 AWS API，此时构建失败了。Ugo 觉得奇怪，于是尝试回退 Unity 对 Azure 的修改，仅保留对 AWS 的修改，此时构建成功了。之后，他继续将原来对 Azure 的修改再次应用到 Unity，此时构建又失败了。Ugo 不得不再次到 StackOverflow 寻求帮助。

Ugo 发现只使用其中一个基于 Moauth 的 API （如 Azure），且使用这些构建参数 `-fmultiverse -fclone` 时，Unity 实际暗含的构建如下图所示：

![](https://research.swtch.com/deps-a5-short@2x.png)

但当他同时使用两个基于 Moauth 的 API 时，Unity 中唯一的 `import "moauth"` 会变得有歧义。因为 Unity 是 main 包，这个包是不能复制的（相对于 Moauth 来说）：

![](https://research.swtch.com/deps-a6-short@2x.png)

Ugo 发现 StackOverflow 有个评论提出了一种折中的办法：将对 Moauth 的 import 移到两个不同的包中，Unity 再 import 这两个包。他尝试了一下，居然成功了：

![](https://research.swtch.com/deps-a7-short@2x.png)

Ugo 终于可以准时下班回家了。但他开始对这个包管理工具感到不太满意，不过也成了 StackOverflow 的忠实粉丝。


# 使用语义版本化后
我们来加一些魔法，以语义版本（而非之前的 `r` 版本号）的方式重新讲一下前面的故事。

下面是变化的地方：

- OAuth2 r1 `—>` OAuth2 1.0.0
- Moauth r1 `—>` Moauth 1.0.0
- Azure r1 `—>` Azure 1.0.0
- AWS r1 `—>` AWS 1.0.0
- OAuth2 r2 `—>` OAuth2 2.0.0（部分不兼容 API）
- Azure r2 `—>` Azure 1.0.1（修复 bug）
- AWS r2 `—>` AWS 1.0.1（修复 bug，内部使用了 OAuth2 2.0.0）
- AWS r3 `—>` AWS 1.1.0（升级功能：添加了 Zeta）
- Azure r3 `—>` Azure 1.1.0（功能升级：添加了基于 Moauth 的 API）
- AWS r4 `—>` AWS 1.2.0（功能升级：添加了基于 Moauth 的 API）

除此之外，故事中其他的内容保持不变。Ugo 再次碰到相同的问题，为了构建 Unity 成功，他再次去 StackOverflow 寻找解决方法（如构建 flag、重构方式等）。根据 [semver](https://semver.org/)，Ugo 应该不会碰到构建不成功的问题：因为 Unity import 的包都没有升级其主版本号。但实际 OAuth2 升级了主版本号，但 OAuth2 不是 Unity 的直接依赖，而是间接依赖。那问题出在哪里？

问题在于，semver 只用于选择版本号和比较版本号大小，没有更多其他的功能了。semver 不负责处理升级主版本号后的应对策略。

semver 最重要的价值在于：鼓励尽可能保持向后兼容。下面摘自其 FAQ：

> 不要在被大量代码依赖的项目上轻易引入不兼容的修改。要清楚破坏性升级带来的代价。在必须升级主版本号来发布不兼容的修改前，你应衡量好代价与收益孰轻孰重。

我十分赞同这句话：`不要轻易引入不兼容的修改`。但我也觉得，semver 的不足之处在于 `不得不升级主版本号` 时只是让你去 `衡量好代价与收益孰轻孰重`，并没有实际解决问题。若想遵循 semver，只需在引入不兼容修改时升级主版本号即可，这很容易，但也不十分适合实际情况，上述故事就是一个反例。

从 Alice 的角度来看，当她进行 OAuth2 的 API 的不兼容修改后再发布时，按 semver 的理解似只要要把版本号升级为 2.0.0 就没问题了。但实际上却确实导致了 Ugo 构建 Unity 时碰到了许多问题。

语义版本解决了如何让作者告诉用户版本号所代表含义这一重要问题，但也点到即止。我们并不能用 semver 本身来解决更大构建的问题。为此，我们需要寻找能解决构建问题的方法，然后，再考虑如何将 semver 融入其中。


## 使用 import 版本化后
再来一次前面故事，但这次会使用 import 兼容性规则：

> 在 Go 语言中，如果一个新包与旧包的 import 路径相同，则新包必须向后兼容旧包。

现在故事的变化更大了。依然是上述故事，但在 `第一章` 中，OAuth2 的作者 Alice 决定创建一个部分不兼容的 OAuth2 API。此时 Alice 不能再使用 `oauth2` 的 import 路径了，于是将包改名为 Pocoauth，并将 import 路径改为 `pocoauth`。Moauth 的作者 Moe 发现此情况后，他必须也创建一个新的包，命名为 Pocomoauth，并将 import 路径改为 `pocomoauth`。AWS 的作者 Anna 为了使用 OAuth2 的新 API，也将 AWS 代码中的 import 路径从 `oauth2` 改为 `pcocauth`，从 `moauth` 改为 `pocomoauth`。之后故事依然按原来的情节继续，最终 Anna 发布了 AWS r2 和 AWS r3 版本。

在第二章中，当 Ugo 高兴地开始引入亚马逊 Zeta 后，所有构建都成功了。构建中，所有包的 import 都精确指明了其所需的包版本。Ugo 也不需要去 StackOverflow 寻找特殊的构建 flag 参数了。Ugo 只需 5 分钟就把所有事情搞定了，可以开始愉快的午餐了。

![](https://research.swtch.com/deps-b1-short@2x.png)

在第三章中，Azure 作者 Amy 将基于 Moauth 的 API 添加到 Azure 中，此时 Anna 也将基于 Pocomoauth 的 API 添加到 AWS 中。

当 Ugo 继续去更新 Azure、AWS 到最新版本时，构建依然都成功了。Ugo 此次更新完全不需要修改他自己的代码。

![](https://research.swtch.com/deps-b2-short@2x.png)

在故事的结尾，Ugo 甚至都无需想起还有包管理工具这回事。一切都没问题，Ugo 几乎没注意到包管理工具的存在。

相对于前面 `仅使用语义的版本化` 的故事，本故事使用 import 兼容性规则后，有两个关键的改变：

- Alice 创建不向后兼容的 OAuth2 API 后，她必须发布为一个新的包（Pocoauth）
- Moe 的 Moauth 包由于直接在其 API 中暴露了对 OAuth2 的类型定义，所以 Moe 也必须将更新后的包发布为新的包（Pocomoauth）

最终 Ugo 的 Unity 程序能轻松构建成功，因为 Alice、Moe 的包都明确区分了不同的结构，为构建成功提供了保障。使用 import 兼容性规则后，只增加了作者少量的额外工作，却能带给包作者、全体用户很大的便利。相对来说，增加类似 `-fmultiverse -fclone` 的构建参数、需用户修改代码就显得太麻烦了。

对于每个不向后兼容的 API 修改，都需要付出一定代价来引入新的名字。但正如 semver 的 FAQ 所说的：包作者都应更好好的想清楚不兼容修改所造成的影响，再做决定。而且，使用版本化的 import 时，这些额外代价能给用户体验带来质的提升。

版本化的 import 的其中一个好处是：对 Go  开发者来说，包的名称和 import 路径都是很容易理解的概念。如果你跟一个包作者说，引入不向后兼容的修改后需要创建一个不同的 import 包路径。那他一下子就知道这样做对包用户的影响：包用户也需要去修改 import 路径，也即 Moauth 不能使用新包了，等等。

由于可以更清晰地预测对用户的影响，包作者可能作做出很不一样的、更好的修改决定。

- Alice 可能就会去思考如何引入更新的、更清晰的 API 到原有的 API 中，以免变成不同的包
- Moe 可能就会更谨慎决定是否在 Moauth 中同时支持 OAuth2 和 Pocoauth，以避免创建新的 Pocomoauth 包
- Amy 可能就会决定更新到 Pocoauth、Pocomoauth，而非继续使用基于过期的 OAuth2 和 Moauth 的 Azure API
- Anna 可能就会让 AWS API 同时支持 Moauth 和 Pocomoauth，这样 Azure 的用户就可更易切换了

相比之下，semver `主版本碰撞` 的含义还不够清晰，因为它并没有对包作者施加相关的压力。清晰的做法是给包作者一些额外工作，评价的依据是这样做能否给用户带来真正的便利。通常，这样的平衡取舍是有道理的，因为包的目的是拥有更多的用户，至少用户的数量应大于作者的数量。


## 基于语义的 import 版本化
前面章节介绍了版本化 import 的版本更新让构建变得更简单、可预测。但对于包作者来说，麻烦的是每次引入不向后兼容的修改时都要想一个新包名，而且这样对用户也不友好。若不经过一番搜索的话，Amy 根本不知道该选 OAuth2 还是 Pocoauth？相比之下，基于语义的 import 版本化就很简单：很明显 OAuth2 2.0.0 就是 OAuth2 1.0.0 的不兼容升级版本。

我们可以使用语义版本化，并遵循 import 兼容性规则，在 import 路径中加入主版本号，而非发明一个很好听但不太相关的新名字，如 Pocoauth：

- Alice 可将她的新 API 命名为 OAuth2 2.0.0，import 路径变为 `oauth2/v2`
- Moe 对应 OAuth2 2.0.0 的新包可称为 Moauth 2.0.0（import 路径为 `moauth/v2`），同时保持 Moauth 1.0.0 依然与 OAuth2 1.0.0 对应

当 Ugo 在第二章中添加对 Zeta 的支持时，他的构建如下图所示：

![](https://research.swtch.com/deps-c1-short@2x.png)

由于 `moauth` 和 `moauth/v2` 是很明显的不同的包，所以 Ugo 很清楚知道他所需的是什么，如 Azure 用 `moauth`，AWS 用 `moauth/v2`，也即这两个路径都要导入。

![](https://research.swtch.com/deps-c2-short@2x.png)

为了保持与目前 Go 语言的使用方式兼容，不产生向后不兼容的 API 修改，我认为无需将 `v1` 添加在 import 路径中：应使用 `moauth`，而非 `moauth/v1`。类似的，v0 的版本身就不考虑向后兼容（译注：因为此时版本功能未稳定下来），所以也无需在 import 路径中添加版本号。用户在使用 v0 版本的依赖包时，应已清楚了解这可能会带来很多不兼容性的修改，并有责任对不兼容修改带来的问题进行处理。（当然，很重要的前提是不要自动升级依赖包。下一篇文章将会介绍最小版本选择是如何做到这一点的。）



# 指明功能的名称 & 不可变的含义
二十年前，Rob Pike 和我在修改 Plan 9 的 C 语言库时，Rob 曾教给我一个经验法则：当你修改一个函数的行为时，首要的原则是你也应同时修改函数的名称，让旧的名称保持旧的功能。为不同功能的函数引入新的名称，并删除旧名称的函数，我们就可保证编译器在需要该更新、重新测试的每行代码都发出错误提示，而非默默的把错误的代码编译通过。对于用户来说，他们可以在编译发生错误时快速发现问题，而非经过漫长的调试才知道坑在何处。特别是在今天到处都在使用分布式版本管理工具的时代，这种问题成倍放大，修改名字显得越发重要。多人协作进行代码合并时，旧功能的代码不应被新功能的代码悄悄的替换掉。

当然，删除旧函数仅适用于你能找到所有用户，或用户都知道自己应负责跟进修改，例如 Plan 9 这样的研究性系统。对于对外暴露的 API，最好还是保留旧函数及旧函数名，只为新功能增加新名字。Rich Hickey 在他的 2016 年演讲 [Spec-ulation](https://www.youtube.com/watch?v=oyLBGkS5ICk) 中提到，这种只添加新名称、新含义，从不删除旧名称、旧含义的做法，正是函数式编程所鼓励的独立变量或数据结构的方法。函数式的方法带来的好处是，在小规模的编程中让代码更清晰更可预测，并且当 import 兼容性规则应用到全部 API 时，好处更明显：依赖地狱实际只是一个巨大的突变地狱。这只是演讲中的一个小点，整个演讲都很值得去看一下。

在早期的 `go get` 命令中，当人们问到如何进行不向后兼容的修改时，我们（基于多年来关于这类软件修改的直觉）总是只告诉他们应基于 import 版本化规则，但并没明确说明为什么这种方法好于不主版本号放到 import 路径中。Go 1.2 添加了一个关于包版本化的 FAQ 条目，提出了以下基本建议（直到 Go 1.10 都没变过）：

> 对外发布的包在演进过程中应尽量保持向后兼容性。[Go 1 兼容性指南（Go 1 compatibility guidelines）](https://golang.org/doc/go1compat.html) 是一个很好的参考：不要删除已导出的名称，鼓励使用组合文字来命名，等等。若需不同的功能，请添加新名称而非修改旧名称的功能。若需引入不兼容修改，应创建一个新包并使用新的 import 路径。


# 避免单例问题
对基于语义的 import 版本化的普遍反对意见是：如今的包作者在指定的构建中希望永远只提供一个副本。由于预期外的对单例的复制，允许在不同主版本使用多个包可能会导致一些问题。譬如，注册 HTTP 的 handler。若包 `my/thing` 为 `/debug/my/thing` 注册了一个 HTTP handler，则拥有此包的两个副本时将会导致重复注册（译注：因为单例模式），从而导致程序在注册时发生 panic。另一个问题是，若程序中有 2 个 HTTP 栈，但只能有 1 个 HTTP 栈可监听 80 端口，将导致有一半的 handler 使用不了，这不符合我们预期。Go 开发者已在打包到 `vendor` 目录时碰到类似问题。

迁移到 `vgo` 和基于语义的 import 版本化后，可明了、简化当前情况。作者可保证每个主版本对应的包分别对应其唯一的实例，从而避免互相影响导致的不可控的重复问题。在 import 路径引入主版本号后，作者就能很清楚知道 `my/thing` 和 `my/thing/v2` 是不同的两个包，并应允许二者并存。可能也就表示 `/debug/my/thing/v2` 会输出 v2 的 debug 信息。可能也意味着可互相协作，v2 可负责注册 handler，同时也为 v1 提供一个钩子（hook）来提供展示到页面的信息。这也就意味着 `my/thing` 可以 import `my/thing/v2`，反之亦然。总之，使用了不同的 import 路径后，更易理解、也更易操作了。相反，若 v1、v2 都使用相同的 import 路径 `my/thing`，则会变得很难做到如何从其中一方导入另一方。


# API 的自动更新
允许 v1 和 v2 并存于一个大型程序中的一个包中的其中一个主要原因是：可以更新客户端中的某个版本，且依然能构建成功。这是渐进式代码修复的一个特例。（关于渐进式代码修复的问题可见我 2016 年的文章：[在 Go 帮助下的代码库重构 - Codebase Refactoring (with help from Go)](https://talks.golang.org/2016/refactor.article)）

除了让构建能继续成功，基于语义的 import 版本化对于渐进式的代码修复还有另一个重要的好处，即我在前面章节所介绍的：一个主版本号的包可被 import 到另一个主版本号的包中使用。v2 的 API 可很简单就能设计成 v1 的包装器，反之也没问题。这样一来，各主版本之间可互相复用代码，可采用适合的设计模式，可复用为别名，甚至还可让客户端同时使用 v1、v2 进行协作。还可解决 API 自动更新中的一个关键技术性问题。

在 Go 1 以前，我们重度依赖 `go fix` 命令，因为用户更新 Go 版本后发现他们的程序编译失败，所以需运行此命令来修复更新带来的问题。我们大部分的程序分析工具都无法对本身就编译不通过的代码进行更新操作，因为这些工具都要求被分析的是之前可编译成功的程序。同时，我们也在想如何才能让 Go 标准库之外的包作者自定义他们特定的 API 更新操作。若可以，同一个程序中以不同名称使用同一个包互不兼容的版本，则可使得：若 v1 的 API 可实现为对 v2 的包装器形式，且此包装器还可用作修复规则。例如，假设 v1 API 包含 `EnableFoor`、`DisableFoo` 两个函数，v2 将这两个函数替换成了一个函数 `SetFoo(enabled bool)`。当 v2 发布后，v1 就可被用作 v2 的包装器：

```go
package p // v1

import v2 "p/v2"

func EnableFoo() {
	//go:fix
	v2.SetFoo(true)
}

func DisableFoo() {
	//go:fix
	v2.SetFoo(false)
}
```

`//go:fix` 这个注释可用于指示 `go fix` 将包装器的函数体提取到调用端的代码中。运行 `go fix` 命令时，会自动将 v1 的 `EnableFoo` 重写为 v2 的 `SetFoo(true)`。由于重写的是纯 Go 代码，因此重写可很容易指定规则和检查类型。更妙的是，这种重写明显是安全的：v1 的 `EnableFoo` 已经调用了 v2 的 `SetFoo(true)`，所以重写调用端的代码并不会改变程序原来的含义。

`go fix` 还可以用于进行反向的修复，如 v1 中有 `SetFoo`，v2 中有 `EnableFoo`、`DisableFoo`，则 v1 的 `SetFoot` 可以这样实现：

```go
package q // v1

import v2 "q/v2"

func SetFoo(enabled bool) {
	if enabled {
		//go:fix
		v2.EnableFoo()
	} else {
		//go:fix
		v2.DisableFoo()
	}
}
```

然后，`go fix` 就可将 `SetFoo(true)` 更新为 `EnableFoo()`，将 `SetFoo(false)` 更新为 `DisableFoo()`。这种修复甚至可用于同一主版本内的更新。例如，v1 将要废弃（但仍保留）`SetFoo`，并引入新的 `EnableFoo` 和 `DisableFoo`。此时的修复也能帮助调用端从废弃的 API 更新到新 API。

准确来说，目前还没实现这些特性，但总会有一天能实现，一切都归功于允许不同的东西对应不同的名称。这些例子说明了为特定代码行为赋予持久的、不可变的名称所带来的的威力。我们都应遵循这样的规则：当你修改了某样东西，那你应同时修改它的名称。


# 致力于兼容性
基于语义的 import 版本化增加了包作者的工作。他们不能在直接发布 v2 时使用与 v1 一样的名称，然后让像 Ugo 这样的用户自己去填坑。若包作者真那样直接发布了，受伤的必然是他们的用户。在我看来，若有这么一个机制会不错：伤害用户变得困难，且能驱动作者朝对用户伤害小的方向行动。

一般来说，Sam Boyer 已在 GopherCon 2017 中谈到包管理工具应如何协调我们的相互沟通、开发人员的协作。我们正面临选择：我们是否想在一个为兼容性优化、平滑过渡、互相协作的机制中工作？还是想在为不兼容性而优化，还允许作者随意破坏用户的程序？基于语义的 import 版本化，尤其是基于语义的 import 版本化将主版本号放到 import 路径后，我们终于可以保证我们为第一种情况而工作。

让我们为兼容性做得更好吧。

