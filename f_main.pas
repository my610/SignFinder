unit f_main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Winapi.ShellAPI;

type
  TmainForm = class(TForm)
    filePath: TEdit;
    mInfo: TMemo;
    btmFindSign: TButton;
    btmOpenFile: TButton;
    OpenFileDlg: TOpenDialog;
    procedure btmFindSignClick(Sender: TObject);
    procedure btmOpenFileClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  protected
    procedure WMDropFiles(var Msg: TMessage); message WM_DROPFILES;
  public
    { Public declarations }
  end;

var
  mainForm: TmainForm;

type
  TComparateData = (cmpByte, cmpWord, cmpDWord, cmpQWord);


implementation

{$R *.dfm}

function OffsetMem(lpBase: Pointer; Offset: Cardinal): Pointer; assembler;
asm
  add eax,edx
end;


function CompDataBase(const lpData, lpMask, lpAsk: Pointer; const offset: Integer; cmpData: TComparateData): Boolean;
begin
  Result:= False;
  case cmpData of
    cmpByte: Result:= Byte(OffsetMem(lpData, offset)^) and Byte(lpMask^) = Byte(lpAsk^);
    cmpWord: Result:= Word(OffsetMem(lpData, offset)^) and Word(lpMask^) = Word(lpAsk^);
    cmpDWord: Result:= DWord(OffsetMem(lpData, offset)^) and DWord(lpMask^) = DWord(lpAsk^);
    cmpQWord: Result:= UInt64(OffsetMem(lpData, offset)^) and UInt64(lpMask^) = UInt64(lpAsk^);
  end;
end;

procedure normalizeSignature(const Sig: String; var mask, ask: TBytes);
var
  tmpStr, tmpHex: String;
  cbSigLen, i: Integer;
begin
  tmpStr:= StringReplace(sig, ' ', '',  [rfReplaceAll, rfIgnoreCase]);

  if ((Length(tmpStr) mod 2) = 0) and (Length(tmpStr) > 1) then begin

    cbSigLen:= Length(tmpStr) div 2;

    SetLength(mask, cbSigLen);
    SetLength(ask, cbSigLen);

    for i:= 0 to cbSigLen - 1 do begin

      tmpHex:= Copy(tmpStr, 1 + i*2, 2);

      if (tmpHex[1] = '?') or (tmpHex[2] = '?') then begin

        if (tmpHex[1] = '?') and (tmpHex[2] = '?') then mask[i]:= $00
        else if (tmpHex[1] = '?') then mask[i]:= $0F
        else mask[i]:= $F0;

        tmpHex:= StringReplace(tmpHex, '?', '0', [rfReplaceAll]);
        ask[i]:= StrToInt('0x' + tmpHex);

      end else begin
        ask[i]:= StrToInt('0x' + tmpHex);
        mask[i]:= $FF;
      end;

    end;
  end;
end;

function findSignature(const sig: String; const lpData: Pointer; cbDataSize: Integer; var offset: Integer): Boolean;
var
  cbMaskLen, idx, sum: Integer;
  mask, ask: TBytes;
  cmpData: TComparateData;
  maxOffset, curOffset: Integer;
begin
  Result:= False;
  offset:= 0;

  normalizeSignature(sig, mask, ask);

  cbMaskLen:= Length(mask);

  case (cbMaskLen div 2) of
    0: cmpData:= cmpByte;
    1: cmpData:= cmpWord;
    else cmpData:= cmpDWord;
  end;

  maxOffset:= cbDataSize - cbMaskLen;

  curOffset:= 0;

  repeat

    if CompDataBase(lpData, @mask[0], @ask[0], curOffset, cmpData) then begin

      idx:= 0;
      sum:= 0;

      repeat

        if CompDataBase(lpData, @mask[idx], @ask[idx], curOffset, cmpByte) then Inc(sum) else Break;

        Inc(idx);
        Inc(curOffset);

      until idx >= cbMaskLen;

      if (sum = cbMaskLen) then begin

        offset:= curOffset - cbMaskLen;
        Result:= True;
        Exit;
      end;
    end;

    Inc(curOffset);
  until curOffset >= maxOffset;

end;

procedure TmainForm.WMDropFiles(var Msg: TMessage);
var
  FileCount, NameLen, i: Integer;
  sFileName: string;
begin
  FileCount:= DragQueryFile(Msg.wParam, $FFFFFFFF, nil, 0); try

    for i:= 0 to FileCount - 1 do begin

      NameLen:= DragQueryFile(Msg.wParam, i, nil, 0) + 1;
      SetLength(sFileName, NameLen);
      DragQueryFile(Msg.wParam, i, Pointer(sFileName), NameLen);

      if FileExists(sFileName) then begin
        filePath.Text:= sFileName;
        Exit;
      end;
    end;

  finally
    DragFinish(Msg.wParam);
  end;
end;

procedure TmainForm.btmOpenFileClick(Sender: TObject);
begin
  if OpenFileDlg.Execute(Handle) then begin
    filePath.Text:= OpenFileDlg.FileName;
  end;
end;


function FindSigInFile(const FileName: PChar; const sig: String): Boolean;
var
  pMapData: Pointer;
  cbSize, offset, pData: Integer;
  tmpStr: String;
  hFileMap, hFile: THandle;
  szFile: DWORD;
begin
  Result:= False;

  tmpStr:= StringReplace(sig, ' ', '',  [rfReplaceAll, rfIgnoreCase]);

  hFile:= CreateFile(PChar(FileName),
                      GENERIC_WRITE or GENERIC_READ,
                      FILE_SHARE_READ or FILE_SHARE_WRITE,
                      nil,
                      OPEN_EXISTING,
                      FILE_ATTRIBUTE_NORMAL,
                      0);

  if (hFile <> INVALID_HANDLE_VALUE) then try

    szFile:= GetFileSize(hFile, nil);
    hFileMap:= CreateFileMapping(hFile, nil, PAGE_READWRITE , 0, szFile, nil);

    if (hFileMap <> INVALID_HANDLE_VALUE) then try

      pMapData:= MapViewOfFile(hFileMap, FILE_MAP_ALL_ACCESS, 0, 0, szFile);

      if Assigned(pMapData) then try

        cbSize:= szFile;

        pData:= 0;

        while True do begin

          offset:= 0;

          if findSignature(sig, Pointer(LongInt(pMapData) + pData), cbSize, offset) then begin

            mainForm.mInfo.Lines.Add(Format('Sign (%s) offset: %d', [sig, pData + offset]));
            Result:= True;

            // next
            pData:= pData + offset + (Length(tmpStr) div 2);
            cbSize:= cbSize - (offset + (Length(tmpStr) div 2));
          end else Break;

        end;

      finally
        UnmapViewOfFile(pMapData);
      end;

    finally
      CloseHandle(hFileMap);
    end;

  finally
    CloseHandle(hFile);
  end;

end;

procedure TmainForm.btmFindSignClick(Sender: TObject);
const
  sign_1 = '80 3D ?? ?? ?? 00 00 74 07 ?? ?? 0F 1F 44 00 00 53';
  sign_2 = '55 53 31 F6 48 89 FB 31 C0 BF ?? ?? ?? ?? 48 83';
begin
  FindSigInFile(PChar(filePath.Text), sign_1);
  FindSigInFile(PChar(filePath.Text), sign_2);
end;

procedure TmainForm.FormCreate(Sender: TObject);
begin
  DragAcceptFiles(Handle, True);
end;

procedure TmainForm.FormDestroy(Sender: TObject);
begin
  DragAcceptFiles(Handle, False);
end;

end.
