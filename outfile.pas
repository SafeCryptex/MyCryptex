unit outFile;

{$mode ObjFPC}{$H+}

interface

uses
  {$IFDEF UNIX}
  cwstring,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  FileUtil, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons,
  StdCtrls, inputkey, Progress, crypto, LanguageUnit;

type
  TEncryptThread = class(TThread)
  private
    FInputFile, FOutputFile, FKey, FHint: string;
    Fno_password_check: boolean;
    Fencryption_grade: integer;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const AInputFile, AOutputFile, AKey, AHint: string; Ano_password_check: boolean; Aencryption_grade: integer);
    property Success: Boolean read FSuccess;
  end;

type
  TDecryptThread = class(TThread)
  private
    FInputFile, FOutputFile, FKey: string;
    FintNo_password_check: integer;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const AInputFile, AOutputFile, AKey: string);
    property intNo_password_check: integer read FintNo_password_check;
    property Success: Boolean read FSuccess;
  end;

type

  { ToutFileForm }

  ToutFileForm = class(TForm)
    btnSaveFile: TBitBtn;
    btnLoadFile: TBitBtn;
    btnCrypt: TBitBtn;
    edtInputFile: TLabeledEdit;
    edtOutputFile: TLabeledEdit;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    procedure btnLoadFileClick(Sender: TObject);
    procedure btnSaveFileClick(Sender: TObject);
    procedure btnCryptClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    pswHint, Password:string;
    ProgressForm: TProgressForm;
    EncryptThread: TEncryptThread;
    DecryptThread: TDecryptThread;
    procedure OnEncryptTerminate(Sender: TObject);
    procedure OnDecryptTerminate(Sender: TObject);
  public
    isEncrypt: boolean;

  end;

var
  outFileForm: ToutFileForm;

implementation

{$R *.lfm}

constructor TEncryptThread.Create(const AInputFile, AOutputFile, AKey, AHint: string; Ano_password_check: boolean; Aencryption_grade: integer);
begin
  inherited Create(True);
  FInputFile := AInputFile;
  FOutputFile := AOutputFile;
  FKey := AKey;
  FHint := AHint;
  Fno_password_check := Ano_password_check;
  Fencryption_grade := Aencryption_grade;
end;

procedure TEncryptThread.Execute;
begin
  FSuccess := EncryptFile(FInputFile, FOutputFile, FKey, FHint, Fno_password_check, Fencryption_grade);
end;

constructor TDecryptThread.Create(const AInputFile, AOutputFile, AKey: string);
begin
  inherited Create(True);
  FInputFile := AInputFile;
  FOutputFile := AOutputFile;
  FKey := AKey;
end;

procedure TDecryptThread.Execute;
begin
  FSuccess := DecryptFile(FInputFile, FOutputFile, FKey, FintNo_password_check);
end;

{ ToutFileForm }

procedure ToutFileForm.btnSaveFileClick(Sender: TObject);
var
  Filepath: string;
begin
  if isEncrypt then SaveDialog1.Filter := '*.cptf|*.cptf'
  else SaveDialog1.Filter := '*.*|*.*';
  if not SaveDialog1.Execute then exit;
  Filepath := SaveDialog1.FileName;
  if Filepath <> '' then
  begin
    if isEncrypt then if LowerCase(ExtractFileExt(Filepath)) <> '.cptf' then
      Filepath := Filepath + '.cptf';
    if FileExists(Filepath) then
      if Application.MessageBox(pchar(LanguageStrings.file_exists),pchar(Caption), WS_EX_APPWINDOW + MB_OKCancel + MB_ICONWARNING + MB_DEFBUTTON1) <> IDOK then
        exit;
    edtOutputFile.Text:=Filepath;
  end;
end;

procedure ToutFileForm.btnLoadFileClick(Sender: TObject);
var
  Filepath, str, Ext, targetFile:ansistring;

  function GenerateTargetFileName(const BaseName: string): string;
  var
    Path, targetExt: String;
    Count: Integer;
  begin
    Result := BaseName;
    if not FileExists(Result) then exit;
    Path := ExtractFileNameWithoutExt(BaseName);
    targetExt := ExtractFileExt(BaseName);
    Count := 1;
    while FileExists(Path + '(' + IntToStr(Count) + ')' + targetExt) do
      Inc(Count);
    Result := Path + '(' + IntToStr(Count) + ')' + targetExt;
  end;
