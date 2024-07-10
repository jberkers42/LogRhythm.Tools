using namespace System
using namespace System.Collections.Generic
using namespace System.Diagnostics

Function Get-LrAieRule {
  <#
    .SYNOPSIS
        Get AIE Rule Definition.
    .DESCRIPTION
        The Get-LrAieRule cmdlet retrieves the current definition
        of the AIE Rule via the Web Console Services Host API.

        The API is somewhat undocumented, and is what is used to render
        AIE Rule structure data in the Web Console for users that have
        permissions to see this information.

        https://community.logrhythm.com/t5/AI-Engine-Rules/AIE-Drilldown-API/m-p/44276#M1295%C2%A0

        This function will only work on a host that has the LogRhythm API Gateway installed and running,
        It uses the loopback address (127.0.0.1), and does not work if any other address is used.
    .PARAMETER Credential
        [PSCredential] containing an API Token in the Password field.

        **Note**
        The Credential parameter can be omitted if a [PSCredential]
        containing the LogRhythm Bearer Token is set to the preference
        variable $LrtConfig.LogRhythm.ApiKey.
    .PARAMETER Id
        The Id of the LogRhythm AIE Rule.
    .INPUTS
        System.Int32 -> Id
    .OUTPUTS
        PSCustomObject representing the AIE Rule Definition.
    .EXAMPLE
        PS C:\> Get-LrAieRule -Credential $token -Id 3
        ---
        id                             : System.Int32
        name                           : System.String
        ruleGroup                      : System.String
        description                    : System.String
        details                        : System.String
        alarmRule                      : System.Object
        commonEvent                    : System.Object
        supression                     : System.Int32
        supressionEff                  : System.Int32
        permissions                    : System.Object
        runtimePriority                : System.Object
        environmentalDependencyFactory : System.Object
        falsePositiveProbability       : System.Object
        accessType                     : System.Object
        eventForwardingEnabled         : System.Boolean
        blocks                         : [System.Object]
    .NOTES
        This API Endpoint is not formally documented, and may be subject to change.
    .LINK
        https://github.com/LogRhythm-Tools/LogRhythm.Tools
    #>

  #region: Parameters
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true,
      Position = 0)]
    [int] $Id,

    [Parameter(Mandatory = $false,
      Position = 1)]
    [ValidateNotNull()]
    [pscredential] $Credential = $LrtConfig.LogRhythm.ApiKey
  )
  #endregion
  #region: Begin
  Begin {
    $Me = $MyInvocation.MyCommand.Name

    $BaseUrl = $LrtConfig.LogRhythm.BaseUrl
    $Token = $Credential.GetNetworkCredential().Password

    # Request Headers
    $Headers = [Dictionary[string, string]]::new()
    $Headers.Add("Authorization", "Bearer $Token")
    $Headers.Add("Accept", "*/*")
    $Headers.Add("Content-Type", "application/json")
    $Headers.Add("User-Agent", "LogRhythm.Tools/1.3.3-dev")

    $Method = $HttpMethod.Post

    $UserId = (Get-LrApiTokenInfo).UserId

    # Enable self-signed certificates and Tls1.2
    Enable-TrustAllCertsPolicy

    # Base URL
    # This API Endpoint only responds when being called via 127.0.0.1.
    # This function can only be used on a host that is a part of the LR Deployment.
    $BaseUrl = 'https://127.0.0.1:8501'

    # Request URI
    $RequestUrl = $BaseUrl + "/lr-services-host-api/actions/domainobject"
  }
  #endregion

  #region: Process
  Process {
    Write-Verbose "[$Me]: Request URL: $RequestUrl"

    # Request Body
    $RequestBody = @{
      source = ''
      destination = 'DomainObjectService'
      messageType = 'GetObjectRequest'
      ver = 1
      data = @{
        objectType = 'AieRule'
        userId     = $UserId
        objectId = $Id
      }
    }
    # Send Request
    $Response = Invoke-RestAPIMethod -Uri $RequestUrl -Headers $Headers -Method $Method -Origin $Me -Body ($RequestBody | ConvertTo-Json)
    if (($null -ne $Response.Error) -and ($Response.Error -eq $true)) {
      return $Response
    }

    #region: Process Result
    return $Response
    #endregion
  }
}