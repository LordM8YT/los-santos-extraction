$ErrorActionPreference = "Stop"

$resourceRoot = Split-Path -Parent $PSScriptRoot
$resources = Split-Path -Parent $resourceRoot
$serverBase = Split-Path -Parent $resources
$oxInventory = Join-Path $resources "[overextended]\ox_inventory"

if (-not (Test-Path -LiteralPath $oxInventory)) {
    throw "ox_inventory was not found at $oxInventory"
}

$bridgeTarget = Join-Path $oxInventory "modules\bridge\lsx"
New-Item -ItemType Directory -Force -Path $bridgeTarget | Out-Null

Copy-Item -LiteralPath (Join-Path $PSScriptRoot "bridge\server\server.lua") -Destination (Join-Path $bridgeTarget "server.lua") -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "bridge\client\client.lua") -Destination (Join-Path $bridgeTarget "client.lua") -Force

$themeTarget = Join-Path $oxInventory "web\build\assets\lsx-theme.css"
Copy-Item -LiteralPath (Join-Path $PSScriptRoot "theme\lsx-theme.css") -Destination $themeTarget -Force

$indexPath = Join-Path $oxInventory "web\build\index.html"
$index = Get-Content -LiteralPath $indexPath -Raw
if ($index -notmatch "lsx-theme.css") {
    $index = $index.Replace("</head>", "    <link rel=`"stylesheet`" href=`"./assets/lsx-theme.css`" />`r`n  </head>")
    Set-Content -LiteralPath $indexPath -Value $index -NoNewline
}

$mysqlPath = Join-Path $oxInventory "modules\mysql\server.lua"
$mysql = Get-Content -LiteralPath $mysqlPath -Raw

if ($mysql -notmatch "ENSURE_LSX_PLAYER") {
    $mysql = $mysql.Replace(
        "    UPDATE_PLAYER = 'UPDATE `{user_table}` SET inventory = ? WHERE `{user_column}` = ?',",
        "    UPDATE_PLAYER = 'UPDATE `{user_table}` SET inventory = ? WHERE `{user_column}` = ?',`r`n    ENSURE_LSX_PLAYER = 'INSERT IGNORE INTO ``lsx_players`` (``identifier``) VALUES (?)',"
    )
}

if ($mysql -notmatch "shared.framework == 'lsx'") {
    $mysql = $mysql.Replace(
        "    if shared.framework == 'ox' then`r`n        playerTable = 'character_inventory'",
        "    if shared.framework == 'lsx' then`r`n        playerTable = 'lsx_players'`r`n        playerColumn = 'identifier'`r`n        vehicleTable = 'lsx_vehicles'`r`n        vehicleColumn = 'id'`r`n    elseif shared.framework == 'ox' then`r`n        playerTable = 'character_inventory'"
    )

    $mysql = $mysql.Replace(
        "    for k, v in pairs(Query) do`r`n        Query[k] = v:gsub('{user_table}', playerTable):gsub('{user_column}', playerColumn):gsub('{vehicle_table}',",
        "    if shared.framework == 'lsx' then`r`n        MySQL.query.await([[`r`n            CREATE TABLE IF NOT EXISTS ``lsx_players`` (`r`n                ``identifier`` varchar(80) NOT NULL,`r`n                ``inventory`` longtext DEFAULT NULL,`r`n                ``created_at`` timestamp NULL DEFAULT current_timestamp(),`r`n                ``updated_at`` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),`r`n                PRIMARY KEY (``identifier``)`r`n            )`r`n        ]])`r`n`r`n        MySQL.query.await([[`r`n            CREATE TABLE IF NOT EXISTS ``lsx_vehicles`` (`r`n                ``id`` int unsigned NOT NULL AUTO_INCREMENT,`r`n                ``plate`` varchar(12) DEFAULT NULL,`r`n                ``glovebox`` longtext DEFAULT NULL,`r`n                ``trunk`` longtext DEFAULT NULL,`r`n                PRIMARY KEY (``id``),`r`n                UNIQUE KEY ``plate`` (``plate``)`r`n            )`r`n        ]])`r`n    end`r`n`r`n    for k, v in pairs(Query) do`r`n        Query[k] = v:gsub('{user_table}', playerTable):gsub('{user_column}', playerColumn):gsub('{vehicle_table}',"
    )

    $mysql = $mysql.Replace(
        "function db.loadPlayer(identifier)`r`n    local inventory = MySQL.prepare.await(Query.SELECT_PLAYER, { identifier })",
        "function db.loadPlayer(identifier)`r`n    if shared.framework == 'lsx' then`r`n        MySQL.prepare.await(Query.ENSURE_LSX_PLAYER, { identifier })`r`n    end`r`n`r`n    local inventory = MySQL.prepare.await(Query.SELECT_PLAYER, { identifier })"
    )
}

Set-Content -LiteralPath $mysqlPath -Value $mysql -NoNewline
Write-Host "Installed LSX ox_inventory bridge into $oxInventory"
