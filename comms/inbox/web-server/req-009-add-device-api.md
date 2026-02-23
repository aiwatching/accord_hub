---
id: req-009-add-device-api
from: orchestrator
to: web-server
scope: external
type: api-addition
priority: medium
status: in-progress
created: 2026-02-23T11:25:00.000Z
updated: '2026-02-23T22:20:32.501Z'
on_behalf_of: user
related_contract: contracts/web-server.yaml
---

## What

提供设备创建的 REST API 端点。

## Proposed Change

在 web-server 中添加设备创建 API:

```yaml
paths:
  /api/devices:
    post:
      summary: 创建新设备
      description: 添加一个新设备到系统中
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required:
                - name
                - type
              properties:
                name:
                  type: string
                  description: 设备名称
                  example: "办公室路由器"
                type:
                  type: string
                  description: 设备类型
                  enum: [router, switch, server, workstation, printer, other]
                  example: "router"
                ipAddress:
                  type: string
                  format: ipv4
                  description: IP地址
                  example: "192.168.1.1"
                macAddress:
                  type: string
                  pattern: '^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$'
                  description: MAC地址
                  example: "00:1A:2B:3C:4D:5E"
                location:
                  type: string
                  description: 设备位置
                  example: "办公室A区"
                metadata:
                  type: object
                  additionalProperties:
                    type: string
                  description: 自定义元数据
      responses:
        201:
          description: 设备创建成功
          content:
            application/json:
              schema:
                type: object
                properties:
                  id:
                    type: string
                    example: "dev-1234567890"
                  name:
                    type: string
                  type:
                    type: string
                  ipAddress:
                    type: string
                  macAddress:
                    type: string
                  location:
                    type: string
                  status:
                    type: string
                    enum: [online, offline, unknown]
                  metadata:
                    type: object
                  createdAt:
                    type: string
                    format: date-time
                  updatedAt:
                    type: string
                    format: date-time
        400:
          description: 请求数据无效
          content:
            application/json:
              schema:
                type: object
                properties:
                  error:
                    type: string
                    example: "Invalid IP address format"
        409:
          description: 设备已存在
          content:
            application/json:
              schema:
                type: object
                properties:
                  error:
                    type: string
                    example: "Device with this name already exists"
        401:
          description: 未授权
        403:
          description: 无权限
```

**实现要点**:
- 调用 device-manager 的 createDevice 接口
- 请求数据验证 (name, type 必填)
- 格式验证 (IP, MAC 地址)
- 错误处理和适当的 HTTP 状态码
- 需要用户认证

## Why

frontend 需要 API 端点来提交设备创建请求。

## Impact

- **工作量**: 中等 (1 个 Controller + 数据验证 + 错误处理)
- **Breaking changes**: 无 (新增端点)
- **依赖**: 依赖 device-manager 的 createDevice 接口
- **测试**: 需要 API 集成测试
- **安全**: 需要认证,建议增加权限检查
