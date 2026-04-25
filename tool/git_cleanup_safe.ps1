param(
  [switch]$WithFlutterClean,
  [switch]$DeleteUntracked,
  [switch]$DeleteIgnored
)

$ErrorActionPreference = "Stop"

Write-Host "== Git status (before) =="
git status --short

Write-Host ""
Write-Host "== Restore generated plugin registrants =="
git restore -- `
  linux/flutter/generated_plugin_registrant.cc `
  linux/flutter/generated_plugins.cmake `
  macos/Flutter/GeneratedPluginRegistrant.swift `
  windows/flutter/generated_plugin_registrant.cc `
  windows/flutter/generated_plugins.cmake 2>$null

if ($WithFlutterClean) {
  Write-Host ""
  Write-Host "== flutter clean =="
  flutter clean
}

Write-Host ""
Write-Host "== Dry-run untracked =="
git clean -nd

Write-Host ""
Write-Host "== Dry-run ignored =="
git clean -ndX

if ($DeleteUntracked) {
  Write-Host ""
  Write-Host "== Delete untracked =="
  git clean -fd
}

if ($DeleteIgnored) {
  Write-Host ""
  Write-Host "== Delete ignored =="
  git clean -fdX
}

Write-Host ""
Write-Host "== Git status (after) =="
git status --short
