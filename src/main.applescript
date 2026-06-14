on run
	-- 1.1 Config File Resolution Initialization
	set configFile to ""
	try
		set configFile to POSIX path of (path to resource "web_path.conf")
	on error
		-- Get path to Resources folder using an existing resource
		set jailPath to POSIX path of (path to resource "xampp-jail.sb")
		set resourcesFolder to do shell script "dirname " & quoted form of jailPath
		set configFile to resourcesFolder & "/web_path.conf"
	end try
	
	-- 1.2 Dynamic Config Generation & Validation Gate
	set configExists to false
	try
		do shell script "test -f " & quoted form of configFile
		set configExists to true
	end try
	
	if not configExists then
		try
			do shell script "echo 'INSERT_YOUR_WEB_FOLDER_PATH_HERE' > " & quoted form of configFile
		end try
	end if
	
	-- Read target path from config file
	set targetFolder to ""
	try
		set targetFolder to do shell script "cat " & quoted form of configFile
		-- Trim any whitespace
		set targetFolder to do shell script "echo " & quoted form of targetFolder & " | xargs"
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
		display dialog "The path specified in web_path.conf is invalid or inaccessible: " & targetFolder & return & "Please correct the path and relaunch." with title "Invalid Path" buttons {"Edit Config", "Quit"} default button "Edit Config" with icon stop
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
		set microConfig to targetFolder & "/.XAMPPconfig/overrides/micro.conf"
		do shell script "printf 'DocumentRoot \"%s\"\\n<Directory \"%s\">\\nOptions Indexes FollowSymLinks\\nAllowOverride All\\nRequire all granted\\n</Directory>\\n' " & quoted form of targetFolder & " " & quoted form of targetFolder & " > " & quoted form of microConfig
	on error errMsg
		display dialog "Failed to generate micro-configuration: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try

	-- Start MySQL with Homebrew PATH exported and output redirected to avoid hanging
	try
		do shell script "export PATH=/opt/homebrew/bin:$PATH; /opt/homebrew/bin/mysql.server start > /dev/null 2>&1"
	on error errMsg
		display dialog "Failed to start MySQL: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
	
	-- Start Apache with Homebrew PATH exported, sandboxed, and using the Micro-Config Include
	try
		set jailPath to POSIX path of (path to resource "xampp-jail.sb")
		-- 1.7 Sandbox Parameter Passing & Micro-Config Injection
		do shell script "export PATH=/opt/homebrew/bin:$PATH; sandbox-exec -D WEB_ROOT=" & quoted form of targetFolder & " -f " & quoted form of jailPath & " /opt/homebrew/bin/httpd -c \"Include " & quoted form of microConfig & "\" -k start > /dev/null 2>&1"
	on error errMsg
		display dialog "Failed to start Apache: " & errMsg buttons {"OK"} default button "OK" with icon stop
	end try
	
	display notification "XAMPP servers are active." with title "XAMPP Manager"
end run

on idle
	return 5
end idle

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
	
	display notification "XAMPP servers stopped." with title "XAMPP Manager"
	continue quit
end quit