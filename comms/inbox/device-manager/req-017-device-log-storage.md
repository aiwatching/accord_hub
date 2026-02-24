---
id: req-017-device-log-storage
from: orchestrator
to: device-manager
scope: internal
type: interface-addition
priority: medium
status: in-progress
created: 2026-02-24T13:00:00.000Z
updated: '2026-02-24T23:51:44.176Z'
on_behalf_of: user
related_contract: contracts/internal/device-manager.md
---

## What

Implement device log storage and query functionality to support receiving, storing, and querying logs from IoT devices.

## Proposed Change

Add device log management interfaces in device-manager:

```java
// DeviceLogService.java
public interface DeviceLogService {
    /**
     * Save a log entry from a device
     * @param deviceId Device ID
     * @param logEntry Log entry to save
     * @return Saved log entry with generated ID
     * @throws DeviceNotFoundException if device does not exist
     */
    DeviceLog saveLog(String deviceId, DeviceLogEntry logEntry);

    /**
     * Batch save log entries (for bulk ingestion)
     * @param deviceId Device ID
     * @param logEntries List of log entries
     * @return Number of logs saved
     */
    int saveLogs(String deviceId, List<DeviceLogEntry> logEntries);

    /**
     * Query logs with filters
     * @param deviceId Device ID
     * @param filters Query filters (time range, level, keyword, etc.)
     * @return Paginated log results
     */
    PagedResult<DeviceLog> queryLogs(String deviceId, LogQueryFilters filters);

    /**
     * Get recent logs for real-time display
     * @param deviceId Device ID
     * @param limit Maximum number of logs to return
     * @return Recent logs ordered by timestamp descending
     */
    List<DeviceLog> getRecentLogs(String deviceId, int limit);

    /**
     * Delete old logs (for retention policy)
     * @param beforeDate Delete logs older than this date
     * @return Number of logs deleted
     */
    int deleteLogsBefore(LocalDateTime beforeDate);

    /**
     * Get log statistics for a device
     * @param deviceId Device ID
     * @param timeRange Time range for statistics
     * @return Log statistics (count by level, etc.)
     */
    LogStatistics getLogStatistics(String deviceId, TimeRange timeRange);
}

// DeviceLogEntry.java (Input)
public class DeviceLogEntry {
    private String timestamp;          // ISO 8601 format
    private String level;              // ERROR, WARN, INFO, DEBUG
    private String message;            // Log message
    private Map<String, Object> metadata; // Optional metadata (component, tags, etc.)
}

// DeviceLog.java (Stored entity)
@Entity
@Table(name = "device_logs", indexes = {
    @Index(name = "idx_device_timestamp", columnList = "device_id,timestamp"),
    @Index(name = "idx_level", columnList = "level"),
    @Index(name = "idx_timestamp", columnList = "timestamp")
})
public class DeviceLog {
    @Id
    @GeneratedValue
    private Long id;

    @Column(name = "device_id", nullable = false)
    private String deviceId;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private LogLevel level;            // ERROR, WARN, INFO, DEBUG

    @Column(columnDefinition = "TEXT", nullable = false)
    private String message;

    @Column(columnDefinition = "JSON")
    private String metadata;           // JSON string

    @Column(name = "created_at")
    private LocalDateTime createdAt;   // When log was received

    // Getters and setters
}

// LogLevel.java
public enum LogLevel {
    ERROR,
    WARN,
    INFO,
    DEBUG
}

// LogQueryFilters.java
public class LogQueryFilters {
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private LogLevel level;            // Filter by specific level
    private String keyword;            // Search in message
    private int page = 0;
    private int pageSize = 50;
    private String sortBy = "timestamp";
    private String sortOrder = "desc";
}

// PagedResult.java
public class PagedResult<T> {
    private List<T> items;
    private long totalCount;
    private int page;
    private int pageSize;
    private int totalPages;
}

// LogStatistics.java
public class LogStatistics {
    private long totalCount;
    private Map<LogLevel, Long> countByLevel;  // ERROR: 10, WARN: 25, etc.
    private LocalDateTime oldestLog;
    private LocalDateTime latestLog;
}
```

**Implementation Details**:

1. **Database Schema**:
   - Table: `device_logs`
   - Indexes on: (device_id, timestamp), level, timestamp
   - Use database partitioning by date for better performance (optional)

2. **Storage Logic**:
   - Validate device exists before saving logs
   - Parse timestamp string to LocalDateTime
   - Validate log level enum
   - Store metadata as JSON string
   - Set createdAt to current server time

3. **Query Optimization**:
   - Use database indexes for efficient queries
   - Limit default page size to 50 logs
   - Support full-text search on message field (if database supports)

4. **Retention Policy** (optional but recommended):
   - Configure retention period (e.g., 90 days)
   - Scheduled job to delete old logs
   - Archive to file system before deletion (optional)

5. **Performance Considerations**:
   - Batch insert for bulk logs
   - Async processing for non-critical log saves
   - Connection pooling for database access

## Why

IoT devices need to send operational logs to the system for monitoring, debugging, and troubleshooting. Centralized log storage enables better visibility into device behavior.

## Impact

- **Effort**: Medium-High (data model + repository + service + database migration)
- **Breaking changes**: None (new feature)
- **Dependencies**:
  - Database with JSON support (PostgreSQL, MySQL 5.7+)
  - JPA/Hibernate for ORM
- **Database Migration**: New table `device_logs` with indexes
- **Performance**:
  - Consider partitioning for large log volumes
  - Indexes critical for query performance
- **Testing**: Unit tests + integration tests with in-memory database
