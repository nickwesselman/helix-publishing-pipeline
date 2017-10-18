. "$PSScriptRoot/utils/WebConfig.ps1"
. "$PSScriptRoot/utils/MSBuild.ps1"
. "$PSScriptRoot/utils/MSDeploy.ps1"

$fixtures = @{
    default = @{
        Solution = "$PSScriptRoot\fixtures/default/HelixBuild.Sample.Web.sln";
        Project1 = "$PSScriptRoot\fixtures/default/Projects\HelixBuild.Sample.Web\HelixBuild.Sample.Web.csproj";
    }
    
}

$count = 1

Describe "Turnkey" {

    Context "building package with default settings" {
        $projectPath = $fixtures.default.Project1
        $projectDir = Split-Path $projectPath -Parent

        Invoke-MSBuild -Project $projectPath -Properties @{
            "DeployOnBuild" = "true";
            "PublishProfile" = "Package";
            "DeployAsIisApp" = "false";
        }

        $packageFilename = Join-Path $projectDir "obj\Debug\Package\HelixBuild.Sample.Web.zip"

        $packageParameters = Get-MSDeployPackageParameters $packageFilename
        $packageParameterNames = $packageParameters.Keys

        $packageFiles = Get-MSDeployPackageFiles $packageFilename

        $webConfigXml = [xml](Get-MSDeployPackageFileContent -PackagePath $packageFilename -FilePath "Web.config")

        It "should include web deploy parameters from the packaged project" {
            $packageParameterNames -contains "Project-Parameter1" | Should Be $true
        }

        It "should include web deploy parameters from all feature modules" {
            $packageParameterNames -contains "Feature1-Parameter1" | Should Be $true
        }

        It "should include web deploy parameters from all foundation modules" {
            $packageParameterNames -contains "Foundation1-Parameter1" | Should Be $true
        }

        It "should include content from the packaged project" {
            $packageFiles -contains "App_Config\Include\HelixBuild.Sample.Web.config" | Should Be $true
        }

        It "should include content from the all feature modules" {
            $packageFiles -contains "App_Config\Include\HelixBuild.Feature1.config" | Should Be $true  
        }

        It "should include content from the all foundation modules" {
            $packageFiles -contains "App_Config\Include\HelixBuild.Foundation1.config" | Should Be $true
            
        }

        It "should include Web.config from the packaged project" {
            (Get-WebConfigAppSetting $webConfigXml "HelixProject") | Should Be "Sample.Web"
        }

        It "should not include include Web.config from any feature modules" {
            (Get-WebConfigAppSetting $webConfigXml "HelixBuild.Feature1") | Should Be $null
        }

        It "should not include include Web.config from any foundation modules" {
            (Get-WebConfigAppSetting $webConfigXml "HelixBuild.Foundation1") | Should Be $null
        }

        It "should include Web.Helix.config transforms from feature modules" {
            (Get-WebConfigAppSetting $webConfigXml "Feature1.ConfigKey") | Should Be "Feature1.ConfigValue"
        }

        It "should include Web.Helix.config transforms from foundation modules" {
            (Get-WebConfigAppSetting $webConfigXml "Foundation1.ConfigKey") | Should Be "Foundation1.ConfigValue"
        }
    }
}