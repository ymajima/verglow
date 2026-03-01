CursorEdgeGuide — Architecture (Phase A)
1. 概要

CursorEdgeGuide は、macOS のマルチディスプレイ環境において、
カーソルがディスプレイ端に近づいたときにそのディスプレイの辺を淡く表示する常駐アプリである。
隣接ディスプレイの有無に関わらず、全ディスプレイの全4辺をトリガー対象とする。

Phase A では 最小機能（MVP） のみ実装する。

2. Phase A のゴール
実装対象

メニューバー常駐アプリ

全ディスプレイ情報の取得

全ディスプレイの全辺（EdgeSegment）生成

カーソル位置監視

端接近時のオーバーレイ線表示

カーソル離脱時に即非表示

非対象（Phase B以降）

設定UI

ディスプレイ番号表示

常時表示モード

カスタム色設定

アニメーション調整

3. 技術方針
OS

macOS Tahoe 以降のみ対応

UI技術

起動：SwiftUI App Lifecycle

実装本体：AppKit

SwiftUI はエントリポイント用途のみ使用する。

4. アーキテクチャ構成
┌──────────────────────┐
│   SwiftUI App Entry   │
└─────────┬────────────┘
          │
┌─────────▼────────────┐
│      AppController     │
└─────────┬────────────┘
          │
┌─────────▼────────────┐
│     CursorMonitor      │
└─────────┬────────────┘
          │
┌─────────▼────────────┐
│      EdgeAnalyzer      │
└─────────┬────────────┘
          │
┌─────────▼────────────┐
│     OverlayManager     │
└─────────┬────────────┘
          │
┌─────────▼────────────┐
│      OverlayWindow     │
└──────────────────────┘
5. レイヤ責務
AppController

アプリ全体の制御

各コンポーネント生成

イベント接続

CursorMonitor

責務：

グローバルマウス位置取得

カーソル移動通知

出力：

cursorMoved(position: CGPoint)
EdgeAnalyzer（Coreロジック）

責務：

NSScreen 情報解析

全ディスプレイの全4辺を EdgeSegment として生成（隣接の有無を問わない）

近接判定（カーソルと辺の距離計算）

入力：

[NSScreen]

出力：

[EdgeSegment]
OverlayManager

責務：

表示／非表示制御

OverlayWindow 管理

OverlayWindow

責務：

境界線の描画

非アクティブ透明ウィンドウ

特徴：

クリック透過

常に最前面

Dock非表示

6. データモデル
EdgeSegment
struct EdgeSegment {
    let rect: CGRect
    let fromScreenID: String
    let toScreenID: String
}

Phase A では rect のみ使用。

7. 表示仕様（Phase A）
表示条件（トリガー）

カーソルがいずれかのディスプレイの任意の辺から 8px 以内に入ったとき
（隣接ディスプレイの有無は問わない。どの辺でもトリガーになる）

表示内容（描画対象）

トリガーが発火したとき、全ディスプレイ間の隣接境界線をすべて表示する
・ライン自体は隣接部分にのみ描画する（非隣接辺・非隣接区間には線を引かない）
・トリガーした辺の場所には関係なく、全隣接セグメントが対象
・各セグメントは隣接する両方のディスプレイのオーバーレイウィンドウに描画する
  例）A─B─C の3台構成の場合、B のウィンドウは A-B 境界と B-C 境界の両方を表示する

表示位置

ディスプレイ境界上（位置C）

同時表示

複数境界 同時表示 YES

見た目

色：白

不透明度：約 30%

太さ：8px

アニメーション

フェードイン

フェードアウトなし（即消去）

非表示条件
カーソルが境界から離れた瞬間
8. ディレクトリ構成
CursorEdgeGuide/
├── App/
│   ├── CursorEdgeGuideApp.swift
│   └── AppController.swift
│
├── Core/
│   └── EdgeAnalyzer.swift
│
├── Monitoring/
│   └── CursorMonitor.swift
│
├── Overlay/
│   ├── OverlayManager.swift
│   └── OverlayWindow.swift
│
└── Model/
    └── EdgeSegment.swift
9. Phase B 予定

ディスプレイ番号表示

設定画面

色変更

表示条件カスタム

1秒自動消去

アニメーション改善

10. 設計原則

Core ロジックは AppKit 非依存

Window 描画とロジックを分離

常駐アプリとして軽量動作を優先

将来公開可能な構造を維持
