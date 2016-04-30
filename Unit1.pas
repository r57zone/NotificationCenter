unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, OleCtrls, SHDocVw, MSHTML, ShellAPI, StdCtrls;

type
  TForm1 = class(TForm)
    WebBrowser1: TWebBrowser;
    procedure FormCreate(Sender: TObject);
    procedure WebBrowser1BeforeNavigate2(Sender: TObject;
      const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
      Headers: OleVariant; var Cancel: WordBool);
    procedure WebBrowser1DocumentComplete(Sender: TObject;
      const pDisp: IDispatch; var URL: OleVariant);
    procedure FormClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    procedure WMCopyData(var Msg: TWMCopyData); message WM_COPYDATA;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure IconMouse(var msg:TMessage); message WM_USER+1;
    procedure WMActivate(var msg:TMessage); message WM_ACTIVATE;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Notifications,ExcludeList:TStringList;

implementation

{$R *.dfm}

procedure MyShow;
begin
  Form1.Left:=Screen.Width-Form1.Width-15;
  Form1.Top:=Screen.Height-Form1.Height-57;
  Application.ProcessMessages;
  if Form1.WebBrowser1.Document <> nil then (Form1.Webbrowser1.Document as IHTMLDocument2).ParentWindow.Focus;
end;

procedure MyHide;
begin
  Form1.Left:=Screen.Width+Form1.Width;
  Form1.Top:=Screen.Height+Form1.Height;
end;

procedure Tray(n:integer);
var
  nim:TNotifyIconData;
begin
//1 - добавить, 2 - удалить, 3 - заменить
with nim do begin
  cbsize:=sizeof(nim);
  wnd:=Form1.handle;
  uid:=1;
  uflags:=nif_icon or nif_message or nif_tip;
  hicon:=application.icon.handle;
  ucallbackmessage:=wm_user+1;
  StrPCopy(szTip,Application.Title);
  end;
  case n of
    1: Shell_NotifyIcon(nim_add,@nim);
    2: Shell_NotifyIcon(nim_delete,@nim);
    3: Shell_NotifyIcon(nim_modify,@nim);
  end;
end;

procedure TForm1.IconMouse(var msg: TMessage);
begin
  case msg.lparam of
    wm_lbuttonup: if (Left=Screen.Width+Width) and (Top=Screen.Height+Height) then MyShow else MyHide;

    wm_rbuttonup:
      begin
        SetForegroundWindow(Application.Handle);
        case MessageBox(Handle,'Закрыть приложение',PChar(Application.Title),35) of
          6: close;
        end;
      end;
  end;
end;

procedure TForm1.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := WS_POPUP or WS_THICKFRAME;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Application.Title:='Центр уведомлений';
  WebBrowser1.Silent:=true;
  WebBrowser1.Navigate(ExtractFilePath(ParamStr(0))+'main.htm');
  tray(1);
  SetWindowLong(Application.Handle, GWL_EXSTYLE,GetWindowLong(Application.Handle, GWL_EXSTYLE) or WS_EX_TOOLWINDOW);
  MyHide;
  Notifications:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0))+'Notifications.txt') then
  Notifications.LoadFromFile(ExtractFilePath(ParamStr(0))+'Notifications.txt');
  ExcludeList:=TStringList.Create;
  if FileExists(ExtractFilePath(ParamStr(0))+'Exclude.txt') then
  ExcludeList.LoadFromFile(ExtractFilePath(ParamStr(0))+'Exclude.txt');
end;

procedure TForm1.WebBrowser1BeforeNavigate2(Sender: TObject;
  const pDisp: IDispatch; var URL, Flags, TargetFrameName, PostData,
  Headers: OleVariant; var Cancel: WordBool);
var
  sUrl:string;
