---
id: req-016-ssh-terminal
from: orchestrator
to: frontend
scope: external
type: api-addition
priority: high
status: completed
created: 2026-02-23T12:00:00.000Z
updated: '2026-02-24T00:29:00.774Z'
on_behalf_of: user
related_contract: contracts/frontend.yaml
---

## What

创建设备 SSH 终端模拟器界面，让用户可以通过 Web 界面直接连接和操作设备。

## Proposed Change

在 frontend 中添加 SSH 终端模拟器功能：

### 1. 路由和页面

**路由**:
- `/devices/{deviceId}/terminal` - SSH 终端页面

**入口**:
- 在设备列表页的操作列添加"终端"按钮
- 在设备详情页添加"打开终端"按钮

### 2. 终端模拟器实现

使用 **xterm.js** 库实现终端：

```bash
npm install xterm xterm-addon-fit xterm-addon-web-links
```

```typescript
import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import { WebLinksAddon } from 'xterm-addon-web-links';
import 'xterm/css/xterm.css';

interface SSHTerminalProps {
  deviceId: string;
  deviceName: string;
  ipAddress: string;
}

const SSHTerminal: React.FC<SSHTerminalProps> = ({ deviceId, deviceName, ipAddress }) => {
  const terminalRef = useRef<HTMLDivElement>(null);
  const terminal = useRef<Terminal | null>(null);
  const ws = useRef<WebSocket | null>(null);
  const fitAddon = useRef<FitAddon | null>(null);

  useEffect(() => {
    // 初始化终端
    terminal.current = new Terminal({
      cursorBlink: true,
      fontSize: 14,
      fontFamily: 'Menlo, Monaco, "Courier New", monospace',
      theme: {
        background: '#1e1e1e',
        foreground: '#d4d4d4',
      },
      cols: 80,
      rows: 24,
    });

    fitAddon.current = new FitAddon();
    terminal.current.loadAddon(fitAddon.current);
    terminal.current.loadAddon(new WebLinksAddon());

    // 挂载终端到 DOM
    if (terminalRef.current) {
      terminal.current.open(terminalRef.current);
      fitAddon.current.fit();
    }

    // 监听终端输入
    terminal.current.onData((data) => {
      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'input',
          payload: { data }
        }));
      }
    });

    // 窗口大小调整
    const handleResize = () => {
      fitAddon.current?.fit();
      const dims = terminal.current?.options;
      if (ws.current && ws.current.readyState === WebSocket.OPEN) {
        ws.current.send(JSON.stringify({
          type: 'resize',
          payload: {
            cols: dims?.cols,
            rows: dims?.rows
          }
        }));
      }
    };

    window.addEventListener('resize', handleResize);

    return () => {
      terminal.current?.dispose();
      ws.current?.close();
      window.removeEventListener('resize', handleResize);
    };
  }, []);

  return (
    <div className="ssh-terminal-container">
      <div className="terminal-header">
        <span>📟 {deviceName} ({ipAddress})</span>
        <button onClick={handleDisconnect}>断开连接</button>
      </div>
      <div ref={terminalRef} className="terminal" />
    </div>
  );
};
```

### 3. WebSocket 连接

```typescript
const connectSSH = (credentials: SSHCredentials) => {
  const token = getAuthToken();
  const wsUrl = `wss://${window.location.host}/ws/ssh/${deviceId}?token=${token}`;

  ws.current = new WebSocket(wsUrl);

  ws.current.onopen = () => {
    // 发送连接请求
    ws.current?.send(JSON.stringify({
      type: 'connect',
      payload: {
        username: credentials.username,
        password: credentials.password,
        port: credentials.port || 22
      }
    }));
  };

  ws.current.onmessage = (event) => {
    const message = JSON.parse(event.data);

    switch (message.type) {
      case 'connected':
        terminal.current?.write('\r\n\x1b[32m✓ SSH 连接成功\x1b[0m\r\n\r\n');
        setConnectionStatus('connected');
        break;

      case 'output':
        terminal.current?.write(message.payload.data);
        break;

      case 'error':
        terminal.current?.write(`\r\n\x1b[31m✗ 错误: ${message.payload.message}\x1b[0m\r\n`);
        setConnectionStatus('error');
        break;

      case 'closed':
        terminal.current?.write('\r\n\x1b[33m连接已关闭\x1b[0m\r\n');
        setConnectionStatus('disconnected');
        break;

      case 'pong':
        // 心跳响应
        break;
    }
  };

  ws.current.onerror = (error) => {
    terminal.current?.write('\r\n\x1b[31m✗ WebSocket 错误\x1b[0m\r\n');
    setConnectionStatus('error');
  };

  ws.current.onclose = () => {
    setConnectionStatus('disconnected');
  };

  // 心跳
  const pingInterval = setInterval(() => {
    if (ws.current?.readyState === WebSocket.OPEN) {
      ws.current.send(JSON.stringify({ type: 'ping' }));
    }
  }, 30000);

  return () => clearInterval(pingInterval);
};
```

### 4. 凭据输入对话框

在连接前显示 SSH 凭据输入表单：

```typescript
interface SSHCredentials {
  username: string;
  password?: string;
  privateKey?: string;
  passphrase?: string;
  port: number;
}

