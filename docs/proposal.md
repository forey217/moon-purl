# Moon PURL 项目申报书

## 一、项目与方向

- 名称：Moon PURL——面向软件物料清单的 Package URL 工具库
- GitHub：https://github.com/forey217/moon-purl
- MoonBit 模块：`forey217/moon_purl`；Apache-2.0；运行依赖仅 `moonbitlang/core`
- 方向：软件供应链与开发工具基础库，用于 SBOM 导入、漏洞库关联和依赖清单审计

## 二、简介与核心功能

项目以纯 MoonBit 实现一套边界明确的 Package URL ASCII 互操作子集：解析结构化字段并返回
稳定错误码与原文 UTF-16 偏移；规范化类型、ASCII 百分号转义、PyPI 名称、npm 名称/作用域
及 qualifier 顺序；按类型、命名空间、名称、版本和 qualifier 子集匹配；生成忽略 qualifier
与 subpath 的“包版本身份”，用于漏洞库粗粒度关联和重复项提示。`diagnose_batch` 隔离非法行，
`audit_inventory` 检查缺版本、重复项与策略限制，`diff_inventory` 比较两版清单的新增、删除和
未变化身份，输出排序稳定，可直接进入 CI。

## 三、实际场景测试与验收边界

仓库内置 1,200 条 SBOM 导入场景：1,000 条正常记录、100 条仅 subpath 不同的重复身份、
50 条非法转义和 50 条缺版本记录。测试要求每条输入均产生结果，实测分类为 ready 1,000、
duplicate 100、invalid 50、unversioned 50，非法行不会中断后续记录。另有 20,000 条可复现
工作负载，在 Windows 11、i7-14650HX、MoonBit 0.10.12、JS 目标的五次暖机运行中位数
169.5 ms；完整命令、逐次数据、环境和限制见 `docs/scenario-validation.md`。

当前验收标准是：受支持输入可稳定往返为 canonical PURL；错误码和偏移可复现；批量总数与
各分类之和一致；快照差异不受输入顺序和重复行影响；四目标 CI 完成格式、检查、构建、测试
和示例运行。项目不联网，不读取 CycloneDX/SPDX 文件，不查询漏洞，不做依赖求解、许可证或
安全结论，也不以身份相同代替二进制摘要相同。0.1.0 不宣称完整 Unicode 规范化。

## 四、技术交付、原创与生态价值

当前交付 856 行核心 MoonBit 库、72 行可执行场景、246 行测试 / 16 个测试块、四后端 CI、
设计边界、来源声明和性能记录。核心使用手写游标、类型化模型与哈希集合，不依赖外部服务。
项目参考 Package URL 公开规范但为独立实现，未复制或移植第三方解析器源码；与单一生态包名
工具相比，它统一处理多生态坐标，并提供批量失败隔离、身份差异和策略审计这一完整链路。
MoonCakes `forey217/moon_purl@0.1.0` 已正式发布，并在全新项目中重新下载、调用规范化和清单
审计接口验证；注册表包与本地发布包 SHA-256 一致，过程见 `docs/release-verification.md`。

## 五、后续计划

后续拟在保持兼容的前提下补充 UTF-8 百分号解码与 Unicode 规范化、更多生态 profile、
流式 CycloneDX/SPDX 适配层、摘要关联和真实脱敏 SBOM 长期基准；上述内容属于后续建设，
不计入本次已完成成果。申报以仓库代码、16 个测试及场景记录为当前验收依据。
