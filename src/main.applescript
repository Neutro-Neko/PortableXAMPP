on run
	-- 1.1 Universal Config File Initialization
	set appSupportDir to POSIX path of (path to application support from user domain)
	set sharedDir to appSupportDir & "PortableXAMPP"
	set configFile to sharedDir & "/config.conf"
	
	-- Ensure the global Shared directory exists natively
	try
		do shell script "mkdir -p " & quoted form of sharedDir
	end try
	
	-- 1.2 Dynamic Config Generation & Validation Gate
	set configExists to false
	try
		do shell script "test -f " & quoted form of configFile
		set configExists to true
	end try
	
	if not configExists then
		try
			do shell script "printf 'TARGET_DIR=INSERT_YOUR_WEB_FOLDER_PATH_HERE\\nSANDBOX=OFF\\nSUDO_TOOL=AUTO\\nSAVE_LOGS=OFF\\n' > " & quoted form of configFile
		end try
	end if
	
	-- Parse Config File
	set targetFolder to ""
	set saveLogs to "OFF"
	try
		set configLines to paragraphs of (do shell script "cat " & quoted form of configFile)
		repeat with currentLine in configLines
			if currentLine contains "=" then
				set keyName to text 1 thru ((offset of "=" in currentLine) - 1) of currentLine
				set valStr to text ((offset of "=" in currentLine) + 1) thru -1 of currentLine
				set valStr to do shell script "echo " & quoted form of valStr & " | xargs"
				
				if keyName is "TARGET_DIR" then
					set targetFolder to valStr
				else if keyName is "SAVE_LOGS" then
					set saveLogs to valStr
				end if
			end if
		end repeat
	end try
	
	-- 1.3 Configuration Validation Gate
	if targetFolder is "" or targetFolder is "INSERT_YOUR_WEB_FOLDER_PATH_HERE" then
		-- 1.4 Native Instructional UI Hook
		display dialog "Please paste the absolute path to your project folder into the configuration file that will now open, save it, and relaunch the app." with title "Configuration Required" buttons {"Edit Config", "Quit"} default button "Edit Config" with icon caution
		if button returned of result is "Edit Config" then
			-- 1.5 TextEdit Routing
			do shell script "open -a TextEdit " & quoted form of configFile
		end if
		return -- Halt execution
	end if
	
	-- 1.6 TCC (Transparency, Consent, and Control) Trigger
	try
		set triggerTCC to (POSIX file targetFolder) as alias
	on error
		display dialog "The path specified in config.conf is invalid or inaccessible: " & targetFolder & return & "Please correct the path and relaunch." with title "Invalid Path" buttons {"Edit Config", "Quit"} default button "Edit Config" with icon stop
		if button returned of result is "Edit Config" then
			do shell script "open -a TextEdit " & quoted form of configFile
		end if
		return
	end try
	
	-- Dependency Check Configurator
	set missingPkgs to ""
	try
		do shell script "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; command -v brew"
	on error
		display dialog "Homebrew is required but not found. Please install Homebrew." with title "Missing Dependency" buttons {"OK"} default button "OK" with icon stop
		return -- exit run handler
	end try
	
	set pkgs to {"httpd", "mysql", "php"}
	repeat with pkg in pkgs
		try
			do shell script "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; brew list " & pkg
		on error
			set missingPkgs to missingPkgs & " " & pkg
		end try
	end repeat
	
	if missingPkgs is not "" then
		display dialog "XAMPP needs to install missing Homebrew dependencies:" & missingPkgs & ". A Terminal window will open to run the installation. Once finished, please relaunch XAMPP." with title "Installing Dependencies" buttons {"OK"} default button "OK"
		tell application "Terminal"
			do script "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; brew install" & missingPkgs & "; echo 'Installation complete. You can close this window and launch XAMPP again.'; exit"
		end tell
		continue quit
		return
	end if
	
	-- Auto-Inject UI Template
	try
		set uiTemplatePath to POSIX path of (path to resource "UI_Template")
		-- Use cp -Rn to avoid overwriting existing UI files
		do shell script "cp -Rn " & quoted form of uiTemplatePath & "/.XAMPPconfig " & quoted form of targetFolder & " || true"
		do shell script "cp -n " & quoted form of uiTemplatePath & "/.htaccess " & quoted form of targetFolder & "/.htaccess || true"
	end try
	
	-- Generate Micro-Config for zero-setup portability
	try
		set microConfig to targetFolder & "/.XAMPPconfig/micro.conf"
		
		-- Universal macOS Logging in /Users/Shared/
		set sharedLogsDir to sharedDir & "/logs/"
		set projectName to do shell script "basename " & quoted form of targetFolder
		set projectLogsDir to sharedLogsDir & projectName
		do shell script "mkdir -p " & quoted form of projectLogsDir
		
		set errorLogPath to projectLogsDir & "/apache_error.log"
		set configContent to "DocumentRoot \"" & targetFolder & "\"