const SSHCredentialDialog: React.FC<Props> = ({ open, onConnect, onCancel }) => {
  const [credentials, setCredentials] = useState<SSHCredentials>({
    username: 'root',
    port: 22
  });
  const [authMethod, setAuthMethod] = useState<'password' | 'key'>('password');

  return (
    <Dialog open={open}>
      <DialogTitle>SSH 连接凭据</DialogTitle>
      <DialogContent>
        <TextField
          label="用户名"
          value={credentials.username}
          onChange={(e) => setCredentials({...credentials, username: e.target.value})}
          fullWidth
          required
        />
        <TextField
          label="端口"
          type="number"
          value={credentials.port}
          onChange={(e) => setCredentials({...credentials, port: parseInt(e.target.value)})}
          fullWidth
        />
        <RadioGroup value={authMethod} onChange={(e) => setAuthMethod(e.target.value)}>
          <FormControlLabel value="password" control={<Radio />} label="密码认证" />
          <FormControlLabel value="key" control={<Radio />} label="私钥认证" />
        </RadioGroup>

        {authMethod === 'password' ? (
          <TextField
            label="密码"
            type="password"
            value={credentials.password}
            onChange={(e) => setCredentials({...credentials, password: e.target.value})}
            fullWidth
            required
          />
        ) : (
          <>
            <TextField
              label="私钥"
              multiline
              rows={8}
              value={credentials.privateKey}
              onChange={(e) => setCredentials({...credentials, privateKey: e.target.value})}
              fullWidth
              required
              placeholder="-----BEGIN RSA PRIVATE KEY-----"
            />
            <TextField
              label="私钥密码（可选）"
              type="password"
              value={credentials.passphrase}
              onChange={(e) => setCredentials({...credentials, passphrase: e.target.value})}
              fullWidth
            />
          </>
        )}
      </DialogContent>
      <DialogActions>
        <Button onClick={onCancel}>取消</Button>
        <Button onClick={() => onConnect(credentials)} variant="contained">连接</Button>
      </DialogActions>
    </Dialog>
  );
};
```

### 5. 会话管理

在页面顶部显示活跃会话列表：

```typescript
// 获取活跃会话
const fetchActiveSessions = async () => {
  const response = await fetch('/api/ssh/sessions', {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  return response.json();
};

// 显示会话列表
<SessionList sessions={activeSessions} onSelect={switchToSession} />
```

### 6. UI/UX 细节

- **终端主题**: 支持浅色/深色主题切换
- **字体大小**: 可调节字体大小
- **复制粘贴**: 支持 Ctrl+C/Ctrl+V
- **全屏模式**: 支持全屏终端
- **连接状态指示器**: 显示连接/断开/错误状态
- **重连机制**: 断开后提示用户重新连接
- **会话保存**: 提供下载会话日志功能

## Why

用户需要通过 Web 界面直接连接设备进行调试，无需使用独立的 SSH 客户端。

## Impact

- **工作量**: 高 (终端模拟器集成 + WebSocket 通信 + 凭据管理)
- **Breaking changes**: 无 (新增页面)
- **依赖**:
  - xterm.js 库
  - web-server 的 WebSocket API
- **浏览器兼容性**: 需要支持 WebSocket 的现代浏览器
- **安全**:
  - 凭据通过 WSS 加密传输
  - 不在本地存储凭据
- **测试**: 需要 E2E 测试和 WebSocket 通信测试
