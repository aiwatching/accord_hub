---
id: req-013-ping-ui
from: orchestrator
to: frontend
scope: external
type: api-addition
priority: medium
status: completed
created: 2026-02-23T12:00:00.000Z
updated: '2026-02-24T00:27:33.744Z'
on_behalf_of: user
related_contract: contracts/frontend.yaml
---

## What

在设备列表页添加设备连通性测试功能，让用户可以快速测试设备是否在线。

## Proposed Change

在 frontend 的设备列表页面添加 Ping 测试功能：

### 1. UI 改动

**设备列表页 - 每行添加操作按钮**:
```typescript
// 在设备列表的操作列添加"测试连通性"按钮
<Button
  icon={<NetworkIcon />}
  size="small"
  onClick={() => handlePingDevice(device.id)}
  loading={pingLoading[device.id]}
>
  测试连通性
</Button>
```

**批量测试功能**:
```typescript
// 在列表顶部工具栏添加批量测试按钮
<Button
  icon={<NetworkCheckIcon />}
  onClick={handleBatchPing}
  disabled={selectedDevices.length === 0}
>
  批量测试 ({selectedDevices.length})
</Button>
```

**测试结果显示**:
- 单设备测试:
  - 在设备行内显示实时状态图标
  - 成功: ✅ 绿色勾 + 延迟时间 (如 "12ms")
  - 失败: ❌ 红色叉 + "不可达"
  - 测试中: ⏳ 加载动画

- 批量测试:
  - 打开模态对话框显示测试进度和结果
  - 显示统计信息: 总数/可达/不可达
  - 可以导出测试结果为 CSV

### 2. API 调用

```typescript
// 单设备 Ping 测试
interface PingResult {
  deviceId: string;
  ipAddress: string;
  reachable: boolean;
  latencyMs: number | null;
  packetsTransmitted: number;
  packetsReceived: number;
  packetLoss: number;
  testedAt: string;
  errorMessage?: string;
}

const pingDevice = async (deviceId: string): Promise<PingResult> => {
  const response = await fetch(`/api/devices/${deviceId}/ping`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });

  if (!response.ok) {
    throw new Error('Ping test failed');
  }

  return response.json();
};

// 批量 Ping 测试
interface BatchPingResult {
  results: PingResult[];
  totalCount: number;
  reachableCount: number;
  unreachableCount: number;
}

const pingDevicesBatch = async (deviceIds: string[]): Promise<BatchPingResult> => {
  const response = await fetch('/api/devices/ping/batch', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ deviceIds })
  });

  if (!response.ok) {
    throw new Error('Batch ping test failed');
  }

  return response.json();
};
```

### 3. 状态管理

```typescript
// 组件状态
const [pingResults, setPingResults] = useState<Record<string, PingResult>>({});
const [pingLoading, setPingLoading] = useState<Record<string, boolean>>({});
const [batchPingDialogOpen, setBatchPingDialogOpen] = useState(false);
const [batchPingResults, setBatchPingResults] = useState<BatchPingResult | null>(null);
```

### 4. 用户体验

- **实时反馈**: 点击按钮后立即显示加载状态
- **结果缓存**: 测试结果在设备行内显示，5分钟后过期
- **自动刷新**: 测试完成后自动更新设备状态
- **错误提示**: 测试失败时显示友好的错误消息
- **批量测试进度**: 显示 "测试中 3/10"
- **结果导出**: 批量测试结果可以导出为 CSV

### 5. 视觉设计

- 可达设备: 绿色图标 + 延迟时间
- 不可达设备: 红色图标 + "不可达"
- 测试中: 旋转的加载图标
- 未测试: 灰色图标（默认状态）

## Why

用户需要在设备列表页快速查看设备的连通性状态，无需逐个进入详情页。

## Impact

- **工作量**: 中等 (列表页UI改动 + API集成 + 批量测试对话框)
- **Breaking changes**: 无 (UI增强)
- **依赖**: 依赖 web-server 的 ping API
- **UI库**: 需要图标组件库支持网络状态图标
- **测试**: 需要组件测试和 E2E 测试
