# RCMD Docker 개발 환경 가이드

**최종 업데이트**: 2025-09-28

이 문서는 RCMD 프로젝트의 Docker 기반 개발 환경 설정 방법을 안내합니다.

## 📋 목차
1. [필수 요구사항](#필수-요구사항)
2. [빠른 시작](#빠른-시작)
3. [개발 워크플로우](#개발-워크플로우)
4. [환경 변수 설정](#환경-변수-설정)
5. [Docker 아키텍처](#docker-아키텍처)
6. [유용한 명령어](#유용한-명령어)
7. [문제 해결](#문제-해결)

---

## 필수 요구사항

- Docker
- Docker Compose

## 빠른 시작

### 개발 환경

```bash
# 개발 서버 시작 (핫 리로드)
docker compose up

# 또는 백그라운드 실행
docker compose up -d
```

개발 서버 접속: **http://localhost:5173**

### 프로덕션 환경

```bash
# 프로덕션 빌드 및 실행
docker compose up

# 또는 백그라운드 실행
docker compose up -d
```

프로덕션 서버 접속: **http://localhost:3000**

---

## 개발 워크플로우

### 인터랙티브 개발

```bash
# 개발 컨테이너 셸 접근
docker compose run --rm app

# 컨테이너 내부에서 실행 가능한 명령들:
npm ci                    # 의존성 설치
npm run dev -- --host    # 개발 서버 시작
npm run build            # 프로덕션 빌드
npm run check            # 타입 체킹
```

### 프로젝트 생성 (초기 설정)

```bash
# 새 SvelteKit 프로젝트 생성
docker compose run --rm app npx -y sv create .
```

---

## 환경 변수 설정

`.env` 파일을 편집하여 환경을 구성하세요:

```env
PUID=1000    # 파일 권한용 사용자 ID
PGID=1000    # 파일 권한용 그룹 ID
```

### 사용자 ID 확인
```bash
id -u    # 사용자 ID 확인
id -g    # 그룹 ID 확인
```

---

## Docker 아키텍처

### 멀티스테이지 빌드

- **base**: Node.js가 포함된 공통 Alpine Linux 설정
- **dev**: Claude Code CLI가 있는 개발 환경
- **build**: 프로덕션 빌드 스테이지
- **prod**: 최적화된 프로덕션 런타임

### 주요 기능

- **권한 매핑**: 파일 권한을 위한 PUID/PGID 자동 처리
- **핫 리로드**: 라이브 개발을 위한 볼륨 마운팅
- **헬스 체크**: 내장 애플리케이션 모니터링
- **보안**: NPM 감사 및 프로덕션 최적화

### 파일 구조

```
├── compose.yaml           # 프로덕션 환경 설정
├── compose.override.yaml  # 개발 환경 오버라이드
├── Dockerfile            # 멀티스테이지 빌드
├── entrypoint.sh         # 컨테이너 진입점
└── .env                  # 환경 변수
```

---

## 유용한 명령어

### 개발

```bash
# 개발 서버 시작
docker compose up

# 백그라운드에서 개발 서버 시작
docker compose up -d

# 개발 컨테이너 셸 접근
docker compose run --rm app
```

### 프로덕션

```bash
# 프로덕션 서버 시작
docker compose up

# 백그라운드에서 프로덕션 서버 시작
docker compose up -d
```

### 유지보수

```bash
# 로그 확인
docker compose logs -f

# 모든 컨테이너 중지
docker compose down

# 컨테이너 재빌드
docker compose build --no-cache

# 정리
docker compose down -v --remove-orphans
docker system prune -f
```

---

## 문제 해결

### 권한 문제
`.env` 파일의 PUID/PGID가 호스트 사용자와 일치하는지 확인:
```bash
id -u    # 사용자 ID 확인
id -g    # 그룹 ID 확인
```

### 포트 충돌
포트 3000 또는 5173이 사용 중이면 `compose.yaml` 또는 `compose.override.yaml`에서 포트 매핑을 수정하세요.

### 컨테이너 시작 실패
상세한 오류 정보를 위해 로그를 확인하세요:
```bash
docker compose logs app
```

### 의존성 문제
컨테이너를 재빌드하여 해결:
```bash
docker compose build --no-cache
docker compose up
```

---

## 개발 팁

1. **코드 변경**: 개발 모드에서는 소스 코드 변경이 자동으로 반영됩니다.

2. **디버깅**: 컨테이너 내부에서 직접 명령어를 실행하려면:
   ```bash
   docker compose exec app bash
   ```

3. **패키지 설치**: 새 패키지를 설치한 후 컨테이너를 재시작하세요:
   ```bash
   docker compose restart
   ```

4. **성능**: 개발 시 핫 리로드가 느리면 볼륨 마운트 최적화를 고려하세요.

---

## 다음 단계

개발 환경이 설정되었으면:

1. **브라우저에서 확인**: http://localhost:5173
2. **코드 편집**: `src/` 디렉터리에서 개발 시작
3. **문서 참조**: `claudedocs/` 폴더의 다른 가이드들 확인

---

*이 가이드는 RCMD 프로젝트의 Docker 기반 개발 환경 설정을 위한 것입니다. 추가 질문이나 문제가 있으면 프로젝트 문서를 참조하세요.*