# -----------------------------
# CHANGE THESE VARIABLES PLEASE
# -----------------------------
#  Example:  $server = "http://192.168.1.88" or $server = "http://CxServer01"
$server = "<<CHANGE ME>>"
$cxUsername = "<<USER NAME>>"
$cxPassword = "<<USER PASSWD>>"
# -----------------------------

# DO NO CHANGE BELOW THIS LINE PLEASE
$serverRestEndpoint = $server + "/cxrestapi/"
$scanID = $args[0]
$serverRestEndpoint = $server + "/cxrestapi/"
function getOAuth2Token(){
    $body = @{
        username = $cxUsername
        password = $cxPassword
        grant_type = "password"
        scope = "sast_rest_api"
        client_id = "resource_owner_client"
        client_secret = "014DF517-39D1-4453-B7B3-9930C563627C"
    }
    
    try {
        $response = Invoke-RestMethod -uri "${serverRestEndpoint}auth/identity/connect/token" -method post -body $body -contenttype 'application/x-www-form-urlencoded'
    } catch {
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        throw "Could not authenticate"
    }
    
    return $response.token_type + " " + $response.access_token
}

function generateReport($scanId){
    $headers = @{
        Authorization = $token
    }
    $body = @{
        reportType = "PDF"
        scanId = $scanId
    }
    try {
        $response = Invoke-RestMethod -uri "${serverRestEndpoint}reports/sastScan" -method post -Headers $headers -Body $body
        return $response
    } catch { 
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        throw "Cannot Generate Report"
    }
}

function getReport($reportUri){
    $headers = @{
        Authorization = $token
    }
    try {
        $response = Invoke-RestMethod -uri "${serverRestEndpoint}${reportUri}" -method get -Headers $headers
        return $response
    } catch { 
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        throw "Failed to Get Report"
    }
}

function getReportStatus($reportStatusUri){
    $headers = @{
        Authorization = $token
    }
    try {
        $response = Invoke-RestMethod -uri "${serverRestEndpoint}${reportStatusUri}" -method get -Headers $headers
        return $response.status.value
    } catch { 
        Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__
        Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
        throw "Failed to Get Report Status"
    }
}

$token = getOAuth2Token
$createReport = generateReport $scanId
if($createReport){
    $reportStatusUri = $createReport.links.status.uri
    $reportUri = $createReport.links.report.uri
    $reportId = $createReport.reportId
    $reportStatus = "InProcess"
    $pastReportStatus = $reportStatus
    write-host "Report phase : ${reportStatus} ..."
    while($reportStatus -ne "Created"){
        $reportStatus = getReportStatus($reportStatusUri)
        if ($pastReportStatus -ne $reportStatus){
            write-host "Report phase : ${reportStatus} ..."
            $pastReportStatus = $reportStatus
        }
    }
	Start-Sleep -s 3
    write-host "Report Finished ${reportId} - Scan ${scanId} - Project ${projectName}"
    $report = getReport $reportUri
}else{
    write-host "Error getting Report of Scan ${scanId}"
}

# write-host $token

