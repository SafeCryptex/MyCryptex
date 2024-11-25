unit crypto;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  SysUtils,
{$IFDEF FPC}
  fpcunit,
  testregistry,
{$ELSE}
  TestFramework,
{$ENDIF FPC}
  HlpIHashInfo,
  HlpHashFactory,
  HlpConverters,
  HlpPBKDF_Argon2NotBuildInAdapter,
  HlpArgon2TypeAndVersion,
  ElAES;

type
    TByteArray = array of byte;

function Argon2Hash(const APassword, ASalt: String): String;
function GenerateRandomSalt: string;
function WriteEncryptedData(PlainText, Filepath, Password, Hint: string; no_password_check: boolean; encryption_grade: integer):boolean;
function ReadEncryptedHint(Filepath: string): string;
function ReadEncryptedData(Filepath, Password: string;var Plaintext:string;var intNo_password_check: integer): boolean;
function EncryptFile(InputFile, OutputFile, Password, Hint: string; no_password_check: boolean; encryption_grade: integer):boolean;
function DecryptFile(InputFile, OutputFile, Password: string;var intNo_password_check: integer):boolean;
function HexStringToByteArray(const HexStr: string): TByteArray;//array of byte;
function Base64EncodeStr(const inStr: string): string;
function Base64DecodeStr(const CinLine: string): string;
function CopyFile(Source, Dest: string): Boolean;

var
  CryptexVersion:integer = 2401;
  AIterations:integer = 3;
  AMemory:integer = 16;
  AParallelism:integer = 4;
  AOutputLength:integer = 48;

implementation

function GenerateRandomSalt: string;
var
  chars: string;
  I: Integer;
begin
  Result := '';
  Randomize;
  chars := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  for i := 1 to 16 do
  begin
    Result := Result + chars[random(length(chars)) + 1];
  end;
end;

function RemoveAESPadding(Str: string): string;
var
  PadLen, i: Integer;
  IsPadding: Boolean;
begin
  PadLen := Ord(Str[Length(Str)]);
  if PadLen <= 16 then
  begin
    IsPadding := True;
    for i := Length(Str) - PadLen+1 to Length(Str) - 1 do
      if Ord(Str[i]) <> PadLen then
      begin
        IsPadding := False;
        Break;
      end;
    if IsPadding then
    begin
      SetLength(Str, Length(Str) - PadLen);
    end;
  end;
  Result := Str;
end;

function Base64EncodeStr(const inStr: string): string;

  function Encode_Byte(b: Byte): char;
  const
    Base64Code: string[64] =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  begin
    Result := Base64Code[(b and $3F)+1];
  end;

var
  i: Integer;
begin
  i := 1;
  Result := '';
  while i <= Length(InStr) do
  begin
    Result := Result + Encode_Byte(Byte(inStr[i]) shr 2);
    Result := Result + Encode_Byte((Byte(inStr[i]) shl 4) or (Byte(inStr[i+1]) shr 4));
    if i+1 <=Length(inStr) then
      Result := Result + Encode_Byte((Byte(inStr[i+1]) shl 2) or (Byte(inStr[i+2]) shr 6))
    else
      Result := Result + '=';
    if i+2 <=Length(inStr) then
      Result := Result + Encode_Byte(Byte(inStr[i+2]))
    else
      Result := Result + '=';
    Inc(i, 3);
  end;
end;

function Base64DecodeStr(const CinLine: string): string;
const
  RESULT_ERROR = -2;
var
  inLineIndex: Integer;
  c: Char;
  x: SmallInt;
  c4: Word;
  StoredC4: array[0..3] of SmallInt;
  InLineLength: Integer;
begin
  Result := '';
  inLineIndex := 1;
  c4 := 0;
  InLineLength := Length(CinLine);

  while inLineIndex <=InLineLength do
  begin
    while (inLineIndex <=InLineLength) and (c4 < 4) do
    begin
      c := CinLine[inLineIndex];
      case c of
        '+'     : x := 62;
        '/'     : x := 63;
        '0'..'9': x := Ord(c) - (Ord('0')-52);
        '='     : x := -1;
        'A'..'Z': x := Ord(c) - Ord('A');
        'a'..'z': x := Ord(c) - (Ord('a')-26);
      else
        x := RESULT_ERROR;
      end;
      if x <> RESULT_ERROR then
      begin
        StoredC4[c4] := x;
        Inc(c4);
      end;
      Inc(inLineIndex);
    end;

    if c4 = 4 then
    begin
      c4 := 0;
      Result := Result + Char((StoredC4[0] shl 2) or (StoredC4[1] shr 4));
      if StoredC4[2] = -1 then Exit;
      Result := Result + Char((StoredC4[1] shl 4) or (StoredC4[2] shr 2));
      if StoredC4[3] = -1 then Exit;
      Result := Result + Char((StoredC4[2] shl 6) or (StoredC4[3]));
    end;
  end;
