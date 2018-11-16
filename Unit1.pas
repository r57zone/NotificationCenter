unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OleCtrls, SHDocVw, MSHTML, ShellAPI, StdCtrls, ExtCtrls, XPMan,
  Menus, ImgList, IniFiles;

type
  TMain = class(TForm)
    WebView: TWebBrowser;
    XPManifest: TXPManifest;
    PopupMenu: TPopupMenu;
    AboutBtn: TMenuItem;
    LineItem: TMenuItem;
    ExitBtn: TMenuItem;
    Icons: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure WebViewBeforeNavigate2(Sender: TObject;
      const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
      Headers: OleVariant; var Cancel: WordBool);
    procedure WebViewDocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure FormDestroy(Sender: TObject);
    procedure AboutBtnClick(Sender: TObject);
    procedure ExitBtnClick(Sender: TObject);
  private
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
    procedure WMNCHITTEST(var Msg: TMessage); message WM_NCHITTEST;
    procedure DefaultHandler(var Message); override;
    procedure MyShow;
    procedure MyHide;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure IconMouse(var Msg: TMessage); message WM_USER + 1;
    procedure WMActivate(var Msg: TMessage); message WM_ACTIVATE;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  Notifications, ExcludeList: TStringList;
  WM_TaskBarCreated: Cardinal;
  IconIndex: byte;
  IconFull: TIcon;
  ID_NOTIFICATIONS, ID_DELETE_ALL, ID_UNKNOWN_APP, ID_LAST_UPDATE: string;
  MainWidth, MainHeight: integer;
  RunOnce: boolean;

implementation

{$R *.dfm}

procedure TMain.MyShow;
begin
  if RunOnce = false then begin
    Width:=MainWidth;
    Height:=MainHeight;
    RunOnce:=true;
  end;
  SetWindowLong(Handle, GWL_STYLE, GetWindowLong(Handle, GWL_STYLE) or WS_POPUP or WS_THICKFRAME);
  Top:=Screen.Height - Main.Height - 54;
  Left:=Screen.Width - Main.Width - 8;
  if WebView.Document <> nil then
    (WebView.Document as IHTMLDocument2).ParentWindow.Focus;
  ShowWindow(Handle, SW_SHOW);
end;

procedure TMain.MyHide;
begin
  SetWindowLong(Handle, GWL_STYLE, GetWindowLong(Handle, GWL_STYLE) and not WS_POPUP and not WS_THICKFRAME);
  ShowWindow(Handle, SW_HIDE);
end;

procedure Tray(ActInd: integer); //1 - добавить, 2 - удалить, 3 -  заменить
var
  nim: TNotifyIconData;
begin
  with NIM do begin
    cbSize:=SizeOf(nim);
    Wnd:=Main.Handle;
    uId:=1;
    uFlags:=NIF_MESSAGE or NIF_ICON or NIF_TIP;

    if IconIndex = 0 then
      hIcon:=SendMessage(Application.Handle, WM_GETICON, ICON_SMALL2, 0)
    else
      hIcon:=IconFull.Handle;

    uCallBackMessage:=WM_USER + 1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case ActInd of
    1: Shell_NotifyIcon(NIM_ADD, @nim);
    2: Shell_NotifyIcon(NIM_DELETE, @nim);
    3: Shell_NotifyIcon(NIM_MODIFY, @nim);
  end;
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.LParam of
    WM_LBUTTONDOWN:
      begin
        MyShow;
        IconIndex:=0;
        Tray(3);
      end;

    WM_LBUTTONDBLCLK:
      MyHide;

    WM_RBUTTONDOWN:
      PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TMain.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style:=WS_POPUP or WS_THICKFRAME;
end;

function GetLocaleInformation(flag: integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, flag, pcLCA, 19)<=0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

