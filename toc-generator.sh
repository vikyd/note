#!/bin/bash

getTocMdFiles(){
  find . -iname '*.md' \
  | xargs grep -nwlzP -e '<!--ts-->' | xargs grep -nwlzP -e '<!--te-->'
}

echo "Generate TOC begin: ..."
getTocMdFiles | xargs -L 1 -P 50 gh-md-toc --insert --no-backup 
echo "Generate TOC end."
echo "-----------------"

echo "Remove time row in TOC begin: ..."
# remove time content to aviod too many changes
getTocMdFiles | xargs sed -i '/<!-- Added by:/d' 
echo "Remove time row in TOC end."


# find . -iname '*.md' | grep -rnwlzP -e '<!--ts-->' 

# |  grep -rnwlzP '.' -e '<!--ts-->\n<!--te-->' \

# awk cut first 2 column: https://stackoverflow.com/a/22908787/2752670
# find . -iname '*.md' \
# |  grep --line-buffered -rnwlzP '.' -e '<!--ts-->\n<!--te-->' \
# | awk -F '' '{sub($1$2 FS,"")}100' \
# | xargs -L 1 gh-md-toc --insert --no-backup 