end;

function CopyFile(Source, Dest: string): Boolean;
var
  SourceStream, DestStream: TFileStream;
begin
  Result := False;
  try
    SourceStream := TFileStream.Create(Source, fmOpenRead);
    try
      DestStream := TFileStream.Create(Dest, fmCreate);
      try
        DestStream.CopyFrom(SourceStream, SourceStream.Size);
        Result := True;
      finally
        DestStream.Free;
      end;
    finally
      SourceStream.Free;
    end;
  except
    Result := False;
  end;
end;

function Argon2Hash(const APassword, ASalt: String): String;
var
  LGenerator: IPBKDF_Argon2;
  LSalt, LPassword: TBytes;
  LActual: String;
  LArgon2Parameter: IArgon2Parameters;

  Argon2ParametersBuilder: IArgon2ParametersBuilder;
  AVersion: TArgon2Version;
begin
  Argon2ParametersBuilder := TArgon2idParametersBuilder.Builder();
  AVersion := TArgon2Version.a2vARGON2_VERSION_13;

  LSalt := TConverters.ConvertStringToBytes(ASalt, TEncoding.ASCII);
  LPassword := TConverters.ConvertStringToBytes(APassword, TEncoding.ASCII);

  Argon2ParametersBuilder.WithVersion(AVersion).WithIterations(AIterations)
    .WithMemoryPowOfTwo(AMemory).WithParallelism(AParallelism).WithSalt(LSalt);

  LArgon2Parameter := Argon2ParametersBuilder.Build();
  Argon2ParametersBuilder.Clear();
  LGenerator := TKDF.TPBKDF_Argon2.CreatePBKDF_Argon2(LPassword,
    LArgon2Parameter);

  LActual := TConverters.ConvertBytesToHexString
    (LGenerator.GetBytes(AOutputLength), False);

  Result:= LActual;
end;

function HexStringToByteArray(const HexStr: string): TByteArray;//array of byte;
var
    i: Integer;
    ByteArr: array of byte;
begin
    SetLength(ByteArr, Length(HexStr) div 2);
    for i := 0 to High(ByteArr) do
        ByteArr[i] := StrToInt('$' + Copy(HexStr, 2 * i + 1, 2));
    Result := ByteArr;
end;

function WriteEncryptedData(PlainText, Filepath, Password, Hint: string; no_password_check: boolean; encryption_grade: integer):boolean;
var
 Data, Hash, Key, IV, Salt, EncryptedInfo, EncodedHint, EncodedSalt: ansistring;
 FileStream: TFileStream;
 LenHint, LenSalt, intNo_password_check: Integer;

 AESKey256: TAESKey256;
 AESIv: TAESBuffer;
 byteArrayKey, byteArrayIv: array of byte;
 j: Integer;
 inStream, outStream: TMemoryStream;
begin
  Result := False;

  if no_password_check then
    intNo_password_check := 1
  else
    intNo_password_check := 0;

  case encryption_grade of
    0:
      begin
        AIterations := 2;
        AMemory := 15;
        AParallelism := 4;
      end;
    2:
      begin
        AIterations := 5;
        AMemory := 18;
        AParallelism := 3;
      end;
    3:
      begin
        AIterations := 10;
        AMemory := 20;
        AParallelism := 1;
      end;
  else
    begin
      AIterations := 3;
      AMemory := 16;
      AParallelism := 4;
    end;
  end;
  AOutputLength := 48;

  Salt := GenerateRandomSalt;
  Hash := Argon2Hash(password, salt);
  Key := copy(hash, 1, 64);
  Iv := copy(hash, 65, 32);

  byteArrayKey := HexStringToByteArray(Key);
  byteArrayIv := HexStringToByteArray(Iv);

  for j := 0 to 31 do
  begin
     if j <= High(byteArrayKey) then
        AESKey256[j] := byteArrayKey[j]
     else
        AESKey256[j] := 0;
  end;
  for j := 0 to 15 do
  begin
     if j <= High(byteArrayIv) then
        AESIv[j] := byteArrayIv[j]
     else
        AESIv[j] := 0;
  end;

  if no_password_check then Data := PlainText
  else Data := Hash+PlainText;

  inStream := TMemoryStream.Create;
  inStream.WriteBuffer(PAnsiChar(Data)^,Length(Data));
  outStream := TMemoryStream.Create;
  try
    EncryptAESStreamCBC(inStream, 0, AESKey256, AESIv, outStream);
    SetLength(Data,outStream.Size);
    outStream.Position := 0;
    outStream.ReadBuffer(PAnsiChar(Data)^,outStream.Size);
  finally
    inStream.Free;
    outStream.Free;
  end;

  EncodedHint := Base64EncodeStr(Hint);
  EncodedSalt := Base64EncodeStr(Salt);

  LenHint := Length(EncodedHint);
  LenSalt := Length(EncodedSalt);
  EncryptedInfo := 'MyCryptex'+IntToHex(CryptexVersion, 4) + IntToHex(intNo_password_check, 4)
    + IntToHex(encryption_grade,4)  + IntToHex(LenSalt, 4)
    + EncodedSalt + IntToHex(LenHint, 4) + EncodedHint + Data;

  FileStream := TFileStream.Create(Filepath, fmCreate);
  try
    FileStream.Write(EncryptedInfo[1], Length(EncryptedInfo));
    Result := True;
  finally
    FileStream.Free;
  end;
