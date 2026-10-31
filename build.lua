#!/usr/bin/env luajit

local GAME_NAME = "example"
local SRC_DIR = "src"
local BUILD_DIR = "build"
local CACHE_FILE = ".build_cache"
local DIR_SEP = package.config:sub(1, 1)
local GAME_BUILD_DIR = BUILD_DIR .. DIR_SEP .. GAME_NAME

local lfs = require("lfs")
local argparse = require("argparse")
local yue = require("yue")

local parser = argparse("build", "Builds the project.")
parser:flag("-a --all", "Build all files.", false)
parser:flag("-c --clear", "Clear built files", false)
local args = parser:parse()

local function mkdir_nested(dir)
    dir = dir:gsub("\\", "/")

    local accum = ""
    for item in dir:gmatch("[^/]+") do
        accum = accum .. item .. "/"

        local mode = lfs.attributes(accum, "mode")
        if mode ~= "directory" then
            local success, err = lfs.mkdir(accum)
            if not success then
                error("Failed to create directory " .. accum .. ": " .. tostring(err))
            end
        end
    end
end

local function rmdir_nested(dir)
    local root_mode = lfs.attributes(dir, "mode")
    if root_mode ~= "directory" then
        return
    end

    local function traverse(path)
        for item in lfs.dir(path) do
            if item ~= "." and item ~= ".." then
                local p = path .. DIR_SEP .. item
                local mode = lfs.attributes(p, "mode")
                if mode == "directory" then
                    rmdir_nested(p)
                else
                    os.remove(p)
                end
            end
        end
        lfs.rmdir(path)
    end

    traverse(dir)
end

local function load_build_cache()
    local cache = {}
    local f = io.open(CACHE_FILE, "r")
    if f then
        local content = f:read("*a")
        f:close()

        local chunk = load("return " .. content)
        if chunk then cache = chunk() end
    end
    return cache
end

local function save_build_cache(cache)
    local f = io.open(CACHE_FILE, "w")
    if f then
        f:write("{")
        for path, mtime in pairs(cache) do
            f:write(string.format("[%q]=%d,", path, mtime))
        end
        f:write("}\n")
        f:close()
    end
end

local function build_file(filepath)
    local filename, extension = filepath:match("([^/\\]-)%.([^/\\]+)$")
    local parent_dir = filepath:match("(.*[/\\])"):gsub(SRC_DIR, GAME_BUILD_DIR)

    if extension == "yue" then
        local f = io.open(filepath)
        if f then
            local content = f:read("*a")
            f:close()

            mkdir_nested(parent_dir)
            local o = io.open(parent_dir .. DIR_SEP .. filename .. ".lua", "w")
            if o then
                local code, error = yue.to_lua(content, { reserve_line_number = false })
                if error then
                    io.write("Error: ", error)
                    return false
                end

                o:write(code)
                o:close()
            end
        end
    end

    return true
end

local function build_game(all)
    local old_cache = load_build_cache()
    local new_cache = {}
    local built_files = 0

    mkdir_nested(GAME_BUILD_DIR)

    local function traverse(root)
        for item in lfs.dir(root) do
            if item ~= "." and item ~= ".." then
                local full_path = root .. DIR_SEP .. item
                local mode = lfs.attributes(full_path, "mode")
                if mode == "file" then
                    local mtime = lfs.attributes(full_path, "modification")
                    new_cache[full_path] = mtime

                    if all or not old_cache[full_path] or mtime > old_cache[full_path] then
                        local success = build_file(full_path)

                        if success then
                            io.write("Built ", full_path, "\n")
                            built_files = built_files + 1
                        end
                    end
                else
                    traverse(full_path)
                end
            end
        end
    end

    if lfs.attributes(SRC_DIR, "mode") == "directory" then
        traverse(SRC_DIR)
    end

    save_build_cache(new_cache)
    io.write("Built ", built_files, " files\n")
end

local function clear_build()
    rmdir_nested(BUILD_DIR)
    os.remove(CACHE_FILE)
    io.write("Cleared build files\n")
end

if args["clear"] then
    clear_build()
else
    build_game(args["all"])
end
