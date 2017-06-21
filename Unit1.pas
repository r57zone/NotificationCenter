unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OleCtrls, SHDocVw, MSHTML, ShellAPI, StdCtrls, ExtCtrls, XPMan,
  Menus;

type
  TMain = class(TForm)
    WebView: TWebBrowser;
    XPManifest1: TXPManifest;
    PopupMenu: TPopupMenu;
    AboutBtn: TMenuItem;
    N2: TMenuItem;
    ExitBtn: TMenuItem;
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
    procedure DefaultHandler(var Message); override;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure IconMouse(var Msg:TMessage); message WM_USER+1;
    procedure WMActivate(var Msg:TMessage); message WM_ACTIVATE;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Main: TMain;
  Notifications, ExcludeList: TStringList;
  DefLng: boolean;
  WM_TaskBarCreated: Cardinal;

implementation

{$R *.dfm}

procedure MyShow;
begin
  Main.Left:=Screen.Width - Main.Width-15;
  Main.Top:=Screen.Height - Main.Height-57;
  Application.ProcessMessages;
  if Main.WebView.Document <> nil then (Main.WebView.Document as IHTMLDocument2).ParentWindow.Focus;
end;

procedure MyHide;
begin
  Main.Left:=0 - Main.Width;
  Main.Top:=0 - Main.Height;
end;

procedure Tray(n:integer); //1 - добавить, 2 - удалить, 3 -  заменить
var
  nim: TNotifyIconData;
begin
  with nim do begin
    cbSize:=SizeOf(nim);
    wnd:=Main.Handle;
    uId:=1;
    uFlags:=nif_icon or nif_message or nif_tip;
    hIcon:=Application.Icon.Handle;
    uCallBackMessage:=WM_User + 1;
    StrCopy(szTip, PChar(Application.Title));
  end;
  case n of
    1: Shell_NotifyIcon(nim_add, @nim);
    2: Shell_NotifyIcon(nim_delete, @nim);
    3: Shell_NotifyIcon(nim_modify, @nim);
  end;
end;

procedure TMain.IconMouse(var Msg: TMessage);
begin
  case Msg.LParam of
    WM_LButtonDown:
      if (Left = 0 - Width) and (Top = 0 - Height) then
        MyShow else MyHide;

    WM_RButtonDown:
      PopupMenu.Popup(Mouse.CursorPos.X, Mouse.CursorPos.Y);
  end;
end;

procedure TMain.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style:=WS_POPUP or WS_THICKFRAME;
end;

function GetLocaleInformation(Flag: Integer): string;
var
  pcLCA: array [0..20] of Char;
begin
  if GetLocaleInfo(LOCALE_SYSTEM_DEFAULT, Flag, pcLCA, 19)<=0 then
    pcLCA[0]:=#0;
  Result:=pcLCA;
end;

procedure TMain.FormCreate(Sender: TObject);
begin
  WM_TaskBarCreated:=RegisterWindowMessage('TaskbarCreated');

  if GetLocaleInformation(LOCALE_SENGLANGUAGE) = 'Russian' then begin
    DefLng:=false;
    Application.Title:='Центр уведомлений';
  end else begin
    DefLng:=true;
    Application.Title:='Notification center';
    AboutBtn.Caption:='About...';
    ExitBtn.Caption:='Exit';
  end;

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

  if sUrl = 'main.htm#1' then begin
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
        if DefLng then begin
          WebView.OleObject.Document.getElementById('title').innerHTML:='Notifications';
          WebView.OleObject.Document.getElementById('clear_btn').innerHTML:='<a onclick="document.location=''#1'';">DELETE ALL</a>';
        end;
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
  NotifyMsg, NotifyTitle, Desc, DescSub, BigImage, SmallImage, NotifyColor: string;
begin
  if Copy(PChar(TWMCopyData(Msg).CopyDataStruct.lpData), 1, 7) = 'NOTIFY ' then begin
    NotifyMsg:=PChar(TWMCopyData(Msg).CopyDataStruct.lpData);
    Delete(NotifyMsg, 1, 8);

    NotifyTitle:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"', NotifyMsg) + 2);

    if Pos(NotifyTitle, ExcludeList.Text) > 0 then Exit;

    Desc:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"', NotifyMsg) + 2);

    DescSub:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"',NotifyMsg) + 2);

    BigImage:=Copy(NotifyMsg, 1, Pos('"', NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"',NotifyMsg) + 2);

    SmallImage:=Copy(NotifyMsg, 1, Pos('"',NotifyMsg) - 1);
    Delete(NotifyMsg, 1, Pos('"', NotifyMsg) + 2);

    NotifyColor:=Copy(NotifyMsg, 1, Pos('"',NotifyMsg)-1);

    if BigImage = 'null' then BigImage:='sys.png';
    if SmallImage <> 'null' then BigImage:=SmallImage;

    if (Desc <> 'null') and (DescSub <> 'null') then Desc:=Desc + ' - ' + DescSub;
    if (Desc = 'null') and (DescSub <> 'null') then Desc:=DescSub;
    if (Desc = 'null') and (DescSub = 'null') then Desc:='';

    if NotifyTitle = 'null' then
      if DefLng then NotifyTitle:='Unkwnon application'
        else NotifyTitle:='Неизвестное приложение';

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
      NotifyColor + ';"><img src="' + BigImage + '" /></div><div id="context"><div id="title">' +
      NotifyTitle + '</div><div id="clear"></div><div id="description">' + Desc +' </div></div><div id="time">' + MyTime + '<br>' +
      DateToStr(Date) + '</div></div>' + WebView.OleObject.Document.getElementById('items').innerHTML;
      
    Notifications.Text:=WebView.OleObject.Document.getElementById('items').innerHTML;
    Notifications.SaveToFile(ExtractFilePath(ParamStr(0)) + 'Notifications.txt');
  end;
  Msg.Result:=Integer(True);
end;

procedure TMain.WMActivate(var Msg: TMessage);
begin
  if Msg.WParam = WA_INACTIVE then MyHide;
end;

procedure TMain.FormDestroy(Sender: TObject);
begin
  Notifications.Free;
  ExcludeList.Free;
  Tray(2);
end;

procedure TMain.DefaultHandler(var Message);
begin
  if TMessage(Message).Msg = WM_TASKBARCREATED then Tray(1);
  inherited;
end;

procedure TMain.AboutBtnClick(Sender: TObject);
begin
  if DefLng then
      Application.MessageBox(PChar(Application.Title+ ' 0.4.3' + #13#10
      + 'Last update: 28.05.2017' + #13#10
      + 'http://r57zone.github.io' + #13#10 + 'r57zone@gmail.com'), 'About...',0)
  else
    Application.MessageBox(PChar(Application.Title+ ' 0.4.3' + #13#10
      + 'Последнеее обновление: 28.05.2017' + #13#10
      + 'http://r57zone.github.io' + #13#10 + 'r57zone@gmail.com'), 'О программе...',0);
end;

procedure TMain.ExitBtnClick(Sender: TObject);
begin
  Close;
end;

end.
