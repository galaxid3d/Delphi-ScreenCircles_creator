unit Unit2;

interface

uses
  Windows, SysUtils, Forms, Menus, ExtCtrls, Controls, Classes, Dialogs,
  StdCtrls, Spin, IniFiles, Messages, ShellAPI, UFileCatcher;

type
  TForm2 = class(TForm)
    EdgeThickness_spEdt: TSpinEdit;
    EdgeThickness_lbl: TLabel;
    SetProperties_btn: TButton;
    Program_menu: TMainMenu;
    Configuration_menu: TMenuItem;
    LoadCnfg_menu: TMenuItem;
    SaveCnfg_menu: TMenuItem;
    LoadCnfg_openDlg: TOpenDialog;
    SaveCnfg_SaveDlg: TSaveDialog;
    TimeInterval_spEdt: TSpinEdit;
    TimeInterval_lbl: TLabel;
    BG_Color_ColorDlg: TColorDialog;
    BG_Color_lbl: TLabel;
    BG_Color_pnl: TPanel;
    procedure EdgeThickness_spEdtKeyPress(Sender: TObject; var Key: Char);
    procedure ValidSpinnerValue(Sender: TObject);
    procedure SetProperties_btnClick(Sender: TObject);
    procedure LoadCnfg_menuClick(Sender: TObject);
    procedure SaveCnfg_menuClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure BG_Color_pnlClick(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure BG_Color_lblClick(Sender: TObject);
    procedure TimeInterval_spEdtClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure DropFiles(var Msg: TWMDropFiles); message WM_DROPFILES; //перетаскивание файла настроек на форму
  end;

var
  Form2: TForm2;

implementation

uses ScreenCircles;

{$R *.dfm}

procedure LabelsColorize(const Color: Integer);
var
  i: Integer;
begin
  for i := 0 to Form2.ComponentCount - 1 do
    if Form2.Components[i] is TLabel then (Form2.Components[i] as TLabel).Font.Color := Color
    else if Form2.Components[i] is TSpinEdit then (Form2.Components[i] as TSpinEdit).Font.Color := Color;
end;

procedure SaveLoadConfig(const path: string; const IsSave: Boolean = False; const Sender: TObject = nil); //сохраняет и загружает настройки из ini-файла
var
  iniCnfg: TIniFile;
  i: Integer;
begin
  iniCnfg := TIniFile.Create(path);
  with Form2 do begin
    if IsSave then begin
      iniCnfg.WriteInteger('Game', 'TimerInterval', TimeInterval_spEdt.Value);
      for i := 0 to 15 do iniCnfg.WriteString('Game', 'User_Color' + IntToStr(i), BG_Color_ColorDlg.CustomColors[i]);
      iniCnfg.WriteInteger('Game', 'BG_Color', ScreenCircles.BG_Color);
      iniCnfg.WriteInteger('Game', 'LabelsColor', BG_Color_lbl.Font.Color);
      iniCnfg.WriteInteger('Visual', 'EdgeThickness', EdgeThickness_spEdt.Value);
      SetProperties_btnClick(nil); end
    else begin
      if (Sender = nil) or (Sender = TimeInterval_spEdt) then TimeInterval_spEdt.Value := iniCnfg.ReadInteger('Game', 'TimerInterval', 45);
      if (Sender = nil) or (Sender = EdgeThickness_spEdt) then EdgeThickness_spEdt.Value := iniCnfg.ReadInteger('Visual', 'EdgeThickness', 1);
      if (Sender = nil) or (Sender = BG_Color_pnl) then begin
        BG_Color_pnl.Color := iniCnfg.ReadInteger('Game', 'BG_Color', $0020020D);
        Form2.Color := BG_Color;
        ScreenCircles.ClearScreenBG(True); end;
      if (Sender = nil) or (Sender = BG_Color_lbl) then LabelsColorize(iniCnfg.ReadInteger('Game', 'LabelsColor', $0000CECE));
      if (Sender = nil) then BG_Color_ColorDlg.CustomColors.Clear();
      if (Sender = nil) then for i := 0 to 15 do BG_Color_ColorDlg.CustomColors.Add(iniCnfg.ReadString('Game', 'User_Color' + IntToStr(i), 'Color' + Chr(65 + i) + '=FFFFFFFF'));
    end
  end;
end;

function LoadDefaultConfig(const Sender: TObject): Boolean; //Если нажали Ctrl+Alt по параметру то загружает значение по умолчанию
begin
  Result := (GetKeyState(VK_CONTROL) < 0) and (GetKeyState(VK_MENU) < 0);
  if Result then
    if (GetKeyState(VK_SHIFT) < 0) then with Form2 do begin
        FormDeactivate(nil);
        Form1.AppDeactivate(nil);
        if LoadCnfg_openDlg.Execute then
          SaveLoadConfig(LoadCnfg_openDlg.FileName, False, Sender);
        Form1.AppActivate(nil); end
    else SaveLoadConfig('', False, Sender);
end;

procedure TForm2.EdgeThickness_spEdtKeyPress(Sender: TObject; var Key: Char);
begin
  if ((GetKeyState(VK_CONTROL) < 0) and (Key = #1)) then (Sender as TSpinEdit).SelectAll(); //Ctrl+A
  if not ((GetKeyState(VK_CONTROL) < 0) and (key in [#26, #24, #3, #22])) and //можно использовать hotkeys: Ctrl+Z/X/C/V
    not (key in ['0'..'9']) and (Key <> #8) then key := #0 //ввод только цифр и Backspace
end;

procedure TForm2.ValidSpinnerValue(Sender: TObject);
var
  i: Integer;
  spEdt: TSpinEdit;
begin
  spEdt := Sender as TSpinEdit;
  if not TryStrToInt(spEdt.Text, i) then spEdt.Value := spEdt.MinValue;
  if i < spEdt.MinValue then spEdt.Value := spEdt.MinValue;
  if i > spEdt.MaxValue then spEdt.Value := spEdt.MaxValue
end;

procedure TForm2.SetProperties_btnClick(Sender: TObject);
begin
  Form2.Close();
  ScreenCircles.bmp.Canvas.Pen.Width := EdgeThickness_spEdt.Value;
  Form1.Timer1.Interval := TimeInterval_spEdt.Value;
  ScreenCircles.BG_Color := BG_Color_pnl.Color;
  Form2.Color := BG_Color;
end;

procedure TForm2.LoadCnfg_menuClick(Sender: TObject);
begin
  FormDeactivate(nil);
  Form1.AppDeactivate(nil);
  if DirectoryExists(ExtractFilePath(LoadCnfg_openDlg.FileName)) then
    LoadCnfg_openDlg.InitialDir := ExtractFilePath(LoadCnfg_openDlg.FileName);
  if LoadCnfg_openDlg.Execute then begin
    SaveLoadConfig(LoadCnfg_openDlg.FileName);
    Form2.SetProperties_btnClick(nil);
  end;
  Form1.AppActivate(nil);
end;

procedure TForm2.SaveCnfg_menuClick(Sender: TObject);
begin
  FormDeactivate(nil);
  Form1.AppDeactivate(nil);
  if DirectoryExists(ExtractFilePath(SaveCnfg_SaveDlg.FileName)) then
    SaveCnfg_SaveDlg.InitialDir := ExtractFilePath(SaveCnfg_SaveDlg.FileName);
  if SaveCnfg_SaveDlg.Execute then SaveLoadConfig(SaveCnfg_saveDlg.FileName, True);
  Form1.AppActivate(nil);
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  DoubleBuffered := True;
  SaveCnfg_SaveDlg.FileName := ExtractFilePath(Application.ExeName) + 'ScreenCircles_creator_Default.ini';
  LoadCnfg_openDlg.FileName := ExtractFilePath(Application.ExeName) + 'ScreenCircles_creator_Default.ini';
  SaveLoadConfig((ExtractFilePath(Application.ExeName) + 'ScreenCircles_creator_Default.ini'));
  DragAcceptFiles(Self.Handle, True); //форма может принимать файлы
  ScreenCircles.bmp.Canvas.Pen.Width := EdgeThickness_spEdt.Value;
  bmp.Canvas.Font.Color := BG_Color_lbl.Font.Color;
  bmp.Canvas.TextOut((bmp.Width div 2) -
    (bmp.Canvas.TextWidth('Для старта программы нажмите ЛКМ') div 2), (bmp.Height
    div 2) - 20, 'Для старта программы нажмите ЛКМ');
  bmp.Canvas.TextOut((bmp.Width div 2) -
    (bmp.Canvas.TextWidth('Затем Вы можете нажать ПКМ --> Установки --> Выбрав нужные установки, нажмите "Начать"') div 2), (bmp.Height div 2) + 20,
    'Затем Вы можете нажать ПКМ --> Установки --> Выбрав нужные установки, нажмите "Начать"');
end;

procedure TForm2.BG_Color_pnlClick(Sender: TObject);
begin
  if LoadDefaultConfig(Sender) then Exit;
  BG_Color_ColorDlg.Color := BG_Color_pnl.Color;
  if BG_Color_ColorDlg.Execute then BG_Color_pnl.Color := BG_Color_ColorDlg.Color;
end;

procedure TForm2.DropFiles(var Msg: TWMDropFiles); //перетаскивание файла настроек на форму
var
  i: Integer;
  Catcher: TFileCatcher;
begin
  inherited;
  Catcher := TFileCatcher.Create(Msg.Drop);
  try
    if Catcher.FileCount > 0 then //т.к. нам не нужно загружать все файлы, то загрузится только первый
      for i := 0 to Pred(Catcher.FileCount) do
        if LowerCase(ExtractFileExt(Catcher.Files[i])) = '.ini' then begin
          SaveLoadConfig(Catcher.Files[i]);
          SetProperties_btnClick(nil);
          Break; end;
  finally Catcher.Free;
  end;
  Msg.Result := 0;
end;

procedure TForm2.FormDeactivate(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to Form2.ComponentCount - 1 do
    if Components[i] is TSpinEdit then (Components[i] as TSpinEdit).OnExit(Components[i] as TObject)
end;

procedure TForm2.BG_Color_lblClick(Sender: TObject);
begin
  if LoadDefaultConfig(Sender) then Exit;
  BG_Color_ColorDlg.Color := (Sender as TLabel).Font.Color;
  if BG_Color_ColorDlg.Execute then LabelsColorize(BG_Color_ColorDlg.Color)
end;

procedure TForm2.TimeInterval_spEdtClick(Sender: TObject);
begin
  LoadDefaultConfig(Sender);
end;

end.

