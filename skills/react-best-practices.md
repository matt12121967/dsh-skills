---
name: react-best-practices
description: "React/Next.js 性能优化规则（Vercel 工程团队维护，8 大类 70 条，按优先级排序：消除瀑布流、包体、服务端性能、客户端数据获取、重渲染、渲染性能、JS 性能、高级模式）。写、审或重构 React/Next.js 代码时使用。"
whenToUse: "编写 React 组件、Next.js 页面、数据获取逻辑，或审查/重构 React/Next.js 代码、优化包体与加载时间时。"
---

# Vercel React Best Practices（React/Next.js 性能优化）

按优先级 8 大类。写/审 React、Next.js 代码时逐项对照。

## 1. 消除瀑布流（CRITICAL）

- await 前先检查廉价的同步条件；把 await 挪进真正用到的分支；
- 相互独立的操作用 `Promise.all` 并行；
- API 路由里尽早启动 promise、晚 await；用 Suspense 流式渲染。

## 2. 包体优化（CRITICAL）

- 直接从模块导入，避免 barrel 文件；优先静态可分析的路径；
- 重组件用 `next/dynamic`；分析/日志类三方库延迟到 hydration 后加载；
- 功能激活时才加载模块；hover/focus 预加载。

## 3. 服务端性能（HIGH）

- Server Action 像 API 路由一样做鉴权；
- 每请求去重用 `React.cache()`；跨请求缓存用 LRU；
- RSC props 避免重复序列化；静态 I/O（字体/logo）提升到模块级；
- RSC/SSR 避免模块级可变请求状态；尽量少给客户端组件传数据；
- 重构组件结构让 fetch 并行；after() 处理非阻塞操作。

## 4. 客户端数据获取（MEDIUM-HIGH）

- 用 SWR 自动去重请求；全局事件监听要合并、scroll 用 passive；
- localStorage 数据加版本并最小化。

## 5. 重渲染优化（MEDIUM）

- 只在回调里用的 state 别订阅；昂贵工作抽进 memo 组件；
- effect 依赖用原始值；渲染期派生 state 而不是 effect；
- 稳定回调用函数式 setState；useState 昂贵初值传函数；
- 简单原始值不用 memo；依赖独立的 hooks 拆分；
- 交互逻辑放事件处理器；非紧急更新用 startTransition；
- 输入保持响应用 useDeferredValue；高频瞬态值用 ref；
- 组件内部不要定义组件。

## 6. 渲染性能（MEDIUM）

- 动画改 div 外层而不是 SVG 元素；长列表用 content-visibility；
- 静态 JSX 提到组件外；SVG 降低坐标精度；
- 仅客户端数据用内联脚本防闪烁；预期的不一致用 suppressHydrationWarning；
- 显示/隐藏用 Activity；条件渲染用三元而非 &&；
- loading 态优先 useTransition；preload 用 React DOM resource hints；
- script 标签用 defer 或 async。

## 7. JS 性能（LOW-MEDIUM）

- CSS 修改用类名或 cssText 批量；重复查找建 Map；
- 循环里缓存属性访问；函数结果模块级 Map 缓存；
- localStorage/sessionStorage 读取要缓存；多个 filter/map 合并成一次循环；
- 先查长度再昂贵比较；函数提前 return；RegExp 提出循环外；
- min/max 用循环不用 sort；O(1) 查找用 Set/Map；
- 不可变用 toSorted()；map+filter 一次完成用 flatMap；
- 非关键任务推迟到 requestIdleCallback。

## 8. 高级模式（LOW）

- useEffectEvent 结果别放 effect 依赖；事件处理器存 ref；
- 应用每次加载只初始化一次；稳定回调 ref 用 useLatest。

## 规则详解

需要某条的完整解释与正反例代码时拉取：
`web_fetch https://raw.githubusercontent.com/vercel-labs/agent-skills/main/skills/react-best-practices/AGENTS.md`
