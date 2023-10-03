program ScreenCircles_creator;

uses
  Forms,
  ScreenCircles in 'ScreenCircles.pas' {Form1},
  Unit2 in 'Unit2.pas' {Form2};

{$R *.res}  
{$SetPEFlags $20} //можно использовать >2Gb

begin
  Application.Initialize;
  Application.Title := 'Разноцветные круги по экрану';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
