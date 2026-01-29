# 🪴 머문 (Meomun)

> **장소로 떠올리는 나의 기록**  
> 지도 위에서 추억을 다시 만나는 위치 기반 개인 기록 서비스

---

## 👬🏻 팀 소개

|S014|S018|S023|S034|  
|---|---|---|---|
|<img width=180 alt="image" src="https://github.com/user-attachments/assets/f4ec7aad-c290-4d7d-b2fc-6ec7b94e8b85" />|<img width=180 alt="image" src="https://github.com/user-attachments/assets/eadac7ac-db84-4a50-9f1c-e744e53b7238" />|<img width=180 alt="image" src="https://github.com/user-attachments/assets/6f89ecfc-1dcf-4fcc-a2e7-8f5c119b3734" />|<img width=180 alt="image" src="https://github.com/user-attachments/assets/d1184d27-973f-4ec8-9416-e0e311dae75e" />|  
|[@ha6q6v](https://github.com/ha6q6v)|[@moonazn](https://github.com/moonazn)|[@Hoon94](https://github.com/Hoon94)|[@MinwooJe](https://github.com/MinwooJe)|  
|박하연|송지연|이대훈|제민우|  

### 팀 성장 목표
<img width=600 src="https://github.com/user-attachments/assets/eabd979b-1849-4b52-8977-d39f46cdcfcb" />

## 📌 서비스 소개

여행지, 자주 가던 카페, 학교 등의 장소를 방문하면 그때의 기억이 떠오르는데요.

**머문**은 그 순간의 생각과 감정을 **지도 위 메시지**로 남겨,  
나중에 같은 장소를 방문했을 때 다시 만날 수 있게 합니다.

### 핵심 컨셉
- 📍 **장소가 곧 타임라인**: 각 장소에 남긴 기록을 지도에서 탐색  
- 📱 **완전한 오프라인**: 서버 없이 온디바이스에서 모든 데이터 관리  


## 📱 주요 기능

### 지도 화면
- Naver Map 기반 지도 위에 내 기록들이 버블로 표시
- 버블 탭 시 해당 위치의 기록 목록 표시

### 3D 공간 화면 (RealityKit)
- 선택한 장소의 기록들이 공간에 배치되어 몰입감 있는 경험 제공
- 몰입감 있는 UI로 과거 기록 재경험

### 기록 작성 화면
- 현재 위치 기반 새 기록 작성
- 특정 장소 태그 가능


## 🛠 기술 스택
- **Language**: Swift 6.0+
- **UI Framework**: SwiftUI
- **RealityKit**: 3D 환경에서의 기록 시각화
- **SwiftData**: 로컬 데이터 영속화
- **CoreLocation**: GPS 기반 위치 정보 수집
- **Naver Map SDK**: 지도 UI 및 위치 마커 표시

### Architecture & Patterns
- **Clean Architecture**: Presentation - Domain - Data 레이어 분리
- **MVI (Model-View-Intent)**: 단방향 데이터 플로우 기반 상태 관리


### 왜 이런 구조를 선택했나요?

**Clean Architecture**
- UI(SwiftUI), 비즈니스 로직(Domain), 데이터(SwiftData)가 서로 독립적
- SwiftData를 Realm이나 CoreData로 교체해도 Domain/Presentation 레이어는 영향 없음

**MVI 패턴**
- Intent(사용자 인터랙션) → Action(상태 변경 트리거) → Reduce(상태 변경, 순수 함수) 기반의 단방향 데이터 플로우
- MVVM의 상태 관리 복잡성을 해결
- 디버깅 시 어떤 Intent가 어떤 State를 만들었는지 추적 가능

**SwiftData + CloudKit**
- SwiftData는 CloudKit과 네이티브 통합되어 별도 동기화 로직 불필요
- `@Model` 객체의 변경사항을 자동으로 추적


## 🔐 데이터 프라이버시

- **로컬 저장**: 모든 데이터는 사용자 기기에만 저장
  - 위치 기반 조회/등록 API
