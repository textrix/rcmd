# GitHub Secrets & Variables 완전 가이드

## 🏗️ 구조 이해

### Repository Level (전체 적용)
```
Repository Settings → Secrets and variables → Actions
├── Repository secrets    # 🔒 전체 리포지토리용 민감 정보
└── Repository variables  # 📋 전체 리포지토리용 공개 설정
```

### Environment Level (환경별 적용)
```
Repository Settings → Environments → [staging/production]
├── Environment secrets   # 🔒 환경별 민감 정보
└── Environment variables # 📋 환경별 공개 설정
```

## 🔐 Repository Secrets (전체 적용)

**위치**: Settings → Secrets and variables → Actions → Repository secrets

**용도**: 모든 환경에서 공통으로 사용하는 민감 정보

### 설정 예시
```bash
# GitHub Container Registry 인증
GITHUB_TOKEN                    # 자동 제공됨 (설정 불필요)

# 외부 서비스 인증
DOCKER_USERNAME=textrix         # Docker Hub 사용자명
DOCKER_PASSWORD=dckr_pat_...    # Docker Hub 토큰

# 공통 API 키
RCLONE_MASTER_KEY=abc123...     # 마스터 암호화 키
NOTIFICATION_WEBHOOK=https://hooks.slack.com/...

# 공통 인증서
SSL_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----...
SSL_CERTIFICATE=-----BEGIN CERTIFICATE-----...
```

**워크플로우에서 사용**:
```yaml
steps:
  - name: Login to Docker Hub
    env:
      DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
      DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
    run: echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
```

## 📋 Repository Variables (전체 적용)

**위치**: Settings → Secrets and variables → Actions → Repository variables

**용도**: 모든 환경에서 공통으로 사용하는 공개 설정

### 설정 예시
```bash
# 빌드 설정
NODE_VERSION=18
PNPM_VERSION=8
DOCKER_REGISTRY=ghcr.io

# 애플리케이션 공통 설정
DEFAULT_TIMEZONE=UTC
CACHE_VERSION=v2
BUILD_TIMEOUT=600

# Docker 설정
PUID=1000
PGID=1000
DOCKERFILE_PATH=./Dockerfile

# 브랜치 설정
MAIN_BRANCH=main
DEVELOP_BRANCH=develop
```

**워크플로우에서 사용**:
```yaml
steps:
  - name: Setup Node.js
    uses: actions/setup-node@v4
    with:
      node-version: ${{ vars.NODE_VERSION }}

  - name: Build Docker image
    env:
      REGISTRY: ${{ vars.DOCKER_REGISTRY }}
      BUILD_TIMEOUT: ${{ vars.BUILD_TIMEOUT }}
```

## 🌍 Environment Secrets (환경별)

**위치**: Settings → Environments → [환경명] → Environment secrets

**용도**: 환경별로 다른 민감 정보

### Staging 환경 설정
```bash
# 데이터베이스
POSTGRES_URL=postgresql://user:pass@staging-db.internal:5432/rcmd_staging
REDIS_URL=redis://staging-redis.internal:6379

# 외부 API
AWS_ACCESS_KEY_ID=AKIA...staging...
AWS_SECRET_ACCESS_KEY=wJa...staging...
STRIPE_SECRET_KEY=sk_test_...

# 서비스별 설정
SMTP_PASSWORD=staging_email_password
OAUTH_CLIENT_SECRET=staging_oauth_secret
```

### Production 환경 설정
```bash
# 데이터베이스
POSTGRES_URL=postgresql://user:pass@prod-db.internal:5432/rcmd_production
REDIS_URL=redis://prod-redis.internal:6379

# 외부 API
AWS_ACCESS_KEY_ID=AKIA...production...
AWS_SECRET_ACCESS_KEY=wJa...production...
STRIPE_SECRET_KEY=sk_live_...

# 서비스별 설정
SMTP_PASSWORD=production_email_password
OAUTH_CLIENT_SECRET=production_oauth_secret
```

**워크플로우에서 사용**:
```yaml
deploy-staging:
  environment: staging  # 환경 지정 필수!
  steps:
    - name: Deploy
      env:
        DATABASE_URL: ${{ secrets.POSTGRES_URL }}  # staging 환경의 값 자동 적용
        REDIS_URL: ${{ secrets.REDIS_URL }}
```

## 📊 Environment Variables (환경별)

**위치**: Settings → Environments → [환경명] → Environment variables

**용도**: 환경별로 다른 공개 설정

### Staging 환경 설정
```bash
# 환경 설정
NODE_ENV=staging
LOG_LEVEL=debug
DEBUG_MODE=true

# 도메인 설정
BASE_URL=https://rcmd-staging.example.com
API_BASE_URL=https://api-staging.example.com
VITE_ALLOWED_HOSTS=rcmd-staging.example.com,.staging.example.com

# 성능 설정
DATABASE_POOL_SIZE=5
CACHE_TTL=300
RATE_LIMIT=100

# 기능 플래그
FEATURE_NEW_UI=true
FEATURE_BETA_API=true
```

