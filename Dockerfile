# Use Windows Nano Server as the base image
FROM mcr.microsoft.com/windows/nanoserver:latest

# Install IIS and PHP
USER ContainerAdministrator
RUN powershell -Command \
    # Download the required packages \
    Add-WindowsPackage -Online -Name Microsoft-Windows-Server-AppCompat-Feature; \
    Invoke-WebRequest -Uri https://windows.php.net/downloads/releases/php-7.4.24-nts-Win32-vc15-x64.zip -OutFile c:\php.zip; \
    Expand-Archive -Path c:\php.zip -DestinationPath c:\php; \
    Remove-Item c:\php.zip -Force; \
    # Install IIS \
    Install-WindowsFeature -Name Web-Server; \
    # Configure PHP for IIS \
    & 'C:\Windows\System32\inetsrv\appcmd.exe' set config /section:system.webServer/fastCGI /+'[fullPath=''C:\php\php-cgi.exe'']'; \
    # Clean up the package cache \
    Remove-Item -Force -Recurse C:\Windows\servicing\Packages\*

# Configure IIS
RUN powershell -Command \
    Import-module IISAdministration; \
    New-IISSite -Name "Site" -PhysicalPath C:\inetpub\wwwroot -BindingInformation "*:80:"

# Expose the port for the IIS site
EXPOSE 80

# Optional: Set a healthcheck
HEALTHCHECK --interval=5s `
 CMD powershell -command `
    try { `
     $response = iwr http://localhost -UseBasicParsing; `
     if ($response.StatusCode -eq 200) { return 0} `
     else {return 1}; `
    } catch { return 1 }

# Optional: Set the default shell to PowerShell
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
