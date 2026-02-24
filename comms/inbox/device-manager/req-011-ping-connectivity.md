---
id: req-011-ping-connectivity
from: orchestrator
to: device-manager
scope: internal
type: interface-addition
priority: medium
status: completed
created: 2026-02-23T12:00:00.000Z
updated: '2026-02-23T16:30:00.000Z'
on_behalf_of: user
related_contract: contracts/internal/device-manager.md
---

## What

实现设备 Ping 连通性测试功能，检测设备是否在线并返回延迟时间。

## Proposed Change

在 device-manager 中添加 Ping 测试接口：

```java
// DeviceConnectivityService.java
public interface DeviceConnectivityService {
    /**
     * 执行设备 Ping 测试
     * @param deviceId 设备ID
     * @return Ping 测试结果
     * @throws DeviceNotFoundException 如果设备不存在
     * @throws InvalidIpAddressException 如果设备没有配置IP地址
     */
    PingResult pingDevice(String deviceId);

    /**
     * 批量 Ping 测试
     * @param deviceIds 设备ID列表
     * @return Ping 测试结果列表
     */
    List<PingResult> pingDevices(List<String> deviceIds);
}

// PingResult.java
public class PingResult {
    private String deviceId;
    private String ipAddress;
    private boolean reachable;        // 是否可达
    private Long latencyMs;           // 延迟时间(毫秒), null表示不可达
    private int packetsTransmitted;   // 发送包数
    private int packetsReceived;      // 接收包数
    private double packetLoss;        // 丢包率(%)
    private LocalDateTime testedAt;   // 测试时间
    private String errorMessage;      // 错误信息(如果有)
}
```

**实现要点**:
- 使用 Java `InetAddress.isReachable()` 或执行系统 `ping` 命令
- 发送 4 个 ICMP 包，超时时间 5 秒
- 计算平均延迟和丢包率
- 如果设备没有配置 IP 地址，抛出异常
- 异步执行，避免阻塞（批量测试时使用线程池）
- 测试结果可选保存到数据库作为历史记录

**错误处理**:
- 设备不存在
- 设备未配置 IP 地址
- 网络不可达
- 超时

## Why

用户需要快速检测设备的网络连通性，判断设备是否在线。

## Impact

- **工作量**: 中等 (服务类 + 结果模型 + 异步处理逻辑)
- **Breaking changes**: 无 (新增接口)
- **依赖**: 需要系统支持 ICMP 协议或 ping 命令
- **性能**: 批量测试时使用线程池，避免串行阻塞
- **测试**: 需要单元测试和集成测试
