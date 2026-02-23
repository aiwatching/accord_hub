---
id: req-004-add-admin-api
from: orchestrator
to: web-server
scope: external
type: api-addition
priority: medium
status: pending
created: 2026-02-23T10:30:00Z
updated: 2026-02-23T10:30:00Z
on_behalf_of: user
related_contract: contracts/web-server.yaml
---

## What

为管理员页面提供后端 API 接口,支持用户管理和系统配置。

## Proposed Change

在 web-server 中添加以下 API 端点:

```yaml
paths:
  /api/admin/users:
    get:
      summary: 获取用户列表
      security:
        - BearerAuth: [admin]
      responses:
        200:
          description: 用户列表
          content:
            application/json:
              schema:
                type: array
                items:
                  type: object
                  properties:
                    id: string
                    username: string
                    email: string
                    role: string
                    createdAt: string
    post:
      summary: 创建新用户
      security:
        - BearerAuth: [admin]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                username: string
                email: string
                password: string
                role: string
      responses:
        201:
          description: 用户创建成功

  /api/admin/users/{id}:
    put:
      summary: 更新用户信息
      security:
        - BearerAuth: [admin]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        200:
          description: 更新成功
    delete:
      summary: 删除用户
      security:
        - BearerAuth: [admin]
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        204:
          description: 删除成功

  /api/admin/settings:
    get:
      summary: 获取系统设置
      security:
        - BearerAuth: [admin]
      responses:
        200:
          description: 系统设置
    put:
      summary: 更新系统设置
      security:
        - BearerAuth: [admin]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
      responses:
        200:
          description: 更新成功
```

**权限要求**:
- 所有 `/api/admin/*` 端点需要验证用户具有 `admin` 角色
- 返回 403 Forbidden 给非管理员用户

**数据库变更** (如需要):
- 确保 User 模型有 `role` 字段
- 创建 Settings 表存储系统配置

## Why

管理员页面需要后端 API 支持来执行用户管理和系统配置操作。

## Impact

- **工作量**: 中等 (约 5-6 个 API 端点 + 权限中间件)
- **Breaking changes**: 无 (新增端点,不影响现有 API)
- **依赖**: 可能依赖现有的认证系统
- **数据库迁移**: 如果 User 表缺少 role 字段,需要添加迁移脚本
- **测试**: 需要添加 API 集成测试和权限测试
