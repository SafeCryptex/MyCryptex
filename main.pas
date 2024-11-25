unit main;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF UNIX}
  cwstring,
  {$ENDIF}
  {$IFDEF WINDOWS}
  Windows,
  {$ENDIF}
  Progress, LCLType, LConvEncoding, LazUTF8, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, outFile, FileUtil,
  ExtCtrls, ComCtrls, StdCtrls, Buttons, Menus, inputkey, crypto, inifiles, LanguageUnit, LCLIntf;

const
  version = '1.00 (24.1125)';

type
  TEncryptThread = class(TThread)
  private
    FPlainText, FFilepath, FPassword, FHint: string;
    Fno_password_check: boolean;
    Fencryption_grade: integer;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const APlainText, AFilepath, APassword, AHint: string; Ano_password_check: boolean; Aencryption_grade: integer);
    property Success: Boolean read FSuccess;
  end;

type
  TDecryptThread = class(TThread)
  private
    FFilepath, FPassword, FHint, FPlaintext: string;
    FintNo_password_check: integer;
    FSuccess: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(const AFilepath, APassword, AHint: string);
    property Filepath: string read FFilepath;
    property Password: string read FPassword;
    property Hint: string read FHint;
    property Plaintext: string read FPlaintext;
    property intNo_password_check: integer read FintNo_password_check;
    property Success: Boolean read FSuccess;
  end;

type

  { TmainForm }

  TmainForm = class(TForm)
    btnClr: TBitBtn;
    btnEnc: TBitBtn;
    btnDec: TBitBtn;
    ImageList1: TImageList;
    Label1: TLabel;
    MainMenu1: TMainMenu;
    menuFile: TMenuItem;
    menuAbout: TMenuItem;
    menuEncryptFile: TMenuItem;
    menuDecryptFile: TMenuItem;
    menuDecryptPy: TMenuItem;
    menuLanguage: TMenuItem;
    menuSearch: TMenuItem;
    Separator1: TMenuItem;
    menuOpen: TMenuItem;
    menuSave: TMenuItem;
    menuClear: TMenuItem;
    menuTools: TMenuItem;
    menuExit: TMenuItem;
    menuHelp: TMenuItem;
    menuWebsite: TMenuItem;
    mm: TMemo;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    Panel2: TPanel;
    SaveDialog1: TSaveDialog;
    StatusBar1: TStatusBar;
    procedure btnClrClick(Sender: TObject);
    procedure btnDecClick(Sender: TObject);
    procedure btnEncClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure menuDecryptFileClick(Sender: TObject);
    procedure menuEncryptFileClick(Sender: TObject);
    procedure menuExitClick(Sender: TObject);
    procedure menuAboutClick(Sender: TObject);
    procedure menuDecryptPyClick(Sender: TObject);
    procedure menuSearchClick(Sender: TObject);
    procedure menuWebsiteClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    pswHint, Password, currentFile:string;
    LastSearchText: string;
    EncryptThread: TEncryptThread;
    DecryptThread: TDecryptThread;
    procedure OnEncryptTerminate(Sender: TObject);
    procedure OnDecryptTerminate(Sender: TObject);
    procedure OpenFile(Filepath: string);
    procedure SearchMemoText(SearchStr: string);
    procedure LoadLanguagesToMenu;
    procedure LanguageMenuItemClick(Sender: TObject);
    procedure SetCurrentLanguage;
  public

  end;

var
  mainForm: TmainForm;

implementation

{$R *.lfm}

constructor TEncryptThread.Create(const APlainText, AFilepath, APassword, AHint: string; Ano_password_check: boolean; Aencryption_grade: integer);
begin
  inherited Create(True);
  FPlainText := APlainText;
  FFilepath := AFilepath;
  FPassword := APassword;
  FHint := AHint;
  Fno_password_check := Ano_password_check;
  Fencryption_grade := Aencryption_grade;
end;

procedure TEncryptThread.Execute;
begin
  FSuccess := WriteEncryptedData(FPlainText, FFilepath, FPassword, FHint, Fno_password_check, Fencryption_grade);
end;

constructor TDecryptThread.Create(const AFilepath, APassword, AHint: string);
begin
  inherited Create(True);
  FFilepath := AFilepath;
  FPassword := APassword;
  FHint := AHint;
end;

procedure TDecryptThread.Execute;
begin
  FSuccess := ReadEncryptedData(FFilepath, FPassword, FPlaintext, FintNo_password_check);
end;

{ TmainForm }

procedure TmainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Shift = [ssCtrl]) and (Key = VK_F) then
  begin
    SearchMemoText('');
    Key := 0;
  end
  else if Key = VK_F3 then
  begin
    if LastSearchText<>'' then SearchMemoText(LastSearchText);
    Key := 0;
  end;
