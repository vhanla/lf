program lf;

{$mode objfpc}{$H+}{$J-}

{$ifdef windows}
{$APPTYPE CONSOLE}
{$endif}

{.$R *.res}

uses
  SysUtils, {$ifdef unix}LCLIntf, crt, termio, BaseUnix,{$endif}  {LCLIntf, LCLType, LMessages,} StrUtils{$ifdef windows}, Windows {$endif}{, fpjson, jsonparser, fpjsonrtti};

function MatchString(const AText: string; const AValues: array of string; var AIndex: Integer): Boolean;
begin
  AIndex := AnsiIndexStr(AText, AValues);
  Result := AIndex <> -1;
end;

{$ifdef windows}
function IsWow64: Boolean;
type
  TIsWow64Process = function(Handle: THandle; var Res: BOOL): BOOL; stdcall;
var
  IsWow64Result: BOOL;
  IsWow64Process: TIsWow64Process = nil;
begin
  // Try to load required function from kernel32
  Pointer(IsWow64Process) := GetProcAddress(GetModuleHandle('kernel32.dll'), 'IsWow64Process');
  if Assigned(IsWow64Process) then
  begin
    // Function is implemented: call it
    IsWow64Result := False;
    if not IsWow64Process(GetCurrentProcess, IsWow64Result) then
      raise Exception.Create('IsWow64: bad process handle');
    // Return result of function
    Result := IsWow64Result;
  end
  else
    // Function not implemented: can't be running on Wow64
    Result := False;
end;

type
  TWow64DisableWow64FsRedirection = function(var OldValue: Windows.PVOID): Windows.BOOL; stdcall;
  TWow64RevertWow64FsRedirection = function(var OldValue: Windows.PVOID): Windows.BOOL; stdcall;
{$endif}

procedure ConsoleColor(var hConsole: THandle; color:Integer);
begin
  {$ifdef windows}
  SetConsoleTextAttribute(hConsole, color);
  {$else}
  // TODO: print using color codes on unix oses
  TextColor(color); // Temporary workaround
  {$endif}
end;

var
  hConsole: THandle;
  {$ifdef windows}
  screen_info_t: TConsoleScreenBufferInfo;
  {$else}
  ws: winsize;
  {$endif}

  original_attributes: WORD;
  console_width: Integer;//SHORT;
  line_count: Integer = 3;//SHORT = 3;
  console_height: integer = 24;

  search_string: string;
  wild_char: string = '*.*';

  file_size: Real;
  //total_size: Real = 0.0;

  i: Integer;
  pause: string = 'q'; //quick by default

  {$ifdef windows}
  Wow64DisableWow64FsRedirection: TWow64DisableWow64FsRedirection = nil;
  Wow64RevertWow64FsRedirection: TWow64RevertWow64FsRedirection = nil;
  OldValue: Pointer = nil;
  {$endif}

  sr: TSearchRec;
  rs: Integer;
  //devicons: TArray<string>;
  filetype: Array [0..54] of string = (
  '.exe', '.dll', '.json', '.js',   '.php', '.ini',  '.cmd',  '.bat',
  '.gif', '.png', '.jpeg', '.jpg',  '.bmp', '.webp', '.flif', '.tga',      '.tiff', '.psd',
  '.ts',  '.vue', '.sass', '.less', '.css', '.html', '.htm',  '.xml',      '.rb',
  '.go',  '.cs',  '.py',   '.styl', '.db',  '.sql',  '.md',   '.markdown', '.java', '.class',
  '.apk', '.pas', '.inc',  '.lnk',  '.sh',  '.log',  '.todo', '.csproj',   '.sln',
  '.rar', '.zip', '.7z',   '.cab',  '.tgz', '.env',  '.pdf',  '.doc',      '.scss'
  );
  devicons: Array [0..54] of integer = (
  //$e608 <- elefante php
  $e70f,  $e714,  $e60b,   $e74e,   $e73d,  $e615,   $e795,   $e795,
  $e60d,  $e60d,  $e60d,   $e60d,   $e60d,  $e60d,   $e60d,   $e60d,       $e60d,   $e60d,
  $e628,  $e62b,  $e603,   $e758,   $e749,  $e736,   $e736,   $e7a3,       $e791,
  $e627,  $e72e,  $e73c,   $e759,   $e706,  $e704,   $e73e,   $e73e,       $e738,   $e738,
  $e70e,  $e72d,  $e7aa,   $e62a,   $e7a2,  $e705,   $e714,   $e77f,       $e77f,
  $e707,  $e707,  $e707,   $e707,   $e707,  $e799,   $e760,   $e76f,       $e603
  );
  colors: Array [0..54] of integer = (
  $0F,    $08,    $0A,     $0A,     $0E,    $0B,     $0F,     $0F,
  $09,    $09,    $09,     $09,     $09,    $09,     $09,     $09,         $09,     $09,
  $0A,    $02,    $08,     $08,     $03,    $03,     $03,     $03,         $08,
  $08,    $08,    $08,     $08,     $08,    $08,     $08,     $08,         $08,     $08,
  $0A,    $08,    $08,     $08,     $08,    $08,     $08,     $08,         $08,
  $08,    $08,    $08,     $08,     $08,    $0B,     $08,     $08,         $08
  );
  idx: Integer;

begin
  //try
    // UTF-8
