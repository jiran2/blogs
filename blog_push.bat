@echo off

if "%1"=="h" goto begin
start mshta vbscript:createobject("wscript.shell").run("""%~nx0"" h",0)(window.close)&&exit

:begin

echo. > blog_push.log

set now=%date% %time%

D:
cd /d D:\blogs

echo "%now%" >> blog_push.log
git add * 2>>blog_push.log

echo "%now%" >> blog_push.log
git commit -m "auto commit at %now%" 2>>blog_push.log

echo "%now%" >> blog_push.log
git pull 2>>blog_push.log
  
echo "%now%" >> blog_push.log
git push 2>>blog_push.log

echo "%now%" >> blog_push.log
set /a "pause_time=%RANDOM% %% 89 + 1"
timeout /nobreak /t %pause_time% 2>>blog_push.log

goto begin
