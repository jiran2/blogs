@echo off

if "%1"=="h" goto begin
start mshta vbscript:createobject("wscript.shell").run("""%~nx0"" h",0)(window.close)&&exit
:begin

del blog_push.log
del blog_error.log

set now=%date% %time%

D:
cd /d D:\blogs

echo "%now%" >> blog_push.log
git add * 2>>blog_push.log

set now=%date% %time%
git commit -m "auto commit at %now%" 2>>blog_error.log

git pull 2>>blog_error.log
  
git push 2>>blog_error.log
 
echo "%now%" >> blog_push.log

set /a "pause_time=%RANDOM% %% 17 + 1"
timeout /nobreak /t %pause_time% 2>>blog_error.log

goto begin
