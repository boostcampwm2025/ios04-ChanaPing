# 🪴 머문 (Meomun)

![iOS](https://img.shields.io/badge/iOS-18.0%2B-000000?style=for-the-badge&logo=apple&logoColor=white) ![Swift](https://img.shields.io/badge/Swift-6.0+-FA7343?style=for-the-badge&logo=swift&logoColor=white) ![Xcode](https://img.shields.io/badge/Xcode-26.0+-1575F9?style=for-the-badge&logo=Xcode&logoColor=white)



<div align="center">
  <a href="https://apps.apple.com/kr/app/%EB%A8%B8%EB%AC%B8/id6758384170?itscg=30200&itsct=apps_box_badge&mttnsubad=6758384170" style="display: inline-block;">
  <video src="https://github.com/user-attachments/assets/3b819e47-97ef-4b2e-9b13-0aa9b4e75d41" />
  </a>
</div>


## 📌 소개
> **장소로 떠올리는 나의 기록**  
> 내가 머문 공간을 기록하는 위치 기반 개인 기록 서비스 ‘머문’


오늘 이 카페에서 무슨 생각을 했지?  
그때 그 거리에서 누구를 만났더라?

머문은 시간이 아닌 '장소'로 기억을 저장합니다. 

지도를 열면, 내가 머물렀던 모든 순간이 그 자리 그대로.


</br>


## 📱 주요 기능

### 기억을 남겨보세요 💬
- 지금 있는 위치에 메시지를 남길 수 있어요.

- 원하는 장소를 선택해서 기억이 담긴 공간을 만들 수 있어요.

| 위치로 남기기 | 장소로 남기기 |
| --- | --- |
| <video width="600" src="https://github.com/user-attachments/assets/98473dd4-eb28-460a-aa73-8cf2ce8620f6"/> | <video width="600" src="https://github.com/user-attachments/assets/e0e664b6-8a64-46b3-9543-4737bd9a45f5"/> |

### 지도에서 장소를 탐색해보세요 🗺️
- 지도 위에서 내 기록이 쌓인 장소들을 한눈에 확인할 수 있어요.

- 지도를 움직이거나, 원하는 장소를 검색하여 내 기록들을 확인할 수 있어요.

- 메시지를 눌러 그 장소에 모인 기록들을 열어보세요.


| 지도 화면 | 쌓인 기록 열기 |
| --- | --- |
| <video width="600" src="https://github.com/user-attachments/assets/793d5d93-9004-4a0d-ba14-8bf62171a535"/> | <video width="600" src="https://github.com/user-attachments/assets/36bd61aa-a708-4941-aba8-ddbdb3b99bde"/> |

| 지도 탐색 | 장소 탐색 |
| --- | --- |
| <video width="600" src="https://github.com/user-attachments/assets/5ef382b1-46cf-42cb-8a30-3b4b4e512231"/> | <video width="600" src="https://github.com/user-attachments/assets/da752a36-69ea-4a61-a809-6a7677578664"/> |



### 나만의 공간을 둘러보세요 ☁️
- 3D 공간에 떠다니는 나의 기억들을 특별한 방식으로 감상할 수 있어요.

| 공간 화면 | 공간 메시지 삭제 |
| --- | --- |
| <video width="600" src="https://github.com/user-attachments/assets/76df3d3a-a04d-42ef-b363-f16c03dbac44"/> | <video width="600" src="https://github.com/user-attachments/assets/bdca50b7-02fe-4596-9d63-217d2777ff0b"/> |


### 지난 기억을 따라가보세요 👣
- 남긴 기록을 타임라인 형식으로 모아볼 수 있어요.

- 한 달 동안의 기록을 한눈에 확인할 수 있어요.

| 머물렀던 순간들 | 흔적 따라가기 |
| --- | --- |
| <video width="600" src="https://github.com/user-attachments/assets/c2fa2bf5-e2e0-46c5-aaca-683c4cd3bf17"/> | <video width="600" src="https://github.com/user-attachments/assets/b9d77f07-74ea-4426-b91d-51bfd0e990a3"/> |

</br>

## 🛠 기술 스택
![SwiftUI](https://img.shields.io/badge/Swift_UI-0563D6?style=for-the-badge&logo=swift&logoColor=ffffff) ![SwiftData](https://img.shields.io/badge/Swift_Data-678494?style=for-the-badge&logo=swift&logoColor=ffffff) ![RealityKit](https://img.shields.io/badge/Reality_Kit-F2CA31?style=for-the-badge&logo=swift&logoColor=ffffff) ![CoreLocation](https://img.shields.io/badge/Core_Location-C50FF0?style=for-the-badge&logo=swift&logoColor=ffffff)

![Naver Map SDK](https://img.shields.io/badge/Naver_Map_SDK-03C75A?style=for-the-badge&logo=naver&logoColor=ffffff) ![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=ffffff)


### Architecture & Patterns

<img width="1980" alt="0-아키텍쳐" src="https://github.com/user-attachments/assets/49e108bc-beab-4229-b930-68d7fa57dd39" />

**Clean Architecture**
- UI(SwiftUI), 비즈니스 로직(Domain), 데이터(SwiftData)가 서로 독립적
- SwiftData를 Realm이나 CoreData로 교체해도 Domain/Presentation 레이어는 영향 없음

**MVI 패턴**
- Intent(사용자 인터랙션) → Action(상태 변경 트리거) → Reduce(상태 변경, 순수 함수) 기반의 단방향 데이터 플로우
- MVVM의 상태 관리 복잡성을 해결
- 디버깅 시 어떤 Intent가 어떤 State 상태 변화를 만들었는지 추적 용이

</br>
</br>

# 👬🏻 Team. ChanaPing

|S014|S018|S023|S034|  
|---|---|---|---|
|<img width=180 alt="image" src="https://github.com/user-attachments/assets/f4ec7aad-c290-4d7d-b2fc-6ec7b94e8b85" />|<img width=180 alt="image" src="https://github.com/user-attachments/assets/eadac7ac-db84-4a50-9f1c-e744e53b7238" />|<img width=180 alt="image" src="https://github.com/user-attachments/assets/6f89ecfc-1dcf-4fcc-a2e7-8f5c119b3734" />|<img width=180 alt="image" src="https://github.com/user-attachments/assets/d1184d27-973f-4ec8-9416-e0e311dae75e" />|  
|[@ha6q6v](https://github.com/ha6q6v)|[@moonazn](https://github.com/moonazn)|[@Hoon94](https://github.com/Hoon94)|[@MinwooJe](https://github.com/MinwooJe)|  
|박하연|송지연|이대훈|제민우|  


## 문의

| 📧 Email | meomun.app@gmail.com |
| --- | --- |
| 📄 **Form** |[**문의 폼**](https://forms.gle/WcsNLJoGdDGmsLaUA) |
