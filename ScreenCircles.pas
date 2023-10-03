unit ScreenCircles;

interface

uses
  Windows, Messages, Graphics, Forms, Menus, ExtCtrls, Classes, Controls, Unit2;

type
  TForm1 = class(TForm)
    PaintBox1: TPaintBox;
    Timer1: TTimer;
    Paintbox_pMenu: TPopupMenu;
    Properties_pMenu: TMenuItem;
    Pause_pMenu: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure PaintBox1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Properties_pMenuClick(Sender: TObject);
    procedure Pause_pMenuClick(Sender: TObject);
    procedure PaintBox1DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    procedure HotKeys(var Message: TMessage); message WM_HOTKEY;
    procedure AppDeactivate(Sender: TObject);
    procedure AppActivate(Sender: TObject);
  end;

type
  TArr_Waves = array of array[1..5] of Integer; //1,2-координаты центра, 3-скорость (и направление) увеличения,4-размер,5-цвет

var
  Form1: TForm1;
  bmp: TBitmap;
  x_y: TPoint;
  ArrWaves: TArr_Waves;
  BG_Color: Integer = clBlack;

procedure ClearScreenBG(const ReturnClearStyle: Boolean = False);

implementation

{$R *.dfm}

procedure ClearScreenBG(const ReturnClearStyle: Boolean = False); //очищает экран
begin
  bmp.canvas.Brush.Color := BG_Color;
  bmp.Canvas.Brush.Style := bsSolid;
  bmp.Canvas.FillRect(Form1.ClientRect);
  if ReturnClearStyle then bmp.Canvas.Brush.Style := bsClear; //возвращать прозрачную заливку обратно
end;

procedure TForm1.AppDeactivate(Sender: TObject);
begin
  UnRegisterHotKey(Handle, 0);
  UnRegisterHotKey(Handle, 1);
  UnRegisterHotKey(Handle, 2);
end;

procedure TForm1.AppActivate(Sender: TObject);
begin //если надо Hotkey: Ctrl + Alt + <Любой символ или Shift, т.е. любая клавиша> и вызываем LoadDefaultConfig, то надо проверять ещё и нажатие ЛКМ
  RegisterHotKey(Handle, 0, MOD_CONTROL, Ord('P'));
  RegisterHotKey(Handle, 1, 0, 32); //Space - пауза
  RegisterHotKey(Handle, 2, 0, VK_F2);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  bmp := TBitmap.Create();
  bmp.Width := PaintBox1.Width - PaintBox1.Left;
  bmp.Height := PaintBox1.Height - PaintBox1.Top;
  ClearScreenBG();
  PaintBox1.ControlStyle := PaintBox1.ControlStyle + [csOpaque];
  DoubleBuffered := True;
  bmp.Canvas.Pen.Color := clWhite;
  bmp.Canvas.Font.Color := clWhite;
  bmp.Canvas.Font.Size := 16;
  bmp.Canvas.Font.Name := 'Times New Roman';
  bmp.Canvas.Font.Style := [fsBold];
  Application.OnDeactivate := AppDeactivate;
  Application.OnActivate := AppActivate;
  PaintBox1.Invalidate;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Draw(0, 0, bmp);
end;

procedure TForm1.PaintBox1Click(Sender: TObject);
begin
  Timer1.Enabled := True;
  SetLength(ArrWaves, Length(ArrWaves) + 1);
  GetCursorPos(x_y);
  x_y := PaintBox1.ScreenToClient(x_Y);
  ArrWaves[High(ArrWaves)][1] := x_y.X;
  ArrWaves[High(ArrWaves)][2] := x_y.Y;
  ArrWaves[High(ArrWaves)][3] := 1;
  ArrWaves[High(ArrWaves)][4] := 1;
  ArrWaves[High(ArrWaves)][5] := Random(16777200) + 16;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  i, k: Integer;
begin
  ClearScreenBG(True);
  for i := 0 to High(ArrWaves) do begin
    k := (ArrWaves[i][4] + ArrWaves[i][3] + (bmp.Canvas.Pen.Width div 2));
    if (k < 1) or ((ArrWaves[i][1] - k) < 1) or ((ArrWaves[i][2] - k) < 1) or
      ((ArrWaves[i][1] + k) > bmp.Width - 1) or ((ArrWaves[i][2] + k) > bmp.Height - 1) then
      ArrWaves[i][3] := -ArrWaves[i][3]; //если текущая координата центра+размер выходят за пределы экрана или размер станет меньше 1, то меняем направление скорости

    ArrWaves[i][5] := RGB(GetRValue(ArrWaves[i][5]) + ArrWaves[i][3], GetGValue(ArrWaves[i][5]) + ArrWaves[i][3], GetBValue(ArrWaves[i][5]) + ArrWaves[i][3]);
    bmp.Canvas.Pen.Color := ArrWaves[i][5];
    bmp.Canvas.Ellipse(ArrWaves[i][1] - ArrWaves[i][4], ArrWaves[i][2] - ArrWaves[i][4], ArrWaves[i][1] + ArrWaves[i][4], ArrWaves[i][2] + ArrWaves[i][4]);
    Inc(ArrWaves[i][4], (ArrWaves[i][3]));
  end;
  PaintBox1.Invalidate;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  bmp.Width := PaintBox1.Width;
  bmp.Height := PaintBox1.Height;
end;

procedure TForm1.Properties_pMenuClick(Sender: TObject);
begin
  Form2.Show();
end;

procedure TForm1.HotKeys(var Message: TMessage);
begin
  if (Message.WParam = 0) then Properties_pMenuClick(nil)
  else if (Message.WParam = 1) then Pause_pMenuClick(nil)
  else if (Message.WParam = 2) then Form2.SetProperties_btnClick(nil)
end;

procedure TForm1.Pause_pMenuClick(Sender: TObject);
begin
  if Timer1.Enabled then Timer1.Enabled := False
  else Timer1.Enabled := True
end;

procedure TForm1.PaintBox1DblClick(Sender: TObject);
begin
  PaintBox1.OnClick(nil);
  PaintBox1.OnClick(nil);
end;

end.

