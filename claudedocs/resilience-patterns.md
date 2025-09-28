# Resilience Patterns and Failure Handling
## RCMD (Rclone Commander)

**문서 버전**: 1.0
**작성일**: 2025-09-24
**문서 유형**: 기술 설계 보완

---

## 📋 목차
1. [Circuit Breaker 패턴](#circuit-breaker-패턴)
2. [부분 실패 처리 전략](#부분-실패-처리-전략)
3. [모니터링 및 알림](#모니터링-및-알림)
4. [Electron 배포 아키텍처](#electron-배포-아키텍처)

---

## Circuit Breaker 패턴

### 개념 설명
Circuit Breaker는 전기 회로의 차단기처럼 작동하여, 장애가 발생한 서비스로의 요청을 차단하고 시스템 전체의 cascading failure를 방지합니다.

### 상태 관리
```typescript
// lib/server/resilience/circuit-breaker.ts
export class CircuitBreaker {
  private state: 'CLOSED' | 'OPEN' | 'HALF_OPEN' = 'CLOSED';
  private failures = 0;
  private successCount = 0;
  private lastFailureTime?: Date;

  private readonly config = {
    failureThreshold: 5,      // 5번 실패 시 차단
    successThreshold: 3,      // 3번 성공 시 정상 복구
    timeout: 60000,           // 60초 후 재시도
    resetTimeout: 120000      // 2분 후 카운터 리셋
  };

  async execute<T>(
    remoteId: string,
    operation: () => Promise<T>
  ): Promise<T> {
    // OPEN 상태: 즉시 실패
    if (this.state === 'OPEN') {
      const now = Date.now();
      const timeSinceLastFailure = now - (this.lastFailureTime?.getTime() || 0);

      if (timeSinceLastFailure > this.config.timeout) {
        this.state = 'HALF_OPEN';
        this.successCount = 0;
      } else {
        throw new CircuitBreakerOpenError(
          `Circuit breaker is OPEN for ${remoteId}. Retry in ${
            Math.ceil((this.config.timeout - timeSinceLastFailure) / 1000)
          } seconds`
        );
      }
    }

    try {
      const result = await this.executeWithTimeout(operation);
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    this.failures = 0;

    if (this.state === 'HALF_OPEN') {
      this.successCount++;
      if (this.successCount >= this.config.successThreshold) {
        this.state = 'CLOSED';
        this.successCount = 0;
      }
    }
  }

  private onFailure() {
    this.lastFailureTime = new Date();
    this.failures++;

    if (this.failures >= this.config.failureThreshold) {
      this.state = 'OPEN';
      this.logStateChange('OPEN', this.failures);
    }
  }

  private async executeWithTimeout<T>(
    operation: () => Promise<T>
  ): Promise<T> {
    return Promise.race([
      operation(),
      new Promise<T>((_, reject) =>
        setTimeout(() => reject(new Error('Operation timeout')), 30000)
      )
    ]);
  }
}
```

### 리모트별 Circuit Breaker 관리
```typescript
// lib/server/resilience/remote-circuit-manager.ts
export class RemoteCircuitManager {
  private breakers = new Map<string, CircuitBreaker>();

  async executeRemoteOperation<T>(
    remoteId: string,
    operation: () => Promise<T>
  ): Promise<T> {
    if (!this.breakers.has(remoteId)) {
      this.breakers.set(remoteId, new CircuitBreaker());
    }

    const breaker = this.breakers.get(remoteId)!;

    try {
      return await breaker.execute(remoteId, operation);
    } catch (error) {
      if (error instanceof CircuitBreakerOpenError) {
        // Circuit breaker가 열려있음 - fallback 전략 실행
        return this.handleCircuitOpen(remoteId, error);
      }
      throw error;
    }
  }

  private async handleCircuitOpen<T>(
    remoteId: string,
    error: CircuitBreakerOpenError
  ): Promise<T> {
    // 1. 캐시된 데이터 반환
    const cached = await this.getCachedData(remoteId);
    if (cached) {
      return cached as T;
    }

    // 2. 대체 리모트 시도
    const fallbackRemote = this.getFallbackRemote(remoteId);
    if (fallbackRemote) {
      return this.executeRemoteOperation(fallbackRemote, operation);
    }

    // 3. 사용자에게 명확한 에러 메시지
    throw new Error(`Remote ${remoteId} is temporarily unavailable. ${error.message}`);
  }

  getStatus(): RemoteHealthStatus[] {
    return Array.from(this.breakers.entries()).map(([remoteId, breaker]) => ({
      remoteId,
      state: breaker.state,
      failures: breaker.failures,
      lastFailure: breaker.lastFailureTime
    }));
  }
}
```

---

## 부분 실패 처리 전략

### 실패 분류 및 처리
```typescript
// lib/server/resilience/failure-handler.ts
export enum FailureType {
  RETRYABLE = 'retryable',
  PERMANENT = 'permanent',
  PARTIAL = 'partial'
}

export class FailureHandler {
  private readonly retryableErrors = [
    'ECONNRESET',
    'ETIMEDOUT',
    'ENOTFOUND',
    'RATE_LIMIT_EXCEEDED',
    'SERVICE_UNAVAILABLE'
  ];

  private readonly permanentErrors = [
    'INVALID_CREDENTIALS',
    'PERMISSION_DENIED',
    'QUOTA_EXCEEDED',
    'FILE_NOT_FOUND',
    'INVALID_OPERATION'
  ];

  classifyError(error: any): FailureType {
    const errorCode = error.code || error.name;

    if (this.retryableErrors.includes(errorCode)) {
      return FailureType.RETRYABLE;
    }

    if (this.permanentErrors.includes(errorCode)) {
      return FailureType.PERMANENT;
    }

    // HTTP 상태 코드 기반 분류
    if (error.statusCode) {
      if (error.statusCode === 429 || error.statusCode >= 500) {
        return FailureType.RETRYABLE;
      }
      if (error.statusCode >= 400 && error.statusCode < 500) {
        return FailureType.PERMANENT;
      }
    }

    return FailureType.PARTIAL;
  }

  async handleFailure(error: any, context: OperationContext) {
    const type = this.classifyError(error);

    switch (type) {
      case FailureType.RETRYABLE:
        return this.handleRetryable(error, context);
      case FailureType.PERMANENT:
        return this.handlePermanent(error, context);
      case FailureType.PARTIAL:
        return this.handlePartial(error, context);
    }
  }

  private async handleRetryable(error: any, context: OperationContext) {
    const retryStrategy = this.getRetryStrategy(error);

    return {
      action: 'RETRY',
      delay: retryStrategy.getNextDelay(),
      maxAttempts: retryStrategy.maxAttempts,
      backoffType: retryStrategy.type // 'exponential' | 'linear' | 'fixed'
    };
  }

  private async handlePermanent(error: any, context: OperationContext) {
    // 영구 실패 - 사용자 개입 필요
    await this.notifyUser(context, error);

    return {
      action: 'FAIL',
      reason: error.message,
      suggestion: this.getSuggestion(error)
    };
  }

  private async handlePartial(error: any, context: OperationContext) {
    // 부분 성공 처리
    return {
      action: 'PARTIAL_SUCCESS',
      completed: context.completedItems,
      failed: context.failedItems,
      canResume: true
    };
  }
}
```

### 배치 작업 부분 실패 처리
```typescript
// lib/server/operations/batch-processor.ts
export class BatchProcessor {
  private failureHandler = new FailureHandler();

  async processBatch(items: FileOperation[]): Promise<BatchResult> {
    const result: BatchResult = {
      total: items.length,
      success: [],
      failed: [],
      skipped: [],
      canResume: false
    };

    // 체크포인트 지원
    const checkpoint = await this.loadCheckpoint();
    const startIndex = checkpoint?.lastProcessedIndex || 0;

    for (let i = startIndex; i < items.length; i++) {
      const item = items[i];

      try {
        const operationResult = await this.processItem(item);
        result.success.push({
          item,
          result: operationResult
        });

        // 주기적으로 체크포인트 저장
        if (i % 10 === 0) {
          await this.saveCheckpoint({
            batchId: this.batchId,
            lastProcessedIndex: i,
            timestamp: new Date()
          });
        }
      } catch (error) {
        const failureResponse = await this.failureHandler.handleFailure(
          error,
          { item, batchId: this.batchId }
        );

        if (failureResponse.action === 'RETRY') {
          // 재시도 큐에 추가
          await this.queueForRetry(item, failureResponse);
          result.skipped.push({ item, reason: 'queued_for_retry' });
        } else {
          result.failed.push({
            item,
            error: error.message,
            canRetry: failureResponse.action !== 'FAIL'
          });
        }

        // 실패율이 임계치를 초과하면 중단
        if (result.failed.length / items.length > 0.5) {
          result.canResume = true;
          break;
        }
      }
    }

    return result;
  }

  async resumeBatch(batchId: string): Promise<BatchResult> {
    const checkpoint = await this.loadCheckpoint(batchId);
    if (!checkpoint) {
      throw new Error('No checkpoint found for batch');
    }

    const items = await this.loadBatchItems(batchId);
    return this.processBatch(items.slice(checkpoint.lastProcessedIndex + 1));
  }
}
```

---

## 모니터링 및 알림

### Status 페이지 구현
```svelte
<!-- routes/status/+page.svelte -->
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import type { JobStatus, RemoteStatus } from '$lib/types';

  let jobs: JobStatus[] = [];
  let remotes: RemoteStatus[] = [];
  let eventSource: EventSource;

  onMount(() => {
    // SSE 연결
    eventSource = new EventSource('/api/sse/status');

    eventSource.addEventListener('job-update', (event) => {
      const data = JSON.parse(event.data);
      updateJob(data);
    });

    eventSource.addEventListener('remote-status', (event) => {
      const data = JSON.parse(event.data);
      updateRemoteStatus(data);
    });

    // 초기 데이터 로드
    loadInitialData();
  });

  onDestroy(() => {
    eventSource?.close();
  });

  function updateJob(jobData: JobStatus) {
    const index = jobs.findIndex(j => j.id === jobData.id);
    if (index >= 0) {
      jobs[index] = jobData;
    } else {
      jobs = [jobData, ...jobs].slice(0, 50); // 최근 50개만 유지
    }
  }
</script>

<div class="status-container">
  <h1>시스템 상태</h1>

  <!-- 리모트 상태 -->
  <section class="remotes-section">
    <h2>리모트 상태</h2>
    <div class="remote-grid">
      {#each remotes as remote}
        <div class="remote-card" class:offline={!remote.online}>
          <h3>{remote.name}</h3>
          <div class="status-indicator">
            {#if remote.circuitBreaker === 'OPEN'}
              <span class="circuit-open">⚠️ Circuit Open</span>
            {:else if !remote.online}
              <span class="offline">❌ Offline</span>
            {:else}
              <span class="online">✅ Online</span>
            {/if}
          </div>
          {#if remote.lastError}
            <div class="error-info">
              Last error: {remote.lastError}
            </div>
          {/if}
        </div>
      {/each}
    </div>
  </section>

  <!-- 작업 큐 -->
  <section class="jobs-section">
    <h2>작업 큐</h2>
    <div class="jobs-table">
      {#each jobs as job}
        <div class="job-row">
          <div class="job-info">
            <span class="job-type">{job.type}</span>
            <span class="job-path">{job.source} → {job.destination}</span>
          </div>
          <div class="job-progress">
            <progress value={job.progress} max="100"></progress>
            <span>{job.progress}%</span>
          </div>
          <div class="job-status" class:error={job.status === 'failed'}>
            {job.status}
          </div>
        </div>
      {/each}
    </div>
  </section>
</div>

<style>
  .remote-card.offline {
    opacity: 0.6;
    background: #fee;
  }

  .circuit-open {
    color: orange;
    font-weight: bold;
  }

  .job-row {
    display: grid;
    grid-template-columns: 2fr 1fr auto;
    gap: 1rem;
    padding: 0.5rem;
    border-bottom: 1px solid #eee;
  }
</style>
```

### 알림 서비스
```typescript
// lib/server/notifications/notification-service.ts
export class NotificationService {
  private channels: NotificationChannel[] = [];

  constructor(config: NotificationConfig) {
    if (config.webhook) {
      this.channels.push(new WebhookChannel(config.webhook));
    }
    if (config.telegram) {
      this.channels.push(new TelegramChannel(config.telegram));
    }
    if (config.email) {
      this.channels.push(new EmailChannel(config.email));
    }
  }

  async notify(event: NotificationEvent) {
    // 이벤트 타입별 필터링
    const relevantChannels = this.channels.filter(
      channel => channel.supportsEventType(event.type)
    );

    await Promise.allSettled(
      relevantChannels.map(channel => channel.send(event))
    );
  }
}

// Telegram 알림 채널
export class TelegramChannel implements NotificationChannel {
  constructor(private config: TelegramConfig) {}

  async send(event: NotificationEvent) {
    const message = this.formatMessage(event);

    await fetch(
      `https://api.telegram.org/bot${this.config.botToken}/sendMessage`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: this.config.chatId,
          text: message,
          parse_mode: 'HTML'
        })
      }
    );
  }

  private formatMessage(event: NotificationEvent): string {
    switch (event.type) {
      case 'JOB_COMPLETED':
        return `✅ <b>작업 완료</b>\n${event.data.source} → ${event.data.destination}\n처리 시간: ${event.data.duration}초`;

      case 'JOB_FAILED':
        return `❌ <b>작업 실패</b>\n${event.data.source} → ${event.data.destination}\n오류: ${event.data.error}`;

      case 'REMOTE_OFFLINE':
        return `⚠️ <b>리모트 오프라인</b>\n${event.data.remoteName}이(가) 응답하지 않습니다`;

      default:
        return `ℹ️ ${event.type}: ${JSON.stringify(event.data)}`;
    }
  }

  supportsEventType(type: string): boolean {
    return ['JOB_COMPLETED', 'JOB_FAILED', 'REMOTE_OFFLINE'].includes(type);
  }
}

