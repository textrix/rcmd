# RCMD 프로젝트 현황 종합

*최종 업데이트: 2025-09-28*

## 📋 목차
1. [프로젝트 개요](#프로젝트-개요)
2. [완료된 구현 사항](#완료된-구현-사항)
3. [기술 스택 및 아키텍처](#기술-스택-및-아키텍처)
4. [프로젝트 구조](#프로젝트-구조)
5. [개발 환경 설정](#개발-환경-설정)
6. [빌드 및 배포](#빌드-및-배포)
7. [다음 단계](#다음-단계)

---

## 프로젝트 개요

**RCMD (Rclone Commander)** - Rclone을 위한 웹 기반 및 데스크톱 GUI 애플리케이션

### 프로젝트 목표
- 101개 이상의 클라우드 스토리지 리모트 관리
- ~500TB 규모의 데이터 처리
- 웹 브라우저 및 데스크톱 앱 동시 지원
- 실시간 전송 모니터링 및 관리

### 현재 상태
- **Phase**: 인프라 구축 완료, 핵심 기능 구현 준비
- **진행률**: 기초 인프라 100% 완료
- **예상 MVP**: 2025-10-15 (3주)

---

## 완료된 구현 사항

### ✅ 1. 개발 환경 (100%)
- **Docker 환경** (`compose.yaml`, `compose.override.yaml`)
  - Node.js 18 Alpine 기반 경량 컨테이너
  - 개발/프로덕션 환경 분리
  - 핫 리로드 및 볼륨 마운팅
  - PUID/PGID 권한 자동 매핑

### ✅ 2. Docker 프로덕션 환경 (100%)
- **Multi-stage Build**
  - 개발/프로덕션 환경 분리
  - Alpine Linux 기반 경량 이미지
  - 최종 이미지 크기: ~200MB

- **권한 관리 시스템**
  - PUID/PGID 동적 사용자 생성 (LinuxServer.io 패턴)
  - Runtime 권한 설정 (`entrypoint.sh`)
  - 보안 강화 (non-root 실행)

### ✅ 3. 데이터베이스 시스템 (100%)
- **자동 감지 시스템** (`src/lib/config/database.ts`)
  ```typescript
  // 환경 변수 기반 자동 전환
  if (POSTGRES_URL || POSTGRES_HOST) → PostgreSQL
  else → SQLite (기본)
  ```
- **듀얼 데이터베이스 지원**
  - SQLite: 단일 사용자, 로컬, Electron 앱
  - PostgreSQL: 다중 사용자, 서버, 엔터프라이즈

### ✅ 4. Electron 데스크톱 앱 (100%)
- **최신 버전**: Electron 38.1.2
- **보안**: 모든 취약점 패치 (0 vulnerabilities)
- **빌드 시스템**:
  - Windows: NSIS installer, Portable
  - macOS: DMG (hardened runtime)
  - Linux: AppImage, DEB, Snap
- **CI/CD**: GitHub Actions 자동 빌드/릴리스

### ✅ 5. 빌드 시스템 (100%)
- **Dual Target 설정**
  - Web: `vite.config.web.ts`
  - Electron: `vite.config.electron.ts`
- **환경별 최적화**
  - 개발: 핫 리로드, DevTools
  - 프로덕션: Terser 압축, 최적화

---

## 기술 스택 및 아키텍처

### Frontend
- **Framework**: SvelteKit 2.22
- **Language**: TypeScript 5.0
- **Build Tool**: Vite 7.0
- **Styling**: CSS (향후 Tailwind CSS 예정)

### Backend
- **Runtime**: Node.js 18
- **Framework**: SvelteKit SSR
- **Process Management**: PM2 (예정)

### Desktop
- **Platform**: Electron 38.1.2
- **IPC**: Context Bridge (보안)
- **Build**: electron-builder 25.0

### Database
- **Primary**: SQLite 3
- **Alternative**: PostgreSQL 14+
- **Migration**: 자동 감지 시스템

### Container
- **Development**: Dev Containers
- **Production**: Docker multi-stage
- **Orchestration**: Docker Compose

---

## 프로젝트 구조

```
rcmd/
├── src/                 # SvelteKit 소스 코드
│   ├── app.html
│   ├── lib/
│   └── routes/
├── static/              # 정적 파일
├── claudedocs/          # 프로젝트 문서
│   ├── readme.md
│   ├── project-current-status.md  # 이 파일
│   └── *.md
├── compose.yaml         # Docker 프로덕션 설정
├── compose.override.yaml # Docker 개발 설정
├── Dockerfile           # 멀티스테이지 빌드
├── entrypoint.sh        # 컨테이너 진입점
├── claudedocs/development-setup.md # 개발 환경 가이드
├── package.json         # 메인 설정
├── svelte.config.js
├── vite.config.ts
└── tsconfig.json
```

---

## 개발 환경 설정

### 빠른 시작 (Quick Start)

#### Docker 개발 환경 (권장)
```bash
# 개발 서버 시작 (핫 리로드)
docker compose up

# 백그라운드 실행
docker compose up -d

# 개발 서버 접속: http://localhost:5173
```

#### 프로덕션 환경
```bash
# 프로덕션 빌드 및 실행
docker compose up

# 프로덕션 서버 접속: http://localhost:3000
```

### 컨테이너 내부 개발
```bash
# 컨테이너 셸 접근
docker compose run --rm app

# 컨테이너 내부에서 실행 가능한 명령
npm ci                    # 의존성 설치
npm run dev -- --host    # 개발 서버
npm run build            # 프로덕션 빌드
npm run check            # 타입 체킹
```

---

## 빌드 및 배포

### 웹 애플리케이션
```bash
# 프로덕션 빌드
npm run build:web

# 미리보기
npm run preview:web
```

### Electron 데스크톱 앱
```bash
# 현재 OS용
npm run electron:build

# 플랫폼별
npm run electron:build:win    # Windows
npm run electron:build:mac    # macOS
npm run electron:build:linux  # Linux

# 출력: electron/dist/
```

### Docker 배포
```bash
# 이미지 빌드
./docker/build.sh

# 컨테이너 실행
docker-compose -f docker/docker-compose.yml up

# PostgreSQL 포함
docker-compose -f docker/docker-compose.yml --profile postgres up
```

---

## 환경 변수

### 데이터베이스 (자동 감지)
```bash
# PostgreSQL (설정 시 자동 전환)
POSTGRES_URL=postgresql://user:pass@host:5432/dbname
# 또는
POSTGRES_HOST=localhost
POSTGRES_USER=rcmd
POSTGRES_PASSWORD=secret
POSTGRES_DB=rcmd

# SQLite (기본, 설정 불필요)
```

### Docker 권한
```bash
PUID=1000  # Process User ID
PGID=1000  # Process Group ID
TZ=Asia/Seoul
```

### 개발/프로덕션
```bash
NODE_ENV=development|production
PORT=5173
PUBLIC_API_URL=/api
```

---

## 다음 단계

### Phase 2: 핵심 기능 (3주)

#### Week 1: Rclone 통합
- [ ] Rclone 프로세스 래퍼 서비스
- [ ] 리모트 관리 API
- [ ] 설정 파일 파서

#### Week 2: 파일 브라우저
- [ ] 파일 시스템 API
- [ ] 브라우저 UI 컴포넌트
- [ ] 드래그 앤 드롭

#### Week 3: 전송 관리
- [ ] 작업 큐 시스템
- [ ] 진행 상황 추적
- [ ] WebSocket 실시간 업데이트

### Phase 3: 고급 기능 (2주)
- [ ] 스케줄링 시스템
- [ ] 대역폭 제어
- [ ] 다중 사용자 지원
- [ ] 알림 시스템

### Phase 4: 완성도 (1주)
- [ ] UI/UX 개선
- [ ] 테스트 자동화
- [ ] 문서화
- [ ] 릴리스 준비

---

## 주요 명령어 참조

### 개발
```bash
# Docker 개발 환경
docker compose up    # 개발 서버 시작
docker compose up -d # 백그라운드 실행

# 컨테이너 내부 접근
docker compose run --rm app
```

### 프로덕션
```bash
# Docker 프로덕션 환경
docker compose up          # 프로덕션 서버 시작
docker compose up -d       # 백그라운드 실행
```

### 유틸리티
```bash
# 로그 확인
docker compose logs -f

# 컨테이너 정리
docker compose down
docker compose down -v --remove-orphans

# 이미지 재빌드
docker compose build --no-cache
```

---

## 메타데이터

- **Author**: Textrix (t3xtrix@gmail.com)
- **License**: MIT
- **Repository**: https://github.com/rcmd/rcmd
- **Version**: 0.0.1
- **Documentation**: `/claudedocs/`
- **Last Updated**: 2025-09-28

---

*이 문서는 프로젝트의 현재 상태를 종합적으로 정리한 것입니다. 상세 기술 문서는 같은 디렉토리의 다른 파일들을 참조하세요.*