object mainForm: TmainForm
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'SignFinder'
  ClientHeight = 196
  ClientWidth = 481
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    481
    196)
  PixelsPerInch = 96
  TextHeight = 13
  object filePath: TEdit
    Left = 8
    Top = 8
    Width = 434
    Height = 21
    TabStop = False
    Anchors = [akLeft, akTop, akRight]
    ReadOnly = True
    TabOrder = 4
    ExplicitWidth = 329
  end
  object mInfo: TMemo
    Left = 8
    Top = 64
    Width = 465
    Height = 124
    Anchors = [akLeft, akRight, akBottom]
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    ExplicitTop = 66
  end
  object btmFindSign: TButton
    Left = 8
    Top = 35
    Width = 465
    Height = 25
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Find sign'
    TabOrder = 2
    OnClick = btmFindSignClick
    ExplicitWidth = 360
  end
  object btmOpenFile: TButton
    Left = 448
    Top = 8
    Width = 25
    Height = 21
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 0
    OnClick = btmOpenFileClick
    ExplicitLeft = 343
  end
  object OpenFileDlg: TOpenDialog
    FileName = ''
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 48
    Top = 248
  end
end
