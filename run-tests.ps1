Get-ChildItem -Filter *.fasl -Recurse | Remove-Item -Force

$sbcl = Get-Command sbcl -ErrorAction SilentlyContinue
$lw = Get-Command lw-console -ErrorAction SilentlyContinue

$found = $false
$sbclLast = "not run"
$lwLast = "not run"
$status = 0
if ($sbcl) {
    $sbclLog = New-TemporaryFile
    & $sbcl.Path `
        --noinform `
        --non-interactive `
        --load alive-lsp.asd `
        --eval '(asdf:load-system :alive-lsp/test)' `
        --eval '(alive/test/coverage:run)' 2>&1 | Tee-Object -FilePath $sbclLog
    $sbclLast = Get-Content $sbclLog | Select-Object -Last 1
    if ($LASTEXITCODE -ne 0) { $status = 1 }
    Remove-Item $sbclLog -Force
    $found = $true
}

if ($lw) {
    $lwLog = New-TemporaryFile
    & $lw.Path -load .\run-tests-lw.lisp 2>&1 | Tee-Object -FilePath $lwLog
    $lwLast = Get-Content $lwLog | Select-Object -Last 1
    if ($LASTEXITCODE -ne 0) { $status = 1 }
    Remove-Item $lwLog -Force
    $found = $true
}

if (-not $found) {
    Write-Error "No SBCL or LispWorks found in PATH."
    exit 1
}

Write-Host "SBCL: $sbclLast"
Write-Host "LispWorks: $lwLast"
exit $status