begin
  if isEncrypt then OpenDialog1.Filter := '*.*|*.*'
  else OpenDialog1.Filter := '*.cptf|*.cptf';
  if not OpenDialog1.Execute then exit;
  Filepath := OpenDialog1.FileName;
  edtInputFile.Text := Filepath;
  if isEncrypt then
  begin
     targetFile:=Filepath+'.cptf';
     targetFile:=GenerateTargetFileName(targetFile);
     edtOutputFile.Text:=targetFile;
  end else
  begin
    targetFile:=ExtractFileNameWithoutExt(Filepath);
    targetFile:=GenerateTargetFileName(targetFile);
    outFileForm.edtOutputFile.Text:=targetFile;
  end;
end;

procedure ToutFileForm.btnCryptClick(Sender: TObject);
begin
  if not FileExists(edtInputFile.Text) then
  begin
    Application.MessageBox(pchar(LanguageStrings.file_not_exists),pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
    exit;
  end;
  if isEncrypt then
  begin
    if EncryptThread <> nil then exit;
    inputkeyForm := TinputkeyForm.Create(Self);
    inputkeyform.edthint.Text:=pswHint;
    inputkeyform.Password:=Password;
    if inputkeyForm.showModal = mrOK then
    begin
      pswHint:=inputkeyform.edthint.Text;
      Password:=inputkeyForm.edtkey.Text;
      ProgressForm := TProgressForm.Create(Self);
      ProgressForm.Label1.Caption:=LanguageStrings.encryption_being_processed;
      ProgressForm.Caption:=LanguageStrings.FileEncryption;
      ProgressForm.Show;
      EncryptThread := TEncryptThread.Create(edtInputFile.Text, edtOutputFile.Text, Password, pswHint, inputkeyForm.isNo_password_check.Checked, inputkeyForm.RadioGroup_encgrade.ItemIndex);
      EncryptThread.FreeOnTerminate := True;
      EncryptThread.OnTerminate := @OnEncryptTerminate;
      EncryptThread.Start;
    end;
  end
  else begin
    pswHint:=ReadEncryptedHint(edtInputFile.Text);
    if pswHint<>'' then pswHint:= '('+LanguageStrings.password_hint+': '+pswHint+')';
    if InputQuery(LanguageStrings.Decryption, LanguageStrings.please_enter_password+#13+pswHint, TRUE, Password) then
    if Password<>'' then
    begin
      ProgressForm := TProgressForm.Create(Self);
      ProgressForm.Caption:=LanguageStrings.FileDecryption;
      ProgressForm.Label1.Caption:=LanguageStrings.Decryption_being_processed;
      ProgressForm.Show;
      DecryptThread := TDecryptThread.Create(edtInputFile.Text, edtOutputFile.Text, Password);
      DecryptThread.FreeOnTerminate := True;
      DecryptThread.OnTerminate := @OnDecryptTerminate;
      DecryptThread.Start;
    end
    else Application.MessageBox(Pchar(LanguageStrings.password_cannot_empty), pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
  end;
end;

procedure ToutFileForm.FormCreate(Sender: TObject);
begin
  EncryptThread := nil;
  DecryptThread := nil;
    //outFileForm.Caption:='文件加密';
    //btnCrypt.Caption:='加密';
    edtInputFile.EditLabel.Caption:=LanguageStrings.inputfile;
    edtOutputFile.EditLabel.Caption:=LanguageStrings.outputfile;
end;

procedure ToutFileForm.OnEncryptTerminate(Sender: TObject);
begin
  ProgressForm.SessionEnding:=True;
  ProgressForm.Close;
  if EncryptThread.Success then
  begin
    Application.MessageBox(pchar(LanguageStrings.successfully_encrypt),pchar(Caption), MB_ICONINFORMATION + MB_OK);
    Close;
  end
  else
    Application.MessageBox(pchar(LanguageStrings.faild_encrypt),pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
    EncryptThread := nil;
end;

procedure ToutFileForm.OnDecryptTerminate(Sender: TObject);
begin
  ProgressForm.SessionEnding:=True;
  ProgressForm.Close;
  if DecryptThread.Success then
  begin
    if DecryptThread.intNo_password_check>0 then Application.MessageBox(pchar(LanguageStrings.decryption_done),pchar(Caption), MB_ICONINFORMATION + MB_OK)
    else Application.MessageBox(pchar(LanguageStrings.successfully_decrypt),pchar(Caption), MB_ICONINFORMATION + MB_OK);
    Close;
  end
  else
    Application.MessageBox(pchar(LanguageStrings.wrong_password),pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
    DecryptThread := nil;
end;

end.