begin
  sUrl:=ExtractFileName(StringReplace(url,'/','\',[rfReplaceAll]));
  if pos('main.htm',sUrl)=0 then Cancel:=true;

  if sUrl='main.htm#1' then begin
    WebBrowser1.OleObject.Document.getElementById('items').innerHTML:='';
    Notifications.Clear;
    Notifications.SaveToFile(ExtractFilePath(ParamStr(0))+'Notifications.txt');
  end;
end;

procedure TForm1.WebBrowser1DocumentComplete(Sender: TObject;
  const pDisp: IDispatch; var URL: OleVariant);
var
  sUrl:string;
begin
  if pDisp=(Sender as TWebBrowser).Application then begin
    sUrl:=ExtractFileName(StringReplace(url,'/','\',[rfReplaceAll]));
    if sUrl='main.htm' then begin
      Application.ProcessMessages;
      if WebBrowser1.Document <> nil then WebBrowser1.OleObject.Document.getElementById('items').innerHTML:=Notifications.Text;
    end;
  end;
end;

procedure TForm1.WMCopyData(var Msg: TWMCopyData);
var
a_notify,a_title,a_desc,a_desc_sub,p_img,p_img2,a_color:String;
begin
  if copy(PChar(TWMCopyData(Msg).CopyDataStruct.lpData),1,7)='NOTIFY ' then begin
    a_notify:=PChar(TWMCopyData(Msg).CopyDataStruct.lpData);
    delete(a_notify,1,8);

    a_title:=copy(a_notify,1,pos('"',a_notify)-1);
    delete(a_notify,1,pos('"',a_notify)+2);

    if (a_title<>'null') and (pos(a_title,ExcludeList.Text)>0) then Exit;

    a_desc:=copy(a_notify,1,pos('"',a_notify)-1);
    delete(a_notify,1,pos('"',a_notify)+2);

    a_desc_sub:=copy(a_notify,1,pos('"',a_notify)-1);
    delete(a_notify,1,pos('"',a_notify)+2);

    p_img:=copy(a_notify,1,pos('"',a_notify)-1);
    delete(a_notify,1,pos('"',a_notify)+2);

    p_img2:=copy(a_notify,1,pos('"',a_notify)-1);
    delete(a_notify,1,pos('"',a_notify)+2);

    a_color:=copy(a_notify,1,pos('"',a_notify)-1);

    if (p_img<>'null') and (p_img2<>'null') then p_img:=p_img2;
    if (p_img<>'null') and (p_img2='null') then p_img:=p_img;
    if (p_img='null') and (p_img2<>'null') then p_img:=p_img2;
    if (p_img='null') and (p_img2='null') then p_img:='sys.png';

    if (a_desc<>'null') and (a_desc_sub<>'null') then a_desc:=a_desc+' '+a_desc_sub;
    if (a_desc<>'null') and (a_desc_sub='null') then a_desc:=a_desc;
    if (a_desc='null') and (a_desc_sub<>'null') then a_desc:=a_desc_sub;
    if (a_desc='null') and (a_desc_sub='null') then a_desc:='';

    if a_title='null' then a_title:='Неизвестное приложение';

    if a_color<>'null' then begin
    case a_color[1] of
      '0': a_color:='#00acee';
      '1': a_color:='#235d82';
      '2': a_color:='#018399';
      '3': a_color:='#008a00';
      '4': a_color:='#5133ab';
      '5': a_color:='#8b0094';
      '6': a_color:='#222222';
      end; end else a_color:='gray';

    WebBrowser1.OleObject.Document.getElementById('items').innerHTML:='<div id="item"><div id="icon" style="background-color:'+a_color+';"><img src="'+p_img+'" /></div><div id="context"><div id="title">'+a_title+'</div><div id="clear"></div><div id="description">'+a_desc+'</div></div><div id="time">'+copy(TimeToStr(Time),1,5)+'</div></div>'+WebBrowser1.OleObject.Document.getElementById('items').innerHTML;
    Notifications.Text:=WebBrowser1.OleObject.Document.getElementById('items').innerHTML;
    Notifications.SaveToFile(ExtractFilePath(ParamStr(0))+'Notifications.txt');
  end;
  Msg.Result:=Integer(True);
end;

procedure TForm1.FormClick(Sender: TObject);
begin
Application.MessageBox('Центр уведомлений 0.3'+#13#10+'https://github.com/r57zone'+#13#10+'Последнее обновление: 28.04.2016','О программе...',0);
end;

procedure TForm1.WMActivate(var msg: TMessage);
begin
if Msg.WParam=WA_INACTIVE then MyHide;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Notifications.Free;
  ExcludeList.Free;
  tray(2);
end;

end.
