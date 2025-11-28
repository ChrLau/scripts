REM Source: https://gist.github.com/jamesfreeman959/231b068c3d1ed6557675f21c0e346a9c?permalink_comment_id=4607377

@if (@a==@a) @end /*

@echo off

set SendKeys=CScript //nologo //E:JScript "%~F0"

set starttime=%TIME%

:loop

cls
set /a rng = %RANDOM% * 60 / 32768 + 30
echo Sending [Shift]+[F15]
echo Start:  %starttime%
echo Latest: %TIME%
%SendKeys% "+{F15}"
timeout /t %rng% /nobreak

goto loop

*/

var WshShell = WScript.CreateObject("WScript.Shell");
WshShell.SendKeys(WScript.Arguments(0));
