#!/usr/bin/env bash

# -- Create a git archive for each git revision (if not already existing)
num=0
padded_num=''
git rev-list --reverse master | while read rev; do
    printf -v padded_num "%03d" ${num}

    if [ -d archive/data/${padded_num} ]
    then
        echo archive ${padded_num} for ${rev} - already exists
    else
        echo archive ${padded_num} for ${rev} - creating

        mkdir -p archive/data/${padded_num}
        git archive ${rev} | (cd archive/data/${padded_num}; tar x index.html styles.css)
    fi

    num=$((num+1))
done

# -- Create a screenshot for each git archive (if not already existing)
# Start HTTP server
python -m SimpleHTTPServer 8001 &
http_server_pid=$!

# Loop through git revisions
num=0
padded_num=''
screenshot_file_name=''
git rev-list --reverse master | while read rev; do
    printf -v padded_num "%03d" ${num}

    if [ -f archive/data/${padded_num}/screenshot.jpg ]
    then
        echo screenshot ${padded_num} for ${rev} - already exists
    else
        echo screenshot ${padded_num} for ${rev} - creating

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
    fi

    num=$((num+1))
done

# Stop HTTP server
kill -9 ${http_server_pid}
