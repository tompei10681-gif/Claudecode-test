# てがきダイアリー — iPad 手帳アプリ

Apple Pencil 対応の手書き日記アプリです。SwiftUI + PencilKit で構築されています。

## 主な機能

| 機能 | 説明 |
|------|------|
| ✏️ 手書き入力 | PencilKit によるApple Pencil フル対応（ツールパレット付き） |
| ⌨️ テキスト入力 | キーボードによる日本語テキスト入力 |
| 📅 ミニカレンダー | 月表示カレンダーでエントリのある日をドット表示 |
| 😄 気分・天気記録 | 5段階の気分と6種の天気を記録 |
| 🏷️ タグ管理 | 自由タグでエントリを分類・フィルタ |
| 🔍 全文検索 | タイトル・本文・タグを横断検索 |
| 📄 ページ背景 | 白紙・横罫線・方眼・ドット罫線から選択 |
| 📤 エクスポート | テキスト形式でシェアシート経由で共有 |
| 🌙 ダークモード | システム設定に自動追従 |
| 📱 iPadOS最適化 | 3カラム NavigationSplitView |

## 技術スタック

- **言語**: Swift 5.9
- **UI フレームワーク**: SwiftUI
- **手書きエンジン**: PencilKit（`PKCanvasView` + `PKToolPicker`）
- **最低 OS**: iPadOS 17.0
- **データ保存**: UserDefaults（JSONEncoder/Decoder）

## プロジェクト構成

```
HandDiary/
├── HandDiary.xcodeproj/          # Xcode プロジェクト
└── HandDiary/
    ├── App/
    │   ├── HandDiaryApp.swift    # @main エントリポイント
    │   └── ContentView.swift     # NavigationSplitView ルート
    ├── Models/
    │   ├── DiaryEntry.swift      # データモデル（気分/天気/タグ/手書き）
    │   └── DiaryStore.swift      # CRUD + 検索 + エクスポート
    ├── Views/
    │   ├── Sidebar/
    │   │   ├── SidebarView.swift      # カレンダー + タグフィルタ + エントリ一覧
    │   │   └── EntryListView.swift    # 日付別エントリリスト
    │   ├── Calendar/
    │   │   └── MiniCalendarView.swift # ミニカレンダー（記録日ドット表示）
    │   ├── Canvas/
    │   │   └── HandwritingCanvasView.swift # PencilKit UIViewRepresentable
    │   ├── Detail/
    │   │   └── DiaryDetailView.swift  # タイピング / 手書き タブ切替
    │   └── Settings/
    │       ├── TagEditorView.swift    # タグ追加・削除
    │       ├── SettingsView.swift     # アプリ設定・統計
    │       └── ShareSheet.swift      # UIActivityViewController ラッパー
    ├── Resources/
    │   └── Info.plist
    └── Assets.xcassets/
```

## セットアップ

1. `HandDiary.xcodeproj` を Xcode 15 以上で開く
2. `PRODUCT_BUNDLE_IDENTIFIER` を自分の Bundle ID に変更
3. iPad 実機またはシミュレータ（iPadOS 17+）でビルド・実行

## App Store 販売戦略

### 収益モデル案

- **フリーミアム**: 基本機能無料、手書き機能 / テーマ / iCloud 同期をアプリ内課金
- **買い切り**: ¥480 〜 ¥980（日本語圏ターゲット）
- **サブスクリプション**: ¥150/月（iCloud バックアップ + プレミアムテーマ）

### 差別化ポイント

- 完全日本語 UI・日本のカレンダー形式
- Apple Pencil に最適化した手書きと文字入力のシームレス切替
- シンプルで美しい和風デザイン

## ライセンス

MIT License
