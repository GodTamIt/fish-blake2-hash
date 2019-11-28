#! /usr/bin/env fish

set argc (count $argv)

if test $argc -ne 1
    echo "Unexpected number of arguments!"
    exit 1
end

set hash_dir (basename $argv[1])

if not test -d $hash_dir
    echo "$hash_dir is not a valid directory!"
    exit 1
end

set hash_paths (find $hash_dir -type f -name "*.blake2")

for i in (seq (count $hash_paths))
    set hash_path $hash_paths[$i]

    set hash_file_size (stat --format=%s $hash_path)
    if test $hash_file_size -eq 0
        echo "Removing 0-sized hash file: $hash_path"
        rm $hash_path
    else
        set -a check_paths $hash_path
    end
end

if test -n "$check_paths"
    set check_count (count $check_paths)
    echo "Checking $check_count checksums..."

    parallel -n 1 "b2sum --check {}" ::: $check_paths
else
    echo "No hash files to check."
end
