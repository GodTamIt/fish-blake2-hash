#! /usr/bin/env fish

set argc (count $argv)

if test $argc -ne 2
    echo "Unexpected number of arguments!"
    exit 1
end

# This is where the files will be
set cur_dir (basename $argv[1])
if not test -d $cur_dir
    echo "$cur_dir is not a valid directory!"
    exit 1
end

# This is where the hashes will be
set hash_dir (basename $argv[2])
if test -e $hash_dir
    if not test -d $hash_dir
        echo "$hash_dir already exists but is not a directory!"
        exit 1
    end
else
    mkdir -p $hash_dir
end

# Find all non-hidden files in the directory
set file_paths (find $cur_dir -not -path "*/\.*" -type f -name "[!.]*" -and ! -name "*.blake2")

# Find all the corresponding hash files that don't exist
for file_path in $file_paths
    set file_name (realpath --relative-to=$cur_dir $file_path)
    set hash_path "$hash_dir/$file_name.blake2"

    # Remove any zero-sized hash files
    if test -e $hash_path
        set hash_file_size (stat --format=%s $hash_path)
        if test $hash_file_size -eq 0
            rm $hash_path
        end
    end

    if not test -e $hash_path
        # Make the file if it doesn't exist
        mkdir -p (dirname $hash_path)
        touch $hash_path

        # Escape the paths in the command
        set arg (string escape $file_path)
        set pipe_out (string escape $hash_path)

        set -a commands "b2sum --binary --length 512 $arg > $pipe_out"
    end
end

if test -n "$commands"
    set command_count (count $commands)
    echo "Creating checksums for $command_count files..."
    parallel -n 1 ::: $commands
else
    echo "No file hashes need to be created."
end
