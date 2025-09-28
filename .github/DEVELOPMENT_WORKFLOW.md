# RCMD 개발 워크플로우 가이드

## 🏗️ 환경별 구분

### 1. Local Development (로컬 개발)
**목적**: 개발자가 코드를 작성하고 테스트하는 환경

**설정**:
```bash
# .env (로컬 파일)
NODE_ENV=development
POSTGRES_URL=  # 비어있으면 SQLite 자동 사용
VITE_ALLOWED_HOSTS=localhost,127.0.0.1,.local
LOG_LEVEL=debug
DEBUG_MODE=true
```

**실행 방법**:
```bash
# Docker 개발 환경
docker compose up

# 또는 로컬 Node.js
npm run dev
```

**특징**:
- ✅ 빠른 핫 리로드
- ✅ SQLite 사용 (설정 간편)
- ✅ 개발자별 독립 환경
- ✅ 디버깅 도구 활성화

### 2. Staging Environment (스테이징)
**목적**: 통합 테스트, QA, 클라이언트 데모

**자동 배포 조건**:
- `main` 브랜치에 push할 때 자동 배포
- GitHub Actions에서 자동 실행

**설정 (GitHub Environment)**:
```bash
# Environment Variables
NODE_ENV=staging
BASE_URL=https://rcmd-staging.example.com
VITE_ALLOWED_HOSTS=rcmd-staging.example.com,.staging.example.com
LOG_LEVEL=debug
DEBUG_MODE=true

# Environment Secrets
POSTGRES_URL=postgresql://user:pass@staging-db:5432/rcmd_staging
AWS_ACCESS_KEY_ID=AKIA...staging...
```

**특징**:
- ✅ 프로덕션과 유사한 환경
- ✅ 실제 도메인 사용
- ✅ PostgreSQL 데이터베이스
- ✅ 팀 전체가 접근 가능
- ✅ 자동 배포

### 3. Production Environment (프로덕션)
**목적**: 실제 사용자에게 서비스 제공

**배포 조건**:
- 버전 태그(`v1.0.0`) 생성 시
- 수동 승인 후 배포

**설정 (GitHub Environment)**:
```bash
# Environment Variables
NODE_ENV=production
BASE_URL=https://rcmd.example.com
VITE_ALLOWED_HOSTS=rcmd.example.com,.example.com
LOG_LEVEL=info
DEBUG_MODE=false

# Environment Secrets
POSTGRES_URL=postgresql://user:pass@prod-db:5432/rcmd_production
AWS_ACCESS_KEY_ID=AKIA...production...
```

**특징**:
- ✅ 최적화된 성능
- ✅ 실제 사용자 데이터
- ✅ 엄격한 보안
- ✅ 승인 후 배포
- ✅ 모니터링 활성화

## 🚀 개발 플로우

### 일반적인 개발 과정

```mermaid
graph LR
    A[로컬 개발] --> B[Git Push] --> C[Staging 자동배포] --> D[QA 테스트] --> E[Production 배포]

    A1[개발자 PC] --> B1[GitHub] --> C1[테스트 서버] --> D1[검증] --> E1[실제 서버]
```

### 1단계: 로컬 개발
```bash
# 개발 환경 시작
docker compose up

# 코드 수정 → 브라우저에서 자동 리로드 확인
# http://localhost:5173

# 기능 완성 후 커밋
git add .
git commit -m "feat: add new feature"
```

### 2단계: Staging 배포 (자동)
```bash
# main 브랜치에 push하면 자동으로 staging 배포
git push origin main

# GitHub Actions에서 자동 실행:
# 1. 빌드 테스트
# 2. Docker 이미지 생성
# 3. Staging 서버에 배포
# 4. https://rcmd-staging.example.com 접속 가능
```

### 3단계: QA 및 테스트
```bash
# Staging 환경에서 테스트
- 통합 테스트
- 성능 테스트
- 사용자 시나리오 테스트
- 클라이언트 데모
```

