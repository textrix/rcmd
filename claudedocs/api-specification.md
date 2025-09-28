# API Specification Document
## RCMD (Rclone Commander)

**문서 버전**: 1.0
**작성일**: 2025-09-24
**API 버전**: v1
**기반 표준**: OpenAPI 3.0.3

---

## 📋 목차
1. [API 개요](#api-개요)
2. [인증 API](#인증-api)
3. [리모트 관리 API](#리모트-관리-api)
4. [파일 시스템 API](#파일-시스템-api)
5. [작업 관리 API](#작업-관리-api)
6. [실시간 통신 API](#실시간-통신-api)
7. [시스템 API](#시스템-api)
8. [에러 처리](#에러-처리)

---

## API 개요

### 기본 정보
- **Base URL**: `https://api.rcmd.local`
- **API Version**: `v1`
- **Protocol**: `HTTPS only`
- **Format**: `JSON`
- **Authentication**: `JWT Bearer Token`

### 공통 헤더
```http
Content-Type: application/json
Accept: application/json
Authorization: Bearer <token>
X-Request-ID: <uuid>
X-CSRF-Token: <csrf_token>
```

### Rate Limiting
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1609459200
```

---

## 인증 API

### POST /api/auth/login
**설명**: 사용자 로그인 및 토큰 발급

#### Request
```json
{
  "username": "string",
  "password": "string",
  "rememberMe": false
}
```

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "username": "string",
      "email": "string",
      "role": "admin|power_user|user",
      "permissions": ["read", "write", "delete"]
    },
    "tokens": {
      "accessToken": "jwt_token",
      "refreshToken": "refresh_token",
      "expiresIn": 900,
      "tokenType": "Bearer"
    }
  }
}
```

#### Response (401 Unauthorized)
```json
{
  "success": false,
  "error": {
    "code": "AUTH_FAILED",
    "message": "Invalid credentials",
    "timestamp": "2025-09-24T10:00:00Z"
  }
}
```

#### cURL Example
```bash
curl -X POST https://api.rcmd.local/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "secure_password"
  }'
```

---

### POST /api/auth/logout
**설명**: 사용자 로그아웃 및 세션 종료

#### Request
```http
POST /api/auth/logout
Authorization: Bearer <token>
```

#### Response (200 OK)
```json
{
  "success": true,
  "message": "Successfully logged out"
}
```

---

### POST /api/auth/refresh
**설명**: 액세스 토큰 갱신

#### Request
```json
{
  "refreshToken": "refresh_token_string"
}
```

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "accessToken": "new_jwt_token",
    "refreshToken": "new_refresh_token",
    "expiresIn": 900
  }
}
```

---

### GET /api/auth/verify
**설명**: 토큰 유효성 검증

#### Request
```http
GET /api/auth/verify
Authorization: Bearer <token>
```

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "valid": true,
    "user": {
      "id": "uuid",
      "username": "string",
      "role": "admin"
    },
    "expiresAt": "2025-09-24T11:00:00Z"
  }
}
```

---

## 리모트 관리 API

### GET /api/remotes
**설명**: 사용자가 접근 가능한 리모트 목록 조회

#### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| page | integer | No | 페이지 번호 (기본: 1) |
| limit | integer | No | 페이지당 항목 수 (기본: 20, 최대: 100) |
| search | string | No | 검색어 |
| type | string | No | 리모트 타입 필터 |
| status | string | No | 상태 필터 (online\|offline\|error) |
| sort | string | No | 정렬 기준 (name\|type\|size\|status) |
| order | string | No | 정렬 순서 (asc\|desc) |

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "remotes": [
      {
        "id": "gdrive",
        "name": "Google Drive",
        "type": "drive",
        "status": "online",
        "storage": {
          "total": 15728640000,
          "used": 5242880000,
          "free": 10485760000,
          "percentUsed": 33.33
        },
        "features": ["copy", "move", "delete", "mkdir"],
        "lastSync": "2025-09-24T10:00:00Z",
        "permissions": ["read", "write"]
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 101,
      "totalPages": 6
    }
  }
}
```

---

### GET /api/remotes/:id
**설명**: 특정 리모트 상세 정보 조회

#### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | 리모트 ID |

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "id": "gdrive",
    "name": "Google Drive",
    "type": "drive",
    "config": {
      "clientId": "***",
      "scope": "drive",
      "rootFolderId": "root"
    },
    "status": {
      "online": true,
      "lastCheck": "2025-09-24T10:00:00Z",
      "latency": 120,
      "error": null
    },
    "storage": {
      "total": 15728640000,
      "used": 5242880000,
      "free": 10485760000,
      "objects": 15234,
      "trashedObjects": 102
    },
    "quota": {
      "apiCalls": {
        "used": 8500,
        "limit": 10000,
        "resetAt": "2025-09-25T00:00:00Z"
      }
    }
  }
}
```

---

### GET /api/remotes/:id/files
**설명**: 리모트 파일 목록 조회

#### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| id | string | 리모트 ID |

#### Query Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| path | string | No | 디렉토리 경로 (기본: /) |
| recursive | boolean | No | 재귀적 조회 여부 |
| maxDepth | integer | No | 재귀 깊이 제한 |
| filter | string | No | 파일 필터 패턴 |
| type | string | No | 파일 타입 (file\|folder\|all) |
| sort | string | No | 정렬 기준 |

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "path": "/documents",
    "files": [
      {
        "name": "report.pdf",
        "path": "/documents/report.pdf",
        "type": "file",
        "size": 1048576,
        "mimeType": "application/pdf",
        "modTime": "2025-09-24T09:00:00Z",
        "isDir": false,
        "hash": {
          "type": "md5",
          "value": "5d41402abc4b2a76b9719d911017c592"
        }
      },
      {
        "name": "projects",
        "path": "/documents/projects",
        "type": "folder",
        "modTime": "2025-09-23T15:00:00Z",
        "isDir": true,
        "childCount": 25
      }
    ],
    "breadcrumb": [
      {"name": "root", "path": "/"},
      {"name": "documents", "path": "/documents"}
    ],
    "hasMore": false
  }
}
```

---

## 파일 시스템 API

### POST /api/operations/copy
**설명**: 파일/폴더 복사 작업 생성

#### Request
```json
{
  "source": {
    "remote": "gdrive",
    "path": "/documents/report.pdf"
  },
  "destination": {
    "remote": "onedrive",
    "path": "/backup/report.pdf"
  },
  "options": {
    "overwrite": false,
    "createPath": true,
    "preserveTimestamp": true
  }
}
```

#### Response (202 Accepted)
```json
{
  "success": true,
  "data": {
    "jobId": "job_uuid_123",
    "type": "copy",
    "status": "queued",
    "createdAt": "2025-09-24T10:00:00Z",
    "estimatedTime": 30
  }
}
```

---

### POST /api/operations/move
**설명**: 파일/폴더 이동 작업 생성

#### Request
```json
{
  "source": {
    "remote": "gdrive",
    "path": "/temp/file.txt"
  },
  "destination": {
    "remote": "gdrive",
    "path": "/documents/file.txt"
  }
}
```

#### Response (202 Accepted)
```json
{
  "success": true,
  "data": {
    "jobId": "job_uuid_124",
    "type": "move",
    "status": "queued"
  }
}
```

---

### DELETE /api/operations/delete
**설명**: 파일/폴더 삭제 작업

#### Request
```json
{
  "remote": "gdrive",
  "paths": [
    "/temp/file1.txt",
    "/temp/file2.txt"
  ],
  "options": {
    "permanent": false,
    "recursive": true
  }
}
```

#### Response (202 Accepted)
```json
{
  "success": true,
  "data": {
    "jobId": "job_uuid_125",
    "type": "delete",
    "status": "queued"
  }
}
```

---

### POST /api/operations/mkdir
**설명**: 디렉토리 생성

#### Request
```json
{
  "remote": "gdrive",
  "path": "/documents/new-folder",
  "options": {
    "parents": true
  }
}
```

#### Response (201 Created)
```json
{
  "success": true,
  "data": {
    "path": "/documents/new-folder",
    "created": true
  }
}
```

---

## 작업 관리 API

### GET /api/jobs
**설명**: 작업 목록 조회

#### Query Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| status | string | pending\|running\|completed\|failed |
| type | string | copy\|move\|delete\|sync |
| limit | integer | 결과 개수 제한 |
| since | datetime | 특정 시간 이후 작업 |

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "jobs": [
      {
        "id": "job_uuid_123",
        "type": "copy",
        "status": "running",
        "progress": {
          "percent": 45,
          "bytesTransferred": 47185920,
          "totalBytes": 104857600,
          "speed": 1048576,
          "eta": 55
        },
        "source": "gdrive:/documents/large-file.zip",
        "destination": "onedrive:/backup/large-file.zip",
        "startedAt": "2025-09-24T10:00:00Z",
        "updatedAt": "2025-09-24T10:00:45Z"
      }
    ],
    "summary": {
      "total": 10,
      "pending": 3,
      "running": 2,
      "completed": 4,
      "failed": 1
    }
  }
}
```

---

### GET /api/jobs/:id
**설명**: 특정 작업 상세 정보

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "id": "job_uuid_123",
    "type": "copy",
    "status": "completed",
    "progress": {
      "percent": 100,
      "bytesTransferred": 104857600,
      "totalBytes": 104857600
    },
    "result": {
      "success": true,
      "duration": 120,
      "averageSpeed": 873813
    },
    "log": [
      {
        "timestamp": "2025-09-24T10:00:00Z",
        "level": "info",
        "message": "Job started"
      },
      {
        "timestamp": "2025-09-24T10:02:00Z",
        "level": "info",
        "message": "Job completed successfully"
      }
    ]
  }
}
```

---

### POST /api/jobs/:id/cancel
**설명**: 작업 취소

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "id": "job_uuid_123",
    "status": "cancelled",
    "cancelledAt": "2025-09-24T10:01:30Z"
  }
}
```

---

### POST /api/jobs/:id/retry
**설명**: 실패한 작업 재시도

#### Response (200 OK)
```json
{
  "success": true,
  "data": {
    "originalJobId": "job_uuid_123",
    "newJobId": "job_uuid_126",
    "status": "queued"
  }
}
```

---

## 실시간 통신 API

### GET /api/sse/connect
**설명**: Server-Sent Events 연결 생성

#### Request Headers
```http
Accept: text/event-stream
Cache-Control: no-cache
```

#### Response (200 OK)
```http
HTTP/1.1 200 OK
Content-Type: text/event-stream
Cache-Control: no-cache
Connection: keep-alive

: heartbeat

event: remote-status
data: {"remoteId":"gdrive","status":"online","timestamp":"2025-09-24T10:00:00Z"}

event: job-progress
data: {"jobId":"job_uuid_123","progress":50,"eta":30}

event: notification
data: {"type":"info","message":"Backup completed successfully","timestamp":"2025-09-24T10:00:00Z"}
```

---

### WebSocket /api/ws
**설명**: WebSocket 연결 (대체 실시간 통신)

#### Connection
```javascript
const ws = new WebSocket('wss://api.rcmd.local/api/ws');

// 인증
ws.send(JSON.stringify({
  type: 'auth',
  token: 'jwt_token'
}));

// 구독
ws.send(JSON.stringify({
  type: 'subscribe',
  channels: ['remotes', 'jobs', 'notifications']
}));
```

#### Messages
```json
// 서버 → 클라이언트
{
  "type": "remote-update",
  "data": {
    "remoteId": "gdrive",
    "changes": {
      "status": "offline"
    }
  }
}

// 클라이언트 → 서버
{
  "type": "ping",
  "timestamp": 1609459200
}
```

---

## 시스템 API

### GET /api/health
**설명**: 시스템 상태 확인

#### Response (200 OK)
```json
{
  "status": "healthy",
  "timestamp": "2025-09-24T10:00:00Z",
  "version": "1.0.0",
  "uptime": 86400,
  "services": {
    "database": "healthy",
    "redis": "healthy",
    "rclone": "healthy"
  }
}
```

---

### GET /api/metrics
**설명**: 시스템 메트릭스 (Prometheus 형식)

#### Response (200 OK)
```text
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",status="200"} 1234
http_requests_total{method="POST",status="201"} 456

# HELP active_jobs Number of active jobs
# TYPE active_jobs gauge
active_jobs{type="copy"} 3
active_jobs{type="move"} 1

# HELP api_response_time API response time in seconds
# TYPE api_response_time histogram
api_response_time_bucket{le="0.1"} 100
api_response_time_bucket{le="0.5"} 250
api_response_time_bucket{le="1"} 300
```

---

### GET /api/status
**설명**: 시스템 상태 대시보드 데이터

#### Response (200 OK)
```json
{
  "remotes": [
    {
      "id": "gdrive",
      "name": "Google Drive",
      "online": true,
      "circuitBreaker": "CLOSED",
      "lastCheck": "2025-09-24T10:00:00Z",
      "errors": 0
    }
  ],
  "jobs": {
    "active": [
      {
        "id": "job_123",
        "type": "copy",
        "progress": 45,
        "source": "gdrive:/file.zip",
        "destination": "onedrive:/backup/",
        "startedAt": "2025-09-24T09:55:00Z"
      }
    ],
    "queued": 3,
    "completed": 127,
    "failed": 2
  },
  "system": {
    "uptime": 86400,
    "memory": {
      "used": 256000000,
      "total": 512000000
    },
    "workers": {
      "active": 2,
      "idle": 3,
      "total": 5
    }
  }
}
```

---

### GET /api/info
**설명**: API 정보 및 기능 목록

#### Response (200 OK)
```json
{
  "name": "RCMD (Rclone Commander) API",
  "version": "1.0.0",
  "environment": "production",
  "features": {
    "auth": true,
    "remotes": true,
    "files": true,
    "jobs": true,
    "realtime": true,
    "search": false,
    "backup": false
  },
  "limits": {
    "maxFileSize": 5368709120,
    "maxConcurrentJobs": 10,
    "maxRemotes": 200,
    "rateLimitPerMinute": 100
  },
  "links": {
    "documentation": "https://docs.rcmd.local",
    "status": "https://status.rcmd.local",
    "support": "https://support.rcmd.local"
  }
}
```

---

## 에러 처리

### 에러 응답 형식
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      "field": "Additional error context"
    },
    "timestamp": "2025-09-24T10:00:00Z",
    "traceId": "trace_uuid"
  }
}
```

### 표준 에러 코드

#### 4xx Client Errors
| Code | HTTP Status | Description |
|------|-------------|-------------|
| BAD_REQUEST | 400 | 잘못된 요청 형식 |
| UNAUTHORIZED | 401 | 인증 필요 |
| FORBIDDEN | 403 | 권한 없음 |
| NOT_FOUND | 404 | 리소스 없음 |
| CONFLICT | 409 | 리소스 충돌 |
| VALIDATION_ERROR | 422 | 유효성 검증 실패 |
| RATE_LIMITED | 429 | 요청 제한 초과 |

#### 5xx Server Errors
| Code | HTTP Status | Description |
|------|-------------|-------------|
| INTERNAL_ERROR | 500 | 서버 내부 오류 |
| NOT_IMPLEMENTED | 501 | 미구현 기능 |
| SERVICE_UNAVAILABLE | 503 | 서비스 일시 중단 |
| GATEWAY_TIMEOUT | 504 | 게이트웨이 타임아웃 |

### 에러 응답 예시

#### 400 Bad Request
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "username": "Username is required",
      "password": "Password must be at least 12 characters"
    }
  }
}
```