procedure TMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  MainWidth:=Width;
  MainHeight:=Height;
  Width:=0;
  Height:=0;
  
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  IconIndex:=Ini.ReadInteger('Main', 'NewMessages', 0);
  Ini.Free;
  IconFull:=TIcon.Create;
  Icons.GetIcon(0, IconFull);

  //Перевод / Translate
  if FileExists(ExtractFilePath(ParamStr(0)) + 'Languages\' + GetLocaleInformation(LOCALE_SENGLANGUAGE) + '.ini') then
    Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Languages\' + GetLocaleInformation(LOCALE_SENGLANGUAGE) + '.ini')
  else
    Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Languages\English.ini');

  Application.Title:=Ini.ReadString('Main', 'ID_TITLE', '');
  ID_NOTIFICATIONS:=Ini.ReadString('Main', 'ID_NOTIFICATIONS', '');
  ID_DELETE_ALL:=Ini.ReadString('Main', 'ID_DELETE_ALL', '');
  ID_UNKNOWN_APP:=Ini.ReadString('Main', 'ID_UNKNOWN_APP', '');
  AboutBtn.Caption:=Ini.ReadString('Main', 'ID_ABOUT_TITLE', '');
  ID_LAST_UPDATE:=Ini.ReadString('Main', 'ID_LAST_UPDATE', '');
  ExitBtn.Caption:=Ini.ReadString('Main', 'ID_EXIT', '');
  
  Ini.Free;
  //

  WM_TaskBarCreated:=RegisterWindowMessage('TaskbarCreated');

  WebView.Silent:=true;
  WebView.Navigate(ExtractFilePath(ParamStr(0)) + 'main.htm');
  Tray(1);
  SetWindowLong(Application.Handle, GWL_EXSTYLE, GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);
  MyHide;
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
  sUrl:string;
begin
  sUrl:=ExtractFileName(StringReplace(url, '/', '\', [rfReplaceAll]));
  if Pos('main.htm', sUrl) = 0 then Cancel:=true;

  if sUrl = 'main.htm#rm' then begin
    WebView.OleObject.Document.getElementById('items').innerHTML:='';
    Notifications.Clear;
    Notifications.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notifications.txt');
  end;
end;

procedure TMain.WebViewDocumentComplete(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
var
  sUrl:string;
begin
  if pDisp = (Sender as TWebBrowser).Application then begin
    sUrl:=ExtractFileName(StringReplace(url, '/', '\', [rfReplaceAll]));
    if sUrl = 'main.htm' then begin
      Application.ProcessMessages;
      if WebView.Document <> nil then begin
        WebView.OleObject.Document.getElementById('items').innerHTML:=Notifications.Text;
        WebView.OleObject.Document.getElementById('title').innerHTML:=ID_NOTIFICATIONS;
        WebView.OleObject.Document.getElementById('clear_btn').innerHTML:='<a onclick="document.location=''#rm'';">' + ID_DELETE_ALL + '</a>';
      end;
      Caption:='Notification center';
    end;
  end;
end;

function MyTime: string;
begin
  Result:=Copy(TimeToStr(Time), 1, 5);
  if Result[Length(Result)] = ':' then
    Result:=Copy(Result, 1, Length(Result) - 1);
end;

procedure TMain.WMCopyData(var Msg: TWMCopyData);
var
  NotifyMsg, NotifyTitle, Desc, DescSub, BigIcon, SmallIcon, NotifyColor: string;
begin
  if Copy(PChar(TWMCopyData(Msg).CopyDataStruct.lpData), 1, 7) = 'NOTIFY ' then begin

    IconIndex:=1;
    Tray(3);

    NotifyMsg:=PChar(TWMCopyData(Msg).CopyDataStruct.lpData);
    Delete(NotifyMsg, 1, 8);

    NotifyTitle:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"', NotifyMsg) + 2);

    if Pos(NotifyTitle, ExcludeList.Text) > 0 then Exit;

    Desc:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"', NotifyMsg) + 2);

    DescSub:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"',NotifyMsg) + 2);

    BigIcon:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"',NotifyMsg) + 2);

    SmallIcon:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"', NotifyMsg) + 2);

    NotifyColor:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg)-1);

    if BigIcon = 'null' then BigIcon:='sys.png';
    if SmallIcon <> 'null' then BigIcon:=SmallIcon;

    if (Desc <> 'null') and (DescSub <> 'null') then Desc:=Desc + ' - ' + DescSub;
    if (Desc = 'null') and (DescSub <> 'null') then Desc:=DescSub;
    if (Desc = 'null') and (DescSub = 'null') then Desc:='';

    if NotifyTitle = 'null' then
      NotifyTitle:=ID_UNKNOWN_APP;

    if NotifyColor <> 'null' then begin
      case NotifyColor[1] of
        '0': NotifyColor:='#00acee';
        '1': NotifyColor:='#235d82';
        '2': NotifyColor:='#018399';
        '3': NotifyColor:='#008a00';
        '4': NotifyColor:='#5133ab';
        '5': NotifyColor:='#8b0094';
        '6': NotifyColor:='#ac193d';
        '7': NotifyColor:='#222222';
        end;
    end else NotifyColor:='gray';

    WebView.OleObject.Document.getElementById('items').innerHTML:='<div id="item"><div id="icon" style="background-color:' +
      NotifyColor + ';"><img src="' + BigIcon + '" /></div><div id="context"><div id="title">' +
      NotifyTitle + '</div><div id="clear"></div><div id="description">' + Desc +' </div></div><div id="time">' + MyTime + '<br>' +
      DateToStr(Date) + '</div></div>' + WebView.OleObject.Document.getElementById('items').innerHTML;
      
    Notifications.Text:=WebView.OleObject.Document.getElementById('items').innerHTML;
    Notifications.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notifications.txt');
  end;
  Msg.Result:=Integer(True);
end;

procedure TMain.WMActivate(var Msg: TMessage);
begin
  if Msg.WParam = WA_INACTIVE then
    MyHide;
  inherited;
end;

procedure TMain.FormDestroy(Sender: TObject);
var
  Ini: TIniFile;
begin
  Ini:=TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'Config.ini');
  Ini.WriteInteger('Main', 'NewMessages', IconIndex);
  Ini.Free;
  Notifications.Free;
  ExcludeList.Free;
  Tray(2);
  IconFull.Free;
end;

procedure TMain.DefaultHandler(var Message);
begin
  if TMessage(Message).Msg = WM_TASKBARCREATED then
    Tray(1);
  inherited;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  Application.MessageBox(PChar(Application.Title + ' 0.6.1' + #13#10
    + ID_LAST_UPDATE + ' 16.11.2018' + #13#10
    + 'http://r57zone.github.io' + #13#10 + 'r57zone@gmail.com'),
    PChar(AboutBtn.Caption), MB_ICONINFORMATION);
end;

procedure TMain.ExitBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMain.WMNCHITTEST(var Msg: TMessage);
begin
  Msg.Result:=HTCLIENT;
end;

end.