// Webhook 알림 채널
export class WebhookChannel implements NotificationChannel {
  constructor(private config: WebhookConfig) {}

  async send(event: NotificationEvent) {
    await fetch(this.config.url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...this.config.headers
      },
      body: JSON.stringify({
        timestamp: new Date().toISOString(),
        event: event.type,
        data: event.data
      })
    });
  }

  supportsEventType(type: string): boolean {
    return true; // Webhook은 모든 이벤트 지원
  }
}
```

---

## Electron 배포 아키텍처

### rproxy의 이중 역할
rproxy는 rclone RC API와 **동일한 인터페이스**를 제공하여, Electron 앱이 웹서비스와 로컬 모두에서 같은 코드로 작동할 수 있도록 합니다.

```typescript
// lib/server/rproxy/compatibility-layer.ts
export class RcloneCompatibilityLayer {
  /**
   * rproxy가 rclone RC API와 100% 호환되는 인터페이스 제공
   * 이를 통해 Electron 앱은 로컬 rclone이나 원격 rproxy를
   * 구분하지 않고 동일하게 사용 가능
   */

  async handleRequest(path: string, body: any): Promise<any> {
    // rclone RC API 경로 패턴 매칭
    if (path.startsWith('/operations/')) {
      return this.handleOperation(path, body);
    }

    if (path.startsWith('/core/')) {
      return this.handleCore(path, body);
    }

    if (path.startsWith('/config/')) {
      return this.handleConfig(path, body);
    }

    // rproxy 전용 기능 (인증 있는 경우만)
    if (this.isAuthenticated && path.startsWith('/admin/')) {
      return this.handleAdmin(path, body);
    }

    // 나머지는 rclone으로 직접 프록시
    return this.proxyToRclone(path, body);
  }

