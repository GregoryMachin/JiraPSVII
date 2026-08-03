#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "5.7"; MaximumVersion = "5.999" }

Describe "Remove-JiraSession" -Tag 'Unit' {

    BeforeAll {
        . "$PSScriptRoot/../../Helpers/TestTools.ps1"
        # $VerbosePreference = 'Continue'

        $script:moduleToTest = Initialize-TestEnvironment

        #region Definitions
        #endregion Definitions

        #region Mocks
        Mock Get-JiraSession -ModuleName JiraPS {
            Write-MockDebugInfo 'Get-JiraSession'
            (Get-Module JiraPS).PrivateData.Session
        }
        #endregion Mocks
    }

    Describe "Signature" {
        BeforeAll {
            $script:command = Get-Command -Name Remove-JiraSession
        }

        Context "Parameter Types" {
            It "has a parameter '<parameter>' of type '<type>'" -TestCases @(
                @{ parameter = 'Session'; type = 'Object' }
            ) {
                param($parameter, $type)
                $command | Should -HaveParameter $parameter -Type $type
            }
        }

        Context "Mandatory Parameters" {
            # TODO: Add tests for mandatory parameters
        }

        Context "Default Values" {
            # TODO: Add tests for parameter default values
        }
    }

    Describe "Behavior" {
        Context "Session Cleanup" {
            It "Closes and removes the AtlassianPS.JiraPS.Session data from module PrivateData" {
                $commandModule = (Get-Command Remove-JiraSession).Module
                $commandModule.PrivateData = @{ Session = $true }
                $commandModule.SessionState.PSVariable.Set('JiraOAuthResourceCache', @{ Data = @('site') })
                $commandModule.PrivateData.Session | Should -Not -BeNullOrEmpty

                Remove-JiraSession

                $commandModule.PrivateData.Session | Should -BeNullOrEmpty
                $commandModule.SessionState.PSVariable.GetValue('JiraOAuthResourceCache') | Should -BeNullOrEmpty
            }

            It "clears OAuth metadata when no session exists" {
                $commandModule = (Get-Command Remove-JiraSession).Module
                $commandModule.PrivateData = @{ Session = $null }
                $commandModule.SessionState.PSVariable.Set('JiraOAuthResourceCache', @{ Data = @('site') })

                Remove-JiraSession

                $commandModule.SessionState.PSVariable.GetValue('JiraOAuthResourceCache') | Should -BeNullOrEmpty
            }
        }
    }

    Describe "Input Validation" {
        Context "Positive cases" {
            # TODO: Add positive input validation tests
        }

        Context "Negative cases" {
            # TODO: Add negative input validation tests
        }
    }
}
