---
id: req-019-device-log-ui
from: orchestrator
to: frontend
scope: external
type: api-addition
priority: medium
status: in-progress
created: 2026-02-24T13:00:00.000Z
updated: '2026-02-24T23:53:04.189Z'
on_behalf_of: user
related_contract: contracts/frontend.yaml
---

## What

Create user interface for viewing device logs in real-time and querying historical logs with filtering and export capabilities.

## Proposed Change

Add device log viewing functionality to the frontend:

### 1. Navigation & Routes

**New Routes**:
- `/devices/{deviceId}/logs` - Device log viewer page
- `/devices/{deviceId}/logs/live` - Real-time log streaming view (optional separate page)

**Entry Points**:
- Add "View Logs" button in device list (actions column)
- Add "Logs" tab in device details page
- Add log icon with error count badge if device has recent errors

### 2. Real-time Log Viewer Component

```typescript
import React, { useEffect, useRef, useState } from 'react';

interface LogEntry {
  id: number;
  deviceId: string;
  timestamp: string;
  level: 'ERROR' | 'WARN' | 'INFO' | 'DEBUG';
  message: string;
  metadata?: Record<string, any>;
}

const RealtimeLogViewer: React.FC<{ deviceId: string }> = ({ deviceId }) => {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [isPaused, setIsPaused] = useState(false);
  const [levelFilter, setLevelFilter] = useState<string>('ALL');
  const [autoScroll, setAutoScroll] = useState(true);
  const ws = useRef<WebSocket | null>(null);
  const logContainerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Connect to WebSocket
    const token = getAuthToken();
    const wsUrl = `wss://${window.location.host}/ws/devices/${deviceId}/logs?token=${token}&level=${levelFilter}`;

    ws.current = new WebSocket(wsUrl);

    ws.current.onopen = () => {
      console.log('WebSocket connected');
    };

    ws.current.onmessage = (event) => {
      if (!isPaused) {
        const message = JSON.parse(event.data);
        if (message.type === 'log') {
          setLogs((prev) => [...prev, message.data].slice(-500)); // Keep last 500 logs
        }
      }
    };

    ws.current.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    ws.current.onclose = () => {
      console.log('WebSocket disconnected');
    };

    return () => {
      ws.current?.close();
    };
  }, [deviceId, levelFilter, isPaused]);

  // Auto-scroll to bottom when new logs arrive
  useEffect(() => {
    if (autoScroll && logContainerRef.current) {
      logContainerRef.current.scrollTop = logContainerRef.current.scrollHeight;
    }
  }, [logs, autoScroll]);

  const getLevelColor = (level: string) => {
    switch (level) {
      case 'ERROR': return '#f44336'; // Red
      case 'WARN': return '#ff9800';  // Orange
      case 'INFO': return '#2196f3';  // Blue
      case 'DEBUG': return '#9e9e9e'; // Gray
      default: return '#000000';
    }
  };

  const getLevelIcon = (level: string) => {
    switch (level) {
      case 'ERROR': return '❌';
      case 'WARN': return '⚠️';
      case 'INFO': return 'ℹ️';
      case 'DEBUG': return '🐛';
      default: return '📄';
    }
  };

  return (
    <div className="realtime-log-viewer">
      {/* Toolbar */}
      <div className="log-toolbar">
        <div className="toolbar-left">
          <select
            value={levelFilter}
            onChange={(e) => setLevelFilter(e.target.value)}
          >
            <option value="ALL">All Levels</option>
            <option value="ERROR">Error Only</option>
            <option value="WARN">Warn & Above</option>
            <option value="INFO">Info & Above</option>
            <option value="DEBUG">Debug & Above</option>
          </select>

          <button onClick={() => setIsPaused(!isPaused)}>
            {isPaused ? '▶️ Resume' : '⏸️ Pause'}
          </button>

          <button onClick={() => setLogs([])}>
            🗑️ Clear
          </button>
        </div>

        <div className="toolbar-right">
          <label>
            <input
              type="checkbox"
              checked={autoScroll}
              onChange={(e) => setAutoScroll(e.target.checked)}
            />
            Auto-scroll
          </label>

          <span className="log-count">
            {logs.length} logs
          </span>
        </div>
      </div>

      {/* Log Display */}
      <div
        ref={logContainerRef}
        className="log-container"
        style={{
          height: '600px',
          overflow: 'auto',
          backgroundColor: '#1e1e1e',
          color: '#d4d4d4',
          fontFamily: 'Consolas, Monaco, "Courier New", monospace',
          fontSize: '13px',
          padding: '10px',
        }}
      >
        {logs.map((log) => (
          <div
            key={log.id}
            className="log-entry"
            style={{
              padding: '4px 0',
              borderBottom: '1px solid #333',
            }}
          >
            <span style={{ color: '#888' }}>
              [{new Date(log.timestamp).toLocaleTimeString()}]
            </span>
            {' '}
            <span style={{ color: getLevelColor(log.level), fontWeight: 'bold' }}>
              {getLevelIcon(log.level)} {log.level}
            </span>
            {' '}
            <span>{log.message}</span>
            {log.metadata && (
              <span style={{ color: '#888', fontSize: '11px' }}>
                {' '}{JSON.stringify(log.metadata)}
              </span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
};
```

### 3. Historical Log Query Component

```typescript
const HistoricalLogQuery: React.FC<{ deviceId: string }> = ({ deviceId }) => {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({
    startTime: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(), // Last 24 hours
    endTime: new Date().toISOString(),
    level: '',
    keyword: '',
    page: 0,
    pageSize: 50,
  });
  const [totalCount, setTotalCount] = useState(0);

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const queryParams = new URLSearchParams({
        startTime: filters.startTime,
        endTime: filters.endTime,
        ...(filters.level && { level: filters.level }),
        ...(filters.keyword && { keyword: filters.keyword }),
        page: filters.page.toString(),
        pageSize: filters.pageSize.toString(),
      });

      const response = await fetch(
        `/api/devices/${deviceId}/logs?${queryParams}`,
        {
          headers: {
            Authorization: `Bearer ${getAuthToken()}`,
          },
        }
      );

      const data = await response.json();
      setLogs(data.items);
      setTotalCount(data.totalCount);
    } catch (error) {
      console.error('Failed to fetch logs:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, [filters.page, filters.pageSize]);

  const handleExport = async (format: 'csv' | 'json') => {
    const queryParams = new URLSearchParams({
      format,
      startTime: filters.startTime,
      endTime: filters.endTime,
      ...(filters.level && { level: filters.level }),
    });

    const url = `/api/devices/${deviceId}/logs/export?${queryParams}`;
    window.open(url, '_blank');
  };

  return (
    <div className="historical-log-query">
      {/* Filters */}
      <div className="filter-panel">
        <div className="filter-row">
          <label>
            Start Time:
            <input
              type="datetime-local"
              value={filters.startTime.slice(0, 16)}
              onChange={(e) =>
                setFilters({ ...filters, startTime: new Date(e.target.value).toISOString() })
              }
            />
          </label>

          <label>
            End Time:
            <input
              type="datetime-local"
              value={filters.endTime.slice(0, 16)}
              onChange={(e) =>
                setFilters({ ...filters, endTime: new Date(e.target.value).toISOString() })
              }
            />
          </label>

          <label>
            Level:
            <select
              value={filters.level}
              onChange={(e) => setFilters({ ...filters, level: e.target.value })}
            >
              <option value="">All</option>
              <option value="ERROR">Error</option>
              <option value="WARN">Warn</option>
              <option value="INFO">Info</option>
              <option value="DEBUG">Debug</option>
            </select>
          </label>

          <label>
            Keyword:
            <input
              type="text"
              placeholder="Search in message..."
              value={filters.keyword}
              onChange={(e) => setFilters({ ...filters, keyword: e.target.value })}
            />
          </label>

          <button onClick={fetchLogs}>🔍 Search</button>
        </div>

        <div className="filter-row">
          <button onClick={() => handleExport('csv')}>📥 Export CSV</button>
          <button onClick={() => handleExport('json')}>📥 Export JSON</button>
        </div>
      </div>

      {/* Results */}
      {loading ? (
        <div>Loading...</div>
      ) : (
        <>
          <div className="results-info">
            Found {totalCount} logs
          </div>

          <table className="log-table">
            <thead>
              <tr>
                <th>Timestamp</th>
                <th>Level</th>
                <th>Message</th>
                <th>Metadata</th>
              </tr>
            </thead>
            <tbody>
              {logs.map((log) => (
                <tr key={log.id}>
                  <td>{new Date(log.timestamp).toLocaleString()}</td>
                  <td>
                    <span className={`badge badge-${log.level.toLowerCase()}`}>
                      {log.level}
                    </span>
                  </td>
                  <td>{log.message}</td>
                  <td>
                    {log.metadata && (
                      <code>{JSON.stringify(log.metadata)}</code>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* Pagination */}
          <div className="pagination">
            <button
              disabled={filters.page === 0}
              onClick={() => setFilters({ ...filters, page: filters.page - 1 })}
            >
              Previous
            </button>
            <span>
              Page {filters.page + 1} of {Math.ceil(totalCount / filters.pageSize)}
            </span>
            <button
              disabled={(filters.page + 1) * filters.pageSize >= totalCount}
              onClick={() => setFilters({ ...filters, page: filters.page + 1 })}
            >
              Next
            </button>
          </div>
        </>
      )}
    </div>
  );
};
```

### 4. Main Log Page Layout

```typescript
const DeviceLogPage: React.FC = () => {
  const { deviceId } = useParams<{ deviceId: string }>();
  const [activeTab, setActiveTab] = useState<'live' | 'history'>('live');

  return (
    <div className="device-log-page">
      <h2>Device Logs: {deviceId}</h2>

      {/* Tab Navigation */}
      <div className="tab-navigation">
        <button
          className={activeTab === 'live' ? 'active' : ''}
          onClick={() => setActiveTab('live')}
        >
          📡 Live Logs
        </button>
        <button
          className={activeTab === 'history' ? 'active' : ''}
          onClick={() => setActiveTab('history')}
        >
          📚 Historical Logs
        </button>
      </div>

      {/* Tab Content */}
      <div className="tab-content">
        {activeTab === 'live' && <RealtimeLogViewer deviceId={deviceId} />}
        {activeTab === 'history' && <HistoricalLogQuery deviceId={deviceId} />}
      </div>
    </div>
  );
};
```

### 5. Features Summary

**Real-time Log Viewer**:
- ✅ WebSocket connection for live log streaming
- ✅ Color-coded log levels (ERROR=red, WARN=orange, INFO=blue, DEBUG=gray)
- ✅ Pause/Resume streaming
- ✅ Auto-scroll toggle
- ✅ Clear logs button
- ✅ Level filter dropdown
- ✅ Keeps last 500 logs in memory

**Historical Log Query**:
- ✅ Time range picker (start & end time)
- ✅ Log level filter
- ✅ Keyword search
- ✅ Paginated results (50 per page)
- ✅ Export to CSV/JSON
- ✅ Results count display

**UI/UX Details**:
- Dark theme for log console (easier on eyes)
- Monospace font for log messages
- Timestamp formatting
- Level badges with icons
- Responsive layout
- Loading states
- Error handling

## Why

Users need a convenient web interface to monitor device logs in real-time and investigate historical issues without using command-line tools.

## Impact

- **Effort**: Medium-High (2 major components + API integration + WebSocket handling)
- **Breaking changes**: None (new pages)
- **Dependencies**:
  - web-server log APIs
  - WebSocket support in browser
  - Date picker component library
- **Browser Compatibility**: Modern browsers with WebSocket support
- **Testing**: Component tests + E2E tests for both real-time and historical views
