//
//  MarkerProtocol.swift
//  Meomun
//
//  Created by 지연 on 2/4/26.
//

import UIKit

/// 마커(핀/오버레이)를 추상화한 포트.
/// alpha, icon, attach/detach, tap handling만 제공.
public protocol MarkerProtocol: AnyObject {
    var alpha: CGFloat { get set }

    /// 마커 아이콘(버블 이미지) 설정
    func setIcon(_ image: UIImage)

    /// 지도에 붙이기/떼기
    func setAttached(to mapView: MapViewProtocol?)

    /// 탭(터치) 이벤트 바인딩
    func setOnTap(_ handler: @escaping () -> Void)
}
