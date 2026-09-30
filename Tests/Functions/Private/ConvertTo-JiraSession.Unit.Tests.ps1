#requires -modules @{ ModuleName = "Pester"; ModuleVersion = "6.2"; MaximumVersion = "6.999" }

BeforeDiscovery {
    . "$PSScriptRoot/../../Helpers/TestTools.ps1"

    $script:moduleToTest = Initialize-TestEnvironment
}

InModuleScope JiraPSVII {
    Describe "ConvertTo-JiraSession" -Tag 'Unit' {
        BeforeAll {
            . "$PSScriptRoot/../../Helpers/TestTools.ps1"

            #region Definitions
            $script:sampleUsername = 'powershell-test'
            $script:sampleSession = @{}
            #endregion Definitions

            #region Mocks
            #endregion Mocks
        }

        Describe "Behavior" {
            Context "Object Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername
                }

                It "creates PSObject from session data" {
                    $result | Should -Not -BeNullOrEmpty
                }

                It "adds custom type 'AtlassianPSVII.JiraPSVII.Session'" {
                    $result.PSObject.TypeNames[0] | Should -Be 'AtlassianPSVII.JiraPSVII.Session'
                }
            }

            Context "Property Mapping" {
                BeforeAll {
                    $script:result = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername
                }

                It "defines 'Username' property with correct value" {
                    $result.Username | Should -Be $sampleUsername
                }

                It "maps explicit configuration metadata when provided" {
                    $result = ConvertTo-JiraSession `
                        -Session $sampleSession `
                        -Username $sampleUsername `
                        -DeploymentType Cloud `
                        -AuthenticationType OAuth `
                        -CloudId '00000000-0000-0000-0000-000000000000'

                    $result.DeploymentType | Should -Be 'Cloud'
                    $result.AuthenticationType | Should -Be 'OAuth'
                    $result.CloudId | Should -Be '00000000-0000-0000-0000-000000000000'
                }
            }

            Context "Type Conversion" {
                BeforeAll {
                    $script:result = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername
                }

                It "converts Username to correct type" {
                    $result.Username | Should -BeOfType [string]
                }
            }

            Context "Pipeline Support" {
                It "accepts session parameter" {
                    $result = ConvertTo-JiraSession -Session $sampleSession -Username $sampleUsername
                    $result | Should -Not -BeNullOrEmpty
                }
            }
        }
    }
}
