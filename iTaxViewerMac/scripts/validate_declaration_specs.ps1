param([string]$RepositoryRoot = (Join-Path $PSScriptRoot '../..'))
$ErrorActionPreference = 'Stop'
$expected = @{
    '864' = @('16','17','18','19','20','21','22','23','24','25','25.1','26','27','28','29','30','31','32')
    '395' = @(21..46 | ForEach-Object { [string]$_ })
    '07' = @(21..33 | ForEach-Object { [string]$_ })
    '847' = @(21..32 | ForEach-Object { [string]$_ })
}
foreach ($code in $expected.Keys | Sort-Object) {
    $directory = Join-Path $RepositoryRoot "docs/reverse-engineering/forms/$code"
    $spec = Get-Content -LiteralPath (Join-Path $directory 'spec.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $actual = @($spec.rows | ForEach-Object { $_.codes } | Sort-Object -Unique)
    if (Compare-Object ($expected[$code] | Sort-Object) $actual) { throw "Indicator coverage mismatch: $code" }
    if ($spec.rows | Where-Object { !$_.label -or !$_.source.line -or !$_.values.Count }) { throw "Incomplete traceability: $code" }
    if ($code -eq '864' -and ($spec.rows | Where-Object indicator -eq '21').unit -ne ([char]86 + 'N' + [char]272)) { throw '864 ct21 must be currency' }
    if ($code -eq '395' -and ($spec.rows | Where-Object indicator -eq '42').unit -eq 'VN' + [char]272) { throw '395 ct42 must be people' }
    foreach ($variant in @('minimal','empty','negative')) {
        [xml]$fixture = Get-Content -LiteralPath (Join-Path $directory "fixtures/$variant.xml") -Raw -Encoding UTF8
        if ($fixture.SelectSingleNode('//NNT/mst').InnerText -ne '0000000000') { throw "Non-synthetic identity in fixture: $code" }
        $main = $fixture.SelectSingleNode('//CTieuTKhaiChinh')
        foreach ($row in $spec.rows) {
            foreach ($value in $row.values) {
                $path = switch ($value.root) { 'ktru' { 'NVuKhauTruThue/' + $value.path }; 'qtoan' { 'NVuQToanThay/' + $value.path }; default { $value.path } }
                if (!$main.SelectSingleNode($path)) { throw "Missing mapped indicator in $code/$variant" }
            }
        }
        foreach ($table in $spec.repeatedTables) {
            $records = $main.SelectNodes($table.recordPath)
            if ($variant -eq 'empty' -and $records.Count -ne 0) { throw "Empty repeating table mismatch: $code" }
            foreach ($record in $records) { foreach ($column in $table.columns) { if (!$record.SelectSingleNode($column.source)) { throw "Missing repeating field: $code" } } }
            foreach ($total in $table.totals) { if (!$main.SelectSingleNode($total.source)) { throw "Missing repeating total: $code" } }
        }
    }
    Write-Output "$code mapping and synthetic fixtures: PASS"
}
