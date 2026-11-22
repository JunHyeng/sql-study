---
title: GitHub 기록 가이드
date: 2026-11-21
tags: [github, git, 포트폴리오]
aliases: [깃허브 가이드]
---

# GitHub 기록 가이드

> [!TIP]
> 추천: 공부가 다 끝나고 한 번에 올리기보다 **처음부터 이 폴더 자체를 GitHub 저장소로 만들고, 수업 하나 끝날 때마다 커밋**하세요. 채용 담당자는 GitHub의 **꾸준한 커밋 기록(잔디)**을 보고 "성실하게 공부한 사람"이라고 판단합니다. 마지막에 한 번에 올리면 커밋이 하루치만 남습니다.

## 저장소를 2개로 나누는 이유

| 저장소 | 내용 | 공개 |
|---|---|---|
| `sql-study` (이 폴더) | 1~4단계 수업 노트, 실습 쿼리, 오답노트, 학습로그 | 공개 |
| 프로젝트별 저장소 (5단계에서 생성) | 포트폴리오 프로젝트 1개당 저장소 1개 | 공개 + 이력서에 링크 |

공부 노트와 포트폴리오를 섞으면 면접관이 프로젝트를 찾기 어렵습니다. 프로젝트는 5단계에서 따로 만들고, 그때 README 쓰는 법을 자세히 알려 드립니다.

## 1. 처음 한 번만 하는 설정

1. **GitHub 가입:** github.com. 아이디는 이력서에 들어가니 실명이나 깔끔한 영문으로 정하세요.
2. **GitHub Desktop 설치:** desktop.github.com. 명령어를 몰라도 버튼으로 커밋할 수 있습니다. Git도 같이 설치됩니다. 익숙해지면 명령어로 바꾸는 방법도 알려 드립니다.
3. GitHub Desktop 실행 → GitHub 계정으로 로그인.
4. **File → Add local repository** → `D:\study\sql` 선택 → "This directory does not appear to be a Git repository" 메시지 옆 **create a repository** 클릭.
   - Name: `sql-study`
   - Git ignore: None (아래 `.gitignore`를 직접 만듭니다)
   - Create repository
> [!WARNING]
> 만들기 창의 **Local path**가 `D:\study\sql`인 상태에서 Name을 `sql-study`로 바꾸면 `D:\study\sql\sql-study`라는 **빈 하위 폴더**에 저장소가 생깁니다. 그러면 노트가 저장소 밖에 있어서 "0 changed files"로 나옵니다. 저장소(`.git` 폴더)는 반드시 노트들과 같은 `D:\study\sql` 바로 안에 있어야 합니다.

5. 상단 **Publish repository** → "Keep this code private" **체크 해제**(공개) → Publish.

### `.gitignore` (올리지 않을 파일 목록)

이 폴더에 `.gitignore` 파일을 만들어 두었습니다. Obsidian의 개인 화면 설정처럼 공유할 필요 없는 파일은 올라가지 않습니다.

## 2. 매번 하는 일 (수업 1개 끝날 때마다)

1. Obsidian에서 노트 정리 완료
2. GitHub Desktop을 열면 왼쪽에 바뀐 파일 목록이 보입니다.
3. 왼쪽 아래 **Summary**에 커밋 메시지 작성 → **Commit to main**
4. 상단 **Push origin** 클릭 → GitHub 사이트에 반영

### 커밋 메시지 규칙

한눈에 무슨 작업인지 보이게 앞에 말머리를 붙입니다.

| 말머리 | 언제 | 예시 |
|---|---|---|
| `study:` | 수업 노트·답안 추가 | `study: 1-1 SELECT 기초 실습 완료` |
| `fix:` | 틀린 답 수정, 오답노트 | `fix: 1-1 문제4 별칭 오류 수정` |
| `docs:` | README·로그 정리 | `docs: 학습로그 11월 3주차 정리` |
| `task:` | 3단계 실전 과제 | `task: 과제 05 월별 매출 분석` |

## 3. GitHub에서 보기 좋게 만드는 법

- 이 폴더의 노트는 GitHub에서도 링크가 그대로 작동하도록 **상대 경로 링크**로 만들고 있습니다. GitHub에서 `README.md`부터 클릭하며 따라갈 수 있습니다.
- `README.md` 대시보드가 저장소 첫 화면이 됩니다. 진행 현황 체크박스가 곧 공부 진도표가 됩니다.
- 3단계부터는 문제를 풀 때마다 `.sql` 파일로도 저장합니다. GitHub 통계에 SQL 언어가 잡히고, 코드 색상도 예쁘게 나옵니다.

## 4. 주의할 점

- **비밀번호를 올리지 마세요.** MySQL root 비밀번호를 노트나 `.sql` 파일에 적지 마세요. 한 번 올라간 비밀번호는 지워도 기록(히스토리)에 남습니다.
- 실습 데이터는 모두 가짜(가상 인물)이므로 공개해도 괜찮습니다. 나중에 공공데이터나 캐글 데이터를 쓸 때는 출처와 라이선스를 README에 적습니다.
- 용량이 큰 원본 데이터(100MB 이상)는 GitHub에 올라가지 않습니다. 이런 데이터는 다운로드 링크만 적어 둡니다.

## 체크리스트

- [x] GitHub 가입
- [x] GitHub Desktop 설치 및 로그인
- [x] `D:\study\sql`을 `sql-study` 저장소로 만들고 Publish (공개)
- [x] 첫 커밋: `docs: SQL 학습 저장소 시작`

Related: [환경 설정](00_환경설정.md) · [5단계 포트폴리오](05_포트폴리오/INDEX.md)
Up: [대시보드](README.md)
