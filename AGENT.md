# TimeScopes 에이전트 지침

## 보존한 AGENTS.md 프로젝트 지침

<a id="repository-guidelines"></a>

# 저장소 지침

<a id="project-structure--module-organization"></a>

## 프로젝트 구조 및 모듈 구성
- `src/Time Scopes/`는 SwiftUI 앱 소스를 보유하고 있습니다.
  - `App/View/`에는 SwiftUI 화면과 재사용 가능한 보기가 포함되어 있습니다.
  - `App/Domain/`에는 모델 및 계산 서비스가 포함되어 있습니다.
  - `App/Data/`에는 지속성과 저장 추상화가 포함되어 있습니다.
  - `App/Events/` 및 `App/User/` 그룹 시간/이벤트 계산 및 사용자 상태.
  - `App/Utility/`에는 UI 도우미와 날짜 유틸리티가 포함되어 있습니다.
- `Time Scopes.xcodeproj/`는 Xcode 프로젝트 및 구성표 구성입니다.
- `Resource/`는 디자인 자산과 스크린샷을 저장합니다(앱 번들로 제공되지 않음).

<a id="build-test-and-development-commands"></a>

## 빌드, 테스트 및 개발 명령
- `open "Time Scopes.xcodeproj"` — Xcode에서 프로젝트를 엽니다.
- `xcodebuild -scheme "Time Scopes" build` — CLI에서 앱을 빌드합니다.
- `xcodebuild -scheme "Time Scopes" test -destination "platform=iOS Simulator,name=<Device>"` — 테스트를 실행합니다(시뮬레이터 이름 추가). 참고: 현재 정의된 테스트 대상이 없습니다.

<a id="coding-style--naming-conventions"></a>

## 코딩 스타일 및 명명 규칙
- 앱 전체에서 Swift + SwiftUI; 기존 파일과 마찬가지로 Swift 4 공간 들여쓰기를 고수하세요.
- 유형 및 보기는 `PascalCase`(예: `UserProfile`, `HomeView`)를 사용합니다.
- 속성, 함수 및 로컬은 `camelCase`(예: `userData`, `remainingTime`)를 사용합니다.
- 보기 파일에 초점을 맞추고 화면이 커질 때 `App/View/`의 작은 하위 보기를 선호합니다.

<a id="testing-guidelines"></a>

## 테스트 지침
- 저장소에는 아직 XCTest 대상이 없습니다. 테스트를 추가하는 경우 Xcode 테스트 대상을 만들고 `*Tests.swift` 이름 지정을 사용하여 앱 옆에 파일을 배치합니다.
- 논리가 많고 UI와 독립적이기 때문에 `App/Domain/Services/`에서 도메인 서비스를 테스트하는 것을 선호합니다.

<a id="commit--pull-request-guidelines"></a>

## 커밋 및 풀 요청 지침
- 최근 커밋은 짧고 명령적인 제목 줄(예: “Refactor time calculations into domain layer”)을 사용합니다. 간결하고 행동 지향적으로 유지하세요.
- PR은 사용자가 볼 수 있는 변경 사항을 설명하고, 새로운 계산 또는 모델 변경 사항을 나열하고, 보기 업데이트를 위한 UI 스크린샷을 포함해야 합니다.
- 마이그레이션에 따른 놀라움을 피하기 위해 `UserDefaults` 매장의 데이터 모델 변경 사항을 알려주세요.

<!-- workspace-docs:agent:start -->
## 문서 구조와 에이전트 탐색

- 프로젝트 루트의 `README.md`는 사람용 영문 진입 문서이며 `AGENT.md`는 에이전트 진입점이다.
- 하위 인간용 Markdown과 구조화된 agent JSON을 함께 유지한다. Markdown이 원본이며 JSON은 원문 해시와 줄 범위를 가진 파생 문서이다.
- 먼저 [docs/agent-index.json](docs/agent-index.json)에서 관련 문서와 JSON 투영을 찾는다. 원문 SHA-256이 다르면 현재 Markdown을 읽고 투영을 갱신한다.
- JSON의 규칙 후보는 검색용 어휘 일치 결과이다. 과거 기록·예제·실패 상태를 현재 지시나 검증 완료로 자동 해석하지 않는다.
- 기존 프로젝트별 규칙, 동결된 증거, 라이선스, 외부 원본, 사용자 데이터와 다른 작업의 변경을 보존한다.
- 이 문서 재편 지침은 과거 작업의 기능 구현·배포를 자동 재개하라는 요청이 아니다. 현재 사용자의 작업 범위를 우선한다.
- 문서를 수정하면 JSON 쌍·색인을 함께 갱신하고 검증한다. 기존 소스 변경에 대한 빌드·테스트 규칙은 계속 따른다.

Workspace에서 이 프로젝트의 문서를 갱신하는 명령은 다음과 같다.

```sh
python3 ../../../Engineering/WorkspaceDocumentation/App/workspace_docs.py --workspace ../../.. sync --project Product/Utility/TimeScopes
```
<!-- workspace-docs:agent:end -->