end;

procedure TmainForm.btnEncClick(Sender: TObject);
var
  Filepath: string;
begin
  mm.Text:=trim(mm.Text);
  if mm.Text='' then
  begin
   mm.Color :=clred;
   Application.MessageBox(pchar(LanguageStrings.cannt_empty),pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
   mm.SetFocus;
   mm.Color :=clWindow;
   exit;
  end;
  inputkeyForm := TinputkeyForm.Create(Self);
  inputkeyform.edthint.Text:=pswHint;
  inputkeyform.Password:=Password;
  //inputkeyform.edtkey.Text:=Password;
  if inputkeyForm.showModal = mrOK then
  begin
    pswHint:=inputkeyform.edthint.Text;
    Password:=inputkeyForm.edtkey.Text;
    SaveDialog1.Filter := '*.cptx|*.cptx';
    if not SaveDialog1.Execute then exit;
    Filepath := SaveDialog1.FileName;
    if Filepath <> '' then
      if LowerCase(ExtractFileExt(Filepath)) <> '.cptx' then
        Filepath := Filepath + '.cptx';
    if FileExists(Filepath) and (Filepath <> currentFile) then
      if Application.MessageBox(pchar(LanguageStrings.file_exists),pchar(Caption), WS_EX_APPWINDOW + MB_OKCancel + MB_ICONWARNING + MB_DEFBUTTON1) <> IDOK then
        exit;

    if EncryptThread <> nil then exit;
    ProgressForm := TProgressForm.Create(Self);
    ProgressForm.Label1.Caption:=LanguageStrings.encryption_being_processed;
    ProgressForm.Caption:=LanguageStrings.Encryption;
    ProgressForm.Show;
    EncryptThread := TEncryptThread.Create(mm.Text, Filepath, Password, pswHint, inputkeyForm.isNo_password_check.Checked, inputkeyForm.RadioGroup_encgrade.ItemIndex);
    EncryptThread.FreeOnTerminate := True;
    EncryptThread.OnTerminate := @OnEncryptTerminate;
    EncryptThread.Start;
    currentFile:=Filepath;
    StatusBar1.Panels[1].Text:=LanguageStrings.current_file+' '+currentFile;
  end;

end;

procedure TmainForm.SetCurrentLanguage;
begin
  with LanguageStrings do
  begin
    Application.Title:=AppTitle;
    Caption:=AppTitle;
    btnEnc.caption:=Save;
    btnDec.caption:=Open;
    btnClr.caption:=Clear;
    menuFile.Caption:=aFile;
    menuOpen.Caption:=Open;
    menuSave.Caption:=Save;
    menuClear.Caption:=Clear;
    menuTools.Caption:=Tools;
    menuDecryptPy.Caption:=DecryptPy;
    menuEncryptFile.Caption:=EncryptFile;
    menuDecryptFile.Caption:=DecryptFile;
    menuSearch.Caption:=Search;
    //menuLanguage.Caption:=Language;
    menuHelp.Caption:=Help;
    menuWebsite.Caption:=Website;
    menuAbout.Caption:=About;
    menuExit.Caption:=Exit;
  end;
end;

procedure TMainForm.LoadLanguagesToMenu;
var
  IniFile: TIniFile;
  Sections: TStringList;
  MenuItem: TMenuItem;
  i: Integer;
begin
  IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName)+'languages.ini');
  try
    Sections := TStringList.Create;
    try
      IniFile.ReadSections(Sections);
      for i := 0 to Sections.Count - 1 do
      begin
        if Sections[i] <> 'General' then
        begin
          MenuItem := TMenuItem.Create(menuLanguage);
          MenuItem.Caption := IniFile.ReadString(Sections[i], 'LocalLanguage', Sections[i]);
          MenuItem.Hint := Sections[i];
          MenuItem.OnClick := @LanguageMenuItemClick;
          menuLanguage.Add(MenuItem);
        end;
      end;
      LoadLanguageStrings(IniFile.ReadString('General', 'Default', 'English'));
      SetCurrentLanguage;
    finally
      Sections.Free;
    end;
  finally
    IniFile.Free;
  end;
end;

procedure TMainForm.LanguageMenuItemClick(Sender: TObject);
var
  IniFile: TIniFile;
begin
  if Sender is TMenuItem then
  begin
    LoadLanguageStrings((Sender as TMenuItem).Hint);
    SetCurrentLanguage;
    IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName)+'languages.ini');
    try
      IniFile.WriteString('General', 'Default', (Sender as TMenuItem).Hint);
    finally
      IniFile.Free;
    end;
  end;
