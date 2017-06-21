object Main: TMain
  Left = 192
  Top = 124
  BorderStyle = bsSingle
  ClientHeight = 322
  ClientWidth = 390
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object WebView: TWebBrowser
    Left = 0
    Top = 0
    Width = 390
    Height = 306
    TabOrder = 0
    OnBeforeNavigate2 = WebViewBeforeNavigate2
    OnDocumentComplete = WebViewDocumentComplete
    ControlData = {
      4C0000004F280000A01F00000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126208000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
  object XPManifest1: TXPManifest
    Left = 8
    Top = 8
  end
  object PopupMenu: TPopupMenu
    Left = 40
    Top = 8
    object AboutBtn: TMenuItem
      Caption = #1054' '#1087#1088#1086#1075#1088#1072#1084#1084#1077'...'
      OnClick = AboutBtnClick
    end
    object N2: TMenuItem
      Caption = '-'
    end
    object ExitBtn: TMenuItem
      Caption = #1042#1099#1093#1086#1076
      OnClick = ExitBtnClick
    end
  end
end