### 4단계: Production 배포 (수동)
```bash
# 릴리스 태그 생성
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions에서:
# 1. Production 환경 승인 대기
# 2. 승인 후 자동 배포
# 3. https://rcmd.example.com 서비스 시작
```

## 🔧 환경별 차이점

### 데이터베이스
| 환경 | DB 종류 | 목적 | 데이터 |
|------|---------|------|--------|
| Local | SQLite | 개발 편의성 | 가짜/테스트 데이터 |
| Staging | PostgreSQL | 실제 환경 시뮬레이션 | 테스트 데이터 |
| Production | PostgreSQL | 성능 및 확장성 | 실제 사용자 데이터 |

### 로깅 및 디버깅
| 환경 | 로그 레벨 | 디버그 모드 | 에러 표시 |
|------|-----------|-------------|-----------|
| Local | debug | ✅ 활성화 | 상세 에러 메시지 |
| Staging | debug | ✅ 활성화 | 상세 에러 메시지 |
| Production | info | ❌ 비활성화 | 간단한 에러 메시지 |

### 성능 설정
| 환경 | 캐시 | 압축 | 최적화 |
|------|------|------|---------|
| Local | ❌ 빠른 개발 | ❌ 원본 유지 | ❌ 개발 편의성 |
| Staging | ✅ 테스트용 | ✅ 실제 환경 | ✅ 프로덕션 시뮬레이션 |
| Production | ✅ 최적화 | ✅ 최대 압축 | ✅ 최고 성능 |

## 💡 왜 Staging이 필요한가?

### Local Development만으로는 부족한 이유:

1. **환경 차이**:
   - 로컬: SQLite, 단일 사용자
   - 실제: PostgreSQL, 다중 사용자

2. **통합 테스트**:
   - 로컬: 개별 기능 테스트
   - Staging: 전체 시스템 통합 테스트

3. **팀 협업**:
   - 로컬: 개발자 개인 환경
   - Staging: 팀 공유 환경

4. **클라이언트 데모**:
   - 로컬: 개발자 PC에서만 접근
   - Staging: 인터넷에서 접근 가능

## 🎯 실제 예시

### 로컬에서는 작동하지만 Staging에서 문제가 되는 경우:

1. **데이터베이스 차이**:
```sql
-- SQLite에서는 작동 (로컬)
SELECT * FROM users WHERE created_at > datetime('now', '-1 day');

-- PostgreSQL에서는 문법 오류 (Staging)
-- 올바른 PostgreSQL 문법:
SELECT * FROM users WHERE created_at > NOW() - INTERVAL '1 day';
```

2. **환경 변수 차이**:
```javascript
// 로컬에서는 .env 파일 사용
const allowedHosts = process.env.VITE_ALLOWED_HOSTS || 'localhost';

// Staging에서는 GitHub Environment Variables 사용
// VITE_ALLOWED_HOSTS=rcmd-staging.example.com
```

3. **외부 서비스 연동**:
```javascript
// 로컬: 개발용 API 키
const stripeKey = 'sk_test_...';

// Staging: 테스트용 API 키
const stripeKey = process.env.STRIPE_SECRET_KEY; // sk_test_staging_...

// Production: 실제 API 키
const stripeKey = process.env.STRIPE_SECRET_KEY; // sk_live_...
```

## 📋 체크리스트

### 로컬 개발 완료 시:
- [ ] 기능이 정상 작동하는가?
- [ ] TypeScript 에러가 없는가?
- [ ] 코드 리뷰가 완료되었는가?

### Staging 배포 후:
- [ ] 자동 배포가 성공했는가?
- [ ] 통합 테스트가 통과하는가?
- [ ] 성능에 문제가 없는가?
- [ ] 외부 서비스 연동이 작동하는가?

### Production 배포 전:
- [ ] Staging에서 모든 테스트가 통과했는가?
- [ ] 보안 검토가 완료되었는가?
- [ ] 백업 계획이 있는가?
- [ ] 롤백 계획이 있는가?

이렇게 3단계로 나누어 개발하면 안정적이고 체계적인 서비스 운영이 가능합니다! 🚀