end;

function EncryptFile(InputFile, OutputFile, Password, Hint: string; no_password_check: boolean; encryption_grade: integer):boolean;
var
 Data, Hash, Key, IV, Salt, EncryptedInfo, EncodedHint, EncodedSalt: ansistring;
 index, dataLength, bsize, pad: integer;
 FileStream: TFileStream;
 LenHint, LenSalt, intNo_password_check: Integer;

 AESKey256: TAESKey256;
 AESIv: TAESBuffer;
 byteArrayKey, byteArrayIv: array of byte;
 j: Integer;
 inStream, outStream: TMemoryStream;
begin
  Result := False;

  if no_password_check then
    intNo_password_check := 1
  else
    intNo_password_check := 0;

  case encryption_grade of
    0:
      begin
        AIterations := 2;
        AMemory := 15;
        AParallelism := 4;
      end;
    2:
      begin
        AIterations := 5;
        AMemory := 18;
        AParallelism := 3;
      end;
    3:
      begin
        AIterations := 10;
        AMemory := 20;
        AParallelism := 1;
      end;
  else
    begin
      AIterations := 3;
      AMemory := 16;
      AParallelism := 4;
    end;
  end;
  AOutputLength := 48;

  Salt := GenerateRandomSalt;
  Hash := Argon2Hash(password, salt);
  Key := copy(hash, 1, 64);
  Iv := copy(hash, 65, 32);

  byteArrayKey := HexStringToByteArray(Key);
  byteArrayIv := HexStringToByteArray(Iv);

  for j := 0 to 31 do
  begin
     if j <= High(byteArrayKey) then
        AESKey256[j] := byteArrayKey[j]
     else
        AESKey256[j] := 0;
  end;
  for j := 0 to 15 do
  begin
     if j <= High(byteArrayIv) then
        AESIv[j] := byteArrayIv[j]
     else
        AESIv[j] := 0;
  end;

  FileStream := TFileStream.Create(InputFile, fmOpenRead);
  try
    SetLength(Data, FileStream.Size);
    FileStream.Read(Data[1], Length(Data));
  finally
    FileStream.Free;
  end;

  if not no_password_check then Data := Hash+Data;

  inStream := TMemoryStream.Create;
  inStream.WriteBuffer(PAnsiChar(Data)^,Length(Data));
  outStream := TMemoryStream.Create;
  try
    EncryptAESStreamCBC(inStream, 0, AESKey256, AESIv, outStream);
    SetLength(Data,outStream.Size);
    outStream.Position := 0;
    outStream.ReadBuffer(PAnsiChar(Data)^,outStream.Size);
  finally
    inStream.Free;
    outStream.Free;
  end;

  EncodedHint := Base64EncodeStr(Hint);
  EncodedSalt := Base64EncodeStr(Salt);

  LenHint := Length(EncodedHint);
  LenSalt := Length(EncodedSalt);
  EncryptedInfo := 'MyCryptex'+IntToHex(CryptexVersion, 4) + IntToHex(intNo_password_check, 4)
    + IntToHex(encryption_grade,4) + IntToHex(LenSalt, 4) + EncodedSalt + IntToHex(LenHint, 4)
    + EncodedHint + Data;

  FileStream := TFileStream.Create(OutputFile, fmCreate);
  try
    FileStream.Write(EncryptedInfo[1], Length(EncryptedInfo));
    Result := True;
  finally
    FileStream.Free;
  end;
