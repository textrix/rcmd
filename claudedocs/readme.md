# RCMD 프로젝트 문서 센터

## 🎯 빠른 참조
- **[project-current-status.md](./project-current-status.md)** - 🔥 **최신 프로젝트 현황 (필독)**

## 📚 핵심 문서

### 1. 요구사항 및 설계
- **[development-requirements-specification.md](./development-requirements-specification.md)** - 기능/비기능 요구사항 명세
- **[technical-architecture-design.md](./technical-architecture-design.md)** - 시스템 아키텍처 설계
- **[api-specification.md](./api-specification.md)** - RESTful API 명세 (OpenAPI 3.0)
- **[database-schema-data-model.md](./database-schema-data-model.md)** - DB 스키마 및 데이터 모델
- **[resilience-patterns.md](./resilience-patterns.md)** - 에러 처리 및 복원력 패턴

### 2. 구현 가이드
- **[implementation-task-breakdown.md](./implementation-task-breakdown.md)** - 작업 분해 구조 (127개 태스크)
- **[build-strategy-guide.md](./build-strategy-guide.md)** - 빌드 전략 및 환경별 최적화
- **[development-setup.md](./development-setup.md)** - Docker 개발 환경 설정
- **[ui-ux-design-guidelines.md](./ui-ux-design-guidelines.md)** - UI/UX 디자인 가이드라인 (Total Commander 스타일)

## 🚀 빠른 시작

### 개발 환경 설정
```bash
# Docker 개발 환경 (권장)
docker compose up

# 또는 백그라운드 실행
docker compose up -d

# 개발 서버 접속: http://localhost:5173
```

### 프로젝트 구조
```
rcmd/
├── src/               # 소스 코드
├── static/            # 정적 파일
├── claudedocs/        # 프로젝트 문서
│   ├── readme.md      # 이 파일
│   └── *.md          # 핵심 문서들
├── compose.yaml       # Docker 프로덕션 설정
├── compose.override.yaml  # Docker 개발 설정
├── Dockerfile         # 멀티스테이지 빌드
├── entrypoint.sh      # 컨테이너 진입점
└── claudedocs/development-setup.md   # 개발 환경 상세 가이드
```

### 3. 구현 현황
- **[implementation-status-update.md](./implementation-status-update.md)** - 🆕 구현 현황 및 진행 상태
- **[readme-database.md](./readme-database.md)** - 데이터베이스 설정 상세

## 📊 프로젝트 현황

### ✅ 완료 (2025-09-28)
- **Docker 환경**: 개발/프로덕션 환경 완전 구축
- **권한 관리**: PUID/PGID 자동 매핑 시스템
- **데이터베이스**: SQLite/PostgreSQL 자동 감지
- **빌드 시스템**: 멀티스테이지 Docker 빌드
- **보안**: NPM 감사 및 최적화 완료

### 🚧 진행 중
- **Phase**: 핵심 기능 구현 준비
- **예상 MVP**: 3주 (2025-10-15)
- **기술 스택**: SvelteKit + SQLite/PostgreSQL + Electron
- **규모**: 101개 리모트, ~500TB 데이터

## 🎯 다음 단계

1. ✅ ~~SvelteKit 프로젝트 초기화~~
2. ✅ ~~Docker 개발 환경 설정~~
3. ⏳ Rclone 프로세스 통합
4. ⏳ 파일 브라우저 UI 구현
5. ⏳ 전송 큐 시스템 개발

---
*최종 업데이트: 2025-09-28*