#!/usr/bin/env ruby

# Copyright (C) 2020 Orange
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Version.............: 1.0.0
# Since...............: 11/05/2020
# Description.........: Checks in the LOG_FILE if commits have been signed-off and if commits authors have been defined.
# Use the principle the LOG_FILE is a temporary file containg results of `git log` command.
# Will split the massive log into a bunch of small commits logs using "commit" word delimiter.
#
# Usage: ruby find-missing-developers-in-git-commits.rb  LOGS_FILE
#

VERSION = "1.0.0"

DEBUG = false
COMMIT_DELIMITER = "commit" 
SIGNED_OF_PATTERN = "Signed-off-by:"
AUTHOR_PATTERN = "Author:"

# ---------
# Functions
# ---------

# Displays the usage of the script
def usage()
    STDOUT.puts "USAGE: ruby find-missing-developers-in-git-commits.rb  LOGS_FILE"
end

# Logs a message in standard output
# @param message The message to log
# 
def log(message)
    STDOUT.puts message
end

# Logs a message in error output
# @param message The message to log
#
def error(message)
    STDERR.puts message
end

# Logs a message in standard output if DEBUG flag is set to true
# @param message The message to log
def debug(message)
    if DEBUG
        log message
    end
end

# Extracts from the commit bundle the hash.
# Assumes the bundle is a whole commit log and the hash is in the first line.
# @param commit The commit bundle to parse
# @return The commit hash
def extract_commit_hash(commit)
    return commit.lines.first.strip!
end

# -------------
# Get arguments
# -------------

if ARGV.length == 1 && ARGV[0] == "--help"
    usage
    exit
end

if ARGV.length == 1 && ARGV[0] == "--version"
    log "VERSION: #{VERSION}"
    exit
end

if ARGV.length != 1
    error "ERROR: Expected only 1 argument"
    usage
    exit
end

git_log_file = ARGV[0]

# ---------------
# Check arguments
# ---------------

debug "Should process commits in log file '#{git_log_file}' with delimiter '#{COMMIT_DELIMITER}'"

if git_log_file.to_s.empty?
    error "The file to use '#{git_log_file}' is not defined"
    exit
end

if !File.exist?(git_log_file)
    error "The file to use '#{git_log_file}' does not exist"
    exit
end

if !File.file?(git_log_file)
    error "The object at '#{git_log_file}' is not a file"
    exit
end

debug "Will process commits in log file '#{git_log_file}' with delimiter '#{COMMIT_DELIMITER}'"

# ---------------
# Processes files
# ---------------

git_log_file_splits = File.read(git_log_file).split(COMMIT_DELIMITER)

# --------------------------------
# Process commits splits and words
# --------------------------------

# We assume each commit message looks like:
            
#   commit abcdefghijklmnopqrstuvwxyz
#   Author: Foo Bar <foo.bar@wizz.bzh>
#   Date:   Thu Aug 8 13:37:42 2012 +0000
# 
#       chore: #0 - did things
#       ...
#       
#       Signed-off-by: Foo Bar <foo.bar@wizz.bzh>
#       

git_log_file_splits.each do |commit|
   
    unless commit.nil? || commit.length <= 0
        
        commit_hash = extract_commit_hash commit
        commit_downcase = commit.downcase

        # ---------------------------
        # Looks for signed-off fields
        # ---------------------------

        dco_pattern_downcase = SIGNED_OF_PATTERN.downcase

        # Check if signed-off available for this commit
        if commit_downcase.include? dco_pattern_downcase

            # Extract the DCO name:
            # 1 - cut the commit message with the "signed-off symbol" 
            # 2 - keep the next part (following text, "on the right")
            # 3 - cut using '\n' with devides each commit message line and keep the first
            # 4 - remove useless caracters like spaces
            commit_dco_raw_split = commit_downcase.split(dco_pattern_downcase)
            commit_dco_split_right_part = commit_dco_raw_split[1]
            commit_dco_split_right_part_top_line = commit_dco_split_right_part.split("\n")[0]
            commit_dco = commit_dco_split_right_part_top_line.strip

            if commit_dco.length <= 0
                log "Undefined signed-off value for commit '#{commit_hash}'"
            end

        # Signed-off not available in this commit    
        else
            log "Missing signed-off field for commit '#{commit_hash}'"
        end

        # -----------------------
        # Looks for author fields
        # -----------------------

        author_pattern_downcase = AUTHOR_PATTERN.downcase

        # Check if author field is available for this commit
        if commit_downcase.include? author_pattern_downcase

            # Extract the author name:
            # 1 - cut the commit message with the "author symbol" 
            # 2 - keep the next part (following text, "on the right")
            # 3 - cut using '\n' with devides each commit message line and keep the first
            # 4 - remove useless caracters like spaces
            commit_author_raw_split = commit_downcase.split(author_pattern_downcase)
            commit_author_split_right_part = commit_author_raw_split[1]
            commit_author_split_right_part_top_line = commit_author_split_right_part.split("\n")[0]
            commit_author = commit_author_split_right_part_top_line.strip

            if commit_author.length <= 0
                log "Undefined author value for commit '#{commit_hash}'"
            end

        # Author not available in this commit    
        else
            log "Missing author field for commit '#{commit_hash}'"
        end

    end # End of unless commit.nil? || commit.length <= 0

end # End of git_log_file_splits.each do |commit|
