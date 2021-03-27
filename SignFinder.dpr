program SignFinder;

uses
  Vcl.Forms,
  f_main in 'f_main.pas' {mainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TmainForm, mainForm);
  Application.Run;
end.
