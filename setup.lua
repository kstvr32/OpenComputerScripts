-- wget https://raw.githubusercontent.com/kstvr32/OpenComputerScripts/main/setup.lua && setup

local shell = require('shell')
local filesystem = require("filesystem")
local args = {...}
local branch
local repo
local libs = {
    'crc32.lua',
    'deflate.lua',
    'item.lua',
    'json.lua',
    'log.lua',
    'nbt.lua'
}
local scripts = {
    'test.lua',
    'blackhole.lua'
}

local workDir = "/home/"

-- BRANCH
if #args >= 1 then
    branch = args[1]
else
    branch = 'main'
end

-- REPO
if #args >= 2 then
    repo = args[2]
else
    repo = 'https://raw.githubusercontent.com/kstvr32/OpenComputerScripts/'
end

-- INSTALL LIB
local libDir = workDir .. "lib/"

print("Removing Library")
filesystem.remove(libDir)

print("Creating Library")
filesystem.makeDirectory(libDir)
shell.setWorkingDirectory(libDir)
for i=1, #libs do
    shell.execute(string.format('wget -f %s%s/lib/%s', repo, branch, libs[i]))
end

-- INSTALL SCRIPTS
local scriptDir = workDir .. "scripts/"

print("Removing Scripts")
filesystem.remove(scriptDir)

print("Creating Scripts")
filesystem.makeDirectory(scriptDir)
shell.setWorkingDirectory(scriptDir)
for i=1, #scripts do
    shell.execute(string.format('wget -f %s%s/scripts/%s', repo, branch, scripts[i]))
end

-- SET SHELL CONTEXT
shell.setWorkingDirectory(workDir)