end;

function ReadEncryptedHint(Filepath: string): string;
var
  EncodedHint, EncryptedInfo: string;
  FileStream: TFileStream;
  LenHint, LenSalt: Integer;
  infoVersion: Integer;
begin
  Result := '';
  FileStream := TFileStream.Create(Filepath, fmOpenRead);
  try
    SetLength(EncryptedInfo, FileStream.Size);
    FileStream.Read(EncryptedInfo[1], 2048);
  finally
    FileStream.Free;
  end;
  infoVersion := StrToInt('$' + Copy(EncryptedInfo, 1+9, 4));
  if infoVersion=2301 then
  begin
   LenSalt := StrToInt('$' + Copy(EncryptedInfo, 1+9+4, 4));
  LenHint := StrToInt('$' + Copy(EncryptedInfo, LenSalt+5+9+4, 4));
  EncodedHint := Copy(EncryptedInfo, LenSalt+9+9+4, LenHint);
  end else
  begin
   LenSalt := StrToInt('$' + Copy(EncryptedInfo, 1+9+4+8, 4));
  LenHint := StrToInt('$' + Copy(EncryptedInfo, LenSalt+5+9+4+8, 4));
  EncodedHint := Copy(EncryptedInfo, LenSalt+9+9+4+8, LenHint);
  end;

  Result := Base64DecodeStr(EncodedHint);
end;

function ReadEncryptedData(Filepath, Password: string; var Plaintext:string;var intNo_password_check: integer): boolean;
var
  Hash, Salt, Key, Iv, Data, EncodedSalt, EncryptedInfo, infoHash: ansistring;
  FileStream: TFileStream;
  LenHint, LenSalt: Integer;

  AESKey256: TAESKey256;
  AESIv: TAESBuffer;
  byteArrayKey, byteArrayIv: array of byte;
  j, infoVersion: Integer;
  inStream, outStream: TStringStream;
  //intNo_password_check,
  encryption_grade: Integer;
begin
  Result := False;
  FileStream := TFileStream.Create(Filepath, fmOpenRead);
  try
    SetLength(EncryptedInfo, FileStream.Size);
    FileStream.Read(EncryptedInfo[1], Length(EncryptedInfo));
  finally
    FileStream.Free;
  end;
  infoVersion := StrToInt('$' + Copy(EncryptedInfo, 1+9, 4));
  intNo_password_check := StrToInt('$' + Copy(EncryptedInfo, 1+9+4, 4));
  encryption_grade := StrToInt('$' + Copy(EncryptedInfo, 1+9+4+4, 4));
  LenSalt := StrToInt('$' + Copy(EncryptedInfo, 1+9+4+8, 4));
  EncodedSalt := Copy(EncryptedInfo, 5+9+4+8, LenSalt);
  LenHint := StrToInt('$' + Copy(EncryptedInfo, LenSalt+5+9+4+8, 4));
  Data := Copy(EncryptedInfo, LenSalt+9+LenHint+9+4+8, Length(EncryptedInfo)-LenSalt-4 -LenHint -4 -9-4-8);

  Salt := Base64DecodeStr(EncodedSalt);

  case encryption_grade of
    0:
      begin
        AIterations := 2;
        AMemory := 15;
        AParallelism := 4;
      end;
    2:
      begin
        AIterations := 5;
        AMemory := 18;
        AParallelism := 3;
      end;
    3:
      begin
        AIterations := 10;
        AMemory := 20;
        AParallelism := 1;
      end;
  else
  begin
    AIterations := 3;
    AMemory := 16;
    AParallelism := 4;
  end;
  end;
    AOutputLength := 48;

    Hash := Argon2Hash(password, salt);
    Key := copy(hash, 1, 64);
    Iv := copy(hash, 65, 32);

    byteArrayKey := HexStringToByteArray(Key);
    byteArrayIv := HexStringToByteArray(Iv);

    for j := 0 to 31 do
    begin
      if j <= High(byteArrayKey) then
        AESKey256[j] := byteArrayKey[j]
      else
        AESKey256[j] := 0;
    end;
    for j := 0 to 15 do
    begin
    if j <= High(byteArrayIv) then
      AESIv[j] := byteArrayIv[j]
    else
      AESIv[j] := 0;
    end;
    inStream := TStringStream.Create(Data);
    outStream := TStringStream.Create('');
    try
      DecryptAESStreamCBC(inStream, inStream.Size - inStream.Position, AESKey256, AESIv, outStream);
      Data := outStream.DataString;
      if intNo_password_check>0 then
      begin
        Plaintext := RemoveAESPadding(copy(Data, 1, Length(EncryptedInfo)));
        Result := true;
      end else
      begin
        infoHash := copy(Data, 1, 96);
        Plaintext := RemoveAESPadding(copy(Data, 97, Length(EncryptedInfo)-96));
        Result := (UpperCase(Hash) = UpperCase(infoHash));
      end;
    finally
      inStream.Free;
      outStream.Free;
    end;
