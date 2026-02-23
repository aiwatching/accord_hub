---
id: req-008-add-device-creation
from: orchestrator
to: device-manager
scope: internal
type: interface-addition
priority: medium
status: in-progress
created: 2026-02-23T11:25:00.000Z
updated: '2026-02-23T22:20:22.508Z'
on_behalf_of: user
related_contract: contracts/internal/device-manager.md
---

## What

实现设备创建功能,支持添加新设备到系统中。

## Proposed Change

在 device-manager 中添加设备创建接口:

```java
// DeviceService.java
public interface DeviceService {
    /**
     * 创建新设备
     * @param deviceRequest 设备创建请求
     * @return 创建的设备信息
     * @throws DeviceAlreadyExistsException 如果设备已存在
     * @throws InvalidDeviceDataException 如果设备数据无效
     */
    Device createDevice(CreateDeviceRequest deviceRequest);
}

// CreateDeviceRequest.java
public class CreateDeviceRequest {
    private String name;           // 设备名称 (必填)
    private String type;           // 设备类型 (必填)
    private String ipAddress;      // IP地址 (可选)
    private String macAddress;     // MAC地址 (可选)
    private String location;       // 位置 (可选)
    private Map<String, String> metadata; // 元数据 (可选)
}

// Device.java (响应)
public class Device {
    private String id;             // 自动生成的设备ID
    private String name;
    private String type;
    private String ipAddress;
    private String macAddress;
    private String location;
    private String status;         // online/offline/unknown
    private Map<String, String> metadata;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

**业务规则**:
- 设备名称必须唯一
- IP 地址格式验证
- MAC 地址格式验证
- 自动设置初始状态为 "unknown"
- 自动生成唯一的设备 ID

**数据持久化**:
- 保存到设备数据库
- 记录创建时间和更新时间

## Why

用户需要能够手动添加新设备到系统中进行管理。

## Impact

- **工作量**: 中等 (约 2-3 个类 + 数据库操作 + 验证逻辑)
- **Breaking changes**: 无 (新增接口)
- **依赖**: 需要数据库支持
- **测试**: 需要单元测试和集成测试
- **错误处理**: 设备已存在、数据验证失败等异常
