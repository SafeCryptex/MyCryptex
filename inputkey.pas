unit inputkey;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, LCLType, StdCtrls, ExtCtrls,
  Buttons, LanguageUnit;

type

  { TinputkeyForm }

  TinputkeyForm = class(TForm)
    Bevel1: TBevel;
    btnQuestion: TBitBtn;
    btncancel: TBitBtn;
    btnok: TBitBtn;
    btnhide: TSpeedButton;
    btnlook: TSpeedButton;
    edthint: TLabeledEdit;
    edtkey: TLabeledEdit;
    isNo_password_check: TCheckBox;
    Label1: TLabel;
    RadioGroup_encgrade: TRadioGroup;
    procedure btnQuestionClick(Sender: TObject);
    procedure btncancelClick(Sender: TObject);
    procedure btnhideClick(Sender: TObject);
    procedure btnlookClick(Sender: TObject);
    procedure btnokClick(Sender: TObject);
    procedure edtkeyChange(Sender: TObject);
    procedure edtkeyKeyPress(Sender: TObject; var Key: char);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    AllowClose: Boolean;
  public
    Password: string;
  end;

var
  inputkeyForm: TinputkeyForm;

implementation

{$R *.lfm}

{ TinputkeyForm }

procedure TinputkeyForm.btnhideClick(Sender: TObject);
begin
  btnhide.Visible:=false;
  btnlook.Visible:=true;
  edtkey.PasswordChar := #42;
end;

procedure TinputkeyForm.btncancelClick(Sender: TObject);
begin
  AllowClose := True;
end;

procedure TinputkeyForm.btnQuestionClick(Sender: TObject);
begin
  Application.MessageBox(pchar(LanguageStrings.TipsText),
    pchar(LanguageStrings.Tips), WS_EX_APPWINDOW + MB_OK + MB_ICONINFORMATION + MB_DEFBUTTON1);
end;

procedure TinputkeyForm.btnlookClick(Sender: TObject);
begin
  btnhide.Visible:=true;
  btnlook.Visible:=false;
  edtkey.PasswordChar := #0;
end;

procedure TinputkeyForm.btnokClick(Sender: TObject);
var
  confirmPassword: boolean;
  newPassword: string;
begin
  if Length(edtkey.Text) < 8 then
  begin
   edtkey.SetFocus;
   edtkey.Color :=clred;
   Application.MessageBox(pchar(LanguageStrings.password_length_less),pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
   AllowClose := False;
   exit;
  end;
  confirmPassword:=False;
  if (edtkey.Text=Password) or btnhide.Visible then confirmPassword:=true
  else if InputQuery(pchar(LanguageStrings.confirm_password), pchar(LanguageStrings.please_password_again), TRUE, newPassword) then
  begin
    if edtkey.Text=newPassword then confirmPassword:=true
    else Application.MessageBox(pchar(LanguageStrings.password_not_match),pchar(LanguageStrings.Err), WS_EX_APPWINDOW + MB_OK + MB_ICONWARNING + MB_DEFBUTTON1);
  end;
  AllowClose := confirmPassword;
end;

procedure TinputkeyForm.edtkeyChange(Sender: TObject);
var
      S:   WideString;
      I,   J:   Integer;
      vSelStart:   Integer;
  begin
      vSelStart   :=   TEdit(Sender).SelStart;
      S   :=   TEdit(Sender).Text;
      J   :=   0;
      for   I   :=   Length(S)   downto   1   do
          if   Length(string(S[I]))   >=   2   then
          begin
              if   vSelStart   <=   Length(string(Copy(S,   1,   I)))   then   Inc(J,   2);
              Delete(S,   I,   1);
          end;
      TEdit(Sender).Text   :=   S;
  end;

procedure TinputkeyForm.edtkeyKeyPress(Sender: TObject; var Key: char);
begin
if ((Ord(Key) > 32) and (Ord(Key) <= 126))  or (ord(Key)=8)then Exit;
  Key := #0;
end;

procedure TinputkeyForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := AllowClose;
end;

procedure TinputkeyForm.FormCreate(Sender: TObject);
begin
  //if util.LangisCn=true then
  begin
    inputkeyForm.Caption:=LanguageStrings.enter_password;
    Label1.Caption:=LanguageStrings.please_enter_hint_password;
    edthint.EditLabel.Caption:=LanguageStrings.Hint;
    edtkey.EditLabel.Caption:=LanguageStrings.Password;
    RadioGroup_encgrade.Caption:=LanguageStrings.encryption_strength;
    isNo_password_check.Caption:=LanguageStrings.bypass_password_check;
    RadioGroup_encgrade.Items[0]:=LanguageStrings.Fast;
    RadioGroup_encgrade.Items[1]:=LanguageStrings.Normal;
    RadioGroup_encgrade.Items[2]:=LanguageStrings.Strong;
    RadioGroup_encgrade.Items[3]:=LanguageStrings.Extreme;
  end;
end;

procedure TinputkeyForm.FormShow(Sender: TObject);
begin

end;

end.

