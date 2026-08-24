import SwiftUI
import UIKit

struct AppIconOption: Identifiable, Hashable {
    let id: String
    let label: String
    let setName: String?   // nil 表示默认
}

enum AppIcons {
    static let all: [AppIconOption] = [
        AppIconOption(id: "default", label: "默认（官方主图标）", setName: nil),
        AppIconOption(id: "IconRounded", label: "圆角版", setName: "IconRounded"),
        AppIconOption(id: "Custom001", label: "自定义 001", setName: "Custom001"),
        AppIconOption(id: "Custom002", label: "自定义 002", setName: "Custom002"),
        AppIconOption(id: "Custom003", label: "自定义 003", setName: "Custom003"),
        AppIconOption(id: "Custom004", label: "自定义 004", setName: "Custom004"),
        AppIconOption(id: "Custom005", label: "自定义 005", setName: "Custom005"),
        AppIconOption(id: "Custom006", label: "自定义 006", setName: "Custom006"),
        AppIconOption(id: "Custom007", label: "自定义 007", setName: "Custom007"),
        AppIconOption(id: "Custom008", label: "自定义 008", setName: "Custom008"),
        AppIconOption(id: "Legacy996", label: "经典 996", setName: "Legacy996"),
        AppIconOption(id: "Legacy997", label: "经典 997", setName: "Legacy997"),
        AppIconOption(id: "Legacy998", label: "经典 998", setName: "Legacy998"),
        AppIconOption(id: "Legacy999", label: "经典 999", setName: "Legacy999"),
        AppIconOption(id: "Production", label: "官方默认", setName: "Production"),
        AppIconOption(id: "Anzac", label: "季节 Anzac", setName: "Anzac"),
        AppIconOption(id: "Autumn", label: "季节 Autumn", setName: "Autumn"),
        AppIconOption(id: "Autumn2021", label: "季节 Autumn2021", setName: "Autumn2021"),
        AppIconOption(id: "Autumn2022", label: "季节 Autumn2022", setName: "Autumn2022"),
        AppIconOption(id: "Barbie", label: "季节 Barbie", setName: "Barbie"),
        AppIconOption(id: "BeijingOlympics1", label: "季节 BeijingOlympics1", setName: "BeijingOlympics1"),
        AppIconOption(id: "BeijingOlympics2", label: "季节 BeijingOlympics2", setName: "BeijingOlympics2"),
        AppIconOption(id: "BlackHistory", label: "季节 BlackHistory", setName: "BlackHistory"),
        AppIconOption(id: "CanadaIndigenous", label: "季节 CanadaIndigenous", setName: "CanadaIndigenous"),
        AppIconOption(id: "Daytona", label: "季节 Daytona", setName: "Daytona"),
        AppIconOption(id: "EarthHour", label: "季节 EarthHour", setName: "EarthHour"),
        AppIconOption(id: "Easter", label: "季节 Easter", setName: "Easter"),
        AppIconOption(id: "Euro", label: "季节 Euro", setName: "Euro"),
        AppIconOption(id: "EurovisionFinal", label: "季节 EurovisionFinal", setName: "EurovisionFinal"),
        AppIconOption(id: "FormulaOne", label: "季节 FormulaOne", setName: "FormulaOne"),
        AppIconOption(id: "Halloween2021", label: "季节 Halloween2021", setName: "Halloween2021"),
        AppIconOption(id: "Halloween2022", label: "季节 Halloween2022", setName: "Halloween2022"),
        AppIconOption(id: "Holi", label: "季节 Holi", setName: "Holi"),
        AppIconOption(id: "Juneteenth", label: "季节 Juneteenth", setName: "Juneteenth"),
        AppIconOption(id: "KentuckyDerby", label: "季节 KentuckyDerby", setName: "KentuckyDerby"),
        AppIconOption(id: "LunarNewYear1", label: "季节 LunarNewYear1", setName: "LunarNewYear1"),
        AppIconOption(id: "LunarNewYear2", label: "季节 LunarNewYear2", setName: "LunarNewYear2"),
        AppIconOption(id: "Masters", label: "季节 Masters", setName: "Masters"),
        AppIconOption(id: "MayTheFourth", label: "季节 MayTheFourth", setName: "MayTheFourth"),
        AppIconOption(id: "Mlb", label: "季节 Mlb", setName: "Mlb"),
        AppIconOption(id: "MothersDay", label: "季节 MothersDay", setName: "MothersDay"),
        AppIconOption(id: "NBAFinals", label: "季节 NBAFinals", setName: "NBAFinals"),
        AppIconOption(id: "Nba1", label: "季节 Nba1", setName: "Nba1"),
        AppIconOption(id: "Nba2", label: "季节 Nba2", setName: "Nba2"),
        AppIconOption(id: "Ncaa", label: "季节 Ncaa", setName: "Ncaa"),
        AppIconOption(id: "NewZealandPride1", label: "季节 NewZealandPride1", setName: "NewZealandPride1"),
        AppIconOption(id: "NewZealandPride2", label: "季节 NewZealandPride2", setName: "NewZealandPride2"),
        AppIconOption(id: "PrideMonth", label: "季节 PrideMonth", setName: "PrideMonth"),
        AppIconOption(id: "PrideSouthern", label: "季节 PrideSouthern", setName: "PrideSouthern"),
        AppIconOption(id: "Ramadan", label: "季节 Ramadan", setName: "Ramadan"),
        AppIconOption(id: "SouthSpring2021", label: "季节 SouthSpring2021", setName: "SouthSpring2021"),
        AppIconOption(id: "SouthSpring2022", label: "季节 SouthSpring2022", setName: "SouthSpring2022"),
        AppIconOption(id: "StPatricksDay", label: "季节 StPatricksDay", setName: "StPatricksDay"),
        AppIconOption(id: "StanleyCup", label: "季节 StanleyCup", setName: "StanleyCup"),
        AppIconOption(id: "Summer", label: "季节 Summer", setName: "Summer"),
        AppIconOption(id: "Summer1", label: "季节 Summer1", setName: "Summer1"),
        AppIconOption(id: "Summer2", label: "季节 Summer2", setName: "Summer2"),
        AppIconOption(id: "Thanksgiving1", label: "季节 Thanksgiving1", setName: "Thanksgiving1"),
        AppIconOption(id: "Thanksgiving2", label: "季节 Thanksgiving2", setName: "Thanksgiving2"),
        AppIconOption(id: "Winter", label: "季节 Winter", setName: "Winter"),
        AppIconOption(id: "Winter1", label: "季节 Winter1", setName: "Winter1"),
        AppIconOption(id: "Winter2", label: "季节 Winter2", setName: "Winter2"),
        AppIconOption(id: "WomansDay", label: "季节 WomansDay", setName: "WomansDay"),
    ]

    static func apply(_ opt: AppIconOption) {
        UIApplication.shared.setAlternateIconName(opt.setName) { error in
            if let error { print("切换图标失败:", error) }
        }
    }
}