end;

procedure TmainForm.FormCreate(Sender: TObject);
begin
  LoadLanguagesToMenu;
  KeyPreview := True;
  EncryptThread := nil;
  DecryptThread := nil;
end;

procedure TmainForm.FormShow(Sender: TObject);
begin
  if ParamStr(1) <> '' then OpenFile(ParamStr(1));
end;

procedure TmainForm.menuDecryptFileClick(Sender: TObject);
begin
  outFileForm:= ToutFileForm.Create(self);
  outFileForm.Caption:=LanguageStrings.FileDecryption;
  outFileForm.btnCrypt.Caption:=LanguageStrings.Decrypt;
  outFileForm.btnCrypt.ImageIndex:=0;
  outFileForm.isEncrypt:=False;
  outFileForm.Show;
end;

procedure TmainForm.menuEncryptFileClick(Sender: TObject);
begin
  outFileForm:= ToutFileForm.Create(self);
  outFileForm.Caption:=LanguageStrings.FileEncryption;
  outFileForm.btnCrypt.Caption:=LanguageStrings.Encrypt;
  outFileForm.btnCrypt.ImageIndex:=1;
  outFileForm.isEncrypt:=True;
  outFileForm.Show;
end;

procedure TmainForm.menuExitClick(Sender: TObject);
begin
  close;
end;

procedure TmainForm.menuAboutClick(Sender: TObject);
begin
  Application.MessageBox(pchar(LanguageStrings.AppTitle+' '+version+' Freeware, produced by SafeCrytex.'),pchar(LanguageStrings.About), WS_EX_APPWINDOW + MB_OK + MB_ICONQUESTION + MB_DEFBUTTON1);
end;

procedure TmainForm.menuDecryptPyClick(Sender: TObject);
var
  SourceFile, DestFile: string;
  Overwrite: Boolean;
begin
  OpenDialog1.Filter := '*.cptx,*.cptf|*.cptx;*.cptf';
  OpenDialog1.Options := [ofFileMustExist, ofHideReadOnly];
  if not OpenDialog1.Execute then exit;
  if OpenDialog1.FileName <> '' then
  begin
    DestFile := OpenDialog1.FileName;
    SourceFile := ExtractFilePath(Application.ExeName) + 'DecryptPy.py';
    DestFile := DestFile + '.py';
    if FileExists(DestFile) then
    begin
      Overwrite := MessageDlg(pchar(LanguageStrings.file_exists),
                              mtConfirmation, [mbYes, mbNo], 0) = mrYes;
      if not Overwrite then
        Exit;
    end;

    if CopyFile(SourceFile, DestFile) then
      MessageDlg(DestFile+' '+LanguageStrings.successfully_generated, mtInformation, [mbOK], 0)
    else
      MessageDlg(DestFile+' '+LanguageStrings.generation_failed, mtError, [mbOK], 0);
  end;
end;

procedure TmainForm.menuSearchClick(Sender: TObject);
begin
  SearchMemoText('');
end;

procedure TmainForm.SearchMemoText(SearchStr: string);
var
  SearchText: string;
  iPosition, StartPos: Integer;
begin
  if SearchStr<>'' then SearchText := SearchStr
  else SearchText := UTF8Encode(InputBox(LanguageStrings.search_text, LanguageStrings.enter_text_to_search, LastSearchText));

  if SearchText = '' then Exit;
  LastSearchText := SearchText;

  StartPos := mm.SelStart + mm.SelLength + 1;
  iPosition := UTF8Pos(UpperCase(SearchText), UpperCase(UTF8Encode(mm.Text)), StartPos);

  if iPosition = 0 then
  begin
    iPosition := UTF8Pos(UpperCase(SearchText), UpperCase(UTF8Encode(mm.Text)));
    if (iPosition > 0)  then
    begin
      mm.SelStart := iPosition - 1;
      mm.SelLength := UTF8Length(SearchText);
      mm.SetFocus;
    end
    else  ShowMessage('"'+SearchText+'" '+LanguageStrings.no_search_results);
  end
  else
  begin
    mm.SelStart := iPosition - 1;
    mm.SelLength := UTF8Length(SearchText);
    mm.SetFocus;
  end;
end;

procedure TmainForm.menuWebsiteClick(Sender: TObject);
begin
  OpenURL('http://www.SafeCrytex.com');
end;

