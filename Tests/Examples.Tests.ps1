#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

Describe "Validation of example codes in the documentation" -Tag Documentation, NotImplemented -Skip {
    BeforeAll {
        $script:commands = Get-Command -Module JiraPSVII -CommandType Cmdlet, Function
        $script:module = Get-Module JiraPSVII
    }

    Describe "Examples" {
        Describe "Examples for <_.Name>" -ForEach $commands -AllowNullOrEmptyForEach {
            BeforeAll {
                $script:command = $_
                $script:help = Get-Help $command
            }

            # TODO:
            It "should have examples implemented as tests" {
                $true | Should -Be $true
            }
        }
    }
}
