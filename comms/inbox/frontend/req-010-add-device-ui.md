---
id: req-010-add-device-ui
from: orchestrator
to: frontend
scope: external
type: api-addition
priority: medium
status: in-progress
created: 2026-02-23T11:25:00.000Z
updated: '2026-02-23T22:20:52.509Z'
on_behalf_of: user
related_contract: contracts/frontend.yaml
---

## What

创建设备添加的用户界面,让用户可以通过表单添加新设备。

## Proposed Change

在 frontend 中添加设备创建功能:

### 1. 添加设备表单页面/对话框

**路由** (如果是独立页面):
- `/devices/new` - 添加设备页面

**或者** (如果是对话框):
- 在设备列表页面添加"添加设备"按钮
- 点击按钮打开模态对话框

### 2. 表单字段

```typescript
interface CreateDeviceForm {
  name: string;           // 必填,文本输入
  type: string;           // 必填,下拉选择
  ipAddress?: string;     // 可选,IP格式验证
  macAddress?: string;    // 可选,MAC格式验证
  location?: string;      // 可选,文本输入
  metadata?: Record<string, string>; // 可选,键值对输入
}

// 设备类型选项
const deviceTypes = [
  { value: 'router', label: '路由器' },
  { value: 'switch', label: '交换机' },
  { value: 'server', label: '服务器' },
  { value: 'workstation', label: '工作站' },
  { value: 'printer', label: '打印机' },
  { value: 'other', label: '其他' }
];
```

### 3. 表单验证

- **name**: 必填,2-50字符
- **type**: 必填,从预定义列表选择
- **ipAddress**: 可选,但如果填写必须是有效的 IPv4 格式
- **macAddress**: 可选,但如果填写必须是有效的 MAC 格式 (XX:XX:XX:XX:XX:XX)
- 实时验证并显示错误提示

### 4. API 调用

```typescript
// API 调用
const createDevice = async (data: CreateDeviceForm) => {
  const response = await fetch('/api/devices', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(data)
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to create device');
  }

  return response.json();
};
```

### 5. 用户体验

- 提交成功后:
  - 显示成功提示消息
  - 关闭对话框/返回设备列表
  - 刷新设备列表显示新设备
- 提交失败时:
  - 显示错误消息 (如"设备名称已存在")
  - 保持表单数据,让用户修改
- 提交中:
  - 禁用提交按钮
  - 显示加载状态

### 6. UI 设计建议

- 使用清晰的标签和占位符
- 必填字段标记 * 号
- 提供设备类型图标辅助识别
- 提供取消按钮

## Why

用户需要友好的界面来添加新设备,而不是通过 API 或命令行。

## Impact

- **工作量**: 中等 (表单组件 + 验证逻辑 + API 集成)
- **Breaking changes**: 无 (新增页面/对话框)
- **依赖**: 依赖 web-server 的 `POST /api/devices` 接口
- **UI库**: 使用项目现有的表单组件库
- **测试**: 需要表单验证测试和 E2E 测试
