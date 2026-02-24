---
id: req-014-ssh-connection
from: orchestrator
to: device-manager
scope: internal
type: interface-addition
priority: high
status: pending
created: 2026-02-23T12:00:00Z
updated: 2026-02-23T12:00:00Z
on_behalf_of: user
related_contract: contracts/internal/device-manager.md
---

## What

实现设备 SSH 连接管理功能，支持建立、维护和关闭 SSH 会话。

## Proposed Change

在 device-manager 中添加 SSH 连接管理接口：

```java
// DeviceSSHService.java
public interface DeviceSSHService {
    /**
     * 创建 SSH 会话
     * @param deviceId 设备ID
     * @param credentials SSH 凭据
     * @return SSH 会话信息
     * @throws DeviceNotFoundException 设备不存在
     * @throws SSHConnectionException SSH 连接失败
     */
    SSHSession createSession(String deviceId, SSHCredentials credentials);

    /**
     * 发送命令到 SSH 会话
     * @param sessionId 会话ID
     * @param command 命令内容
     * @throws SessionNotFoundException 会话不存在
     * @throws SSHException SSH 执行异常
     */
    void sendCommand(String sessionId, String command);

    /**
     * 接收 SSH 输出（流式读取）
     * @param sessionId 会话ID
     * @return 输出流
     */
    InputStream receiveOutput(String sessionId);

    /**
     * 关闭 SSH 会话
     * @param sessionId 会话ID
     */
    void closeSession(String sessionId);

    /**
     * 获取会话状态
     * @param sessionId 会话ID
     * @return 会话信息
     */
    SSHSession getSession(String sessionId);

    /**
     * 获取用户的所有活跃会话
     * @param userId 用户ID
     * @return 会话列表
     */
    List<SSHSession> getActiveSessions(String userId);
}

// SSHCredentials.java
public class SSHCredentials {
    private String username;          // SSH 用户名
    private String password;          // SSH 密码（可选）
    private String privateKey;        // SSH 私钥（可选）
    private String passphrase;        // 私钥密码（可选）
    private int port = 22;           // SSH 端口，默认 22
}

// SSHSession.java
public class SSHSession {
    private String sessionId;         // 会话唯一ID
    private String deviceId;          // 设备ID
    private String userId;            // 用户ID
    private String ipAddress;         // 设备IP
    private int port;                 // SSH 端口
    private String username;          // 登录用户名
    private SessionStatus status;     // 会话状态
    private LocalDateTime createdAt;  // 创建时间
    private LocalDateTime lastActiveAt; // 最后活跃时间
}

// SessionStatus.java
public enum SessionStatus {
    CONNECTING,    // 连接中
    CONNECTED,     // 已连接
    DISCONNECTED,  // 已断开
    ERROR         // 错误
}
```

**实现要点**:
- 使用 JSch 或 Apache MINA SSHD 库实现 SSH 连接
- 会话管理:
  - 使用 ConcurrentHashMap 存储活跃会话
  - 会话超时机制: 30分钟无活动自动断开
  - 单用户单设备最多 3 个并发会话
- 安全性:
  - 凭据不存储，仅在内存中使用
  - 支持密码和私钥认证
  - 记录所有 SSH 操作日志（审计）
- 流式输出:
  - SSH 输出通过 InputStream 流式返回
  - 支持实时读取终端输出
- 错误处理:
  - 连接超时 (10秒)
  - 认证失败
  - 网络断开
  - 会话不存在

**数据持久化**:
- 会话元数据保存到数据库
- 不保存会话内容和凭据

## Why

用户需要通过 SSH 直接连接设备进行调试和管理操作。

## Impact

- **工作量**: 高 (SSH 客户端实现 + 会话管理 + 流式处理)
- **Breaking changes**: 无 (新增接口)
- **依赖**:
  - JSch 或 Apache MINA SSHD 库
  - 需要设备支持 SSH 服务
- **安全**: 需要加密存储私钥（如果允许保存）
- **性能**: 需要管理并发连接，避免资源耗尽
- **测试**: 需要集成测试（需要测试 SSH 服务器）
