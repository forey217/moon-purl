# Moon PURL 项目申报书

## 一、项目名称及地址

- 项目名称：Moon PURL——面向 SBOM 处理流程的 Package URL 工具库
- GitHub：https://github.com/forey217/moon-purl
- MoonBit 模块：`forey217/moon_purl`
- 开源许可证：Apache-2.0

## 二、项目简介

Moon PURL 是一个使用 MoonBit 编写的软件供应链基础组件。项目不再局限于单个 Package URL
字符串的解析，而是直接接收 CycloneDX 和 SPDX JSON 文档，提取其中的包标识，完成 PURL
规范化、错误隔离、清单策略审计以及跨 SBOM 格式差异比较。其目标是为 SBOM 上传网关、格式
迁移校验、CI 依赖清单检查和漏洞数据库关联准备提供一个无网络依赖、结果稳定、可嵌入的底层库。

## 三、项目方向与适用场景

项目属于软件供应链与开发工具方向。第一类场景是企业接收 CycloneDX 清单时，对顶层及嵌套
组件逐项提取 PURL，标记缺失和非法标识，并继续处理其余组件；第二类场景是从 SPDX
`PACKAGE-MANAGER` 外部引用中提取 PURL，再执行版本必填、类型限制和 qualifier 策略；第三类
场景是系统由 CycloneDX 迁移到 SPDX 后，使用规范化的包版本身份比较新增、删除和未变化依赖，
避免仅因大小写、PyPI 拼写或 qualifier 顺序差异产生误报。

## 四、核心功能与独立复用价值

核心库实现 PURL 结构化解析、规范输出、字段匹配、批量诊断、库存审计和快照差异；对 PyPI、
npm、Maven、Go、GitHub 提供保守的生态规则，同时保留通用类型支持。0.2.0 新增 CycloneDX
顶层及递归嵌套组件导入、SPDX 包外部引用导入、逐条 `Imported/MissingPurl/InvalidPurl` 结果、
文档直接审计和跨格式差异接口。下游程序不需要自行遍历 JSON 或处理某一条坏数据导致整批失败，
可直接使用 `audit_cyclonedx_json`、`audit_spdx_json` 和 `diff_sbom_imports` 完成完整流程。

项目与完整 SBOM 平台边界清楚：它不联网查询注册表或漏洞，不做依赖求解、许可证裁决和完整
CycloneDX/SPDX schema 校验；它只负责可靠提取、规范化和比较包身份。相同 PURL 身份也不代表
二进制内容相同，制品一致性仍应由摘要校验完成。

## 五、测试、场景及验收标准

当前共有 21 个确定性测试。原有 1,200 行库存场景验证正常、重复、非法及缺版本分类；新增
1,500 组件 CycloneDX JSON 场景，固定得到 1,300 条成功导入、100 条非法 PURL、100 条缺失
PURL，导入结果进一步得到 1,200 条 ready 和 100 条 duplicate。跨格式测试验证同一个 PyPI
包在 CycloneDX 与 SPDX 中规范化后保持一致，并准确报告一个新增和一个删除依赖。

性能工作负载同时处理 20,000 条库存记录和 5,000 组件 CycloneDX JSON。在 Windows 11、
i7-14650HX、MoonBit 0.10.12、JS 后端上五次暖机运行中位数为 201.6 ms。验收标准为：所有
文档条目均有结果；非法或缺失 PURL 不影响后续条目；规范输出与差异顺序稳定；示例可运行；
wasm、wasm-gc、JavaScript、native 四后端 CI 全部通过。

## 六、原创性及后续规划

项目根据公开 Package URL、CycloneDX 与 SPDX 字段约定独立实现，未复制或移植第三方解析器
源码，运行依赖仅为 `moonbitlang/core`。后续计划包括 UTF-8 百分号解码与 Unicode 规范化、
更多生态 profile、依赖关系图提取、流式大文件适配以及脱敏真实 SBOM 回归语料。当前申报内容
仅以仓库内已实现代码、21 个测试、可执行示例和可复现性能记录为验收依据。
