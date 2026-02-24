---
id: req-015-ssh-websocket
from: orchestrator
to: web-server
scope: external
type: api-addition
priority: high
status: completed
created: 2026-02-23T12:00:00.000Z
updated: '2026-02-24T00:27:54.968Z'
completed: '2026-02-23T18:30:00.000Z'
on_behalf_of: user
related_contract: contracts/web-server.yaml
---

## What

提供 WebSocket API 用于设备 SSH 会话的实时双向通信。

## Proposed Change

在 web-server 中添加 SSH WebSocket 端点：

### 1. WebSocket 端点

```yaml
paths:
  /ws/ssh/{deviceId}:
    get:
      summary: SSH WebSocket 连接
      description: 建立 SSH 终端的 WebSocket 双向通信
      parameters:
        - name: deviceId
          in: path
          required: true
          schema:
            type: string
          description: 设备ID
        - name: token
          in: query
          required: true
          schema:
            type: string
          description: 认证令牌
      responses:
        101:
          description: 切换到 WebSocket 协议
        401:
          description: 未授权
        404:
          description: 设备不存在
        400:
          description: 设备未配置IP或SSH端口
```

### 2. WebSocket 消息协议

**客户端 → 服务器 (JSON 格式)**:

```typescript
// 1. 建立 SSH 连接
{
  "type": "connect",
  "payload": {
    "username": "admin",
    "password": "secret123",    // 可选
    "privateKey": "-----BEGIN...", // 可选
    "passphrase": "keypass",    // 可选
    "port": 22
  }
}

// 2. 发送命令/输入
{
  "type": "input",
  "payload": {
    "data": "ls -la\n"
  }
}

// 3. 调整终端大小
{
  "type": "resize",
  "payload": {
    "cols": 80,
    "rows": 24
  }
}

// 4. 关闭连接
{
  "type": "close"
}

// 5. Ping (保活)
{
  "type": "ping"
}
```

**服务器 → 客户端 (JSON 格式)**:

```typescript
// 1. 连接成功
{
  "type": "connected",
  "payload": {
    "sessionId": "ssh-session-12345",
    "deviceId": "dev-001",
    "username": "admin"
  }
}

// 2. SSH 输出数据
{
  "type": "output",
  "payload": {
    "data": "total 48\ndrwxr-xr-x..."  // Base64编码或直接字符串
  }
}

// 3. 错误消息
{
  "type": "error",
  "payload": {
    "code": "AUTH_FAILED",
    "message": "Authentication failed: Invalid username or password"
  }
}

// 4. 连接关闭
{
  "type": "closed",
  "payload": {
    "reason": "User requested close"
  }
}

// 5. Pong (响应 ping)
{
  "type": "pong"
}
```

### 3. 实现要点

```java
@Controller
public class SSHWebSocketHandler extends TextWebSocketHandler {

    @Override
    public void afterConnectionEstablished(WebSocketSession session) {
        // 验证认证令牌
        // 从 URI 获取 deviceId
        // 初始化 WebSocket 会话
    }

    @Override
    protected void handleTextMessage(WebSocketSession session, TextMessage message) {
        JSONObject msg = JSON.parseObject(message.getPayload());
        String type = msg.getString("type");

        switch (type) {
            case "connect":
                // 调用 device-manager 创建 SSH 会话
                // 启动输出流读取线程
                break;
            case "input":
                // 发送输入到 SSH 会话
                break;
            case "resize":
                // 调整 PTY 大小
                break;
            case "close":
                // 关闭 SSH 会话
                break;
            case "ping":
                // 回复 pong
                break;
        }
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        // 清理 SSH 会话
        // 关闭输出流读取线程
    }
}
```

**关键功能**:
- 认证: 通过 query 参数传递 JWT token
- 会话映射: WebSocket session ↔ SSH session
- 流式输出: 启动后台线程持续读取 SSH 输出并推送到 WebSocket
- 心跳机制: 每 30 秒 ping/pong 保持连接
- 错误处理: 连接失败、认证失败、网络断开等
- 超时控制: 30 分钟无活动自动断开

### 4. REST API (辅助)

```yaml
paths:
  /api/ssh/sessions:
    get:
      summary: 获取当前用户的活跃 SSH 会话列表
      security:
        - BearerAuth: []
      responses:
        200:
          description: 会话列表
          content:
            application/json:
              schema:
                type: array
                items:
                  type: object
                  properties:
                    sessionId:
                      type: string
                    deviceId:
                      type: string
                    deviceName:
                      type: string
                    username:
                      type: string
                    status:
                      type: string
                    createdAt:
                      type: string
                      format: date-time
                    lastActiveAt:
                      type: string
                      format: date-time

  /api/ssh/sessions/{sessionId}:
    delete:
      summary: 强制关闭 SSH 会话
      security:
        - BearerAuth: []
      parameters:
        - name: sessionId
          in: path
          required: true
          schema:
            type: string
      responses:
        204:
          description: 会话已关闭
        404:
          description: 会话不存在
```

## Why

frontend 需要实时双向通信来实现终端模拟器功能。

## Impact

- **工作量**: 高 (WebSocket 实现 + 会话管理 + 流式处理)
- **Breaking changes**: 无 (新增端点)
- **依赖**: 依赖 device-manager 的 SSH 接口
- **性能**: 需要管理 WebSocket 连接池，避免资源泄漏
- **安全**:
  - 认证令牌验证
  - SSH 凭据加密传输 (WSS)
  - 限制并发连接数
- **测试**: 需要 WebSocket 集成测试