#### 429 Rate Limited
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMITED",
    "message": "Too many requests",
    "details": {
      "limit": 100,
      "remaining": 0,
      "resetAt": "2025-09-24T11:00:00Z"
    }
  }
}
```

---

## API 보안

### 인증 방식
- **JWT Bearer Token**: 모든 보호된 엔드포인트
- **API Key**: 외부 시스템 연동 (선택적)
- **OAuth 2.0**: 향후 지원 예정

### CORS 설정
```javascript
{
  origin: ['https://rcmd.local', 'https://app.rcmd.local'],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-CSRF-Token'],
  maxAge: 86400
}
```

### 보안 헤더
```http
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
Content-Security-Policy: default-src 'self'
```

---

## API 버저닝

### 버전 관리 정책
- **URL Path 버저닝**: `/api/v1/`, `/api/v2/`
- **하위 호환성**: 최소 6개월 유지
- **Deprecation**: 3개월 전 공지
- **Sunset Header**: 종료 예정 API 표시

### Deprecation 헤더
```http
Sunset: Sat, 31 Dec 2025 23:59:59 GMT
Deprecation: true
Link: <https://api.rcmd.local/api/v2/remotes>; rel="successor-version"
```

---

## 페이지네이션

### Cursor 기반 페이지네이션
```json
{
  "data": [...],
  "pagination": {
    "cursor": "eyJpZCI6MTAwfQ==",
    "hasNext": true,
    "hasPrev": false,
    "limit": 20
  }
}
```

### Offset 기반 페이지네이션
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 101,
    "totalPages": 6
  }
}
```

