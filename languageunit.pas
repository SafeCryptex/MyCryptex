unit LanguageUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Forms;

type
    TLanguageStrings = record
        AppTitle: string;
        aFile:string;
        Open: string;
        Save: string;
        Clear: string;
        Exit: string;
        Tools: string;
        DecryptPy: string;
        EncryptFile: string;
        DecryptFile: string;
        FileEncryption: string;
        FileDecryption: string;
        Language: string;
        Search: string;
        ContextMenu: string;
        Create: string;
        Delete: string;
        AssocCptxCptf: string;
        Assoc: string;
        Disassoc: string;
        Help: string;
        Website: string;
        About: string;
        Encrypt: string;
        Decrypt: string;
        Encryption: string;
        Decryption: string;
        Err: string;
        cannt_empty: string;
        file_exists: string;
        current_file: string;
        encryption_being_processed: string;
        search_text: string;
        enter_text_to_search: string;
        no_search_results: string;
        password_hint: string;
        please_enter_password: string;
        Decryption_being_processed: string;
        successfully_encrypt: string;
        successfully_decrypt: string;
        faild_encrypt: string;
        wrong_password: string;
        decryption_done: string;
        Encrypt_Decrypt_With_MyCryptex: string;
        Tips: string;
        TipsText: string;
        password_length_less: string;
        confirm_password: string;
        please_password_again: string;
        password_not_match: string;
        please_enter_hint_password: string;
        Hint: string;
        Password: string;
        bypass_password_check: string;
        encryption_strength: string;
        Fast: string;
        Normal: string;
        Strong: string;
        Extreme: string;
        enter_password: string;
        file_not_exists: string;
        password_cannot_empty: string;
        inputfile: string;
        outputfile: string;
        successfully_generated: string;
        generation_failed: string;
    end;

var
  LanguageStrings: TLanguageStrings;

procedure LoadLanguageStrings(const Language: string);

implementation

procedure LoadLanguageStrings(const Language: string);
var
    IniFile: TIniFile;
