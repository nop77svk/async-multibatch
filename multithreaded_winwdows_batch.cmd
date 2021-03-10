@echo off
:: !IMPORTANT! Set the following variable to your desired size of the "thread pool" :-)
set g_maximum_threads=3

goto :the_coordinator

:: ===============================================================================================
:coordinator_stuff
:: Use "call :async_thread <arguments>" to spawn a thread
:: !IMPORTANT! Start editing here for your "coordinator" stuff

call :async_thread 1 Q %*
call :async_thread 2 W %*
call :async_thread 3 E %*
call :async_thread 4 R %*
call :async_thread 5 T %*
call :async_thread 1 Y %*
call :async_thread 2 U %*
call :async_thread 3 I %*
call :async_thread 4 O %*
call :async_thread 5 P %*

:: !IMPORTANT! End editing here for your "coordinator" stuff
exit /b 0

:: -----------------------------------------------------------------------------------------------
:thread_stuff
:: !IMPORTANT! Start editing here for your "thread" stuff

echo.This thread started just now
echo.Parameters passed = %*

set l_timeout_in_seconds=%1
echo.Target thread run time = %l_timeout_in_seconds% seconds

%SystemRoot%\system32\timeout.exe /t %l_timeout_in_seconds% /nobreak

echo.This thread has done its work

:: !IMPORTANT! End editing here for your "thread" stuff
exit /b 0

:: ===============================================================================================
:: !IMPORTANT! DO NOT EDIT STUFF AFTER THIS POINT
:the_coordinator

set g_this_script=%0
if "x%DEBUG%"=="xyes" echo.This script = %g_this_script%>&2
if "x%DEBUG%"=="xyes" echo.Maximum number of active threads = %g_maximum_threads%>&2

set l_modus_operandi=child
if "x%nop77svk_async_multibatch_run%"=="x" set l_modus_operandi=master
if "x%nop77svk_async_multibatch_child%"=="x" set l_modus_operandi=master
if "x%DEBUG%"=="xyes" echo.Current modus operandi = %l_modus_operandi%>&2

if %l_modus_operandi%==child (
	if "x%DEBUG%"=="xyes" echo.I'm a run %nop77svk_async_multibatch_run%'s child #%nop77svk_async_multibatch_child%>&2
	call :thread_stuff %*
	del %TEMP%\nop77svk_async_multibatch.%nop77svk_async_multibatch_run%.%nop77svk_async_multibatch_child%.lck
) else (
	set l_run_id=%RANDOM%
	if exist %TEMP%\nop77svk_async_multibatch.%l_run_id%.*.lck (
		echo ERROR: There appear to be some active threads with the run id of %l_run_id%!
		exit /b 1
	)

	set l_child_id=0
	if "x%DEBUG%"=="xyes" echo.I'm a run %l_run_id%'s master>&2
	call :coordinator_stuff %*
	call :wait_for_active_threads_to_be_max 0
)

exit /b 0

:: -----------------------------------------------------------------------------------------------
:async_thread

set /a l_maximum_threads_minus_one=%g_maximum_threads%-1
call :wait_for_active_threads_to_be_max %l_maximum_threads_minus_one%

set /a l_child_id=l_child_id+1
echo.>%TEMP%\nop77svk_async_multibatch.%l_run_id%.%l_child_id%.lck

set nop77svk_async_multibatch_run=%l_run_id%
set nop77svk_async_multibatch_child=%l_child_id%
if "x%DEBUG%"=="xyes" echo.Spawning a run id %l_run_id%'s child #%l_child_id%>&2
::echo.cmd /c %g_this_script% %*
::cmd /c %g_this_script% %*
start cmd /c %g_this_script% %*
set nop77svk_async_multibatch_run=
set nop77svk_async_multibatch_child=

exit /b 0

:: -----------------------------------------------------------------------------------------------
:wait_for_active_threads_to_be_max

set l_max_no_of_active_threads=%1
if "x%l_max_no_of_active_threads%"=="x" set l_max_no_of_active_threads=0

setlocal EnableExtensions
:loop
for /f %%a in ('dir /one /b %TEMP%\nop77svk_async_multibatch.%l_run_id%.*.lck 2^>nul ^| %SystemRoot%\System32\find.exe /c ".lck"') do set l_active_threads=%%a
if "x%l_active_threads%"=="x" set l_active_threads=0
if "x%DEBUG%"=="xyes" echo.Active threads = %l_active_threads%, waiting for maximum of %l_max_no_of_active_threads% acive threads >&2
if %l_active_threads% gtr %l_max_no_of_active_threads% (
	if "x%DEBUG%"=="xyes" (
		%SystemRoot%\system32\timeout.exe /t 1 /nobreak >&2
	) else (
		%SystemRoot%\system32\timeout.exe /t 1 /nobreak >nul
	)
	goto :loop
)
endlocal

exit /b 0
