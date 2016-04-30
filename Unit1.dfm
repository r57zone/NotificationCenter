object Form1: TForm1
  Left = 192
  Top = 124
  BorderStyle = bsSingle
  Caption = 'Notification center'
  ClientHeight = 322
  ClientWidth = 380
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnClick = FormClick
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object WebBrowser1: TWebBrowser
    Left = 0
    Top = 0
    Width = 380
    Height = 306
    TabOrder = 0
    OnBeforeNavigate2 = WebBrowser1BeforeNavigate2
    OnDocumentComplete = WebBrowser1DocumentComplete
    ControlData = {
      4C00000046270000A01F00000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126208000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
end