end;

function DecryptFile(InputFile, OutputFile, Password: string;var intNo_password_check: integer):boolean;
var
  Hash, Salt, Key, Iv, Data, EncodedSalt, EncryptedInfo, infoHash, Plaintext: string;
  FileStream: TFileStream;
  LenHint, LenSalt: Integer;

  AESKey256: TAESKey256;
  AESIv: TAESBuffer;
  byteArrayKey, byteArrayIv: array of byte;
  j, infoVersion: Integer;
  inStream, outStream: TStringStream;
  //intNo_password_check,
  encryption_grade: Integer;
begin
  Result := False;
  FileStream := TFileStream.Create(InputFile, fmOpenRead);
  try
    SetLength(EncryptedInfo, FileStream.Size);
    FileStream.Read(EncryptedInfo[1], Length(EncryptedInfo));
  finally
    FileStream.Free;
  end;
  infoVersion := StrToInt('$' + Copy(EncryptedInfo, 1+9, 4));
  LenSalt := StrToInt('$' + Copy(EncryptedInfo, 1+9+4+8, 4));
  EncodedSalt := Copy(EncryptedInfo, 5+9+4+8, LenSalt);
  LenHint := StrToInt('$' + Copy(EncryptedInfo, LenSalt+5+9+4+8, 4));
  intNo_password_check := StrToInt('$' + Copy(EncryptedInfo, 1+9+4, 4));
  encryption_grade := StrToInt('$' + Copy(EncryptedInfo, 1+9+4+4, 4));
  Data := Copy(EncryptedInfo, LenSalt+9+LenHint+9+4+8, Length(EncryptedInfo)-LenSalt-4 -LenHint -4 -9-4-8);
  Salt := Base64DecodeStr(EncodedSalt);
  Hash := Argon2Hash(password, salt);

  case encryption_grade of
    0:
      begin
        AIterations := 2;
        AMemory := 15;
        AParallelism := 4;
      end;
    2:
      begin
        AIterations := 5;
        AMemory := 18;
        AParallelism := 3;
      end;
    3:
      begin
        AIterations := 10;
        AMemory := 20;
        AParallelism := 1;
      end;
    else
    begin
      AIterations := 3;
      AMemory := 16;
      AParallelism := 4;
    end;
    end;
    AOutputLength := 48;

    Hash := Argon2Hash(password, salt);
    Key := copy(hash, 1, 64);
    Iv := copy(hash, 65, 32);

    byteArrayKey := HexStringToByteArray(Key);
    byteArrayIv := HexStringToByteArray(Iv);

    for j := 0 to 31 do
    begin
      if j <= High(byteArrayKey) then
        AESKey256[j] := byteArrayKey[j]
      else
        AESKey256[j] := 0;
    end;
    for j := 0 to 15 do
    begin
    if j <= High(byteArrayIv) then
      AESIv[j] := byteArrayIv[j]
    else
      AESIv[j] := 0;
    end;
    inStream := TStringStream.Create(Data);
    outStream := TStringStream.Create('');
    try
      DecryptAESStreamCBC(inStream, inStream.Size - inStream.Position, AESKey256, AESIv, outStream);
      Data := outStream.DataString;
      if intNo_password_check>0 then
      begin
        Plaintext := RemoveAESPadding(copy(Data, 1, Length(EncryptedInfo)));
        Result := true;
      end else
      begin
        infoHash := copy(Data, 1, 96);
        Plaintext := RemoveAESPadding(copy(Data, 97, Length(EncryptedInfo)-96));
        Result := (UpperCase(Hash) = UpperCase(infoHash));
      end;
    finally
      inStream.Free;
      outStream.Free;
    end;

    if Result then
    begin
      FileStream := TFileStream.Create(OutputFile, fmCreate);
      try
        FileStream.Write(Plaintext[1], Length(Plaintext));
        Result := True;
      finally
        FileStream.Free;
      end;
    end;
end;

end.

