local M = {}

function M.copyDatabaseTo( filename, destination )
    assert( type(filename) == "string", "string expected for the first parameter but got " .. type(filename) .. " instead." )
    assert( type(destination) == "table", "table expected for the second paramter but bot " .. type(destination) .. " instead." )
    local sourceDBpath = system.pathForFile( filename, system.ResourceDirectory )
    
    -- io.open opens a file at path; returns nil if no file found
    local readHandle, errorString = io.open( sourceDBpath, "rb" )
    assert( readHandle, "Database at " .. filename .. " could not be read from system.ResourceDirectory" )
    assert( type(destination.filename) == "string", "filename should be a string, its a " .. type(destination.filename) )
    print( type(destination.baseDir) )
    assert( type(destination.baseDir) == "userdata", "baseName should be a valid system directory" )
    local destinationDBpath = system.pathForFile( destination.filename, destination.baseDir )
    local writeHandle, writeErrorString = io.open( destinationDBpath, "wb" )
    assert( writeHandle, "Could not open " .. destination.filename .. " for writing." )
    local contents = readHandle:read( "*a" )
    writeHandle:write( contents )
    io.close( writeHandle )
    io.close( readHandle )
    return true
end

return M