  private async handleOperation(path: string, body: any) {
    const operation = path.split('/')[2];

    // rclone RC API 표준 응답 형식 유지
    switch (operation) {
      case 'copyfile':
        const jobId = await this.jobQueue.enqueue({
          type: 'copy',
          ...body
        });

        // rclone과 동일한 응답 형식
        return {
          jobid: jobId
        };

      case 'about':
        return this.getAbout(body.fs);

      default:
        return this.proxyToRclone(path, body);
    }
  }
}
```

### Electron 앱 구성
```typescript
// electron/main.ts
import { app, BrowserWindow } from 'electron';
import { spawn } from 'child_process';

class ElectronApp {
  private mainWindow: BrowserWindow;
  private rcloneProcess: any;
  private rproxyUrl: string;

  async initialize() {
    // 로컬 모드 vs 원격 모드 결정
    if (this.isLocalMode()) {
      // 로컬 rclone 실행
      this.startLocalRclone();
      this.rproxyUrl = 'http://127.0.0.1:5572';
    } else {
      // 원격 rproxy 사용
      this.rproxyUrl = this.getRemoteRproxyUrl();
    }

    // 동일한 API 클라이언트 사용
    this.initializeApiClient(this.rproxyUrl);
  }

  private startLocalRclone() {
    this.rcloneProcess = spawn('rclone', [
      'rcd',
      '--rc-addr=127.0.0.1:5572',
      '--rc-no-auth'  // 로컬이므로 인증 불필요
    ]);
  }

