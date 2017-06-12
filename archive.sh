#!/usr/bin/env bash

# -- Empty the archive/data folder
rm -rf archive/data

# -- Create a git archive for each git revision
num=0
padded_num=''
git rev-list --reverse master | while read rev; do
    printf -v padded_num "%03d" ${num}

    echo creating archive ${padded_num} for ${rev}

    mkdir -p archive/data/${padded_num}
    git archive ${rev} | (cd archive/data/${padded_num}; tar x index.html styles.css)

    num=$((num+1))
done

# -- Create a screenshot for each git archive
# Start HTTP server
python -m SimpleHTTPServer 8001 &
http_server_pid=$!

# Loop through git revisions
num=0
padded_num=''
screenshot_file_name=''
git rev-list --reverse master | while read rev; do
    printf -v padded_num "%03d" ${num}

    echo creating screenshot ${padded_num} for ${rev}

    # Open chrome
    google-chrome --headless --hide-scrollbars --remote-debugging-port=9222 --disable-gpu &
    chrome_pid=$!

    # Wait for chrome to open
    sleep 1

    # Take screenshot
    node chrome-headless-screenshots/index.js --viewportWidth=2000 --viewportHeight=1280 --format=jpeg --url="http://localhost:8001/archive/data/${padded_num}/index.html"
    convert output.jpg -resize 200x128 output.jpg
    mv output.jpg archive/data/${padded_num}/screenshot.jpg

    # Close chrome
    kill -9 ${chrome_pid}

    num=$((num+1))
done

# Stop HTTP server
kill -9 ${http_server_pid}
