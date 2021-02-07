# Version SAT

原文：https://research.swtch.com/version-sat

作者：[Russ Cox](https://swtch.com/~rsc/)

翻译时间：2019-12-15

# 软件版本的 SAT 问题

发表时间：2016-12-13 周二

# 目录

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [译注](#%E8%AF%91%E6%B3%A8)
- [译前名称解释](#%E8%AF%91%E5%89%8D%E5%90%8D%E7%A7%B0%E8%A7%A3%E9%87%8A)
- [正文](#%E6%AD%A3%E6%96%87)
- [证明版本选择是 NP 完全问题](#%E8%AF%81%E6%98%8E%E7%89%88%E6%9C%AC%E9%80%89%E6%8B%A9%E6%98%AF-np-%E5%AE%8C%E5%85%A8%E9%97%AE%E9%A2%98)
- [各种包管理器的实现方式](#%E5%90%84%E7%A7%8D%E5%8C%85%E7%AE%A1%E7%90%86%E5%99%A8%E7%9A%84%E5%AE%9E%E7%8E%B0%E6%96%B9%E5%BC%8F)
- [路在何方](#%E8%B7%AF%E5%9C%A8%E4%BD%95%E6%96%B9)
- [相关工作](#%E7%9B%B8%E5%85%B3%E5%B7%A5%E4%BD%9C)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# 译注

本文主要讲了 3 个点：

- 原因：版本满足性问题是一个 NP 完全问题，并给出了证明
- 现状：现存各语言的包管理器如何应对此问题
- 可行性分析：尝试避免 NP 完全问题来解决版本相关问题

# 译前名称解释

- package：译作包，即软件包或模块的意思
- dependency：译作依赖，即软件包需要其他包才能运行的意思
- version selection：译作版本选择，即寻找依赖包时该选择哪些版本

# 正文

依赖地狱是一个 NP 完全问题。但说不定我们可以爬出来。

包版本选择问题是指找到一组依赖关系，这些依赖关系可用于构建顶层的包 P，且 P 是完整的（满足所有依赖关系）和兼容的（没有选择任何互不兼容的依赖包）。由于钻石依赖问题，这样的依赖集合可能并不存在：譬如 A 依赖 B、C；B 依赖 D 的版本 1，而非版本 2；C 依赖 D 的版本 2，而非版本 1。此时，假设不允许同时选择 D 的两个不同版本，则无法构建 A。

![钻石依赖](https://research.swtch.com/version-sat.svg)

包管理器需要一个算法来处理包版本选择的问题：当你运行 `apt-get install perl` 时，包管理器默认会给你安装最新版本的 Perl，然后开始寻找满足 Perl 所有依赖的方法，若找不到则打印 Perf 安装不了的详细原因。你很可能会疑惑：在最坏的情况下，解决包版本选择问题有那么难吗？你肯定不希望你所用的包管理器需要几个小时、几天甚至几年才能算出 Perl 是否能安装吧。

不幸的是，版本的选择问题是一个 NP 完全问题，也即是说我们几乎不可能找到可对所有输入情况都能快速得出结果的算法。本文主要介绍 3 点：

- 证明版本选择是一个 NP 完全问题
- 调研现存包管理器如何应对版本选择问题
- 简要地讨论能否找到一种方法以避免 NP 完全问题

# 证明版本选择是 NP 完全问题

面对 NP 完全的问题时，我们需要将具有丰富输出算法的现实世界简化为关于复杂度理论的有限世界，在这样的世界中算法只有布尔类型的输入：true 或 false。在这个复杂度理论的世界里，我们定义 VERSION 问题（全大写）为有效版本的选择问题。这个布尔类型的 VERSION 问题只是我们最初问题的一半，我们也能证明它是 NP 完全问题。为了证明此问题，我们需要证明 2 个互相独立的事实：

- VERSION 是 NP 问题
- VERSION 是 NP 困难问题（NP-hard）

若每个为 true 的答案都能在多项式时间复杂度中被验证，则此问题是 NP 的。

VERSION 是 NP 问题，因为任何为 true 的答案都能通过列举所选择的包版本来验证。所选择的版本列表的大小不会大于输入，且能在不差于输入的二次方时间复杂度内验证其正确性（甚至可以是线性复杂度，随不同计算模型的细节而变）。

若一个问题的有效解可被约化为 NP 中所有其他问题的有效解，则此问题是 NP 困难问题。NP 困难问题目前几乎不可解决，但对于我们来说能做到下面就已经足够了：将 VERSION 的有效解约化为某种 NP 困难（NP-hard）的有效解（称之为 HARD），并依赖于别人已证明的一个事实：NP 困难问题的有效解可被约化为任何其他 NP 问题的有效解。

NP 完全问题（同时属于 NP 和 NP 困难）的其中一个有用例子是 3-SAT。在 3-SAT 中，所有输入都是由一定数量的布尔值组成的子句，每 3 个字面量（literal）为一个子句，每个字面量是 1 个布尔变量或其反值，子句与子句间的关系可以为 `连接（conjunction）`（即 AND）或 `分离（disjunctions）`（即 OR）。例如，下面是 3-SAT 的一种输入（`∧`：AND，`∨`：OR，`¬`：NOT）：

<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;(&space;\neg&space;x_{1}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;\neg&space;x_{3})&space;\wedge&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{3}&space;\vee&space;\neg&space;x_{4})&space;\wedge&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;x_{3})&space;\wedge&space;(x_{2}&space;\vee&space;x_{2}&space;\vee&space;x_{2})" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;(&space;\neg&space;x_{1}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;\neg&space;x_{3})&space;\wedge&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{3}&space;\vee&space;\neg&space;x_{4})&space;\wedge&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;x_{3})&space;\wedge&space;(x_{2}&space;\vee&space;x_{2}&space;\vee&space;x_{2})" title="( \neg x_{1} \vee \neg x_{2} \vee \neg x_{3}) \wedge (\neg x_{2} \vee \neg x_{3} \vee \neg x_{4}) \wedge (\neg x_{2} \vee \neg x_{2} \vee x_{3}) \wedge (x_{2} \vee x_{2} \vee x_{2})" /></a>

此式子在以下情况时结果为 true：<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;x_{1}&space;=&space;0,&space;x_{2}&space;=&space;1,&space;x_{3}&space;=&space;1,&space;x_{4}&space;=&space;0," target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;x_{1}&space;=&space;0,&space;x_{2}&space;=&space;1,&space;x_{3}&space;=&space;1,&space;x_{4}&space;=&space;0," title="x_{1} = 0, x_{2} = 1, x_{3} = 1, x_{4} = 0," /></a> 。

若继续扩展此式子：

<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;(&space;\neg&space;x_{1}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;\neg&space;x_{3})&space;\wedge&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{3}&space;\vee&space;\neg&space;x_{4})&space;\wedge&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;x_{3})&space;\wedge&space;(x_{2}&space;\vee&space;x_{2}&space;\vee&space;x_{2})&space;\wedge&space;(x_{1}&space;\vee\neg&space;x_{2}&space;\vee&space;x_{4})" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;(&space;\neg&space;x_{1}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;\neg&space;x_{3})&space;\wedge&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{3}&space;\vee&space;\neg&space;x_{4})&space;\wedge&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;x_{3})&space;\wedge&space;(x_{2}&space;\vee&space;x_{2}&space;\vee&space;x_{2})&space;\wedge&space;(x_{1}&space;\vee\neg&space;x_{2}&space;\vee&space;x_{4})" title="( \neg x_{1} \vee \neg x_{2} \vee \neg x_{3}) \wedge (\neg x_{2} \vee \neg x_{3} \vee \neg x_{4}) \wedge (\neg x_{2} \vee \neg x_{2} \vee x_{3}) \wedge (x_{2} \vee x_{2} \vee x_{2}) \wedge (x_{1} \vee\neg x_{2} \vee x_{4})" /></a>

则不管变量为任何值，此式子都无法成立，结果均为 false。

3-SAT 的一般形式定义为：一个式子 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;F" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;F" title="F" /></a> 由子句 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;C_{1}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;C_{1}" title="C_{1}" /></a> 至 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;C_{n}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;C_{n}" title="C_{n}" /></a> 用 AND（<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;\wedge" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;\wedge" title="\wedge" /></a>）连成。每个子句 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;C_{i}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;C_{i}" title="C_{i}" /></a> 由 3 个字面量用 OR（<a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;\vee" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;\vee" title="\vee" /></a>）连成，每个字面量是变量 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;V_{1}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;V_{1}" title="V_{1}" /></a> 至 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;V_{m}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;V_{m}" title="V_{m}" /></a> 中的 1 个或其反值。变量 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;x_{j}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;x_{j}" title="x_{j}" /></a> 可对应的字面量为 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;x_{j}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;x_{j}" title="x_{j}" /></a> 或 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;\neg&space;x_{j}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;\neg&space;x_{j}" title="\neg x_{j}" /></a>。子句中允许重复的字面量，如前面的 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;x_{3})" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;(\neg&space;x_{2}&space;\vee&space;\neg&space;x_{2}&space;\vee&space;x_{3})" title="(\neg x_{2} \vee \neg x_{2} \vee x_{3})" /></a> 和 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;(x_{2}&space;\vee&space;x_{2}&space;\vee&space;x_{2})" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;(x_{2}&space;\vee&space;x_{2}&space;\vee&space;x_{2})" title="(x_{2} \vee x_{2} \vee x_{2})" /></a>。

我们可将 3-SAT 的任意实例转换为 VERSION 的实例，并具有相同的结果。关于包管理器，我们只需做以下假设：

1. 一个包可依赖于 0 或多个其他包的版本
2. 若安装一个包，必须也安装其所有依赖包
3. 包的每个版本可依赖不同的包
4. 不允许同时安装一个包的不同版本

我们将包 `P` 的版本 `V` 缩写为 `P:V`（区别：3-SAT 式子是*斜体*的，包或版本是 `高亮` 的）。一个包若依赖 `P`，则必须精确指明版本 `V`，而不能模糊地指 `V-1` 或 `V+1`。

给定一个 3-SAT 式子，我们可以创建：

- 包 `F` 表示整个式子
- 包 `C1`，`C2`，...，`Cn`：表示每个子句
- 包 `X1`，`X2`，...，`Xm`：表示每个变量

> ↑ 译注：假设你有一个包依赖了 `C1` 包，而 `C1` 包也依赖了 `X1` 等的子包，所以 `C1`、`X1` 都是包

每个包 `Xj` 有 2 个版本：`Xj:0` 和 `Xj:1`。如前面提到的 `Xj:0` 和 `Xj:1` 是互相冲突的，不能同时安装。`Xj:1` 对应原式子中的 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;x_{j}=1" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;x_{j}=1" title="x_{j}=1" /></a>。

包 `Ci` 有 3 个版本：0、1、2，每个版本依赖了对应子句中的字面量。举例来说，若子句 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;C_{5}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;C_{5}" title="C_{5}" /></a> 为 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;(x_{1}&space;\vee\neg&space;x_{2}&space;\vee&space;x_{4})" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;(x_{1}&space;\vee\neg&space;x_{2}&space;\vee&space;x_{4})" title="(x_{1} \vee\neg x_{2} \vee x_{4})" /></a>，则 `C5:0` 依赖了 `X1:1`，`C5:1` 依赖了 `X2:0`（译注：此处 `X2:0`中的 0 对应了式子中的 NOT 符号 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;\neg" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;\neg" title="\neg" /></a>），`C5:2` 依赖了 `X4:1`。`Ci:k` 若能安装成功则代表对应的 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;C_{i}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;C_{i}" title="C_{i}" /></a> 的第 k 个字面量为 true（因此 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;C_{i}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;C_{i}" title="C_{i}" /></a> 也为 true）。

包 `F` 依赖了 `C1`，`C2`，...，`Cn`。若 `F` 能安装成功，则说明所有的 `Ci` 也能安装成功，也即 `Ci`
对应的所有子句 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;C_{i}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;C_{i}" title="C_{i}" /></a> 也为 true，因此对应的 3-SAT 式子 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;F" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;F" title="F" /></a> 也为 true。

若包管理器可找到一种方法将包 `F` 安装成功，则原式子的每个变量 <a href="https://www.codecogs.com/eqnedit.php?latex=\inline&space;\fn_cm&space;x_{j}" target="_blank"><img src="https://latex.codecogs.com/svg.latex?\inline&space;\fn_cm&space;x_{j}" title="x_{j}" /></a> 均可以与 `Xj:1` 的安装状态对应，也即 3-SAT 式子结果为 true。同样的，若 3-SAT 式子结果为 true，则包管理器也就能找到对应的依赖来满足 `F` 包的安装。因此，我们已将 3-SAT 的实例转换到对应的 VERSION 实例，且结果一样。因此，可用 VERSION 解决 3-SAT 问题，也即说明 VERSION 是 NP 困难问题。

由于 VERSION 既是 NP 问题（前面已提到），也是 NP 困难问题，所以 VERSION 是 NP 完全问题（译注：NP、NP 困难的交集就是 NP 完全）。

# 各种包管理器的实现方式

前面章节的假设所设置的限制其实并不多，限制如下：一个包可依赖一系列其他包，这些依赖包的版本可随时改变，还可被限制为特定的版本，同一个包的不同版本可能会互相冲突。对于包管理器来说，这些限制算是最基本要求。有些包管理器可能不允许指定一个依赖包的具体某个版本，而允许指定版本的范围，不过此时我们可以轻松将依赖版本 0 或 1 改为 ≤ 0 和 ≥ 1。有些包管理器默认不认为同一个包的不同版本会冲突，但它必须允许指明类似这样的冲突：在 Unix 系统中 `/bin/bash` 不能同时有 2 个版本；C 语言中 `printf` 不能有 2 种定义。

我所见过的每个包管理器都符合上述假设：

- Debian：APT
- RedHat：RPM
- Rust：Cargo
- Node：npmjs
- Java：Maven
- Haskell：Cabal
- 等等

也即是说，这些包管理器都面临 NP 完全问题。每次都需要很长时间才能选择好待安装的依赖包版本，或才告知此包不能安装。（当然，有些包管理器可能不经意的做到这两点）

Kunth 在 [第 4 卷，第 6 册](http://ptgmedia.pearsoncmg.com/images/9780134397603/samplepages/9780134397603.pdf) 写到：

> 满足性的故事正是软件工程取得成功的故事，并结合了许多精美的数学知识。得益于新的优雅数据结构和其他相关技术，现代 SAT 求解器已能够例行地处理涉及成千上万个变量的实际问题，而在几年前这些问题还被不被看好。

在实际应用中，貌似现代的包管理器都倾向于使用 SAT 求解器：

- [Oinstall](http://0install.net/) 刚开始基于启发式，但后来 [发现必须](https://mail.mozilla.org/pipermail/rust-dev/2012-February/001378.html) 切换到 [SAT 求解器](http://0install.net/solver.html)。
- [Chef](https://chef.io/) 是一个系统集成框架，将 [dep-selector 的 Ruby 绑定](https://github.com/chef/dep-selector) 用于 [Gecode 约束求解器](http://www.gecode.org/)。
- Dart 语言的包管理器 [Pub](https://pub.dartlang.org/) 引入了一个 [回溯求解器](https://github.com/dart-lang/pub/blob/master/lib/src/solver/backtracking_solver.dart)，但需要 [耗时很长](https://github.com/dart-lang/pub/issues/912)。
- Debian 系统的包管理器 [apt-get](https://wiki.debian.org/apt-get) 默认基于启发式，但可 [调用一个 SAT 求解器](http://www.dicosmo.org/MyOpinions/index.php?post/2014/10/30/139-saved-yet-another-time-by-an-external-solver-for-apt)，并允许 [用户进行配置](http://www.dicosmo.org/MyOpinions/index.php?post/2014/03/05/137-user-preferences-for-dependency-solvers-a-short-survey-and-new-features-added-in-the-latest-aspcud-solver)。Debian 的质量保证团队还运行了 [一个求解器](http://www.dicosmo.org/MyOpinions/index.php?post/2014/05/21/138-static-analysis-of-software-component-repositories-from-debian-to-opam) 来找出仓库中不可安装的包。
- IDE 软件 [Eclipse](https://www.eclipse.org/) 使用了 [sat4j SAT 求解器](http://www.sat4j.org/) 来 [管理其插件的安装](https://forge.ow2.org/forum/forum.php?forum_id=1369)。
- Fedora 系统的 [DNF](https://lwn.net/Articles/503581/)（Dandified yum）在其实验模式中用到了 [一个 SAT 求解器](https://fedoraproject.org/wiki/Features/DNF#Detailed_Description)。
- FreeBSD 的包管理器 [pkg](https://github.com/freebsd/pkg)（也被用于 DragonflyBSD 系统）用到了 [picosat SAT 求解器](https://github.com/freebsd/pkg/tree/master/external/picosat)。
- OCaml 语言的包管理器 [OPAM](https://opam.ocaml.org/) 可 [调用本地或远程的 SAT 求解器](https://opam.ocaml.org/doc/Specifying_Solver_Preferences.html)。与 Debian 系统的 apt-get 类似，OPAM 的求解器允许用户进行配置，并会扫描 OPAM 的仓库不可安装的包。
- [OpenSUSE 系统](https://www.opensuse.org/) 的包管理器使用了 [libsolv](https://github.com/openSUSE/libsolv)，libsolv 是一个 `基于满足性算法的免费的包依赖求解器`。还有 OpenSUSE 的 zypper，它使用了自己的 [libzypp](https://en.opensuse.org/openSUSE:Libzypp_satsolver) SAT 求解器。
- Python 语言的包管理器 [Anaconda](https://www.continuum.io/anaconda-overview) 使用了 [SAT 求解器](https://www.continuum.io/blog/developer/new-advances-conda-0)，但 [依然耗时较长](https://groups.google.com/a/continuum.io/forum/#!topic/anaconda/CT7viK-fFDI)。
- Rust 语言的包管理器 [Cargo](https://blog.rust-lang.org/2016/05/05/cargo-pillars.html) 使用了 [基本的回溯求解器](https://github.com/rust-lang/cargo/blob/8b5aec111926d1d03d2da32dd494e0fff073f870/src/cargo/core/resolver/mod.rs#L426)。它也允许同一个 crate 的不同版本被同时连接到最终的二进制文件中。
- Solaris 系统的包管理器 [pkg](https://docs.oracle.com/cd/E36784_01/html/E36856/docinfo.html#scrolltoc) 有时也被称为 IPS，被用于 Illumos 系统中，它 [使用了 minisat SAT 求解器](https://blogs.oracle.com/barts/entry/satisfaction)。
- Swift 语言的 [包管理器](https://github.com/apple/swift-package-manager) 使用了 [基本的回溯求解器](https://github.com/apple/swift-package-manager/blob/master/Sources/PackageGraph/DependencyResolver.swift#L518)。

> 我希望在这里添加更多的包管理器。若你发现了新的包管理器（或本文有什么错漏的），请发 [邮件](rsc@swtch.com) 或 [Twitter 私信](https://twitter.com/_rsc) 给我。

# 路在何方

我们该如何面对包的版本选择是 NP 完全问题这一事实？其中一种方法是直面复杂度，并祈求 SAT 求解器能做得更好。另一种方法是：质疑是否还有其他更好的方向。或许我们根本无需那些尝试直接解决此问题的工具，或许我们在开发软件时一开始就走错了方向。

如果包的版本选择是一个 NP 完全问题，则意味着包组合的可能搜索空间太大，且难以进行高效的系统分析；还有，该如何进行高效的系统测试？如果搜索发现了无冲突的组合，但此时我们又凭什么去相信这个组合是没问题的？没有版本冲突可能也只能说明此组合未经测试。如果搜索不到无冲突的组合，那该如何向开发者解释此问题或下一步该怎么办？在我们的软件配置决策中若不考虑 NP 完全问题，我们的软件将很难正常工作。让我们来重新审视一下我们是如何发展到目前这个地步的，以及我们该如何跳出此坑。

上面的证明的前提是下面这些假设，这里再重复一次：

1. 一个包可依赖于 0 或多个其他包的版本
2. 若安装一个包，必须也安装其所有依赖包
3. 包的每个版本可依赖不同的包
4. 不允许同时安装一个包的不同版本

正如我在前面所说的，传统观念认为上述假设是：`包管理器的最低要求`，但或许我们能找到一种减少上述假设的方法。

避免 NP 完全问题的其中一种方法是干掉 `假设 1`：如果一个依赖包只能指定一个最低版本，而非允许依赖包指定包的一堆版本，会发生什么事情？此时需要一个简单的算法来寻找依赖包：从你想安装的软件的最新版本开始，然后递归地获取该软件所有依赖的最新版本。正如本文开头所说的钻石依赖问题：

- A 依赖了 B、C
- 而 B、C 分别依赖了不同版本的 D
- 若 B 依赖了 D 1.5
- 若 C 依赖了 D 1.6
- 若构建只使用 D 1.6 没问题还好
- 若 B 不兼容 D 1.6，则认为 B 有 bug，或 D 1.6 有 bug
- 有 bug 的版本应从循环中完全删掉，并应发布新版本修复此问题
- 在依赖图中添加冲突标记，就像只在文档标记为有 bug，但却没去实际修复

避免 NP 完全问题的另一种方法是干掉 `假设 4`：如果允许同时安装同一个包的不同版本会怎样？此时，大部分的搜索算法都能找到依赖包版本的组合；这些可能不是最小组合（依然是 NP 完全问题）。若 B 依赖 D 1.5，而 C 依赖 D 2.2，则构建是可同时将 D 的不同版本包含在最终的二进制文件中，并把不同版本当成是不同的包。前面我曾提到过，C 语言中的 `prinft` 不允许有 2 种定义，但拥有模块机制的语言则没问题，因为可将不同含义的同名函数放到不同的命名空间。

还有一种避免 NP 完全问题的方法是同时结合上述 2 种方法。正如前面例子所指出的，若包的版本遵循 [语言版本 SemVer](http://semver.org/)，则包管理器可在相同主版本号的前提下自动使用最新的版本，若主版本号不同，则认为是 2 个不同的包，互不干扰。

设置上述限制的根本原因在于：开发者在构建软件时几乎不可能对整个可能的包组合空间进行考虑。上述限制可有助于开发者以及他们的工具就软件构建方式上达成一致。若上述几种方法真能在实际应用中使用，那语言包管理器在简化操作性、易理解性方面还有很长的路要走。

# 相关工作

Debian 和 RedHat 系统上的包安装问题是 NP 完全问题，其证明可见：[EDOS 可交付使用的 WP2-D2.1：软件依赖的正式管理的报告](https://hal.inria.fr/hal-00697463)，第 49-50 页。在包安装时，减少 3-SAT 的其中困难一步是如何构造出 `分离`（译注：即 OR）。EDOS 中提到通过包管理器的能力来编码 `OR`：单个依赖可表示为一堆候选包，在 Debian 中是直接表示，在 RedHat 中是提供指令。例如，这些系统允许类似 `text-editor` 的伪包名，若已安装实际的包 `ed`、`vi`、`acme` 的任意一个的话，则认为 `text-editor` 已安装。

类似 Rust 语言的 Cargo 包管理器，其依赖规范相比 Debian、RedHat 来说，意外地简单得多，因此 EDOS 的证明在此处不适用。有人可能因此希望语言的包管理器可更简单，从而避免 NP 完全问题。新的证据让这个希望破灭了。（查看上述证明的一种方法是模拟 `提供（provides）` 指令：通过为 `text-editor` 定义 3 个版本，每个版本分别依赖了：`ed`、`vi`、`acme`）

通过对同一个软件的不同版本当成不同的软件来编码 `OR` 的话，Debian 和 RedHat 的包管理器就可以不做任何修改就能继续使用，而且此方式本质上也应适用于任何未来可预见的操作系统或语言包管理器。我怀疑大多数语言的包管理器作者都认为他们面临的问题是 NP 完全问题，但我却找不到任何已有的文章说明这个问题。

一些依赖管理系统使用了基于约束的求解器，而非基于 SAT 求解器，但其面对的依然是 [NP 完全问题](https://en.wikipedia.org/wiki/Schaefer%27s_dichotomy_theorem)。

在 2008 年，Daniel Burrows 写了一篇文章 [利用 dpkg 来解决数独问题](http://web.archive.org/web/20160326062818/http://algebraicthunk.net/~dburrows/blog/entry/package-management-sudoku/)。

感谢 Sam Boyer 告诉我有 EDOS 这份报告，也感谢他对包管理器的 [精彩综述](https://medium.com/@sdboyer/so-you-want-to-write-a-package-manager-4ae9c17d9527)。

Roberto Di Cosmo 写了几篇对 EDOS 报告的后续研究问题，见 [这里](http://www.dicosmo.org/Publications/publi-by-topic.html)。特别是，[解决依赖问题：组件演化管理上的一个另类担忧](http://www.dicosmo.org/Articles/2012-AbateDiCosmoTreinenZacchiroli-Jss.pdf)，里面包含了更新的证明。此研究使用了 SAT 求解器，同时也允许用户进行配置。

另一个相关的研究工作是：Tucker 等人在 ICSE 2007 上发表的 [OPIUM：最佳的软件包安装/卸载管理器](https://cseweb.ucsd.edu/~lerner/papers/opium.pdf)。OPIUM 是 [Oinstall 求解器的启蒙者](http://0install.net/solver.html#idp172528)。

Jaroslav Tulach 在 [2009 年](http://wiki.apidesign.org/wiki/LibraryReExportIsNPComplete) 发现了与前面一样的证明。感谢 HN（译注：HackerNews）的读者 edwintorok [提供的链接](https://news.ycombinator.com/item?id=13167981)。

在 Tulach [关于 LtU 的证明的讨论](http://lambda-the-ultimate.org/node/3588) 中提到了 Daniel Burrow 在 2005 年发表的文章 [软件依赖关系的建模与解决](https://people.debian.org/~dburrows/model.pdf)，但此文章的证明比 Tulach（前面提到的）的更像 EDOS 的证明。

很多读者向我发了不少引用链接和包管理器的 SAT 求解器，再次感谢大家。
