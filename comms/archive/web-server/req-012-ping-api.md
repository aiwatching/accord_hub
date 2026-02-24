---
id: req-012-ping-api
from: orchestrator
to: web-server
scope: external
type: api-addition
priority: medium
status: completed
created: 2026-02-23T12:00:00.000Z
updated: 2026-02-23T12:00:00.000Z
completed: 2026-02-23T12:00:00.000Z
on_behalf_of: user
related_contract: contracts/web-server.yaml
---

## What

提供设备 Ping 连通性测试的 REST API 端点。

## Proposed Change

在 web-server 中添加 Ping 测试 API：

```yaml
paths:
  /api/devices/{id}/ping:
    post:
      summary: 测试单个设备连通性
      description: 执行 Ping 测试检查设备是否在线
      security:
        - BearerAuth: []
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
          description: 设备ID
      responses:
        200:
          description: Ping 测试成功
          content:
            application/json:
              schema:
                type: object
                properties:
                  deviceId:
                    type: string
                    example: "dev-1234567890"
                  ipAddress:
                    type: string
                    example: "192.168.1.1"
                  reachable:
                    type: boolean
                    example: true
                  latencyMs:
                    type: number
                    example: 12.5
                    description: 平均延迟(毫秒), null表示不可达
                  packetsTransmitted:
                    type: integer
                    example: 4
                  packetsReceived:
                    type: integer
                    example: 4
                  packetLoss:
                    type: number
                    example: 0
                    description: 丢包率(%)
                  testedAt:
                    type: string
                    format: date-time
                  errorMessage:
                    type: string
                    nullable: true
        404:
          description: 设备不存在
        400:
          description: 设备未配置IP地址
        401:
          description: 未授权
        503:
          description: 服务暂时不可用（如ping命令执行失败）

  /api/devices/ping/batch:
    post:
      summary: 批量测试设备连通性
      description: 同时测试多个设备的连通性
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                deviceIds:
                  type: array
                  items:
                    type: string
                  example: ["dev-001", "dev-002", "dev-003"]
                  maxItems: 50
      responses:
        200:
          description: 批量测试结果
          content:
            application/json:
              schema:
                type: object
                properties:
                  results:
                    type: array
                    items:
                      type: object
                      properties:
                        deviceId:
                          type: string
                        ipAddress:
                          type: string
                        reachable:
                          type: boolean
                        latencyMs:
                          type: number
                        packetLoss:
                          type: number
                        testedAt:
                          type: string
                          format: date-time
                  totalCount:
                    type: integer
                    example: 3
                  reachableCount:
                    type: integer
                    example: 2
                  unreachableCount:
                    type: integer
                    example: 1
        400:
          description: 请求无效（如设备ID列表为空或超过限制）
        401:
          description: 未授权
```

**实现要点**:
- 调用 device-manager 的 `pingDevice()` 和 `pingDevices()` 接口
- 单个设备测试超时时间 10 秒
- 批量测试最多支持 50 个设备，使用异步处理
- 需要用户认证
- 适当的错误处理和 HTTP 状态码

## Why

frontend 需要 API 端点来执行设备连通性测试。

## Impact

- **工作量**: 中等 (2 个 API 端点 + 异步处理)
- **Breaking changes**: 无 (新增端点)
- **依赖**: 依赖 device-manager 的 ping 接口
- **性能**: 批量测试需要异步处理，避免超时
- **测试**: 需要 API 集成测试