//    SetConsoleOutputCP(CP_WINUNICODE);

    {$ifdef windows}
    SetConsoleOutputCP(CP_UTF8);

    hConsole := GetStdHandle(STD_OUTPUT_HANDLE);
    GetConsoleScreenBufferInfo(hConsole, screen_info_t);

    original_attributes := screen_info_t.wAttributes;
    console_width := screen_info_t.srWindow.Right;
    console_height := screen_info_t.srWindow.Bottom - screen_info_t.srWindow.Top;
    {$else}
    //STDIN_FILENO = 0
    //STDOUT_FILENO = 1
    //STOERR_FILENO = 2
    FpIOCtl(1, TIOCGWINSZ, @ws);
    console_width := ws.ws_col;
    console_height:= ws.ws_row;
    {$endif}

    search_string := GetCurrentDir;


    //ConsoleColor(hConsole, $0F); // Bright white label

    ConsoleColor(hConsole, 3);
    //Writeln('Path: ' + search_string);

    {$ifdef windows}
    for i := 0 to console_width - 1 do
    begin
      if console_width / 2 = i then
        Write('┬')
      else
        Write('─');
    end;


    if IsWow64 then
    begin
      Pointer(Wow64DisableWow64FsRedirection) := Windows.GetProcAddress(Windows.GetModuleHandle('kernel32.dll'), 'Wow64DisableWow64FsRedirection');
      if Assigned(Wow64DisableWow64FsRedirection) then
        Wow64DisableWow64FsRedirection(&OldValue);
          //writeln(#13#10'WowRedirection Disabled');
    end;
    {$endif}

    // parse params
    if (ParamCount = 1) and (ParamStr(1) = '?') then
    begin
      WriteLn(#13#10'Help');
    end
    else if ParamCount > 0 then
    begin
      if (ParamCount = 1) and (ParamStr(1) = '/p') then
         pause := 'n' // page it
      else
        wild_char :=  ParamStr(1);

      if (ParamCount > 1) and (ParamStr(2) = '/p') then
      begin
        wild_char :=  ParamStr(1);
        pause := 'n'; // page it
      end;
    end;

    // devicons
    //https://stackoverflow.com/questions/8409026/search-a-string-array-in-delphi
    //https://stackoverflow.com/questions/3054517/delphi-search-files-and-directories-fastest-alghorithm
    //devicons := TArray<string>.Create('.exe', '.dll');

    Writeln('');
    // search now
    //rs := FindFirst('c:\windows\*.*', faAnyFile, sr);
    {$ifdef windows}
    rs := FindFirst(search_string + '\' + wild_char, faAnyFile, sr);
    {$else}
    rs := FindFirst(search_string + '/' + wild_char, faAnyFile, sr);
    {$endif}
    if rs = 0 then
    try
      while rs = 0 do
      begin
        if (sr.Name <> '.') and (sr.Name <> '..') then
        begin
          Write(' ');
          if sr.Attr and faDirectory = faDirectory then
          begin
            ConsoleColor(hConsole, $0D);
            if sr.Name = '.git' then
            begin
              ConsoleColor(hConsole, $04);
              Write(WideChar($e5fb))
            end
            else if sr.Name = 'node_modules' then
              Write(WideChar($e5fa))
            else if sr.Name = '.vscode' then
              Write(WideChar($e70c))
            else
              Write(WideChar($e5fe))
          end
          else if sr.Name = 'artisan' then
          begin
            ConsoleColor(hConsole, $0F);
            Write(WideChar($e795))
          end
          else if (sr.Name = '.gitignore') or (sr.Name = '.gitattributes') then
            Write(WideChar($e727))
          else if pos('.blade.php', sr.Name) > 0 then
            Write(WideChar($e73f))
          else if MatchString(LowerCase(ExtractFileExt(sr.Name)), filetype, idx) then
          begin
            ConsoleColor(hConsole, colors[idx]);
            Write(WideChar(devicons[idx]));
          end
          else
          begin
            ConsoleColor(hConsole, $08);
            Write(WideChar($f016));
          end;

          Write(Format(' %-*s' ,[(console_width div 2 - 8), sr.Name]));

          if sr.Attr and faDirectory <> faDirectory then
          begin
            write(' ');
            file_size := sr.Size;
            //total_size := total_size + file_size;
            if file_size > 1023 then
            begin
              file_size := file_size / 1024.0;
              if file_size > 1023 then
              begin
                file_size := file_size / 1024.0;
                if file_size > 1023 then
                begin
                  file_size := file_size / 1024.0;
                  if file_size > 1023 then
                  begin
                    write(Format('%5.1f TB', [file_size]));
                  end
                  else
                    write(Format('%5.1f GB', [file_size]));
                end
                else
                  write(Format('%5.1f MB', [file_size]));
              end
              else
                write(Format('%5.1f KB', [file_size]));
            end
            else
              write(Format('%5.1f B', [file_size]));
          end
          else
            write(' <dir>');
          writeln('');
        end;

        line_count := line_count + 1;
        if (line_count = console_height) and (pause <> 'q') then
        begin
          {$ifdef windows}
          ConsoleColor(hConsole, original_attributes);
          {$else}

          {$endif}
          writeln('Press Enter to continue...');
          readln(pause);
          //Winexec('c:\windows\system32\cmd.exe /c pause', SW_SHOWNORMAL);
          line_count := 3;
        end;

        rs := FindNext(sr);
      end;
      ConsoleColor(hConsole, original_attributes);

    finally
      SysUtils.FindClose(sr);
    end;

    {$ifdef windows}
    if IsWow64 then
    begin
      Pointer(Wow64RevertWow64FsRedirection) := Windows.GetProcAddress(Windows.GetModuleHandle('kernel32.dll'), 'Wow64RevertWow64FsRedirection');
      if Assigned(Wow64RevertWow64FsRedirection) then
        Wow64RevertWow64FsRedirection(OldValue);
          //writeln(#13#10'WowRedirection Reverted');
    end;
    {$endif}


    //Readln;

  //except
  //  on E: Exception do
  //    Writeln(E.ClassName, ': ', E.Message);
  //end;
end.
