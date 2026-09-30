#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "Invoke-JiraWebRequestSafely" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            if (-not ('JiraPSVII.Tests.FakeWebRequestException' -as [type])) {
                Add-Type -TypeDefinition @"
namespace JiraPSVII.Tests {
    public class FakeWebRequestException : System.Exception {
        public object Response { get; private set; }
        public FakeWebRequestException(string message, object response) : base(message) {
            Response = response;
        }
    }
}
"@
            }
        }

        It "returns web response with no exception on success" {
            $expectedResponse = [PSCustomObject]@{
                StatusCode = [System.Net.HttpStatusCode]::OK
            }
            Mock Invoke-WebRequest -ModuleName 'JiraPSVII' { $expectedResponse }

            $result = Invoke-JiraWebRequestSafely -SplatParameters @{
                Uri     = 'https://jira.example.com/rest/api/2/myself'
                Method  = 'GET'
                Headers = @{}
            }

            $result.WebResponse | Should -Be $expectedResponse
            $result.Exception | Should -BeNullOrEmpty
        }

        It "returns exception and falls back to the exception response object" {
            $fallbackResponse = [PSCustomObject]@{
                StatusCode = [System.Net.HttpStatusCode]::ServiceUnavailable
            }
            Mock Invoke-WebRequest -ModuleName 'JiraPSVII' {
                throw [JiraPSVII.Tests.FakeWebRequestException]::new('boom', $fallbackResponse)
            }

            $result = Invoke-JiraWebRequestSafely -SplatParameters @{
                Uri     = 'https://jira.example.com/rest/api/2/myself'
                Method  = 'GET'
                Headers = @{}
            }

            $result.Exception | Should -Not -BeNullOrEmpty
            $result.WebResponse | Should -Be $fallbackResponse
        }

        It "captures session variable name and value when SessionVariable is used" {
            $capturedSession = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
            Mock Get-Variable -ModuleName 'JiraPSVII' -ParameterFilter {
                $Name -eq 'newSessionVar' -and $Scope -eq 'Local'
            } {
                [PSCustomObject]@{
                    Value = $capturedSession
                }
            }
            Mock Invoke-WebRequest -ModuleName 'JiraPSVII' {
                [PSCustomObject]@{
                    StatusCode = [System.Net.HttpStatusCode]::OK
                }
            }

            $result = Invoke-JiraWebRequestSafely -SplatParameters @{
                Uri             = 'https://jira.example.com/rest/api/2/myself'
                Method          = 'GET'
                Headers         = @{}
                SessionVariable = 'newSessionVar'
            }

            $result.SessionVariableName | Should -Be 'newSessionVar'
            $result.SessionVariableValue | Should -Be $capturedSession
        }

        It "returns null session value when SessionVariable is requested but not available in scope" {
            Mock Get-Variable -ModuleName 'JiraPSVII' -ParameterFilter {
                $Name -eq 'missingSessionVar' -and $Scope -eq 'Local'
            } { $null }
            Mock Invoke-WebRequest -ModuleName 'JiraPSVII' {
                [PSCustomObject]@{
                    StatusCode = [System.Net.HttpStatusCode]::OK
                }
            }

            $result = Invoke-JiraWebRequestSafely -SplatParameters @{
                Uri             = 'https://jira.example.com/rest/api/2/myself'
                Method          = 'GET'
                Headers         = @{}
                SessionVariable = 'missingSessionVar'
            }

            $result.SessionVariableName | Should -Be 'missingSessionVar'
            $result.SessionVariableValue | Should -BeNullOrEmpty
        }

        It "restores ProgressPreference after successful requests" {
            Mock Invoke-WebRequest -ModuleName 'JiraPSVII' { [PSCustomObject]@{ StatusCode = [System.Net.HttpStatusCode]::OK } }
            $previousProgressPreference = $ProgressPreference
            $ProgressPreference = 'Continue'
            try {
                $null = Invoke-JiraWebRequestSafely -SplatParameters @{
                    Uri     = 'https://jira.example.com/rest/api/2/myself'
                    Method  = 'GET'
                    Headers = @{}
                }
                $ProgressPreference | Should -Be 'Continue'
            }
            finally {
                $ProgressPreference = $previousProgressPreference
            }
        }

        It "restores ProgressPreference when request throws" {
            Mock Invoke-WebRequest -ModuleName 'JiraPSVII' {
                throw [JiraPSVII.Tests.FakeWebRequestException]::new('boom', $null)
            }
            $previousProgressPreference = $ProgressPreference
            $ProgressPreference = 'Continue'
            try {
                $null = Invoke-JiraWebRequestSafely -SplatParameters @{
                    Uri     = 'https://jira.example.com/rest/api/2/myself'
                    Method  = 'GET'
                    Headers = @{}
                }
                $ProgressPreference | Should -Be 'Continue'
            }
            finally {
                $ProgressPreference = $previousProgressPreference
            }
        }
    }
}
