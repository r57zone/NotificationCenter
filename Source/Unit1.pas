unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OleCtrls, SHDocVw, MSHTML, ShellAPI, StdCtrls, ExtCtrls, XPMan,
  Menus, ImgList, IniFiles, Registry;

type
  TMain = class(TForm)
    WebView: TWebBrowser;
    XPManifest: TXPManifest;
    PopupMenu: TPopupMenu;
    AboutBtn: TMenuItem;
    LineItem2: TMenuItem;
    ExitBtn: TMenuItem;
    Icons: TImageList;
    ItemsPopupMenu: TPopupMenu;
    RemoveBtn: TMenuItem;
    ItemsLine: TMenuItem;
    BlockBtn: TMenuItem;
    ShowBtn: TMenuItem;
    LineItem: TMenuItem;
    ChangeIcon: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure WebViewBeforeNavigate2(Sender: TObject;
      const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
      Headers: OleVariant; var Cancel: WordBool);
    procedure WebViewDocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure FormDestroy(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure ExitBtnClick(Sender: TObject);
    procedure RemoveBtnClick(Sender: TObject);
    procedure BlockBtnClick(Sender: TObject);
    procedure ShowBtnClick(Sender: TObject);
    procedure ChangeIconTimer(Sender: TObject);
    procedure PressScroll;
  private
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
    procedure WMNCHITTEST(var Msg: TMessage); message WM_NCHITTEST;
    procedure DefaultHandler(var Message); override;
    procedure AddNotification(NotifyID: integer; NotifyTitle, NotifyDesc, NotifyTimeHM, NotifyDate, NotifyIconPath, NotifyColor: string);
    procedure LoadNotifications;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure IconMouse(var Msg: TMessage); message WM_USER + 1;
    procedure WMActivate(var Msg: TMessage); message WM_ACTIVATE;
    { Private declarations }
  public
    procedure NotificationCenterShow;
    procedure NotificationCenterHide;
    { Public declarations }
  end;

var
  Main: TMain;
  Notifications, ExcludeList: TStringList;
  WM_TASKBARCREATED: Cardinal;
  IconIndex: byte;
  IconFull: TIcon;
  IDS_NOTIFICATIONS, IDS_DELETE_ALL, IDS_UNKNOWN_APP, IDS_BLOCK_QUESTION, IDS_LAST_UPDATE: string;
  NotifyIndex: integer;
  ScrollBlink, ScrollState: boolean;

implementation

{$R *.dfm}

type TTrayAction = (TrayAdd, TrayUpdate, TrayDelete);
procedure Tray(TrayAction: TTrayAction);
var
  NIM: TNotifyIconData;
begin
  with NIM do begin
    cbSize:=SizeOf(NIM);
    Wnd:=Main.Handle;
    uId:=1;
    uFlags:=NIF_MESSAGE or NIF_ICON or NIF_TIP;
    hIcon:=SendMessage(Main.Handle, WM_GETICON, ICON_SMALL2, 0);
    uCallBackMessage:=WM_USER + 1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case TrayAction of
    TrayAdd: Shell_NotifyIcon(NIM_ADD, @NIM);
    TrayUpdate: Shell_NotifyIcon(NIM_MODIFY, @NIM);
    TrayDelete: Shell_NotifyIcon(NIM_DELETE, @NIM);
  end;
end;

procedure TMain.NotificationCenterShow;
begin
  if Main.AlphaBlend then begin
    Main.AlphaBlendValue:=255;
    Main.AlphaBlend:=false;
  end;
  Top:=Screen.Height - Main.Height - 54;
  Left:=Screen.Width - Main.Width - 8;
  if WebView.Document <> nil then
    (WebView.Document as IHTMLDocument2).ParentWindow.Focus;
  ShowWindow(Handle, SW_SHOW);

  // ��������� "��������" ������
  ChangeIcon.Enabled:=false;
  if ScrollState then // ��������� ���������, ������ ���������
    PressScroll;

  IconIndex:=0;
  Tray(TrayUpdate);
end;

procedure TMain.NotificationCenterHide;
begin
  ShowWindow(Handle, SW_HIDE);
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.LParam of
    WM_LBUTTONDOWN:
      begin
        if IsWindowVisible(Main.Handle) then
          NotificationCenterHide
        else
          NotificationCenterShow;

        if ScrollState then
          PressScroll;
      end;

    WM_RBUTTONDOWN:
      PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TMain.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style:=WS_POPUP or WS_THICKFRAME;
end;

function GetLocaleInformation(Flag: integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19)<=0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

procedure TMain.AddNotification(NotifyID: integer; NotifyTitle, NotifyDesc, NotifyTimeHM, NotifyDate, NotifyIconPath, NotifyColor: string);
begin
  WebView.OleObject.Document.getElementById('items').innerHTML:='<div oncontextmenu="document.location=''#item=' + IntToStr(NotifyID) + ''';" id="item"><div id="icon" style="background-color:' +
    NotifyColor + ';"><img src="' + NotifyIconPath + '" /></div><div id="context"><div id="title">' +
    NotifyTitle + '</div><div id="clear"></div><div id="description">' + NotifyDesc +' </div></div><div id="time">' + NotifyTimeHM + '<br>' +
    NotifyDate + '</div></div>' + WebView.OleObject.Document.getElementById('items').innerHTML;
end;

procedure TMain.LoadNotifications;
var
  NotifyTitle, NotifyDesc, NotifyTimeHM, NotifyDate, NotifyIconPath, NotifyColor: string;
  i: integer;
  NotifyStr: string;
begin
  for i:=0 to Notifications.Count - 1 do begin
    NotifyStr:=Notifications.Strings[i];

    NotifyTitle:=Copy(NotifyStr, 1, Pos(#9, NotifyStr) - 1);
    Delete(NotifyStr, 1, Pos(#9, NotifyStr));

    NotifyDesc:=Copy(NotifyStr, 1, Pos(#9, NotifyStr) - 1);
    Delete(NotifyStr, 1, Pos(#9, NotifyStr));

    NotifyTimeHM:=Copy(NotifyStr, 1, Pos(#9, NotifyStr) - 1);
    Delete(NotifyStr, 1, Pos(#9, NotifyStr));

    NotifyDate:=Copy(NotifyStr, 1, Pos(#9, NotifyStr) - 1);
    Delete(NotifyStr, 1, Pos(#9, NotifyStr));

    NotifyIconPath:=Copy(NotifyStr, 1, Pos(#9, NotifyStr) - 1);
    Delete(NotifyStr, 1, Pos(#9, NotifyStr));

    NotifyColor:=NotifyStr;

    AddNotification(i, NotifyTitle, NotifyDesc, NotifyTimeHM, NotifyDate, NotifyIconPath, NotifyColor);
  end;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
  Reg: TRegistry;
  LangFileName: string;
begin
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  ScrollBlink:=Ini.ReadBool('Main', 'ScrollBlink', false);
  IconIndex:=Ini.ReadInteger('Main', 'NewMessages', 0);

  // �������� "��������" ������
  if IconIndex = 1 then begin
    ChangeIcon.Enabled:=true;
    PressScroll;
  end;

  if Ini.ReadBool('Main', 'FirstRun', true) then begin
    Ini.WriteBool('Main', 'FirstRun', false);
    Reg:=TRegistry.Create;
    Reg.RootKey:=HKEY_CURRENT_USER;
    if Reg.OpenKey('\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION', true) then begin
        Reg.WriteInteger(ExtractFileName(ParamStr(0)), 11000);
      Reg.CloseKey;
    end;
    Reg.Free;
  end;

  Ini.Free;
  IconFull:=TIcon.Create;
  Icons.GetIcon(0, IconFull);

  //������� / Translate
  LangFileName:=GetLocaleInformation(LOCALE_SENGLANGUAGE) + '.ini';
  if FileExists(ExtractFilePath(ParamStr(0)) + 'Languages\' + LangFileName) then
    Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Languages\' + LangFileName)
  else
    Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Languages\English.ini');

  Application.Title:=Ini.ReadString('Main', 'IDS_TITLE', '');
  IDS_NOTIFICATIONS:=Ini.ReadString('Main', 'IDS_NOTIFICATIONS', '');
  IDS_DELETE_ALL:=Ini.ReadString('Main', 'IDS_DELETE_ALL', '');
  IDS_UNKNOWN_APP:=Ini.ReadString('Main', 'IDS_UNKNOWN_APP', '');

  RemoveBtn.Caption:=Ini.ReadString('Main', 'IDS_REMOVE', '');
  BlockBtn.Caption:=Ini.ReadString('Main', 'IDS_BLOCK', '');
  IDS_BLOCK_QUESTION:=Ini.ReadString('Main', 'IDS_BLOCK_QUESTION', '');

  ShowBtn.Caption:=Application.Title;
  AboutBtn.Caption:=Ini.ReadString('Main', 'IDS_ABOUT_TITLE', '');
  IDS_LAST_UPDATE:=Ini.ReadString('Main', 'IDS_LAST_UPDATE', '');
  ExitBtn.Caption:=Ini.ReadString('Main', 'IDS_EXIT', '');
  
  Ini.Free;
  //

  WM_TASKBARCREATED:=RegisterWindowMessage('TaskbarCreated');

  WebView.Silent:=true;
  WebView.Navigate(ExtractFilePath(ParamStr(0)) + 'main.html');
  Tray(TrayAdd);
  SetWindowLong(Application.Handle, GWL_EXSTYLE, GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);
  NotificationCenterHide;
  Notifications:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'Notifications.txt') then
    Notifications.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Notifications.txt');
  ExcludeList:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0)) + 'Exclude.txt') then
    ExcludeList.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'Exclude.txt');
end;

procedure TMain.WebViewBeforeNavigate2(Sender: TObject;
  const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
  Headers: OleVariant; var Cancel: WordBool);
var
  sURL: string; NotificationIndex: integer;
begin
  sUrl:=ExtractFileName(StringReplace(url, '/', '\', [rfReplaceAll]));
  if Pos('main.html', sUrl) = 0 then Cancel:=true;

  if sUrl = 'main.html#rm' then begin
    WebView.OleObject.Document.getElementById('items').innerHTML:='';
    Notifications.Clear;
    Notifications.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notifications.txt');
  end;

  if Copy(sUrl, 1, 15) = 'main.html#item=' then begin
    NotifyIndex:=StrToIntDef(Copy(sUrl, 16, Length(sUrl)), -1);
    ItemsPopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TMain.WebViewDocumentComplete(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
var
  sUrl: string;
begin
  if pDisp = (Sender as TWebBrowser).Application then begin
    sUrl:=ExtractFileName(StringReplace(URL, '/', '\', [rfReplaceAll]));
    if sUrl = 'main.html' then begin
      Application.ProcessMessages;
      if WebView.Document <> nil then begin
        LoadNotifications;
        WebView.OleObject.Document.getElementById('title').innerHTML:=IDS_NOTIFICATIONS;
        WebView.OleObject.Document.getElementById('clear_btn').innerHTML:='<a onclick="document.location=''#rm'';">' + IDS_DELETE_ALL + '</a>';
      end;
      Caption:='Notification center';
    end;
  end;
end;

function CurrentTimeHM: string;
begin
  Result:=Copy(TimeToStr(Time), 1, 5);
  if Result[Length(Result)] = ':' then
    Result:=Copy(Result, 1, Length(Result) - 1);
end;

procedure TMain.WMCopyData(var Msg: TWMCopyData);
var
  NotifyTitle, NotifyDesc, DescSub, BigIcon, SmallIcon, NotifyColor: string;
  NotifyMsg: TStringList;
  i: integer;
begin
  if Copy(PChar(TWMCopyData(Msg).CopyDataStruct.lpData), 1, 8) = '{NOTIFY}' then begin

    NotifyMsg:=TStringList.Create;
    NotifyMsg.Text:=PChar(TWMCopyData(Msg).CopyDataStruct.lpData);
    NotifyMsg.Text:=StringReplace(NotifyMsg.Text, #9, #13#10, [rfReplaceAll]);
    NotifyMsg.Text:=StringReplace(NotifyMsg.Text, '&&', '&', [rfReplaceAll]);
    NotifyMsg.Delete(0);

    NotifyTitle:=IDS_UNKNOWN_APP;
    NotifyColor:='gray';
    BigIcon:='Sys.png';
    SmallIcon:='';

    for i:=0 to NotifyMsg.Count - 2 do begin
      if NotifyMsg.Strings[i] = '-t' then
        NotifyTitle:=NotifyMsg.Strings[i + 1];

      if NotifyMsg.Strings[i] = '-d' then
        NotifyDesc:=StringReplace(NotifyMsg.Strings[i + 1], '\n', ' - ', [rfReplaceAll]);

      if NotifyMsg.Strings[i] = '-b' then
        BigIcon:=NotifyMsg.Strings[i + 1];

      if NotifyMsg.Strings[i] = '-s' then
        SmallIcon:=NotifyMsg.Strings[i + 1];

      if NotifyMsg.Strings[i] = '-c' then
        NotifyColor:=NotifyMsg.Strings[i + 1];
    end;

    if (SmallIcon <> '') and (BigIcon = 'Sys.png') then
      BigIcon:=SmallIcon;

    case NotifyColor[1] of
      '0': NotifyColor:='#3591ce'; // ������-�����
      '1': NotifyColor:='#235d82'; // �����-�����
      '2': NotifyColor:='#018399'; // ����-�������
      '3': NotifyColor:='#008a00'; // ������
      '4': NotifyColor:='#2933ab'; // ����������
      '5': NotifyColor:='#8d44ad'; // �����-�������
      '6': NotifyColor:='#c0392b'; // �������
      '7': NotifyColor:='#2c3e50'; // ׸����
    else
      NotifyColor:='#3591ce';      // ������-�����
    end;

    // ��������� ����������� ���������
    if Pos(NotifyTitle, ExcludeList.Text) = 0 then begin
      Notifications.Add(NotifyTitle + #9 + NotifyDesc + #9 + CurrentTimeHM + #9 + DateToStr(Date) + #9 + BigIcon + #9 + NotifyColor);
      AddNotification(Notifications.Count - 1, NotifyTitle, NotifyDesc, CurrentTimeHM, DateToStr(Date), BigIcon, NotifyColor);
      IconIndex:=1;
      Tray(TrayUpdate);
      // �������� "��������" ������
      ChangeIcon.Enabled:=true;
      PressScroll;
      Notifications.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notifications.txt');
    end;

    NotifyMsg.Free;
  end;
  Msg.Result:=Integer(True);
end;

procedure TMain.WMActivate(var Msg: TMessage);
begin
  if Msg.WParam = WA_INACTIVE then
    NotificationCenterHide;
  inherited;
end;

procedure TMain.FormDestroy(Sender: TObject);
var
  Ini: TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Setup.ini');
  if ChangeIcon.Enabled then IconIndex:=1;
  Ini.WriteInteger('Main', 'NewMessages', IconIndex);
  Ini.Free;
  Notifications.Free;
  ExcludeList.Free;
  Tray(TrayDelete);
  IconFull.Free;
  if ScrollState then
    PressScroll;
end;

procedure TMain.DefaultHandler(var Message);
begin
  if TMessage(Message).Msg = WM_TASKBARCREATED then
    Tray(TrayAdd);
  inherited;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar(Application.Title + ' 0.7.9' + #13#10 +
  IDS_LAST_UPDATE + ' 28.10.25' + #13#10 +
  'https://r57zone.github.io' + #13#10 +
  'r57zone@gmail.com'), PChar(AboutBtn.Caption), MB_ICONINFORMATION);
end;

procedure TMain.ExitBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMain.WMNCHITTEST(var Msg: TMessage);
begin
  Msg.Result:=HTCLIENT;
end;

procedure TMain.RemoveBtnClick(Sender: TObject);
begin
  if NotifyIndex <> -1 then begin
    Notifications.Delete(NotifyIndex);
    Notifications.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notifications.txt');
    WebView.OleObject.Document.getElementById('items').innerHTML:='';
    LoadNotifications;
  end;
end;

procedure TMain.BlockBtnClick(Sender: TObject);
var
  ExcludeTitle: string;
begin
  if NotifyIndex <> -1 then begin
    ExcludeTitle:=Copy(Notifications.Strings[NotifyIndex], 1, Pos(#9, Notifications.Strings[NotifyIndex]) - 1);

    case MessageBox(Handle, PChar(Format(IDS_BLOCK_QUESTION, [ExcludeTitle])), PChar(Caption), 35) of
      6: begin
          ExcludeList.Add(ExcludeTitle);
          ExcludeList.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Exclude.txt');
        end;
    end;
  end;
end;

procedure TMain.ShowBtnClick(Sender: TObject);
begin
  NotificationCenterShow;
end;

procedure TMain.ChangeIconTimer(Sender: TObject);
begin
  if IconIndex = 0 then
    IconIndex:=1
  else
    IconIndex:=0;
  PressScroll;
  Tray(TrayUpdate);
end;

procedure TMain.PressScroll;
var
  ScrollOn: Boolean;
begin
  if ScrollBlink = false then Exit;
  ScrollOn := (GetKeyState(VK_SCROLL) and 1) = 1;
  if ScrollOn <> ScrollState then begin
    keybd_event(VK_SCROLL, VK_SCROLL, KEYEVENTF_EXTENDEDKEY, 0);
    keybd_event(VK_SCROLL, VK_SCROLL, KEYEVENTF_EXTENDEDKEY or KEYEVENTF_KEYUP, 0);
    ScrollState := not ScrollState;
  end;
end;

end.