begin
    IniFile := TIniFile.Create(ExtractFilePath(Application.ExeName)+'languages.ini');
    try
      LanguageStrings.AppTitle := IniFile.ReadString(Language, 'AppTitle', 'My Cryptex');
      LanguageStrings.aFile := IniFile.ReadString(Language, 'File', 'File');
      LanguageStrings.Open := IniFile.ReadString(Language, 'Open', 'Open');
      LanguageStrings.Save := IniFile.ReadString(Language, 'Save', 'Save');
      LanguageStrings.Clear := IniFile.ReadString(Language, 'Clear', 'Clear');
      LanguageStrings.Exit := IniFile.ReadString(Language, 'Exit', 'Exit');
      LanguageStrings.Tools := IniFile.ReadString(Language, 'Tools', 'Tools');
      LanguageStrings.DecryptPy := IniFile.ReadString(Language, 'DecryptPy', 'DecryptPy');
      LanguageStrings.EncryptFile := IniFile.ReadString(Language, 'EncryptFile', 'Encrypt file');
      LanguageStrings.DecryptFile := IniFile.ReadString(Language, 'DecryptFile', 'Decrypt file');
      LanguageStrings.FileEncryption := IniFile.ReadString(Language, 'FileEncryption', 'File Encryption');
      LanguageStrings.FileDecryption := IniFile.ReadString(Language, 'FileDecryption', 'File Decryption');
      LanguageStrings.Language := IniFile.ReadString(Language, 'Language', 'Language');
      LanguageStrings.Search := IniFile.ReadString(Language, 'Search', 'Search(ctrl+F/F3)');
      LanguageStrings.ContextMenu := IniFile.ReadString(Language, 'ContextMenu', 'Context menu');
      LanguageStrings.Create := IniFile.ReadString(Language, 'Create', 'Create');
      LanguageStrings.Delete := IniFile.ReadString(Language, 'Delete', 'Delete');
      LanguageStrings.AssocCptxCptf := IniFile.ReadString(Language, 'AssocCptxCptf', 'Assoc  *.cptx,*.cptf');
      LanguageStrings.Assoc := IniFile.ReadString(Language, 'Assoc', 'Assoc');
      LanguageStrings.Disassoc := IniFile.ReadString(Language, 'Disassoc', 'Disassoc');
      LanguageStrings.Help := IniFile.ReadString(Language, 'Help', 'Help');
      LanguageStrings.Website := IniFile.ReadString(Language, 'Website', 'Website');
      LanguageStrings.About := IniFile.ReadString(Language, 'About', 'About');
      LanguageStrings.Encrypt := IniFile.ReadString(Language, 'Encrypt', 'Encrypt');
      LanguageStrings.Decrypt := IniFile.ReadString(Language, 'Decrypt', 'Decrypt');
      LanguageStrings.Encryption := IniFile.ReadString(Language, 'Encryption', 'Encryption');
      LanguageStrings.Decryption := IniFile.ReadString(Language, 'Decryption', 'Decryption');
      LanguageStrings.Err := IniFile.ReadString(Language, 'Err', 'Error');
      LanguageStrings.cannt_empty := IniFile.ReadString(Language, 'cannt_empty', 'The content to be encrypted cannot be empty.');
      LanguageStrings.file_exists := IniFile.ReadString(Language, 'file_exists', 'The file already exists! Do you want to rewrite it?');
      LanguageStrings.current_file := IniFile.ReadString(Language, 'current_file', 'Current file:');
      LanguageStrings.encryption_being_processed := IniFile.ReadString(Language, 'encryption_being_processed', 'Encryption is being processed, please wait ...');
      LanguageStrings.search_text := IniFile.ReadString(Language, 'search_text', 'Search Text');
      LanguageStrings.enter_text_to_search := IniFile.ReadString(Language, 'enter_text_to_search', 'Please enter the text to search:');
      LanguageStrings.no_search_results := IniFile.ReadString(Language, 'no_search_results', 'No search results found!');
      LanguageStrings.password_hint := IniFile.ReadString(Language, 'password_hint', 'Password hint');
      LanguageStrings.please_enter_password := IniFile.ReadString(Language, 'please_enter_password', 'Please enter the password:');
      LanguageStrings.Decryption_being_processed := IniFile.ReadString(Language, 'Decryption_being_processed', 'Decryption is being processed, please wait ...');
      LanguageStrings.successfully_encrypt := IniFile.ReadString(Language, 'successfully_encrypt', 'Successfully encrypted!');
      LanguageStrings.successfully_decrypt := IniFile.ReadString(Language, 'successfully_decrypt', 'Successfully decrypted!');
      LanguageStrings.faild_encrypt := IniFile.ReadString(Language, 'faild_encrypt', 'Failed to encrypt!');
      LanguageStrings.wrong_password := IniFile.ReadString(Language, 'wrong_password', 'Wrong password! Please try it again.');
      LanguageStrings.decryption_done := IniFile.ReadString(Language, 'decryption_done', 'Decryption done (skipped password check, please verify content by yourself)!');
      LanguageStrings.Encrypt_Decrypt_With_MyCryptex := IniFile.ReadString(Language, 'Encrypt_Decrypt_With_MyCryptex', 'Encrypt/Decrypt With MyCryptex');
      LanguageStrings.Tips := IniFile.ReadString(Language, 'Tips', 'Tips');
      LanguageStrings.TipsText := IniFile.ReadString(Language, 'TipsText', 'Higher encryption levels consume more hardware resources, slow down the process, but offer stronger security. Skipping password verification during decryption is a special protection method. If decryption fails, you will only see garbled data without a password error message.');
      LanguageStrings.password_length_less := IniFile.ReadString(Language, 'password_length_less', 'Password length must not be less than 8 digits!');
      LanguageStrings.confirm_password := IniFile.ReadString(Language, 'confirm_password', 'Confirm Password');
      LanguageStrings.please_password_again := IniFile.ReadString(Language, 'please_password_again', 'Please enter your password again to confirm:');
      LanguageStrings.password_not_match := IniFile.ReadString(Language, 'password_not_match', 'The passwords entered twice do not match!');
      LanguageStrings.please_enter_hint_password := IniFile.ReadString(Language, 'please_enter_hint_password', 'Please enter password hint and password:');
      LanguageStrings.Hint := IniFile.ReadString(Language, 'Hint', 'Hint:');
      LanguageStrings.Password  := IniFile.ReadString(Language, 'Password', 'Password:');
      LanguageStrings.bypass_password_check := IniFile.ReadString(Language, 'bypass_password_check', 'Bypass Password Verification When Decrypting');
      LanguageStrings.encryption_strength := IniFile.ReadString(Language, 'encryption_strength', 'Encryption Strength');
      LanguageStrings.Fast := IniFile.ReadString(Language, 'Fast', 'Fast');
      LanguageStrings.Normal := IniFile.ReadString(Language, 'Normal', 'Normal');
      LanguageStrings.Strong := IniFile.ReadString(Language, 'Strong', 'Strong');
      LanguageStrings.Extreme:= IniFile.ReadString(Language, 'Extreme', 'Extreme');
      LanguageStrings.enter_password:= IniFile.ReadString(Language, 'enter_password', 'Enter Password');
      LanguageStrings.file_not_exists := IniFile.ReadString(Language, 'file_not_exists', 'The input file does not exists!');
      LanguageStrings.password_cannot_empty := IniFile.ReadString(Language, 'password_cannot_empty', 'Password cannot be empty!');
      LanguageStrings.inputfile := IniFile.ReadString(Language, 'inputfile', 'Input file:');
      LanguageStrings.outputfile := IniFile.ReadString(Language, 'outputfile', 'Output file:');
      LanguageStrings.successfully_generated := IniFile.ReadString(Language, 'successfully_generated', 'generated successfully, you can now use this Python script to decrypt your documents (please check the comments in the .py file for instructions)');
      LanguageStrings.generation_failed := IniFile.ReadString(Language, 'generation_failed', 'generation failed');
    finally
        IniFile.Free;
    end;
end;


end.

