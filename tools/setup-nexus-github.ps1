param(
    [Parameter(Mandatory = $true)]
    [string]$ModId,

    [Parameter(Mandatory = $true)]
    [string]$FileId,

    [string]$ApiKey = $env:NEXUSMODS_API_KEY,

    [string]$Repo = "cmoates/QuickSalvage"
)

$ErrorActionPreference = "Stop"

if (-not $ApiKey) {
    $secure = Read-Host "Nexus API key (https://www.nexusmods.com/settings/api-keys)" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $ApiKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

if (-not $ApiKey) {
    throw "NEXUSMODS_API_KEY is required."
}

gh secret set NEXUSMODS_API_KEY --repo $Repo --body $ApiKey
gh variable set NEXUSMODS_MOD_ID --repo $Repo --body $ModId
gh variable set NEXUSMODS_FILE_ID --repo $Repo --body $FileId
gh variable set NEXUSMODS_UPLOAD_ENABLED --repo $Repo --body "true"

Write-Host "Configured $Repo for Nexus CI uploads."
Write-Host "  NEXUSMODS_MOD_ID=$ModId"
Write-Host "  NEXUSMODS_FILE_ID=$FileId"
Write-Host "  NEXUSMODS_UPLOAD_ENABLED=true"