### Production 환경 설정
```bash
# 환경 설정
NODE_ENV=production
LOG_LEVEL=info
DEBUG_MODE=false

# 도메인 설정
BASE_URL=https://rcmd.example.com
API_BASE_URL=https://api.example.com
VITE_ALLOWED_HOSTS=rcmd.example.com,.example.com

# 성능 설정
DATABASE_POOL_SIZE=20
CACHE_TTL=3600
RATE_LIMIT=1000

# 기능 플래그
FEATURE_NEW_UI=false
FEATURE_BETA_API=false
```

**워크플로우에서 사용**:
```yaml
deploy-production:
  environment: production  # 환경 지정 필수!
  steps:
    - name: Deploy
      env:
        NODE_ENV: ${{ vars.NODE_ENV }}           # production 환경의 값
        BASE_URL: ${{ vars.BASE_URL }}
        ALLOWED_HOSTS: ${{ vars.VITE_ALLOWED_HOSTS }}
```

## 🎯 우선순위 및 덮어쓰기

### 우선순위 (높음 → 낮음)
1. **Environment secrets** (환경별 민감 정보)
2. **Environment variables** (환경별 공개 설정)
3. **Repository secrets** (전체 민감 정보)
4. **Repository variables** (전체 공개 설정)

### 실제 예시
```bash
# Repository variables에 설정
NODE_ENV=development

# Production environment variables에 설정
NODE_ENV=production

# production 환경에서 워크플로우 실행 시
# → NODE_ENV=production (Environment variables가 우선)
```

## 🚀 실전 워크플로우 설정

### 환경별 배포 예시
```yaml
name: Deploy

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [staging, production]

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment || 'staging' }}

    steps:
      - name: Deploy application
        env:
          # Repository secrets (공통)
          DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}

          # Environment secrets (환경별)
          DATABASE_URL: ${{ secrets.POSTGRES_URL }}

          # Repository variables (공통)
          REGISTRY: ${{ vars.DOCKER_REGISTRY }}

          # Environment variables (환경별)
          NODE_ENV: ${{ vars.NODE_ENV }}
          BASE_URL: ${{ vars.BASE_URL }}

        run: |
          echo "Deploying to ${{ vars.NODE_ENV }} environment"
          echo "Base URL: ${{ vars.BASE_URL }}"
          # 민감한 정보는 echo하지 말 것!
```

## 🔧 설정 권장사항

### Repository Level (공통)
```bash
# Repository secrets
DOCKER_USERNAME             # Docker 인증
DOCKER_PASSWORD
NOTIFICATION_WEBHOOK        # 공통 알림

# Repository variables
NODE_VERSION=18             # 빌드 설정
DOCKER_REGISTRY=ghcr.io
PUID=1000                   # Docker 권한
PGID=1000
```

### Environment Level (환경별)
```bash
# Environment secrets (staging)
POSTGRES_URL=postgresql://...staging...
AWS_ACCESS_KEY_ID=AKIA...staging...

# Environment secrets (production)
POSTGRES_URL=postgresql://...production...
AWS_ACCESS_KEY_ID=AKIA...production...

# Environment variables (staging)
NODE_ENV=staging
BASE_URL=https://staging.example.com
LOG_LEVEL=debug

# Environment variables (production)
NODE_ENV=production
BASE_URL=https://example.com
LOG_LEVEL=info
```

## 🛡️ 보안 모범 사례

### DO ✅
- 환경별로 다른 데이터베이스 URL 사용
- 프로덕션과 스테이징 API 키 분리
- 민감한 정보는 절대 Variables에 넣지 않기
- Environment protection rules 설정

### DON'T ❌
- 프로덕션 비밀번호를 Variables에 저장
- 모든 환경에서 같은 API 키 사용
- 워크플로우 로그에 Secrets 출력
- 테스트용 토큰을 프로덕션에서 사용

## 🔍 디버깅 팁

### 변수 확인 (안전한 방법)
```yaml
- name: Debug environment
  run: |
    echo "Environment: ${{ vars.NODE_ENV }}"
    echo "Registry: ${{ vars.DOCKER_REGISTRY }}"
    echo "Base URL: ${{ vars.BASE_URL }}"

    # Secrets 존재 여부만 확인 (값은 출력하지 않음)
    echo "Database configured: ${{ secrets.POSTGRES_URL != '' }}"
    echo "AWS configured: ${{ secrets.AWS_ACCESS_KEY_ID != '' }}"
```

### 환경 변수 매핑 확인
```yaml
- name: Check variable priority
  environment: production
  run: |
    echo "This should show production values:"
    echo "NODE_ENV: ${{ vars.NODE_ENV }}"
    echo "BASE_URL: ${{ vars.BASE_URL }}"
```