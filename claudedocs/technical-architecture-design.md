# Technical Architecture Design Document
## RCMD (Rclone Commander)

**문서 버전**: 1.0
**작성일**: 2025-09-24
**프로젝트 코드명**: RCMD
**아키텍처 패턴**: Layered Architecture + Microservices Pattern

---

## 📋 목차
1. [아키텍처 개요](#아키텍처-개요)
2. [시스템 컴포넌트](#시스템-컴포넌트)
3. [데이터 플로우](#데이터-플로우)
4. [기술 스택 상세](#기술-스택-상세)
5. [배포 아키텍처](#배포-아키텍처)
6. [보안 아키텍처](#보안-아키텍처)
7. [성능 최적화 전략](#성능-최적화-전략)
8. [확장성 설계](#확장성-설계)
9. [참조 구현](#참조-구현)

---

## 아키텍처 개요

### 1.1 고수준 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                     사용자 인터페이스 계층                    │
│                   (Svelte + Mantine UI)                      │
├─────────────────────────────────────────────────────────────┤
│                      API Gateway 계층                        │
│                  (SvelteKit rproxy Server)                   │
├─────────────────────────────────────────────────────────────┤
│                     비즈니스 로직 계층                        │
│              (인증, 권한, 캐싱, 작업 관리)                    │
├─────────────────────────────────────────────────────────────┤
│                      데이터 접근 계층                         │
│                   (ORM, Query Builder)                       │
├─────────────────────────────────────────────────────────────┤
│                      외부 서비스 계층                         │
│                  (rclone RC API, Cloud APIs)                 │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 핵심 설계 원칙

#### 무상태 프론트엔드
- 모든 상태는 서버에서 관리
- API 호출을 통한 데이터 페칭
- 클라이언트 캐싱 최소화

#### 보안 우선 설계
- Zero Trust 아키텍처
- 모든 요청 검증
- 최소 권한 원칙

#### 확장 가능한 설계
- 수평 확장 가능
- 마이크로서비스 준비
- 이벤트 기반 통신

---

## 시스템 컴포넌트

### 2.1 Frontend Components

```typescript
// 컴포넌트 계층 구조
src/lib/components/
├── core/                 # 핵심 재사용 컴포넌트
│   ├── Button/
│   ├── Modal/
│   └── Table/
├── features/            # 기능별 컴포넌트
│   ├── auth/           # 인증 관련
│   │   ├── LoginForm.svelte
│   │   └── AuthGuard.svelte
│   ├── remotes/        # 리모트 관리
│   │   ├── RemoteList.svelte
│   │   ├── RemoteCard.svelte
│   │   └── RemoteStatus.svelte
│   ├── files/          # 파일 시스템
│   │   ├── FileBrowser.svelte
│   │   ├── FileGrid.svelte
│   │   └── FilePreview.svelte
│   └── jobs/           # 작업 관리
│       ├── JobQueue.svelte
│       └── JobProgress.svelte
└── layout/             # 레이아웃 컴포넌트
    ├── Header.svelte
    ├── Sidebar.svelte
    └── Footer.svelte
```

### 2.2 Backend Services

#### 2.2.1 Authentication Service
```typescript
// lib/server/services/auth.service.ts
export class AuthService {
  async login(credentials: LoginDTO): Promise<AuthToken>
  async logout(token: string): Promise<void>
  async refresh(refreshToken: string): Promise<AuthToken>
  async verify(token: string): Promise<User>
  async generateTokenPair(user: User): Promise<TokenPair>
}
```

#### 2.2.2 Permission Service
```typescript
// lib/server/services/permission.service.ts
export class PermissionService {
  async checkRemoteAccess(userId: string, remoteId: string): Promise<boolean>
  async getPermissionMatrix(userId: string): Promise<PermissionMatrix>
  async updatePermissions(permissions: Permission[]): Promise<void>
  async enforcePathPermission(userId: string, path: string): Promise<boolean>
}
```

#### 2.2.3 Proxy Service
```typescript
// lib/server/services/proxy.service.ts
export class ProxyService {
  async forward(request: Request): Promise<Response>
  async validateRequest(request: Request): Promise<void>
  async transformResponse(response: Response): Promise<Response>
  async handleRateLimiting(clientId: string): Promise<void>
}
```

#### 2.2.4 Cache Service
```typescript
// lib/server/services/cache.service.ts
export class CacheService {
  async get<T>(key: string): Promise<T | null>
  async set<T>(key: string, value: T, ttl?: number): Promise<void>
  async invalidate(pattern: string): Promise<void>
  async warmup(): Promise<void>
}
```

#### 2.2.5 Job Queue Service
```typescript
// lib/server/services/job.service.ts
export class JobQueueService {
  async enqueue(job: Job): Promise<string>
  async process(jobId: string): Promise<void>
  async getStatus(jobId: string): Promise<JobStatus>
  async cancel(jobId: string): Promise<void>
  async retry(jobId: string): Promise<void>
}
```

### 2.3 Data Access Layer

```typescript
// lib/server/database/schema.ts
export const schema = {
  users: {
    id: varchar('id').primaryKey(),
    username: varchar('username').unique(),
    email: varchar('email').unique(),
    passwordHash: varchar('password_hash'),
    role: enum(['admin', 'power_user', 'user']),
    createdAt: timestamp('created_at'),
    updatedAt: timestamp('updated_at')
  },

  permissions: {
    id: varchar('id').primaryKey(),
    userId: varchar('user_id').references(() => users.id),
    remoteId: varchar('remote_id'),
    permissions: json('permissions'),
    paths: json('paths'),
    createdAt: timestamp('created_at')
  },

  jobs: {
    id: varchar('id').primaryKey(),
    type: enum(['copy', 'move', 'delete', 'sync']),
    status: enum(['pending', 'running', 'completed', 'failed']),
    progress: integer('progress'),
    payload: json('payload'),
    result: json('result'),
    error: text('error'),
    createdAt: timestamp('created_at'),
    startedAt: timestamp('started_at'),
    completedAt: timestamp('completed_at')
  },

  sessions: {
    id: varchar('id').primaryKey(),
    userId: varchar('user_id').references(() => users.id),
    token: varchar('token').unique(),
    expiresAt: timestamp('expires_at'),
    createdAt: timestamp('created_at')
  }
};
```

---

## 데이터 플로우

### 3.1 인증 플로우

```mermaid
sequenceDiagram
    participant Client
    participant rproxy
    participant AuthService
    participant Database
    participant rclone

    Client->>rproxy: POST /api/auth/login
    rproxy->>AuthService: validateCredentials()
    AuthService->>Database: findUser()
    Database-->>AuthService: User
    AuthService->>AuthService: generateTokens()
    AuthService->>Database: saveSession()
    AuthService-->>rproxy: TokenPair
    rproxy-->>Client: 200 OK (tokens)

    Client->>rproxy: GET /api/remotes (with token)
    rproxy->>AuthService: verifyToken()
    AuthService->>Database: getSession()
    Database-->>AuthService: Session
    AuthService-->>rproxy: User
    rproxy->>rclone: Forward request
    rclone-->>rproxy: Remote list
    rproxy-->>Client: 200 OK (remotes)
```

### 3.2 파일 작업 플로우

```mermaid
sequenceDiagram
    participant Client
    participant rproxy
    participant JobQueue
    participant Worker
    participant rclone

    Client->>rproxy: POST /api/operations/copy
    rproxy->>JobQueue: enqueue(copyJob)
    JobQueue-->>rproxy: jobId
    rproxy-->>Client: 202 Accepted (jobId)

    Worker->>JobQueue: poll()
    JobQueue-->>Worker: copyJob
    Worker->>rclone: operations/copyfile

    loop Progress Updates
        rclone-->>Worker: progress
        Worker->>JobQueue: updateProgress()
        Client->>rproxy: GET /api/jobs/{jobId}
        rproxy->>JobQueue: getStatus()
        JobQueue-->>rproxy: JobStatus
        rproxy-->>Client: 200 OK (status)
    end

    rclone-->>Worker: complete
    Worker->>JobQueue: complete()
```

### 3.3 실시간 업데이트 플로우

```mermaid
sequenceDiagram
    participant Client
    participant rproxy
    participant SSE
    participant CacheService
    participant rclone

    Client->>rproxy: GET /api/sse/connect
    rproxy->>SSE: createConnection()
    SSE-->>Client: EventStream

    loop Background Updates
        rclone->>rproxy: status change
        rproxy->>CacheService: update()
        CacheService->>SSE: broadcast()
        SSE-->>Client: data: {event}
    end

    Client->>rproxy: GET /api/sse/disconnect
    rproxy->>SSE: closeConnection()
```

---

## 기술 스택 상세

### 4.1 Frontend Stack

| 기술 | 버전 | 용도 | 선정 이유 |
|-----|------|-----|----------|
| Svelte | 5.x | UI Framework | 컴파일 타임 최적화, 작은 번들 |
| SvelteKit | 2.x | Full-stack Framework | SSR, API Routes, 통합 개발 |
| Mantine UI | 7.x | Component Library | 완성도 높은 컴포넌트 |
| TypeScript | 5.x | Type Safety | 대규모 프로젝트 안정성 |
| Vite | 5.x | Build Tool | 빠른 HMR, 최적화된 빌드 |
| TanStack Query | 5.x | Data Fetching | 캐싱, 동기화, 백그라운드 업데이트 |

### 4.2 Backend Stack

| 기술 | 버전 | 용도 | 선정 이유 |
|-----|------|-----|----------|
| Node.js | 20.x | Runtime | LTS, 성능 개선 |
| SvelteKit | 2.x | API Server | 통합 개발 환경 |
| Drizzle ORM | 0.35.x | Database ORM | TypeScript 우선, 가벼움 |
| PostgreSQL | 16.x | Primary Database | JSONB, 확장성 |
| Redis | 7.x | Cache/Queue | 고성능 캐싱 |
| BullMQ | 5.x | Job Queue | 신뢰성, 모니터링 |

### 4.3 DevOps Stack

| 기술 | 용도 | 설정 |
|-----|-----|------|
| Docker | Containerization | Multi-stage builds |
| Docker Compose | Local Development | 전체 스택 오케스트레이션 |
| GitHub Actions | CI/CD | 자동 테스트, 배포 |
| Nginx | Reverse Proxy | SSL, Load Balancing |
| Prometheus | Monitoring | 메트릭 수집 |
| Grafana | Visualization | 대시보드 |

---

## 배포 아키텍처

### 5.1 Electron 배포와 rproxy 역할

#### 5.1.1 Electron 배포 요구사항

Electron으로 데스크톱 애플리케이션을 배포할 때, rproxy가 rclone rc API와 동일하게 작동해야 하는 핵심 이유:

1. **API 호환성**:
   - Electron 앱은 rclone binary와 함께 패키징됨
   - 프론트엔드는 로컬 rclone daemon과 통신해야 함
   - rproxy는 rclone rc API의 완전한 프록시 역할을 수행

2. **로컬 실행 환경**:
   ```typescript
   // Electron 환경에서의 rproxy 설정
   const RCLONE_CONFIG = {
     url: 'http://127.0.0.1:5572',  // 로컬 rclone daemon
     auth: {
       user: 'local_user',
       pass: 'generated_password'
     }
   };

   // rproxy는 모든 API 요청을 투명하게 전달
   app.use('/api/rc', createRcloneProxy(RCLONE_CONFIG));
   ```

3. **통합 배포 패키지**:
   ```
   RCMD-Desktop/
   ├── resources/
   │   ├── rclone.exe (Windows)
   │   ├── rclone (macOS/Linux)
   │   └── rclone.conf
   ├── app/
   │   ├── build/ (SvelteKit 빌드)
   │   └── node_modules/
   └── package.json
   ```

#### 5.1.2 rproxy의 API 투명성

```typescript
// lib/server/proxy/electron.proxy.ts
export class ElectronProxy {
  async forwardToRclone(request: Request): Promise<Response> {
    const rcloneUrl = `${RCLONE_BASE_URL}${request.url.pathname}`;

    // 요청 헤더와 바디를 그대로 전달
    const response = await fetch(rcloneUrl, {
      method: request.method,
      headers: this.buildHeaders(request.headers),
      body: request.body
    });

    // 응답을 그대로 전달 (변조 없음)
    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers: response.headers
    });
  }

  // 인증만 추가, API 구조는 변경하지 않음
  private buildHeaders(originalHeaders: Headers): HeadersInit {
    return {
      ...Object.fromEntries(originalHeaders.entries()),
      'Authorization': this.generateRcloneAuth()
    };
  }
}
```

### 5.2 개발 환경

```yaml
# docker-compose.dev.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "5173:5173"  # Vite dev server
      - "5174:5174"  # SvelteKit preview
    volumes:
      - .:/app
      - /app/node_modules
    environment:
      - NODE_ENV=development
      - DATABASE_URL=postgresql://user:pass@db:5432/rcmd
      - REDIS_URL=redis://redis:6379

  db:
    image: postgres:16-alpine
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_DB=rcmd
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - pgdata:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  rclone:
    image: rclone/rclone:latest
    command: rcd --rc-addr=:5572 --rc-user=admin --rc-pass=admin
    ports:
      - "5572:5572"

volumes:
  pgdata:
```

### 5.3 웹/서버 배포 환경

#### 5.3.1 프로덕션 환경

```yaml
# kubernetes/deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rcmd-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rcmd
  template:
    metadata:
      labels:
        app: rcmd
    spec:
      containers:
      - name: app
        image: rcmd:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: rcmd-secrets
              key: database-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 5.3.2 네트워크 아키텍처 (웹/서버 배포)

```
Internet
    │
    ▼
[Cloudflare/CDN]
    │
    ▼
[Load Balancer]
    │
    ├──► [rproxy Instance 1] ──┐
    ├──► [rproxy Instance 2] ──├──► [Redis Cluster]
    └──► [rproxy Instance 3] ──┘         │
                │                        │
                ├──► [PostgreSQL Primary]│
                │           │            │
                │    [PostgreSQL Replica]│
                │                        │
                └──► [rclone rcd Pool] ◄─┘
                          │
                          ▼
                    [Cloud Storage APIs]
```

### 5.4 배포 모드별 비교

| 특성 | Electron 배포 | 웹/서버 배포 |
|-----|-------------|------------|
| **rclone 위치** | 로컬 번들 (127.0.0.1:5572) | 원격 서버/컨테이너 |
| **rproxy 역할** | API 투명 프록시 | 인증+권한+프록시 |
| **사용자 관리** | 단일 사용자 (로컬) | 다중 사용자 (중앙) |
| **데이터베이스** | ❌ 의존성 없음 | PostgreSQL (서버) |
| **캐싱** | ❌ Redis 미사용 | Redis 클러스터 |
| **인증 방식** | 단순화된 로컬 인증 | JWT + 세션 관리 |
| **외부 API** | ✅ rproxy와 동일 | ✅ rproxy와 동일 |
| **업데이트** | 앱 업데이트 | 롤링 배포 |

### 5.5 Redis/DB 사용 구분 기준

#### 5.5.1 🔴 Redis/DB 필요한 경우 (웹서비스 전용)

**멀티유저 시나리오**:
- 여러 사용자간 데이터 공유/협업
- 사용자별 권한 및 세션 관리
- 중앙집중식 설정 및 정책 관리

**대용량/복잡성 시나리오**:
- 메모리 한계를 넘는 대용량 데이터셋
- 복잡한 쿼리 및 집계 분석 필요
- 트랜잭션 및 동시성 제어 요구사항

**지속성/확장성 시나리오**:
- 시스템 재시작 후에도 데이터 보존 필요
- 수평 확장이 필요한 워크로드
- 고성능 캐싱 및 세션 클러스터링

#### 5.5.2 🟢 Redis/DB 불필요한 경우 (Electron)

**단일 사용자 시나리오**:
- 개인용 로컬 작업 환경
- 단일 세션 기반 데이터 처리
- 로컬 설정 및 캐시 관리

**임시/실시간 시나리오**:
- 세션 단위 임시 데이터
- 실시간 UI 반응성 우선
- 간단한 필터링/정렬 수준 연산

**오프라인/독립성 시나리오**:
- 네트워크 연결 없이 동작
- 외부 의존성 최소화
- 단순하고 빠른 로컬 처리

### 5.6 통합 API 라우팅 설계

#### 5.6.1 빌드 타임 환경 결정

```typescript
// 빌드 시점에 결정되는 전역 상수
declare const __BUILD_TARGET__: 'electron' | 'web';
declare const __ENABLE_REDIS__: boolean;
declare const __ENABLE_POSTGRES__: boolean;

// lib/server/services/storage.factory.ts
export const createStorageService = () => {
  if (__BUILD_TARGET__ === 'electron') {
    // Electron 빌드: 인메모리 구현만 번들에 포함
    return new ElectronStorageService({
      cache: new Map(),
      persistence: 'session'
    });
  } else {
    // Web 빌드: Redis/DB 구현만 번들에 포함
    return new WebStorageService({
      redis: redisClient,
      database: postgresClient,
      persistence: 'permanent'
    });
  }
};

// lib/server/config/build.config.ts
export const BUILD_CONFIG = {
  target: __BUILD_TARGET__,
  features: {
    redis: __ENABLE_REDIS__,
    postgres: __ENABLE_POSTGRES__,
    multiUser: __BUILD_TARGET__ === 'web',
    offlineMode: __BUILD_TARGET__ === 'electron'
  }
} as const;

// Tree-shaking으로 불필요한 코드 제거됨
export const storageService = createStorageService();
export const cacheService = __ENABLE_REDIS__ ? new RedisCache() : new MemoryCache();
```

#### 5.6.2 빌드 구성

```json
// package.json
{
  "scripts": {
    "build:electron": "vite build --config vite.config.electron.ts",
    "build:web": "vite build --config vite.config.web.ts",
    "dev:electron": "vite dev --config vite.config.electron.ts",
    "dev:web": "vite dev --config vite.config.web.ts"
  }
}
```

```typescript
// vite.config.electron.ts
export default defineConfig({
  define: {
    __BUILD_TARGET__: '"electron"',
    __ENABLE_REDIS__: false,
    __ENABLE_POSTGRES__: false
  },
  build: {
    rollupOptions: {
      external: ['redis', 'pg'], // 불필요한 의존성 제외
    }
  }
});

// vite.config.web.ts
export default defineConfig({
  define: {
    __BUILD_TARGET__: '"web"',
    __ENABLE_REDIS__: true,
    __ENABLE_POSTGRES__: true
  }
});
```

#### 5.6.2 단일 API 환경별 처리

```
외부 클라이언트
    │
    ▼
[Unified API Endpoints]
    │ /api/remotes
    │ /api/operations/*
    │ /api/jobs
    ▼
[rproxy Environment Detection]
    │
    ├─ Electron Environment  → 인메모리 처리 (Redis/DB 없음)
    │                           ├─ 단일 사용자
    │                           ├─ 임시 데이터
    │                           └─ 로컬 캐시
    │
    └─ Web Service Environment → Redis/DB 처리
                                 ├─ 멀티 사용자
                                 ├─ 영구 데이터
                                 └─ 분산 캐시
```

#### 5.6.3 의존성 주입 패턴

```typescript
// lib/server/container/di.container.ts
export class DIContainer {
  private static instance: DIContainer;
  private services: Map<string, any> = new Map();

  static getInstance(): DIContainer {
    if (!DIContainer.instance) {
      DIContainer.instance = new DIContainer();
      DIContainer.instance.registerServices();
    }
    return DIContainer.instance;
  }

  private registerServices() {
    // 빌드 타임에 결정된 구현체 등록
    if (__BUILD_TARGET__ === 'electron') {
      this.services.set('storage', new ElectronStorageService());
      this.services.set('cache', new MemoryCacheService());
      this.services.set('auth', new LocalAuthService());
      this.services.set('session', new SingleSessionService());
    } else {
      this.services.set('storage', new WebStorageService());
      this.services.set('cache', new RedisCacheService());
      this.services.set('auth', new JWTAuthService());
      this.services.set('session', new DistributedSessionService());
    }
  }

  get<T>(serviceName: string): T {
    return this.services.get(serviceName);
  }
}

// lib/server/services/base.service.ts
export abstract class BaseService {
  protected storage = DIContainer.getInstance().get<StorageService>('storage');
  protected cache = DIContainer.getInstance().get<CacheService>('cache');
  protected auth = DIContainer.getInstance().get<AuthService>('auth');
}
```

#### 5.6.4 빌드별 특성 비교

| 특성 | Electron 빌드 | Web 빌드 | 빌드 결정 |
|------|---------------|----------|-----------|
| **저장소** | MemoryStorageService | WebStorageService | Tree-shaking |
| **캐싱** | Map 기반 캐시 | Redis 클러스터 | 조건부 컴파일 |
| **인증** | LocalAuthService | JWTAuthService | 팩토리 패턴 |
| **세션** | SingleSessionService | DistributedSessionService | DI 컨테이너 |
| **번들 크기** | ~2MB (DB 라이브러리 제외) | ~5MB (전체 기능) | Rollup externals |
| **시작 속도** | ~100ms | ~500ms | 의존성 최소화 |

#### 5.6.5 단일 API 인터페이스

```typescript
// 클라이언트는 환경에 관계없이 동일한 API 사용
const client = new RCMDClient({
  baseUrl: 'http://localhost:3000/api', // Electron
  // 또는
  // baseUrl: 'https://api.rcmd.io/api', // Web Service
});

// 모든 환경에서 동일한 인터페이스
await client.remotes.list();             // Electron: Map, Web: PostgreSQL
await client.operations.copy(src, dst);  // Electron: Memory, Web: Redis Queue
await client.jobs.status(jobId);         // Electron: Memory, Web: Redis Cache
```

### 5.7 빌드 타임 최적화 이점

#### 5.7.1 성능 향상
- **번들 크기**: Electron 60% 축소 (불필요한 DB 라이브러리 제외)
- **시작 시간**: 런타임 분기 제거로 80% 빠른 초기화
- **메모리 사용**: Tree-shaking으로 미사용 코드 완전 제거
- **실행 속도**: 조건문 제거로 hot path 최적화

#### 5.7.2 개발 경험 개선
- **타입 안전성**: 빌드 타임 상수로 정적 타입 체크
- **IDE 지원**: 조건부 컴파일로 정확한 자동완성
- **디버깅**: 환경별 전용 코드로 명확한 디버깅
- **테스트**: 각 빌드별 독립적 테스트 환경

#### 5.7.3 배포 단순화
- **의존성 관리**: 각 환경별 최소 의존성만 포함
- **보안**: 불필요한 코드 완전 제거로 공격 표면 축소
- **유지보수**: 환경별 코드 분리로 명확한 책임 구분

#### 5.4.1 Electron 환경에서의 아키텍처 단순화

```typescript
// Electron에서 단순화된 rproxy
export class ElectronRproxy {
  private rcloneProcess: ChildProcess;

  async start() {
    // 1. 로컬 rclone daemon 시작
    this.rcloneProcess = spawn('rclone', [
      'rcd',
      '--rc-addr=127.0.0.1:5572',
      '--rc-user=local',
      '--rc-pass=generated_password'
    ]);

    // 2. 단순한 프록시 서버 시작
    const app = express();
    app.use('/api/rc/*', this.proxyToRclone);
    app.listen(3000);
  }

  // API 투명성 - rclone과 100% 호환
  private proxyToRclone = async (req: Request, res: Response) => {
    const rcloneResponse = await fetch(`http://127.0.0.1:5572${req.path}`, {
      method: req.method,
      headers: req.headers,
      body: req.body
    });

    res.status(rcloneResponse.status);
    res.set(rcloneResponse.headers);
    rcloneResponse.body.pipe(res);
  };
}
```

---

## 보안 아키텍처

### 6.1 보안 계층

```
┌─────────────────────────────────────┐
│         네트워크 보안 계층           │
│   (Firewall, DDoS Protection)       │
├─────────────────────────────────────┤
│         전송 보안 계층               │
│      (TLS 1.3, HSTS, CSP)          │
├─────────────────────────────────────┤
│        애플리케이션 보안 계층         │
│    (Authentication, Authorization)   │
├─────────────────────────────────────┤
│         데이터 보안 계층             │
│    (Encryption, Data Masking)       │
└─────────────────────────────────────┘
```

### 6.2 보안 구현

#### 6.2.1 인증 토큰 관리
```typescript
// lib/server/security/token.ts
export class TokenManager {
  private readonly ACCESS_TOKEN_TTL = 15 * 60; // 15분
  private readonly REFRESH_TOKEN_TTL = 7 * 24 * 60 * 60; // 7일

  async generateAccessToken(user: User): Promise<string> {
    return jwt.sign(
      {
        sub: user.id,
        role: user.role,
        type: 'access'
      },
      privateKey,
      {
        algorithm: 'RS256',
        expiresIn: this.ACCESS_TOKEN_TTL
      }
    );
  }

  async verifyToken(token: string): Promise<TokenPayload> {
    try {
      return jwt.verify(token, publicKey, {
        algorithms: ['RS256']
      });
    } catch (error) {
      throw new UnauthorizedError('Invalid token');
    }
  }
}
```

#### 6.2.2 요청 검증 미들웨어
```typescript
// lib/server/middleware/security.ts
export async function securityMiddleware(
  event: RequestEvent
): Promise<void> {
  // CSRF 보호
  const csrfToken = event.request.headers.get('X-CSRF-Token');
  if (!csrfToken || !validateCsrfToken(csrfToken)) {
    throw error(403, 'Invalid CSRF token');
  }

  // Rate Limiting
  const clientId = getClientId(event);
  if (await isRateLimited(clientId)) {
    throw error(429, 'Too many requests');
  }

  // 인증 검증
  const token = extractToken(event.request);
  if (token) {
    event.locals.user = await verifyToken(token);
  }

  // 권한 검증
  if (requiresAuth(event.url.pathname)) {
    if (!event.locals.user) {
      throw error(401, 'Authentication required');
    }

    if (!hasPermission(event.locals.user, event.url.pathname)) {
      throw error(403, 'Insufficient permissions');
    }
  }
}
```

### 6.3 보안 모니터링

```typescript
// lib/server/security/audit.ts
export class AuditLogger {
  async logAuthAttempt(
    username: string,
    success: boolean,
    ip: string
  ): Promise<void> {
    await this.log({
      type: 'AUTH_ATTEMPT',
      username,
      success,
      ip,
      timestamp: new Date(),
      userAgent: request.headers.get('user-agent')
    });
  }

  async logFileOperation(
    userId: string,
    operation: string,
    path: string,
    result: 'success' | 'failure'
  ): Promise<void> {
    await this.log({
      type: 'FILE_OPERATION',
      userId,
      operation,
      path,
      result,
      timestamp: new Date()
    });
  }

  async detectAnomalies(): Promise<Anomaly[]> {
    // 비정상 패턴 감지
    const recentLogs = await this.getRecentLogs(60); // 최근 60분
    return this.analyzePatterns(recentLogs);
  }
}
```

---

## 성능 최적화 전략

### 7.1 프론트엔드 최적화

#### 7.1.1 번들 최적화
```javascript
// vite.config.js
export default {
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor': ['svelte', 'mantine'],
          'utils': ['lodash', 'date-fns'],
          'charts': ['d3', 'recharts']
        }
      }
    },
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: true,
        drop_debugger: true
      }
    }
  }
};
```

#### 7.1.2 가상 스크롤링
```svelte
<!-- lib/components/features/remotes/VirtualRemoteList.svelte -->
<script>
  import { VirtualList } from '@tanstack/svelte-virtual';

  export let remotes;

  const rowVirtualizer = new VirtualList({
    count: remotes.length,
    getScrollElement: () => parentRef,
    estimateSize: () => 100,
    overscan: 5
  });
</script>

<div bind:this={parentRef} class="remote-list">
  {#each $rowVirtualizer.virtualItems as virtualRow}
    <div
      style="height: {virtualRow.size}px; transform: translateY({virtualRow.start}px)"
    >
      <RemoteCard remote={remotes[virtualRow.index]} />
    </div>
  {/each}
</div>
```

### 7.2 백엔드 최적화

#### 7.2.1 캐싱 전략
```typescript
// lib/server/cache/strategy.ts
export class CacheStrategy {
  private readonly TTL = {
    remotes: 300,      // 5분
    fileList: 60,      // 1분
    userPermissions: 600, // 10분
    staticAssets: 86400  // 24시간
  };

  async getCached<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl?: number
  ): Promise<T> {
    // 캐시 확인
    const cached = await cache.get<T>(key);
    if (cached) return cached;

    // 캐시 미스 - 데이터 페칭
    const data = await fetcher();

    // 캐시 저장
    await cache.set(key, data, ttl || this.getTTL(key));

    return data;
  }

  async invalidatePattern(pattern: string): Promise<void> {
    const keys = await cache.keys(pattern);
    await Promise.all(keys.map(key => cache.del(key)));
  }
}
```

#### 7.2.2 데이터베이스 최적화
```sql
-- 인덱스 최적화
CREATE INDEX idx_permissions_user_remote
  ON permissions(user_id, remote_id);

CREATE INDEX idx_jobs_status_created
  ON jobs(status, created_at DESC);

CREATE INDEX idx_sessions_token
  ON sessions(token)
  WHERE expires_at > NOW();

-- 파티셔닝 (대용량 로그)
CREATE TABLE audit_logs_2025_01 PARTITION OF audit_logs
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
```

### 7.3 네트워크 최적화

#### 7.3.1 HTTP/2 Push
```typescript
// lib/server/optimization/http2.ts
export function pushAssets(event: RequestEvent) {
  const pushHeaders = [
    '</css/app.css>; rel=preload; as=style',
    '</js/app.js>; rel=preload; as=script',
    '</fonts/inter.woff2>; rel=preload; as=font; crossorigin'
  ];

  event.setHeaders({
    'Link': pushHeaders.join(', ')
  });
}
```

#### 7.3.2 압축 설정
```typescript
// lib/server/middleware/compression.ts
export async function compressionMiddleware(
  event: RequestEvent
): Promise<Response> {
  const response = await event.next();

  if (shouldCompress(response)) {
    const acceptEncoding = event.request.headers.get('accept-encoding');

    if (acceptEncoding?.includes('br')) {
      return compressBrotli(response);
    } else if (acceptEncoding?.includes('gzip')) {
      return compressGzip(response);
    }
  }

  return response;
}
```

---

## 확장성 설계

### 8.1 수평 확장 전략

#### 8.1.1 무상태 설계
```typescript
// 세션 데이터는 Redis에 저장
export class SessionManager {
  async createSession(userId: string): Promise<string> {
    const sessionId = generateId();
    const sessionData = {
      userId,
      createdAt: Date.now(),
      expiresAt: Date.now() + SESSION_TTL
    };

    await redis.setex(
      `session:${sessionId}`,
      SESSION_TTL,
      JSON.stringify(sessionData)
    );

    return sessionId;
  }

  async getSession(sessionId: string): Promise<Session | null> {
    const data = await redis.get(`session:${sessionId}`);
    return data ? JSON.parse(data) : null;
  }
}
```

#### 8.1.2 로드 밸런싱
```nginx
# nginx.conf
upstream rcmd_backend {
    least_conn;
    server app1:3000 weight=1 max_fails=3 fail_timeout=30s;
    server app2:3000 weight=1 max_fails=3 fail_timeout=30s;
    server app3:3000 weight=1 max_fails=3 fail_timeout=30s;

    keepalive 32;
}

server {
    listen 443 ssl http2;

    location / {
        proxy_pass http://rcmd_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # 스티키 세션 (SSE 연결용)
        ip_hash;
    }
}
```

### 8.2 수직 확장 고려사항

#### 8.2.1 리소스 모니터링
```typescript
// lib/server/monitoring/resources.ts
export class ResourceMonitor {
  async checkHealth(): Promise<HealthStatus> {
    const metrics = {
      memory: process.memoryUsage(),
      cpu: await getCpuUsage(),
      connections: {
        database: await checkDatabaseConnection(),
        redis: await checkRedisConnection(),
        rclone: await checkRcloneConnection()
      },
      responseTime: await measureResponseTime()
    };

    return {
      status: evaluateHealth(metrics),
      metrics,
      timestamp: Date.now()
    };
  }

  async autoScale(): Promise<void> {
    const health = await this.checkHealth();

    if (health.metrics.cpu > 80) {
      await this.scaleUp();
    } else if (health.metrics.cpu < 20) {
      await this.scaleDown();
    }
  }
}
```

### 8.3 마이크로서비스 준비

#### 8.3.1 서비스 분리 계획
```yaml
# 향후 마이크로서비스 분리 계획
services:
  auth-service:
    responsibilities:
      - 사용자 인증
      - 토큰 관리
      - 세션 관리

  permission-service:
    responsibilities:
      - 권한 관리
      - ACL 처리
      - 감사 로깅

  file-service:
    responsibilities:
      - 파일 작업
      - rclone 프록시
      - 캐시 관리

  job-service:
    responsibilities:
      - 작업 큐
      - 스케줄링
      - 백그라운드 작업

  notification-service:
    responsibilities:
      - 실시간 업데이트
      - 이메일 알림
      - 웹훅
```

#### 8.3.2 이벤트 기반 통신
```typescript
// lib/server/events/eventbus.ts
export class EventBus {
  private readonly emitter = new EventEmitter();

  async publish(event: string, data: any): Promise<void> {
    // 로컬 이벤트
    this.emitter.emit(event, data);

    // Redis Pub/Sub (분산 환경)
    await redis.publish(event, JSON.stringify(data));

    // 영구 저장 (중요 이벤트)
    if (isPersistentEvent(event)) {
      await this.saveToDatabase(event, data);
    }
  }

  async subscribe(
    event: string,
    handler: (data: any) => Promise<void>
  ): Promise<void> {
    // 로컬 구독
    this.emitter.on(event, handler);

    // Redis 구독
    const subscriber = redis.duplicate();
    await subscriber.subscribe(event);
    subscriber.on('message', async (channel, message) => {
      if (channel === event) {
        await handler(JSON.parse(message));
      }
    });
  }
}
```

---

## 모니터링 및 관찰성

### 9.1 메트릭 수집

```typescript
// lib/server/monitoring/metrics.ts
import { register, Counter, Histogram, Gauge } from 'prom-client';

export const metrics = {
  httpRequestDuration: new Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status']
  }),

  activeConnections: new Gauge({
    name: 'active_connections',
    help: 'Number of active connections'
  }),

  jobQueueSize: new Gauge({
    name: 'job_queue_size',
    help: 'Number of jobs in queue',
    labelNames: ['status']
  }),

  apiCalls: new Counter({
    name: 'api_calls_total',
    help: 'Total number of API calls',
    labelNames: ['service', 'method']
  })
};

export async function collectMetrics(): Promise<string> {
  return register.metrics();
}
```

### 9.2 로깅 전략

```typescript
// lib/server/logging/logger.ts
import winston from 'winston';

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: 'rcmd',
    environment: process.env.NODE_ENV
  },
  transports: [
    // 파일 로그
    new winston.transports.File({
      filename: 'logs/error.log',
      level: 'error',
      maxsize: 10485760, // 10MB
      maxFiles: 5
    }),

    // 콘솔 출력 (개발 환경)
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
  ]
});
```

---

## 재해 복구 계획

### 10.1 백업 전략

```yaml
# backup-strategy.yml
backup:
  database:
    frequency: daily
    retention: 30 days
    method: pg_dump
    storage: s3://backups/postgres/

  redis:
    frequency: hourly
    retention: 7 days
    method: RDB snapshots
    storage: s3://backups/redis/

  files:
    frequency: weekly
    retention: 90 days
    method: restic
    storage: s3://backups/files/
```

### 10.2 복구 절차

```bash
#!/bin/bash
# disaster-recovery.sh

# 1. 데이터베이스 복구
pg_restore -h localhost -U postgres -d rcmd latest_backup.dump

# 2. Redis 복구
redis-cli --rdb /backup/redis/dump.rdb

# 3. 애플리케이션 재배포
kubectl rollout restart deployment/rcmd-app

# 4. 상태 검증
./health-check.sh

# 5. 트래픽 복구
kubectl patch service rcmd-service -p '{"spec":{"selector":{"version":"new"}}}'
```

---

## 부록

### A. API 엔드포인트 목록
```
POST   /api/auth/login
POST   /api/auth/logout
POST   /api/auth/refresh
GET    /api/auth/verify

GET    /api/remotes
GET    /api/remotes/:id
GET    /api/remotes/:id/files
GET    /api/remotes/:id/status

POST   /api/operations/copy
POST   /api/operations/move
POST   /api/operations/delete
POST   /api/operations/sync

GET    /api/jobs
GET    /api/jobs/:id
POST   /api/jobs/:id/cancel
POST   /api/jobs/:id/retry

GET    /api/sse/connect
GET    /api/sse/disconnect

GET    /api/health
GET    /api/metrics
```

### B. 환경 변수
```env
# Application
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/rcmd
DATABASE_POOL_SIZE=20

# Redis
REDIS_URL=redis://localhost:6379
REDIS_MAX_RETRIES=3

# rclone
RCLONE_RC_URL=http://127.0.0.1:5572
RCLONE_RC_USER=admin
RCLONE_RC_PASS=secure_password

# Security
JWT_PRIVATE_KEY=path/to/private.key
JWT_PUBLIC_KEY=path/to/public.key
CSRF_SECRET=random_secret

# Monitoring
PROMETHEUS_PORT=9090
LOG_LEVEL=info
```

---

## 참조 구현

### 9.1 참조 레포지토리

프로젝트 구현 시 참조할 수 있는 오픈소스 프로젝트들이 `.ref/` 디렉토리에 있습니다:

#### rclone 관련
- **`.ref/rclone/`** - rclone 백엔드 구현 (Go)
  - RC API 서버 구현 패턴
  - 파일 작업 알고리즘
  - 클라우드 프로바이더 통합 방법

- **`.ref/rclone-webui-react/`** - rclone 웹 UI (React)
  - RC API 클라이언트 구현
  - 파일 브라우저 컴포넌트
  - 실시간 전송 모니터링 UI

#### AList 관련
- **`.ref/alist/`** - AList 백엔드 (Go)
  - 다중 스토리지 지원 패턴
  - WebDAV 서버 구현
  - 캐싱 전략

- **`.ref/alist-web/`** - AList 웹 UI (SolidJS)
  - 현대적 파일 매니저 UI
  - 가상 스크롤링 구현
  - 반응형 레이아웃

### 9.2 참조 활용 가이드

#### 기능 구현 시 참조 방법
```bash
# RC API 통합 참조
grep -r "rc/operations" .ref/rclone/
grep -r "useRclone" .ref/rclone-webui-react/src/

# 파일 브라우저 UI 참조
ls .ref/alist-web/src/components/FileList/
ls .ref/rclone-webui-react/src/views/Explorer/

# 듀얼 패널 구현 참조
grep -r "split.*panel\|dual.*pane" .ref/
```

#### 주요 참조 포인트

1. **API 설계**
   - rclone RC API 명세 및 구현
   - RESTful 엔드포인트 패턴
   - WebSocket/SSE 실시간 통신

2. **UI/UX 패턴**
   - Total Commander 스타일 듀얼 패널
   - 파일 작업 진행률 표시
   - 드래그 앤 드롭 구현

3. **성능 최적화**
   - 대용량 파일 목록 가상화
   - 청크 업로드/다운로드
   - 메모리 효율적 스트리밍

### 9.3 주의사항

- 코드를 직접 복사하지 말고 패턴과 아이디어를 참조
- SvelteKit 아키텍처에 맞게 조정하여 구현
- rclone RC API 호환성 유지 필수
- 참조 구현의 라이선스 확인 및 준수

자세한 참조 가이드는 [`.ref/REFERENCE-GUIDE.md`](../.ref/REFERENCE-GUIDE.md)를 참고하세요.

---

**문서 완료**: 2025-09-24
**최종 업데이트**: 2025-09-27 (참조 구현 섹션 추가)
**다음 단계**: API 명세 문서 작성