---

## API 테스팅

### Postman Collection
```json
{
  "info": {
    "name": "RCMD API",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Login",
          "request": {
            "method": "POST",
            "url": "{{baseUrl}}/api/auth/login",
            "body": {
              "mode": "raw",
              "raw": "{\"username\":\"{{username}}\",\"password\":\"{{password}}\"}"
            }
          }
        }
      ]
    }
  ]
}
```

### 테스트 시나리오
```javascript
// 인증 플로우 테스트
describe('Authentication Flow', () => {
  it('should login successfully', async () => {
    const response = await api.post('/auth/login', {
      username: 'testuser',
      password: 'Test123!@#'
    });

    expect(response.status).toBe(200);
    expect(response.data.tokens).toBeDefined();
  });
});
```

---

## 부록

### A. Status Codes 요약
- **2xx**: 성공
  - 200: OK
  - 201: Created
  - 202: Accepted
  - 204: No Content
- **4xx**: 클라이언트 에러
  - 400: Bad Request
  - 401: Unauthorized
  - 403: Forbidden
  - 404: Not Found
  - 429: Too Many Requests
- **5xx**: 서버 에러
  - 500: Internal Server Error
  - 503: Service Unavailable

### B. Content Types
- `application/json`: 기본 응답 형식
- `text/event-stream`: SSE 스트림
- `multipart/form-data`: 파일 업로드
- `application/octet-stream`: 파일 다운로드

### C. 날짜 형식
- **ISO 8601**: `2025-09-24T10:00:00Z`
- **Unix Timestamp**: `1609459200` (선택적)

---

**문서 완료**: 2025-09-24
**다음 단계**: 데이터베이스 스키마 문서 작성