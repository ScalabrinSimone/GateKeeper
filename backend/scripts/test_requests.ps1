$base = 'http://127.0.0.1:8000'

Write-Output '1) Create user'
Write-Output '1) Create user'
$body = @{ username='mario'; password='secret' } | ConvertTo-Json
Invoke-RestMethod -Uri "$base/users" -Method Post -ContentType 'application/json' -Body $body | ConvertTo-Json

Write-Output '2) Add device'
$body = @{ name='Sensor1' } | ConvertTo-Json
Invoke-RestMethod -Uri "$base/devices" -Method Post -ContentType 'application/json' -Body $body | ConvertTo-Json

Write-Output '3) Associate user to device'
$body = @{ user_id=1; device_id=1 } | ConvertTo-Json
Invoke-RestMethod -Uri "$base/associate" -Method Post -ContentType 'application/json' -Body $body | ConvertTo-Json

Write-Output '4) Add log'
$body = @{ user_id=1; device_id=1; action='ENTRATO' } | ConvertTo-Json
Invoke-RestMethod -Uri "$base/logs" -Method Post -ContentType 'application/json' -Body $body | ConvertTo-Json

Write-Output '5) List logs'
Invoke-RestMethod -Uri "$base/logs"