ErrorLog \"" & errorLogPath & "\"
LogLevel debug
<Directory \"" & targetFolder & "\">
Options Indexes FollowSymLinks
AllowOverride All
Require all granted
</Directory>
"
		set fileRef to open for access POSIX file microConfig with write permission
		set eof of fileRef to 0
		write configContent to fileRef starting at eof
		close access fileRef
	on error errMsg
		try
			close access fileRef
		end try
		display dialog "Failed to generate micro-configuration: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
	
	set startupLog to quoted form of (projectLogsDir & "/startup.log")
	
	set redirOp to ">"
	if saveLogs is "ON" then
		set redirOp to ">>"
	else
		-- Clear old logs if not saving them
		try
			do shell script "> " & quoted form of errorLogPath
			do shell script "> " & startupLog
		end try
	end if
	
	-- Start MySQL with Homebrew PATH exported and output redirected to log
	try
		do shell script "export PATH=/opt/homebrew/bin:$PATH; /opt/homebrew/bin/mysql.server start " & redirOp & " " & startupLog & " 2>&1"
	on error errMsg
		display dialog "Failed to start MySQL: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
	
	-- Start Apache with Homebrew PATH exported, sandboxed, and using the Micro-Config Include
	try
		set jailPath to POSIX path of (path to resource "xampp-jail.sb")
		-- 1.7 Sandbox Parameter Passing & Micro-Config Injection
		do shell script "export PATH=/opt/homebrew/bin:$PATH; sandbox-exec -D WEB_ROOT=" & quoted form of targetFolder & " -D APP_SUPPORT=" & quoted form of sharedDir & " -f " & quoted form of jailPath & " /opt/homebrew/bin/httpd -c \"Include " & quoted form of microConfig & "\" -k start " & redirOp & " " & startupLog & " 2>&1"
	on error errMsg
		display dialog "Failed to start Apache: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
	
	display notification "XAMPP servers are active." with title "Portable XAMPP"
end run

on idle
	return 5
end idle

on reopen
	set appSupportDir to POSIX path of (path to application support from user domain)
	set sharedDir to appSupportDir & "PortableXAMPP"
	set configFile to sharedDir & "/config.conf"
	set logsDir to sharedDir & "/logs"
	
	set userChoice to button returned of (display dialog "Portable XAMPP Menu" buttons {"Open Config", "View Logs", "Close"} default button "Close" with title "Portable XAMPP")
	
	if userChoice is "Open Config" then
		do shell script "open -a TextEdit " & quoted form of configFile
	else if userChoice is "View Logs" then
		do shell script "open " & quoted form of logsDir
	end if
end reopen

on quit
	-- Stop Apache natively WITHOUT admin privileges
	try
		do shell script "export PATH=/opt/homebrew/bin:$PATH; /opt/homebrew/bin/httpd -k stop > /dev/null 2>&1"
	on error errMsg
	end try
	
	-- Stop MySQL
	try
		do shell script "export PATH=/opt/homebrew/bin:$PATH; /opt/homebrew/bin/mysql.server stop > /dev/null 2>&1"
	on error errMsg
	end try
	
	display notification "XAMPP servers stopped." with title "Portable XAMPP"
	continue quit
end quit