procedure TmainForm.OpenFile(Filepath: string);
var
  newPassword, newHint, Ext, targetFile:ansistring;
  strHint: string;

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
  Ext := LowerCase(ExtractFileExt(Filepath));
  if Ext = '.cptx' then
  begin
    newHint:=ReadEncryptedHint(Filepath);
    if newHint<>'' then strHint:= '('+LanguageStrings.password_hint+': '+newHint+')'
    else strHint:='';
    if Filepath = currentFile then  newPassword:=Password;
    if InputQuery(LanguageStrings.Decryption, LanguageStrings.please_enter_password+#13+strHint, TRUE, newPassword) then
    begin
      if (newPassword<>'') then
      begin
        ProgressForm := TProgressForm.Create(Self);
        ProgressForm.Caption:=LanguageStrings.Decryption;
        ProgressForm.Label1.Caption:=LanguageStrings.Decryption_being_processed;
        ProgressForm.Show;
        DecryptThread := TDecryptThread.Create(Filepath, newPassword, newHint);
        DecryptThread.FreeOnTerminate := True;
        DecryptThread.OnTerminate := @OnDecryptTerminate;
        DecryptThread.Start;

      end else if ParamStr(1)<>'' then Close;
    end else if ParamStr(1)<>'' then Close;
  end
  else if Ext = '.cptf' then
  begin
     outFileForm:= ToutFileForm.Create(self);
     outFileForm.Caption:=LanguageStrings.FileDecryption;
     outFileForm.btnCrypt.Caption:=LanguageStrings.Decrypt;
     outFileForm.edtInputFile.Text:=Filepath;
     targetFile:=ExtractFileNameWithoutExt(Filepath);
     targetFile:=GenerateTargetFileName(targetFile);
     outFileForm.edtOutputFile.Text:=targetFile;
     outFileForm.btnCrypt.ImageIndex:=0;
     outFileForm.isEncrypt:=False;
     if ParamStr(1)='' then outFileForm.Show
     else if outFileForm.ShowModal<100 then Close;
  end
  else if (Ext = '.txt') or (Ext = '.csv') then
  begin
    Password:='';
    currentFile:='';
    pswHint:='';
    StatusBar1.Panels[1].Text:='';
    mm.Lines.LoadFromFile(Filepath);
  end
  else
  begin
     outFileForm:= ToutFileForm.Create(self);
     outFileForm.Caption:=LanguageStrings.FileEncryption;
     outFileForm.btnCrypt.Caption:=LanguageStrings.Encrypt;
     outFileForm.edtInputFile.Text:=Filepath;
     targetFile:=Filepath+'.cptf';
     targetFile:=GenerateTargetFileName(targetFile);
     outFileForm.edtOutputFile.Text:=targetFile;
     outFileForm.btnCrypt.ImageIndex:=1;
     outFileForm.isEncrypt:=True;
     if ParamStr(1)='' then outFileForm.Show
     else if outFileForm.ShowModal<100 then Close;
  end;
end;

procedure TmainForm.btnDecClick(Sender: TObject);
begin
  OpenDialog1.Filter := '*.cptx|*.cptx|*.cptf|*.cptf|*.*|*.*';
  OpenDialog1.Options := [ofFileMustExist, ofHideReadOnly];
  if not OpenDialog1.Execute then exit;
  if OpenDialog1.FileName <> '' then
  begin
    OpenFile(OpenDialog1.FileName);
    LastSearchText := '';
  end;
end;

procedure TmainForm.btnClrClick(Sender: TObject);
begin
  mm.clear;
  mm.SetFocus;
  Password:='';
  currentFile:='';
  pswHint:='';
  StatusBar1.Panels[1].Text:='';
  LastSearchText := '';
end;

procedure TmainForm.OnEncryptTerminate(Sender: TObject);
begin
  ProgressForm.SessionEnding:=True;
  ProgressForm.Close;
  if EncryptThread.Success then
    Application.MessageBox(pchar(LanguageStrings.successfully_encrypt),pchar(Caption), MB_ICONINFORMATION + MB_OK)
  else
    Application.MessageBox(pchar(LanguageStrings.faild_encrypt),pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
  EncryptThread := nil;
end;

procedure TmainForm.OnDecryptTerminate(Sender: TObject);
begin
  ProgressForm.SessionEnding:=True;
  ProgressForm.Close;
  if DecryptThread.Success then
  begin
    currentFile:=DecryptThread.Filepath;
    StatusBar1.Panels[1].Text:=LanguageStrings.current_file+' '+currentFile;
    mm.text:=DecryptThread.Plaintext;
    Password:=DecryptThread.Password;
    pswHint:=DecryptThread.Hint;
    if DecryptThread.intNo_password_check>0 then Application.MessageBox(pchar(LanguageStrings.decryption_done),pchar(Caption), MB_ICONINFORMATION + MB_OK);
  end
  else
    Application.MessageBox(pchar(LanguageStrings.wrong_password),pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
  DecryptThread := nil;
end;

end.

