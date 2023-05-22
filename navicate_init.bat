echo "start delete NavicatPremium regedit"

reg delete "HKEY_CURRENT_USER\Software\PremiumSoft\NavicatPremium\Registration15XCS" /f

setlocal enabledelayedexpansion

for /f "delims=: tokens=1,*" %%i in ('reg query "HKEY_CURRENT_USER\Software\Classes\CLSID"') do (
    set /a index=0
    set /a num=0
    for /f "delims=: tokens=1,*" %%j in ('reg query %%i') do (
        set /a index+=1
        for %%a in (%%j) do (
            if %%~nxa==Info if not %%j==%%i (
                set /a num+=1
            )
        )
    )
    if !num! EQU 1 if !index! EQU 1 (
        echo "正在删除 %%i "
        reg delete "%%i" /f
    )
)

echo "end delete NavicatPremium regedit"

pause