  private initializeApiClient(baseUrl: string) {
    // 웹버전과 동일한 API 클라이언트 코드 사용
    global.apiClient = new RcloneApiClient({
      baseUrl,
      // Electron에서는 인증 불필요 (로컬 실행)
      auth: null
    });
  }
}
```

### 공통 코어 라이브러리
```typescript
// lib/core/file-operations.ts
/**
 * 웹서비스와 Electron 앱에서 공유하는 핵심 로직
 */
export class FileOperationsCore {
  constructor(private apiClient: RcloneApiClient) {}

  async copyFile(source: string, dest: string): Promise<string> {
    // rclone RC API 호출 (rproxy든 직접 rclone이든 동일)
    const response = await this.apiClient.post('/operations/copyfile', {
      srcFs: source,
      dstFs: dest
    });

    return response.jobid;
  }

  async listFiles(remote: string, path: string = '/'): Promise<FileInfo[]> {
    const response = await this.apiClient.post('/operations/list', {
      fs: `${remote}:${path}`,
      recurse: false
    });

    return response.list;
  }

  async getAbout(remote: string): Promise<AboutInfo> {
    const response = await this.apiClient.post('/operations/about', {
      fs: `${remote}:`
    });

    return response;
  }
}
```

### 배포 설정
```json
// package.json
{
  "name": "rcmd",
  "version": "1.0.0",
  "scripts": {
    // 웹서비스
    "dev:web": "vite dev",
    "build:web": "vite build",

    // Electron 앱
    "dev:electron": "electron .",
    "build:electron": "electron-builder",

    // 공통
    "test": "vitest",
    "lint": "eslint ."
  },
  "build": {
    "appId": "com.rcmd.app",
    "productName": "RCMD",
    "directories": {
      "output": "dist-electron"
    },
    "files": [
      "electron/**/*",
      "build/**/*",
      "!**/*.map"
    ],
    "extraResources": [
      {
        "from": "bin/rclone",
        "to": "bin/rclone"
      }
    ],
    "mac": {
      "category": "public.app-category.utilities"
    },
    "win": {
      "target": "nsis"
    },
    "linux": {
      "target": "AppImage"
    }
  }
}
```

---

## 구현 우선순위

### Phase 1: 기본 복원력 (1주차)
1. **Circuit Breaker 구현**: 리모트별 독립적 차단기
2. **기본 재시도 로직**: 지수 백오프
3. **간단한 /status 페이지**: 작업 상태 표시

### Phase 2: 부분 실패 처리 (2주차)
1. **실패 분류 시스템**: retryable vs permanent
2. **배치 작업 체크포인트**: 중단 지점 저장
3. **부분 성공 보고**: 성공/실패 분리 보고

### Phase 3: 모니터링 강화 (3주차)
1. **SSE 실시간 업데이트**: 상태 변경 알림
2. **Telegram/Webhook 알림**: 중요 이벤트 알림
3. **Circuit breaker 대시보드**: 시각적 상태 표시

### Phase 4: Electron 통합 (4주차)
1. **rproxy 호환 레이어**: rclone RC API 100% 호환
2. **Electron 패키징**: 플랫폼별 빌드
3. **로컬/원격 모드 전환**: 유연한 배포

---

**문서 완료**: 2025-09-24
**다음 단계**: 구현 시작