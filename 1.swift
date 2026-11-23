BaiyueNav/
├── BaiyueNav.xcodeproj          ← 需由你的 CI 產生或手動建立（見文末）
├── Info.plist
└── BaiyueNav/
    ├── BaiyueNavApp.swift       App 進入點
    ├── Models.swift             資料模型、路線幾何運算（最近線段、累積距離、爬升）
    ├── GPXParser.swift          XMLParser 解析 + 上次路線快取
    ├── LocationManager.swift    定位、背景錄製、GPX 輸出
    ├── ElevationChartView.swift Swift Charts 海拔剖面圖
    └── ContentView.swift        地圖、儀表板、偏離警告、錄製控制
