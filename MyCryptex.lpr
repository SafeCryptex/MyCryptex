program MyCryptex;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, main, inputkey, crypto, outFile, Progress, LanguageUnit
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Title:='My Cryptex';
  Application.Initialize;
  Application.CreateForm(TmainForm, mainForm);
  Application.CreateForm(TinputkeyForm, inputkeyForm);
  Application.CreateForm(ToutFileForm, outFileForm);
  Application.CreateForm(TProgressForm, ProgressForm);
  Application.Run;
end.

